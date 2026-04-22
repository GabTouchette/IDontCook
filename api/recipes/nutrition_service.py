import logging
import re
from typing import Optional, Dict, Any
from django.conf import settings
from .models import NutritionData
from .usda_api import USDAClient

# Words that describe preparation or state, not the ingredient itself.
# These pollute USDA searches and cause bad matches.
_PREP_WORDS = {
    'fresh', 'dried', 'dry', 'frozen', 'raw', 'cooked', 'roasted', 'toasted',
    'minced', 'chopped', 'diced', 'sliced', 'grated', 'shredded', 'spiralized',
    'crushed', 'ground', 'mashed', 'peeled', 'deveined', 'trimmed', 'halved',
    'quartered', 'julienned', 'cubed', 'crumbled', 'pureed', 'squeezed',
    'boneless', 'skinless', 'pitted', 'seeded', 'cored',
    'large', 'small', 'medium', 'whole', 'handful',
    'unsalted', 'salted', 'sweetened', 'unsweetened', 'plain',
    'organic', 'extra', 'virgin', 'pure', 'natural',
    'leaves', 'leaf', 'cloves', 'clove', 'stalks', 'stalk', 'sprig', 'sprigs',
    'slices', 'chunks', 'pieces', 'strips',
    'finely', 'roughly', 'thinly', 'coarsely',
}


def _clean_for_usda(name: str) -> str:
    """Strip preparation/state words from an ingredient name before USDA lookup.

    Examples:
        'Garlic cloves, minced'  -> 'garlic'
        'Fresh basil leaves'     -> 'basil'
        'Chicken breast, boneless skinless' -> 'chicken breast'
    """
    # Remove anything after a comma (preparation notes)
    name = name.split(',')[0]
    # Tokenize and drop prep words
    tokens = re.split(r'[\s/]+', name.lower())
    cleaned = [t for t in tokens if t and t not in _PREP_WORDS]
    result = ' '.join(cleaned).strip()
    # Fall back to original (lowercased, comma-stripped) if everything was stripped
    return result if result else name.split(',')[0].strip().lower()


class NutritionService:
    def __init__(self):
        self.usda_client = USDAClient()
        
    def get_nutrition_for_parsed_ingredient(self, ingredient_name: str, quantity: float, unit: str = None, usda_name: str = None) -> Optional[Dict[str, float]]:
        """
        Get nutrition data for an already-parsed ingredient.
        Use this when you have ingredient name, quantity, unit, and optional usda_name already separated.
        """
        result, _ = self._lookup_ingredient(ingredient_name, quantity, unit, usda_name)
        return result

    def _lookup_ingredient(
        self,
        ingredient_name: str,
        quantity: float,
        unit: str = None,
        usda_name: str = None,
    ):
        """Internal: returns (scaled_dict, NutritionData_or_None)."""
        try:
            print(f"\n=== NUTRITION DEBUG START ===")
            print(f"Original ingredient: '{ingredient_name}', quantity: {quantity}, unit: '{unit}', usda_name: '{usda_name}'")
            
            # Prefer explicit usda_name; otherwise clean the ingredient name of prep words
            if usda_name:
                search_name = usda_name
            else:
                search_name = _clean_for_usda(ingredient_name)
            print(f"Using search_name: '{search_name}'")
            
            # Check local database first
            existing_obj = self._get_nutrition_data_obj(search_name)
            if existing_obj:
                scaled_result = self._scale_nutrition(self._nutrition_to_dict(existing_obj), quantity, unit, search_name)
                return scaled_result, existing_obj
            
            print(f"Not found in local DB, searching USDA...")
            usda_result = self.usda_client.search_food(search_name)
            
            if usda_result:
                print(f"USDA API returned result: {usda_result}")
                # Save to local database
                nutrition_data_obj = self._save_usda_result(usda_result, search_name)
                print(f"Saved nutrition data: {nutrition_data_obj}")
                result = self._nutrition_to_dict(nutrition_data_obj)
                print(f"Nutrition dict (per 100g): {result}")
                scaled_result = self._scale_nutrition(result, quantity, unit, search_name)
                print(f"Final scaled result: {scaled_result}")
                print(f"=== NUTRITION DEBUG END (from USDA) ===\n")
                return scaled_result, nutrition_data_obj
            else:
                print(f"=== NUTRITION DEBUG END (no results) ===\n")
                return None, None
            
        except Exception as e:
            import traceback
            print(f"ERROR in nutrition lookup: {str(e)}")
            print(f"Traceback: {traceback.format_exc()}")
            print(f"=== NUTRITION DEBUG END (error) ===\n")
            return None, None
    
    def _nutrition_to_dict(self, nutrition_data: NutritionData) -> Dict[str, float]:
        """Convert NutritionData model to dictionary."""
        return {
            'calories': nutrition_data.calories_per_100g,
            'protein': nutrition_data.protein_per_100g,
            'fat': nutrition_data.fat_per_100g,
            'carbs': nutrition_data.carbs_per_100g,
        }
    
    def _scale_nutrition(self, nutrition_data: Dict[str, float], quantity: float, unit: str, ingredient_name: str = '') -> Dict[str, float]:
        """Scale nutrition data based on quantity and unit."""
        grams = self._convert_to_grams(quantity, unit, ingredient_name)
        scale_factor = grams / 100.0  # nutrition_data is per 100g
        
        print(f"SCALING DEBUG: {quantity} {unit} '{ingredient_name}' -> {grams:.1f}g, scale_factor: {scale_factor:.3f}")
        print(f"Original nutrition (per 100g): {nutrition_data}")
        
        scaled_result = {
            key: value * scale_factor
            for key, value in nutrition_data.items()
        }
        
        print(f"Scaled nutrition result: {scaled_result}")
        return scaled_result
    
    def _convert_to_grams(self, quantity: float, unit: str, ingredient_name: str = '') -> float:
        """Convert quantity/unit to grams, with density hints for volumetric units."""
        if not unit:
            # No unit: assume it's a count. Default 50g per item (egg, apple, etc.)
            return quantity * 50

        unit = unit.lower().strip()

        # --- Exact mass/weight conversions ---
        mass_conversions = {
            'g': 1, 'gram': 1, 'grams': 1,
            'kg': 1000, 'kilogram': 1000, 'kilograms': 1000,
            'oz': 28.35, 'ounce': 28.35, 'ounces': 28.35,
            'lb': 453.6, 'pound': 453.6, 'lbs': 453.6, 'pounds': 453.6,
            'mg': 0.001, 'milligram': 0.001, 'milligrams': 0.001,
        }
        if unit in mass_conversions:
            return quantity * mass_conversions[unit]

        # --- Piece/count conversions with ingredient hint ---
        name_lower = ingredient_name.lower()

        piece_weights = {
            # generic
            'piece': 50, 'pieces': 50, 'pc': 50,
            'item': 50, 'items': 50,
            # specific
            'slice': 25, 'slices': 25,
            'clove': 4, 'cloves': 4,          # garlic clove ~4g
            'leaf': 1, 'leaves': 1,            # herb leaf ~1g
            'sprig': 3, 'sprigs': 3,
            'stalk': 40, 'stalks': 40,         # celery stalk
            'ear': 150, 'ears': 150,            # corn ear
            'head': 500, 'heads': 500,          # lettuce/cabbage head
            'bunch': 100, 'bunches': 100,
            'can': 400, 'cans': 400,
        }
        if unit in piece_weights:
            return quantity * piece_weights[unit]

        # --- Size words used as units ---
        size_weights = {
            'small': 80, 'medium': 150, 'large': 230, 'extra-large': 300,
        }
        if unit in size_weights:
            return quantity * size_weights[unit]

        # --- Volumetric conversions (density-aware) ---
        # Convert to mL first, then apply density
        ml_conversions = {
            'ml': 1, 'milliliter': 1, 'milliliters': 1, 'millilitre': 1, 'millilitres': 1,
            'l': 1000, 'liter': 1000, 'liters': 1000, 'litre': 1000, 'litres': 1000,
            'fl oz': 29.57, 'fluid oz': 29.57, 'fluid ounce': 29.57, 'fluid ounces': 29.57,
            'cup': 240, 'cups': 240, 'cup(s)': 240,
            'tbsp': 15, 'tablespoon': 15, 'tablespoon(s)': 15, 'tablespoons': 15,
            'tsp': 5, 'teaspoon': 5, 'teaspoon(s)': 5, 'teaspoons': 5,
        }

        if unit in ml_conversions:
            ml = quantity * ml_conversions[unit]
            density = self._get_volume_density(name_lower)
            return ml * density

        # Unknown unit — assume small dried/powdered portion (5g as conservative guess)
        return quantity * 5

    # Approximate g/mL densities by ingredient keyword
    _DENSITY_HINTS = [
        # liquids: close to water
        (['water', 'broth', 'stock', 'juice', 'milk', 'buttermilk', 'cream', 'yogurt',
          'vinegar', 'sauce', 'syrup', 'molasses', 'ketchup', 'wine', 'beer'], 1.0),
        # oils / fats: lighter than water
        (['oil', 'butter', 'ghee', 'lard', 'shortening'], 0.88),
        # honey / maple syrup: heavier
        (['honey', 'maple'], 1.40),
        # flour / starch (unsifted): ~0.6
        (['flour', 'starch', 'cornstarch', 'cornmeal', 'powder'], 0.60),
        # sugar (granulated): ~0.85
        (['sugar', 'salt', 'baking soda', 'baking powder'], 0.85),
        # grated/shredded hard cheese: ~0.30
        (['parmesan', 'pecorino', 'romano'], 0.30),
        # shredded soft cheese / mozzarella: ~0.50
        (['cheddar', 'mozzarella', 'cheese', 'gouda', 'swiss', 'gruyere'], 0.50),
        # leafy herbs (very light): ~0.04 g/mL
        (['basil', 'cilantro', 'parsley', 'mint', 'thyme', 'oregano', 'dill',
          'chive', 'rosemary', 'sage', 'tarragon'], 0.04),
        # ground spices: ~0.50
        (['cumin', 'paprika', 'turmeric', 'cinnamon', 'pepper', 'cayenne',
          'chili', 'curry', 'ginger', 'nutmeg', 'clove', 'cardamom',
          'coriander', 'allspice', 'anise'], 0.50),
        # oats / rolled grains: ~0.40
        (['oat', 'oats', 'grain', 'quinoa', 'rice', 'lentil', 'bean', 'chickpea',
          'pea', 'barley'], 0.75),
        # chopped/diced vegetables (denser than herbs): ~0.55
        (['onion', 'garlic', 'tomato', 'pepper', 'carrot', 'celery', 'zucchini',
          'mushroom', 'spinach', 'kale', 'broccoli', 'cabbage'], 0.55),
        # chopped nuts: ~0.55
        (['almond', 'walnut', 'pecan', 'cashew', 'pistachio', 'peanut',
          'hazelnut', 'nut'], 0.55),
        # seeds: ~0.65
        (['sesame', 'sunflower', 'pumpkin', 'flax', 'chia', 'seed'], 0.65),
    ]

    def _get_volume_density(self, name_lower: str) -> float:
        """Return approximate g/mL density for a volumetric ingredient."""
        for keywords, density in self._DENSITY_HINTS:
            if any(kw in name_lower for kw in keywords):
                return density
        # Default: treat as water-like liquid
        return 1.0

    
    def _get_nutrition_data_obj(self, search_name: str) -> Optional[NutritionData]:
        """Return a cached NutritionData object from the local DB, or None."""
        return NutritionData.objects.filter(
            normalized_name=search_name.lower()
        ).first()

    # Keep legacy helper for any external callers
    def _get_from_local_db(self, search_name: str):
        obj = self._get_nutrition_data_obj(search_name)
        if obj:
            return self._nutrition_to_dict(obj)
        return None
    
    def _save_usda_result(self, usda_data: Dict[str, Any], original_name: str) -> NutritionData:
        """Save USDA API result to local database, using get_or_create to prevent race conditions."""
        usda_description = usda_data.get('description', original_name)
        nutrition_data, _ = NutritionData.objects.get_or_create(
            name=usda_description,
            defaults={
                'normalized_name': original_name.lower(),
                'calories_per_100g': usda_data.get('calories', 0),
                'protein_per_100g': usda_data.get('protein', 0),
                'fat_per_100g': usda_data.get('fat', 0),
                'carbs_per_100g': usda_data.get('carbs', 0),
                'usda_fdc_id': str(usda_data.get('fdcId', '')) if usda_data.get('fdcId') else None,
            },
        )
        return nutrition_data

    def estimate_nutrition_with_llm(self, recipe) -> Optional[Dict[str, float]]:
        """Ask Claude to estimate per-serving nutrition when USDA data is unavailable/anomalous.

        Returns a dict with keys 'calories', 'protein', 'fat', 'carbs' (per serving),
        or None on failure.
        """
        try:
            from django.conf import settings
            import anthropic
            import json
            import re

            servings = recipe.servings or 1
            ingredient_lines = []
            for ing in recipe.ingredients.all():
                qty = ing.quantity or ''
                unit = ing.unit or ''
                name = ing.name or ''
                ingredient_lines.append(f"- {qty} {unit} {name}".strip())

            ingredients_text = '\n'.join(ingredient_lines) or 'No ingredients listed'

            prompt = (
                f"Recipe: {recipe.title or 'unknown'}\n"
                f"Servings: {servings}\n"
                f"Ingredients:\n{ingredients_text}\n\n"
                "Estimate the total nutrition for the entire recipe and return ONLY a JSON object "
                "with these exact keys: calories, protein_g, fat_g, carbs_g. "
                "All values must be numbers (total for the whole recipe, not per serving). "
                "No explanation, no markdown fences, just the raw JSON."
            )

            client = anthropic.Anthropic(api_key=getattr(settings, 'ANTHROPIC_API_KEY', None))
            response = client.messages.create(
                model='claude-haiku-4-5',
                max_tokens=256,
                messages=[{'role': 'user', 'content': prompt}],
            )

            raw = response.content[0].text.strip()
            raw = re.sub(r'^```[a-z]*\s*|\s*```$', '', raw).strip()
            data = json.loads(raw)

            total_cal = float(data.get('calories', 0))
            total_protein = float(data.get('protein_g', 0))
            total_fat = float(data.get('fat_g', 0))
            total_carbs = float(data.get('carbs_g', 0))

            print(f"🤖 LLM nutrition estimate for '{recipe.title}': "
                  f"{total_cal:.0f} cal / {servings} servings = {total_cal/servings:.0f} cal/serving")

            return {
                'calories': total_cal,
                'protein': total_protein,
                'fat': total_fat,
                'carbs': total_carbs,
            }

        except Exception as e:
            print(f"LLM nutrition fallback failed: {e}")
            return None

    def calculate_recipe_nutrition(self, recipe) -> Dict[str, float]:
        """Calculate total nutrition for a recipe based on its ingredients."""
        total_nutrition = {
            'calories': 0,
            'protein': 0,
            'fat': 0,
            'carbs': 0,
        }
        
        
        for ingredient in recipe.ingredients.all():
            if ingredient.name and ingredient.quantity:
                nutrition = self.get_nutrition_for_parsed_ingredient(
                    ingredient.name, 
                    ingredient.quantity, 
                    ingredient.unit,
                    ingredient.usda_name
                )
                
                if nutrition:
                    total_nutrition['calories'] += nutrition.get('calories', 0)
                    total_nutrition['protein'] += nutrition.get('protein', 0)
                    total_nutrition['fat'] += nutrition.get('fat', 0)
                    total_nutrition['carbs'] += nutrition.get('carbs', 0)
        
        return total_nutrition
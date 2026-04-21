import logging
from typing import Optional, Dict, Any
from django.conf import settings
from .models import NutritionData
from .usda_api import USDAClient


class NutritionService:
    def __init__(self):
        self.usda_client = USDAClient()
        
    def get_nutrition_for_parsed_ingredient(self, ingredient_name: str, quantity: float, unit: str = None, usda_name: str = None) -> Optional[Dict[str, float]]:
        """
        Get nutrition data for an already-parsed ingredient.
        Use this when you have ingredient name, quantity, unit, and optional usda_name already separated.
        """
        try:
            print(f"\n=== NUTRITION DEBUG START ===")
            print(f"Original ingredient: '{ingredient_name}', quantity: {quantity}, unit: '{unit}', usda_name: '{usda_name}'")
            
            # Always use usda_name if provided, otherwise fall back to ingredient_name
            search_name = usda_name if usda_name else ingredient_name
            print(f"Using search_name: '{search_name}'")
            
            # Check local database first
            existing_data = self._get_from_local_db(search_name)
            if existing_data:
                scaled_result = self._scale_nutrition(existing_data, quantity, unit)
                return scaled_result
            
            print(f"Not found in local DB, searching USDA...")
            usda_result = self.usda_client.search_food(search_name)
            
            if usda_result:
                print(f"USDA API returned result: {usda_result}")
                # Save to local database
                nutrition_data = self._save_usda_result(usda_result, search_name)
                print(f"Saved nutrition data: {nutrition_data}")
                result = self._nutrition_to_dict(nutrition_data)
                print(f"Nutrition dict (per 100g): {result}")
                scaled_result = self._scale_nutrition(result, quantity, unit)
                print(f"Final scaled result: {scaled_result}")
                print(f"=== NUTRITION DEBUG END (from USDA) ===\n")
                return scaled_result
            else:
                print(f"=== NUTRITION DEBUG END (no results) ===\n")
                return None
            
        except Exception as e:
            import traceback
            print(f"ERROR in nutrition lookup: {str(e)}")
            print(f"Traceback: {traceback.format_exc()}")
            print(f"=== NUTRITION DEBUG END (error) ===\n")
            return None
    
    def _nutrition_to_dict(self, nutrition_data: NutritionData) -> Dict[str, float]:
        """Convert NutritionData model to dictionary."""
        return {
            'calories': nutrition_data.calories_per_100g,
            'protein': nutrition_data.protein_per_100g,
            'fat': nutrition_data.fat_per_100g,
            'carbs': nutrition_data.carbs_per_100g,
        }
    
    def _scale_nutrition(self, nutrition_data: Dict[str, float], quantity: float, unit: str) -> Dict[str, float]:
        """Scale nutrition data based on quantity and unit."""
        grams = self._convert_to_grams(quantity, unit)
        scale_factor = grams / 100.0  # nutrition_data is per 100g
        
        print(f"SCALING DEBUG: {quantity} {unit} -> {grams}g, scale_factor: {scale_factor}")
        print(f"Original nutrition (per 100g): {nutrition_data}")
        
        scaled_result = {
            key: value * scale_factor
            for key, value in nutrition_data.items()
        }
        
        print(f"Scaled nutrition result: {scaled_result}")
        return scaled_result
    
    def _convert_to_grams(self, quantity: float, unit: str) -> float:
        """Convert quantity/unit to grams."""
        if not unit:
            return quantity  # Assume grams if no unit
            
        unit = unit.lower().strip()
        
        # Simple conversion table  
        conversions = {
            'g': 1, 'gram': 1, 'grams': 1,
            'kg': 1000, 'kilogram': 1000,
            'oz': 28.35, 'ounce': 28.35,
            'lb': 453.6, 'pound': 453.6, 'lbs': 453.6,
            'cup': 240, 'cups': 240, 'cup(s)': 240,
            'tbsp': 15, 'tablespoon': 15, 'tablespoon(s)': 15,
            'tsp': 5, 'teaspoon': 5, 'teaspoon(s)': 5,
            'slice': 25, 'slice(s)': 25,  # ~25g per slice
            'piece': 50, 'piece(s)': 50,  # ~50g per piece
            'pieces': 50,
            'clove': 3,  # garlic clove ~3g
            'cloves': 3,
            'medium': 150,  # medium item ~150g
            'large': 250,   # large item ~250g  
            'small': 75,    # small item ~75g
        }
        
        if unit in conversions:
            grams = quantity * conversions[unit]
            return grams
        else:
            # Much more conservative default - assume small portion
            default_grams = quantity * 10  # 10g per unit instead of 100g
            return default_grams
    
    def _get_from_local_db(self, search_name: str) -> Optional[Dict[str, float]]:
        """Check local database for existing nutrition data."""
        # First try exact match on normalized_name (this is the usda_name from ingredients)
        existing = NutritionData.objects.filter(
            normalized_name=search_name.lower()
        ).first()
        
        if existing:
            return {
                'calories': existing.calories_per_100g,
                'protein': existing.protein_per_100g,
                'fat': existing.fat_per_100g,
                'carbs': existing.carbs_per_100g,
            }
        
        return None
    
    def _save_usda_result(self, usda_data: Dict[str, Any], original_name: str) -> NutritionData:
        """Save USDA API result to local database."""
        # Check if already exists to avoid UNIQUE constraint error
        existing = NutritionData.objects.filter(
            normalized_name=original_name.lower()
        ).first()
        if existing:
            return existing
            
        nutrition_data = NutritionData.objects.create(
            name=usda_data.get('description', original_name),
            normalized_name=original_name.lower(),  # This is the usda_name from ingredient
            calories_per_100g=usda_data.get('calories', 0),
            protein_per_100g=usda_data.get('protein', 0),
            fat_per_100g=usda_data.get('fat', 0),
            carbs_per_100g=usda_data.get('carbs', 0),
        )
        return nutrition_data

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
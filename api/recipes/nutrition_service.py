import re
import logging
import hashlib
from typing import Optional, Dict, Any, List, Tuple
from django.conf import settings
from django.core.cache import cache
from .models import NutritionData
from .usda_api import USDAClient
from .ingredient_parser import IngredientParser
from rapidfuzz import fuzz, process

logger = logging.getLogger(__name__)

class NutritionService:
    def __init__(self):
        self.usda_client = USDAClient()
        self.ingredient_parser = IngredientParser()
        
    def get_nutrition_for_ingredient(self, ingredient_text: str, quantity: float = None, unit: str = None) -> Optional[Dict[str, float]]:
        """
        Get nutrition data for an ingredient with quantity.
        If quantity/unit not provided, parses them from ingredient_text.
        Returns nutrition per specified quantity/unit.
        """
        try:
            print(f"DEBUG: Getting nutrition for ingredient: '{ingredient_text}' with quantity: {quantity}, unit: {unit}")
            # Parse ingredient text to extract quantity, unit, and name if not provided
            if quantity is None or unit is None:
                parsed = self.ingredient_parser.parse_ingredient(ingredient_text)
                ingredient_name = parsed['name']
                quantity = parsed['quantity'] or 100  # Default to 100g
                unit = parsed['unit'] or 'g'
                logger.info(f"DEBUG: Parsed ingredient '{ingredient_text}' -> name: '{ingredient_name}', quantity: {quantity}, unit: {unit}")
            else:
                ingredient_name = ingredient_text
                logger.info(f"DEBUG: Using provided values for '{ingredient_text}' -> quantity: {quantity}, unit: {unit}")
            
            # Step 1: Check cache first
            cache_key = self._make_cache_key(f"nutrition:{ingredient_name.lower()}")
            cached_data = cache.get(cache_key)
            if cached_data:
                logger.info(f"DEBUG: Found cached nutrition for '{ingredient_name}': {cached_data}")
                scaled_result = self._scale_nutrition(cached_data, quantity, unit)
                logger.info(f"DEBUG: Scaled nutrition result: {scaled_result}")
                return scaled_result
            
            # Step 2: Try exact match in local database
            nutrition_data = self._find_exact_match(ingredient_name)
            if nutrition_data:
                result = self._nutrition_to_dict(nutrition_data)
                cache.set(cache_key, result, 60 * 60 * 24 * 7)  # Cache for 1 week
                return self._scale_nutrition(result, quantity, unit)
            
            # Step 3: Fuzzy matching
            nutrition_data = self._find_fuzzy_match(ingredient_name)
            if nutrition_data:
                result = self._nutrition_to_dict(nutrition_data)
                cache.set(cache_key, result, 60 * 60 * 24 * 7)
                return self._scale_nutrition(result, quantity, unit)
            
            # Step 4: USDA API lookup
            # Clean the ingredient name for better USDA search results
            search_name = self._clean_ingredient_for_usda(ingredient_name)
            logger.info(f"DEBUG: Searching USDA with cleaned name: '{search_name}' (original: '{ingredient_name}')")
            
            usda_result = self.usda_client.search_food(search_name)
            if usda_result:
                nutrition_data = self._save_usda_result(usda_result, ingredient_name)
                result = self._nutrition_to_dict(nutrition_data)
                cache.set(cache_key, result, 60 * 60 * 24 * 7)
                return self._scale_nutrition(result, quantity, unit)
            
            logger.warning(f"No nutrition data found for ingredient: {ingredient_name}")
            return None
            
        except Exception as e:
            logger.error(f"Error getting nutrition for {ingredient_text}: {e}")
            return None
    
    def _find_exact_match(self, ingredient_text: str) -> Optional[NutritionData]:
        """Find exact match in local database."""
        normalized = self._normalize_for_search(ingredient_text)
        return NutritionData.objects.filter(normalized_name=normalized).first()
    
    def _find_fuzzy_match(self, ingredient_text: str, threshold: int = 85) -> Optional[NutritionData]:
        """Find fuzzy match using RapidFuzz."""
        normalized = self._normalize_for_search(ingredient_text)
        
        # Get all nutrition data names for fuzzy matching
        all_names = list(NutritionData.objects.values_list('normalized_name', 'id'))
        if not all_names:
            return None
        
        names = [name[0] for name in all_names]
        name_to_id = {name[0]: name[1] for name in all_names}
        
        # Find best match
        match = process.extractOne(normalized, names, scorer=fuzz.WRatio)
        if match and match[1] >= threshold:
            matched_name = match[0]
            nutrition_id = name_to_id[matched_name]
            return NutritionData.objects.get(id=nutrition_id)
        
        return None
    
    def _normalize_for_search(self, text: str) -> str:
        """Normalize text for consistent searching."""
        text = text.lower().strip()
        text = re.sub(r'\b(fresh|dried|frozen|canned|raw|cooked)\b', '', text)
        text = re.sub(r'\s+', ' ', text).strip()
        return text
    
    def _nutrition_to_dict(self, nutrition_data: NutritionData) -> Dict[str, float]:
        """Convert NutritionData model to dictionary."""
        return {
            'calories': nutrition_data.calories_per_100g,
            'protein': nutrition_data.protein_per_100g,
            'fat': nutrition_data.fat_per_100g,
            'carbs': nutrition_data.carbs_per_100g,
            'fiber': nutrition_data.fiber_per_100g,
            'sugar': nutrition_data.sugar_per_100g,
        }
    
    def _scale_nutrition(self, nutrition_data: Dict[str, float], quantity: float, unit: str) -> Dict[str, float]:
        """Scale nutrition data based on quantity and unit."""
        # Convert to grams (simplified conversion)
        grams = self._convert_to_grams(quantity, unit)
        scale_factor = grams / 100.0  # nutrition_data is per 100g
        
        logger.info(f"DEBUG: Scaling nutrition - quantity: {quantity} {unit} -> {grams}g, scale factor: {scale_factor}")
        
        scaled_result = {
            key: value * scale_factor
            for key, value in nutrition_data.items()
        }
        
        logger.info(f"DEBUG: Original nutrition (per 100g): {nutrition_data}")
        logger.info(f"DEBUG: Scaled nutrition result: {scaled_result}")
        
        return scaled_result
    
    def _convert_to_grams(self, quantity: float, unit: str) -> float:
        """Convert quantity/unit to grams."""
        if not unit:
            logger.info(f"DEBUG: No unit provided, assuming {quantity}g")
            return quantity  # Assume grams if no unit
            
        unit = unit.lower().strip()
        logger.info(f"DEBUG: Converting {quantity} {unit} to grams")
        
        # Weight conversions
        weight_conversions = {
            'g': 1, 'gram': 1, 'grams': 1,
            'kg': 1000, 'kilogram': 1000, 'kilograms': 1000,
            'oz': 28.35, 'ounce': 28.35, 'ounces': 28.35,
            'lb': 453.6, 'pound': 453.6, 'pounds': 453.6, 'lbs': 453.6,
        }
        
        # Volume conversions (approximate - varies by ingredient)
        volume_conversions = {
            'cup': 240, 'cups': 240,  # ~240g for most ingredients
            'tbsp': 15, 'tablespoon': 15, 'tablespoons': 15,
            'tsp': 5, 'teaspoon': 5, 'teaspoons': 5,
            'ml': 1, 'milliliter': 1, 'milliliters': 1,  # ~1g for water-like liquids
            'l': 1000, 'liter': 1000, 'liters': 1000,
        }
        
        # Piece conversions (very approximate)
        piece_conversions = {
            'piece': 100, 'pieces': 100,  # Default 100g per piece
            'clove': 3,  # ~3g per garlic clove
            'slice': 25,  # ~25g per slice
        }
        
        # Check weight first (most accurate)
        if unit in weight_conversions:
            result = quantity * weight_conversions[unit]
            logger.info(f"DEBUG: Weight conversion: {quantity} {unit} = {result}g")
            return result
        
        # Then volume
        if unit in volume_conversions:
            result = quantity * volume_conversions[unit]
            logger.info(f"DEBUG: Volume conversion: {quantity} {unit} = {result}g")
            return result
        
        # Then pieces
        if unit in piece_conversions:
            result = quantity * piece_conversions[unit]
            logger.info(f"DEBUG: Piece conversion: {quantity} {unit} = {result}g")
            return result
        
        # Default fallback
        result = quantity * 100
        logger.warning(f"DEBUG: Unknown unit '{unit}', assuming 100g per unit = {result}g")
        return result
    
    def _save_usda_result(self, usda_data: Dict[str, Any], original_name: str) -> NutritionData:
        """Save USDA API result to local database."""
        normalized_name = self._normalize_for_search(original_name)
        
        nutrition_data = NutritionData.objects.create(
            name=usda_data.get('description', original_name),
            normalized_name=normalized_name,
            calories_per_100g=usda_data.get('calories', 0),
            protein_per_100g=usda_data.get('protein', 0),
            fat_per_100g=usda_data.get('fat', 0),
            carbs_per_100g=usda_data.get('carbs', 0),
            fiber_per_100g=usda_data.get('fiber', 0),
            sugar_per_100g=usda_data.get('sugar', 0),
            usda_fdc_id=usda_data.get('fdc_id'),
        )
        
        return nutrition_data
    
    def _make_cache_key(self, key: str) -> str:
        """Create a safe cache key by hashing problematic characters."""
        # If key is safe (alphanumeric, underscore, hyphen), use as-is
        if re.match(r'^[a-zA-Z0-9_:-]+$', key) and len(key) <= 250:
            return key
        
        # Otherwise, create a hash-based key
        safe_prefix = re.sub(r'[^a-zA-Z0-9_-]', '_', key[:50])
        key_hash = hashlib.md5(key.encode('utf-8')).hexdigest()
        return f"{safe_prefix}_{key_hash}"

    def calculate_recipe_nutrition(self, recipe) -> Dict[str, float]:
        """Calculate total nutrition for a recipe based on its ingredients."""
        total_nutrition = {
            'calories': 0,
            'protein': 0,
            'fat': 0,
            'carbs': 0,
        }
        
        logger.info(f"DEBUG: Calculating nutrition for recipe '{recipe.title}' with {recipe.ingredients.count()} ingredients")
        
        for ingredient in recipe.ingredients.all():
            if ingredient.name and ingredient.quantity:
                logger.info(f"DEBUG: Processing ingredient: '{ingredient.name}' - {ingredient.quantity} {ingredient.unit}")
                
                nutrition = self.get_nutrition_for_ingredient(
                    ingredient.name, 
                    ingredient.quantity or 100, 
                    ingredient.unit or 'g'
                )
                
                if nutrition:
                    logger.info(f"DEBUG: Ingredient nutrition: {nutrition}")
                    total_nutrition['calories'] += nutrition.get('calories', 0)
                    total_nutrition['protein'] += nutrition.get('protein', 0)
                    total_nutrition['fat'] += nutrition.get('fat', 0)
                    total_nutrition['carbs'] += nutrition.get('carbs', 0)
                else:
                    logger.warning(f"DEBUG: No nutrition data found for ingredient: {ingredient.name}")
        
        logger.info(f"DEBUG: Total nutrition before servings adjustment: {total_nutrition}")
        
        # Scale by servings if available
        if recipe.servings and recipe.servings > 0:
            logger.info(f"DEBUG: Dividing by {recipe.servings} servings")
            for key in total_nutrition:
                total_nutrition[key] = total_nutrition[key] / recipe.servings
        
        logger.info(f"DEBUG: Final recipe nutrition per serving: {total_nutrition}")
        return total_nutrition
    
    def _clean_ingredient_for_usda(self, ingredient_name: str) -> str:
        """Clean ingredient name specifically for USDA API searches."""
        # Use the basic cleaning from ingredient parser but be more aggressive
        cleaned = ingredient_name.lower().strip()
        
        # Remove descriptors that don't help with USDA searches
        descriptors_to_remove = [
            'thin', 'thick', 'about', 'peeled', 'with', 'tail', 'without', 
            'boneless', 'skinless', 'slices', 'pieces', 'strips', 'chunks',
            'cubes', 'fresh', 'dried', 'frozen', 'canned', 'chopped', 'diced',
            'sliced', 'minced', 'grated', 'shredded', 'ground', 'whole',
            'large', 'small', 'medium', 'raw', 'cooked', 'organic', 'free-range'
        ]
        
        for descriptor in descriptors_to_remove:
            cleaned = re.sub(rf'\b{descriptor}\b', '', cleaned)
        
        # Remove extra whitespace and punctuation
        cleaned = re.sub(r'[,\-]+', ' ', cleaned)
        cleaned = re.sub(r'\s+', ' ', cleaned).strip()
        
        # Handle special cases for better USDA matching
        replacements = {
            'sambal oelek': 'chili paste',
            'pancetta': 'bacon',
            'toothpicks': '',  # Not food
        }
        
        for old, new in replacements.items():
            if old in cleaned:
                cleaned = new
                
        # Remove empty results
        if not cleaned or len(cleaned) < 2:
            return ingredient_name  # Return original if cleaning failed
            
        return cleaned
import requests
import logging
import re
import hashlib
from typing import Optional, Dict, Any, List
from django.conf import settings
from django.core.cache import cache

logger = logging.getLogger(__name__)

class USDAClient:
    """Client for USDA FoodData Central API."""
    
    def __init__(self):
        self.base_url = "https://api.nal.usda.gov/fdc/v1"
        self.api_key = getattr(settings, 'USDA_API_KEY', None)
        
    def search_food(self, query: str, page_size: int = 5) -> Optional[Dict[str, Any]]:
        """
        Search for food in USDA database and return the best match with nutrition data.
        """
        try:
            # Check cache first
            cache_key = self._make_cache_key(f"usda_search:{query.lower()}")
            cached_result = cache.get(cache_key)
            if cached_result:
                logger.info(f"DEBUG: Found cached USDA result for '{query}'")
                return cached_result
            
            # Search for foods
            search_url = f"{self.base_url}/foods/search"
            search_params = {
                'query': query,
                'pageSize': page_size,
                'api_key': self.api_key,
                'dataType': ['Foundation', 'SR Legacy'],  # Prefer these data types
                'sortBy': 'dataType.keyword',
                'sortOrder': 'asc'
            }
            
            response = requests.get(search_url, params=search_params, timeout=10)
            response.raise_for_status()

            print(f"DEBUG: USDA API response for query '{query}': {response.status_code}")  # Debugging line
            
            search_data = response.json()
            foods = search_data.get('foods', [])
            
            if not foods:
                logger.warning(f"DEBUG: No USDA foods found for query: '{query}' - API returned empty results")
                return None
            
            logger.info(f"DEBUG: Found {len(foods)} USDA foods for query: '{query}'")
            
            # Find the best match and get detailed nutrition data
            for i, food in enumerate(foods):
                food_desc = food.get('description', 'Unknown')
                logger.info(f"DEBUG: Trying food {i+1}/{len(foods)}: '{food_desc}'")
                
                nutrition_data = self._extract_nutrition_data(food, query)
                if nutrition_data:
                    logger.info(f"DEBUG: Successfully extracted nutrition from '{food_desc}': {nutrition_data}")
                    # Cache the result
                    cache.set(cache_key, nutrition_data, 60 * 60 * 24 * 7)  # Cache for 1 week
                    return nutrition_data
                else:
                    logger.warning(f"DEBUG: Failed to extract nutrition from '{food_desc}'")
            
            logger.warning(f"DEBUG: No valid nutrition data found in any of the {len(foods)} USDA results for '{query}'")
            return None
            
        except requests.RequestException as e:
            logger.error(f"USDA API request failed for query '{query}': {e}")
            return None
        except Exception as e:
            logger.error(f"Error processing USDA response for query '{query}': {e}")
            return None
    
    def _extract_nutrition_data(self, food_data: Dict[str, Any], original_query: str) -> Optional[Dict[str, Any]]:
        """Extract nutrition data from USDA food item."""
        try:
            fdc_id = food_data.get('fdcId')
            description = food_data.get('description', '')
            
            # Get food nutrients
            nutrients = food_data.get('foodNutrients', [])
            
            # Map USDA nutrient IDs to our fields
            nutrient_map = {
                1008: 'calories',     # Energy (kcal)
                1003: 'protein',      # Protein
                1004: 'fat',          # Total lipid (fat)
                1005: 'carbs',        # Carbohydrate, by difference
                1079: 'fiber',        # Fiber, total dietary
                2000: 'sugar',        # Total sugars
            }
            
            nutrition_data = {
                'fdc_id': str(fdc_id),
                'description': description,
                'calories': 0,
                'protein': 0,
                'fat': 0,
                'carbs': 0,
                'fiber': 0,
                'sugar': 0,
            }
            
            # Extract nutrient values
            for nutrient in nutrients:
                nutrient_id = nutrient.get('nutrientId')
                value = nutrient.get('value', 0)
                
                if nutrient_id in nutrient_map:
                    field_name = nutrient_map[nutrient_id]
                    nutrition_data[field_name] = float(value) if value else 0
            
            logger.info(f"DEBUG: Extracted nutrition values: {nutrition_data}")
            
            # Validate that we have meaningful nutrition data (at least calories OR protein OR carbs)
            has_meaningful_data = (nutrition_data['calories'] > 0 or 
                                 nutrition_data['protein'] > 0 or 
                                 nutrition_data['carbs'] > 0)
            
            if has_meaningful_data:
                return nutrition_data
            else:
                logger.warning(f"DEBUG: No meaningful nutrition data found in food '{description}' - all values are 0")
            
            return None
            
        except Exception as e:
            logger.error(f"Error extracting nutrition data from USDA food: {e}")
            return None
    
    def get_food_details(self, fdc_id: str) -> Optional[Dict[str, Any]]:
        """Get detailed information for a specific food by FDC ID."""
        if not self.api_key:
            return None
            
        try:
            url = f"{self.base_url}/food/{fdc_id}"
            params = {'api_key': self.api_key}
            
            response = requests.get(url, params=params, timeout=10)
            response.raise_for_status()
            
            return response.json()
            
        except requests.RequestException as e:
            logger.error(f"USDA API request failed for FDC ID '{fdc_id}': {e}")
            return None
    
    def _make_cache_key(self, key: str) -> str:
        """Create a safe cache key by hashing problematic characters."""
        # If key is safe (alphanumeric, underscore, hyphen), use as-is
        if re.match(r'^[a-zA-Z0-9_:-]+$', key) and len(key) <= 250:
            return key
        
        # Otherwise, create a hash-based key
        safe_prefix = re.sub(r'[^a-zA-Z0-9_-]', '_', key[:50])
        key_hash = hashlib.md5(key.encode('utf-8')).hexdigest()
        return f"{safe_prefix}_{key_hash}"
import requests
import logging
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
        if not self.api_key:
            logger.warning("USDA API key not configured")
            return None
            
        try:
            # Check cache first
            cache_key = f"usda_search:{query.lower()}"
            cached_result = cache.get(cache_key)
            if cached_result:
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
            
            search_data = response.json()
            foods = search_data.get('foods', [])
            
            if not foods:
                logger.info(f"No USDA foods found for query: {query}")
                return None
            
            # Find the best match and get detailed nutrition data
            for food in foods:
                nutrition_data = self._extract_nutrition_data(food, query)
                if nutrition_data:
                    # Cache the result
                    cache.set(cache_key, nutrition_data, 60 * 60 * 24 * 7)  # Cache for 1 week
                    return nutrition_data
            
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
            
            # Validate that we have at least calories
            if nutrition_data['calories'] > 0:
                return nutrition_data
            
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
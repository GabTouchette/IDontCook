import requests
from typing import Optional, Dict, Any
from django.conf import settings

class USDAClient:
    """Client for USDA FoodData Central API."""
    
    def __init__(self):
        self.base_url = "https://api.nal.usda.gov/fdc/v1"
        self.api_key = getattr(settings, 'USDA_API_KEY', None)
        
    def search_candidates(self, query: str, page_size: int = 10, data_types=None):
        """Return ranked search hits as lightweight ``{fdc_id, description, data_type}``
        dicts, without extracting nutrition.

        Used by ``backfill_canonical_fdc_ids`` to *choose* which FDC entry a
        canonical ingredient should pin to (the caller scores these), as opposed
        to ``search_food`` which eagerly returns the first usable nutrition hit.
        """
        if not self.api_key:
            return []
        try:
            params = {
                'query': query,
                'pageSize': page_size,
                'api_key': self.api_key,
                # Foundation / SR Legacy are the clean generic single-food entries
                # (and carry the richest foodPortions). FNDDS/Survey is excluded by
                # default — it's full of composite dishes ("Bread, onion") that
                # score deceptively well against a bare ingredient name.
                'dataType': data_types or ['Foundation', 'SR Legacy'],
            }
            resp = requests.get(f"{self.base_url}/foods/search", params=params, timeout=10)
            resp.raise_for_status()
            out = []
            for food in resp.json().get('foods', []):
                fdc_id = food.get('fdcId')
                if not fdc_id:
                    continue
                out.append({
                    'fdc_id': str(fdc_id),
                    'description': food.get('description', '') or '',
                    'data_type': food.get('dataType', '') or '',
                })
            return out
        except Exception as exc:
            print(f"ERROR during USDA candidate search for '{query}': {exc}")
            return []

    def search_food(self, query: str, page_size: int = 5) -> Optional[Dict[str, Any]]:
        """
        Search for food in USDA database and return the first valid match with nutrition data.
        """
        try:
            print(f"\n--- USDA API SEARCH START ---")
            print(f"Searching USDA for query: '{query}'")

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

            print(f"Search URL: {search_url}")
            print(f"Search params: {search_params}")

            response = requests.get(search_url, params=search_params, timeout=10)
            response.raise_for_status()

            search_data = response.json()
            foods = search_data.get('foods', [])

            print(f"USDA returned {len(foods)} food results")

            if not foods:
                print("No foods found in USDA search")
                print("--- USDA API SEARCH END (no results) ---\n")
                return None

            print("Trying each result until we find one with usable nutrition data:")
            for i, food in enumerate(foods):
                food_desc = food.get('description', 'Unknown')
                fdc_id = food.get('fdcId', 'Unknown')
                data_type = food.get('dataType', 'Unknown')
                print(f"  {i+1}. Trying [{data_type}] {food_desc} (ID: {fdc_id})")

                nutrition_data = self._extract_nutrition_data(food)
                if nutrition_data:
                    print(f"✓ Selected food: {food_desc}")
                    print(f"✓ Nutrition data: {nutrition_data}")
                    print("--- USDA API SEARCH END (found match) ---\n")
                    return nutrition_data
                else:
                    print(f"✗ Food has insufficient nutrition data")

            print("No foods with complete nutrition data found")
            print("--- USDA API SEARCH END (no valid nutrition) ---\n")
            return None

        except Exception as e:
            print(f"ERROR during USDA search: {str(e)}")
            return None

    
    def _extract_nutrition_data(self, food_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Extract nutrition data from USDA food item."""
        try:
            fdc_id = food_data.get('fdcId')
            description = food_data.get('description', '')
            
            print(f"    Extracting nutrition from: {description} (ID: {fdc_id})")
            
            # Get food nutrients
            nutrients = food_data.get('foodNutrients', [])
            print(f"    Found {len(nutrients)} nutrients in food data")
            
            # Map USDA nutrient IDs to our fields
            nutrient_map = {
                1008: 'calories',     # Energy (kcal) - primary
                1062: 'calories_kj',  # Energy (kJ) - alternative, will convert
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
                'calories_kj': 0,  # For kJ conversion
                'protein': 0,
                'fat': 0,
                'carbs': 0,
                'fiber': 0,
                'sugar': 0,
            }
            
            # Extract nutrient values
            nutrients_found = []
            for nutrient in nutrients:
                nutrient_id = nutrient.get('nutrientId')
                value = nutrient.get('value', 0)
                nutrient_name = nutrient.get('nutrientName', 'Unknown')
                
                if nutrient_id in nutrient_map:
                    field_name = nutrient_map[nutrient_id]
                    nutrition_data[field_name] = float(value) if value else 0
                    nutrients_found.append(f"{field_name}={value}")
                    print(f"    Found {nutrient_name} (ID: {nutrient_id}): {value}")
            
            print(f"    Extracted nutrients: {', '.join(nutrients_found) if nutrients_found else 'none'}")
            
            # Handle missing calories
            if nutrition_data['calories'] == 0:
                # Try to convert from kJ if available
                if nutrition_data['calories_kj'] > 0:
                    nutrition_data['calories'] = nutrition_data['calories_kj'] / 4.184  # Convert kJ to kcal
                    print(f"    Converted {nutrition_data['calories_kj']} kJ to {nutrition_data['calories']:.1f} kcal")
                # Fallback: Calculate from macros (protein=4cal/g, carbs=4cal/g, fat=9cal/g)
                elif nutrition_data['protein'] > 0 or nutrition_data['carbs'] > 0 or nutrition_data['fat'] > 0:
                    calculated_calories = (nutrition_data['protein'] * 4) + (nutrition_data['carbs'] * 4) + (nutrition_data['fat'] * 9)
                    nutrition_data['calories'] = calculated_calories
                    print(f"    Calculated calories from macros: {calculated_calories:.1f} kcal (P:{nutrition_data['protein']}*4 + C:{nutrition_data['carbs']}*4 + F:{nutrition_data['fat']}*9)")
            
            # Remove the temporary kJ field
            del nutrition_data['calories_kj']
            
            # Validate that we have meaningful nutrition data (at least calories OR protein OR carbs)
            has_meaningful_data = (nutrition_data['calories'] > 0 or 
                                 nutrition_data['protein'] > 0 or 
                                 nutrition_data['carbs'] > 0)
            
            print(f"    Has meaningful data: {has_meaningful_data} (calories: {nutrition_data['calories']}, protein: {nutrition_data['protein']}, carbs: {nutrition_data['carbs']})")
            
            if has_meaningful_data:
                print(f"    ✓ Returning nutrition data: {nutrition_data}")
                return nutrition_data
            
            return None
            
        except Exception as e:
            import traceback
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
            return None

    # Nutrient ids shared by the search and detail endpoints.
    _NUTRIENT_MAP = {
        1008: 'calories',
        1062: 'calories_kj',
        1003: 'protein',
        1004: 'fat',
        1005: 'carbs',
        1079: 'fiber',
        2000: 'sugar',
    }

    # USDA measureUnit / modifier words -> the unit labels nutrition_service and
    # grocery_builder already understand. Anything unmapped is passed through
    # lowercased so callers can still decide what to keep.
    _PORTION_UNIT_ALIASES = {
        'tablespoon': 'tbsp', 'tablespoons': 'tbsp', 'tbsp': 'tbsp',
        'teaspoon': 'tsp', 'teaspoons': 'tsp', 'tsp': 'tsp',
        'cup': 'cup', 'cups': 'cup',
        'slice': 'slice', 'slices': 'slice',
        'clove': 'clove', 'cloves': 'clove',
        'leaf': 'leaf', 'leaves': 'leaf',
        'sprig': 'sprig', 'sprigs': 'sprig',
        'stalk': 'stalk', 'stalks': 'stalk',
        'head': 'head', 'heads': 'head',
        'ear': 'ear', 'ears': 'ear',
        'bunch': 'bunch', 'bunches': 'bunch',
        'can': 'can', 'cans': 'can',
        'stick': 'stick', 'sticks': 'stick',
        'piece': 'piece', 'pieces': 'piece',
        'small': 'small', 'medium': 'medium', 'large': 'large',
        'fl oz': 'fl oz', 'fl. oz': 'fl oz',
    }

    def get_nutrition_by_fdc_id(self, fdc_id: str) -> Optional[Dict[str, Any]]:
        """Return per-100g nutrition for one pinned FDC entry (stable linkage).

        Unlike ``search_food`` this does not guess which food matches a name — the
        caller already decided via the canonical catalog's ``usda_fdc_id``.
        """
        detail = self.get_food_details(fdc_id)
        if not detail:
            return None
        return self.parse_detail_nutrition(detail)

    @classmethod
    def parse_detail_nutrition(cls, detail: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Extract nutrition from a ``/food/{fdcId}`` detail payload.

        The detail endpoint nests the nutrient under ``foodNutrient['nutrient']``
        (``id``/``number``) with the value in ``amount`` — a different shape from
        the search endpoint handled by ``_extract_nutrition_data``.
        """
        nutrition = {
            'fdc_id': str(detail.get('fdcId', '')),
            'description': detail.get('description', ''),
            'calories': 0, 'calories_kj': 0,
            'protein': 0, 'fat': 0, 'carbs': 0, 'fiber': 0, 'sugar': 0,
        }
        for fn in detail.get('foodNutrients', []) or []:
            nutrient = fn.get('nutrient') or {}
            try:
                nid = int(nutrient.get('id') or nutrient.get('number') or 0)
            except (TypeError, ValueError):
                continue
            field = cls._NUTRIENT_MAP.get(nid)
            if not field:
                continue
            value = fn.get('amount', fn.get('value', 0)) or 0
            try:
                nutrition[field] = float(value)
            except (TypeError, ValueError):
                nutrition[field] = 0

        if nutrition['calories'] == 0:
            if nutrition['calories_kj'] > 0:
                nutrition['calories'] = nutrition['calories_kj'] / 4.184
            elif nutrition['protein'] or nutrition['carbs'] or nutrition['fat']:
                nutrition['calories'] = (
                    nutrition['protein'] * 4 + nutrition['carbs'] * 4 + nutrition['fat'] * 9
                )
        del nutrition['calories_kj']

        has_data = nutrition['calories'] > 0 or nutrition['protein'] > 0 or nutrition['carbs'] > 0
        return nutrition if has_data else None

    @classmethod
    def parse_food_portions(cls, detail: Dict[str, Any]) -> Dict[str, float]:
        """Extract household-unit gram weights from a detail payload.

        Returns a ``{unit_label: grams_for_one_unit}`` map (e.g.
        ``{"cup": 136.0, "medium": 118.0}``), keeping the smallest gram weight
        when the same unit appears more than once (most specific/least packed).
        Units we don't recognise are skipped — the caller already has a density
        fallback for those.
        """
        out: Dict[str, float] = {}
        for p in detail.get('foodPortions', []) or []:
            gram_weight = p.get('gramWeight')
            if not gram_weight:
                continue
            try:
                amount = float(p.get('amount') or 1) or 1.0
            except (TypeError, ValueError):
                amount = 1.0
            measure = ((p.get('measureUnit') or {}).get('name') or '').strip().lower()
            modifier = (p.get('modifier') or '').strip().lower()
            # Prefer a real measure unit; fall back to the modifier for the common
            # "undetermined" rows ("1 medium", "1 clove").
            raw_label = measure if measure and measure != 'undetermined' else modifier
            label = cls._PORTION_UNIT_ALIASES.get(raw_label)
            if not label:
                # Try the first word of the modifier ("medium (approx 2-1/2\")").
                first = modifier.split()[0] if modifier else ''
                label = cls._PORTION_UNIT_ALIASES.get(first)
            if not label:
                continue
            try:
                grams_per_unit = float(gram_weight) / amount
            except (TypeError, ValueError, ZeroDivisionError):
                continue
            if grams_per_unit <= 0:
                continue
            if label not in out or grams_per_unit < out[label]:
                out[label] = round(grams_per_unit, 2)
        return out
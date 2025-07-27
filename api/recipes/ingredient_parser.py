import re
import logging
import hashlib
from typing import Optional, Dict
from openai import OpenAI
from django.conf import settings
from django.core.cache import cache

logger = logging.getLogger(__name__)

class IngredientParser:
    """
    Parses ingredient text to extract quantity, unit, and ingredient name.
    Handles: "2 cups diced fresh tomatoes" → {'quantity': 2, 'unit': 'cup', 'name': 'tomatoes'}
    """
    
    def __init__(self):
        self.client = OpenAI(api_key=getattr(settings, 'OPENAI_API_KEY', None))
    
    def parse_ingredient(self, ingredient_text: str) -> Dict[str, any]:
        """
        Parse ingredient text to extract name, quantity, and unit.
        Returns: {'name': 'tomatoes', 'quantity': 2.0, 'unit': 'cup'}
        """
        if not ingredient_text or not ingredient_text.strip():
            return {'name': ingredient_text, 'quantity': None, 'unit': None}
        
        # Check cache first
        cache_key = self._make_cache_key(f"ingredient_parse:{ingredient_text.lower()}")
        cached_result = cache.get(cache_key)
        if cached_result:
            return cached_result
        
        try:
            # Try regex-based parsing first (faster)
            parsed = self._regex_parse(ingredient_text)
            if parsed['name']:
                cache.set(cache_key, parsed, 60 * 60 * 24)
                return parsed
            
            # Use AI for complex cases
            if self.client and hasattr(settings, 'OPENAI_API_KEY'):
                ai_parsed = self._ai_parse(ingredient_text)
                if ai_parsed and ai_parsed['name']:
                    cache.set(cache_key, ai_parsed, 60 * 60 * 24)
                    return ai_parsed
            
            # Fallback to basic parsing
            fallback = self._basic_parse(ingredient_text)
            cache.set(cache_key, fallback, 60 * 60 * 24)
            return fallback
            
        except Exception as e:
            logger.error(f"Error parsing ingredient '{ingredient_text}': {e}")
            return self._basic_parse(ingredient_text)
    
    def _regex_parse(self, text: str) -> Dict[str, any]:
        """Parse ingredient using regex patterns."""
        text = text.strip()
        
        # Pattern 1: quantity unit ingredient (e.g., "2 cups tomatoes", "1 tbsp butter")
        pattern1 = r'^([\d\s/.,\-]+)\s+(cups?|tbsp|tsp|tablespoons?|teaspoons?|oz|ounces?|lb|lbs|pounds?|kg|g|grams?|ml|l|liters?|pieces?|cloves?)\s+(.+)$'
        
        match = re.match(pattern1, text, re.IGNORECASE)
        if match:
            quantity_str = match.group(1).strip()
            unit = match.group(2).strip()
            ingredient_name = match.group(3).strip()
            
            quantity = self._parse_quantity(quantity_str)
            ingredient_name = self._clean_ingredient_name(ingredient_name)
            
            return {
                'name': ingredient_name,
                'quantity': quantity,
                'unit': self._standardize_unit(unit) if unit else None
            }
        
        # Pattern 2: unit ingredient without explicit quantity (e.g., "Tbsp butter" = "1 Tbsp butter")
        pattern2 = r'^(cups?|tbsp|tsp|tablespoons?|teaspoons?|oz|ounces?|lb|lbs|pounds?|kg|g|grams?|ml|l|liters?|pieces?|cloves?)\s+(.+)$'
        
        match = re.match(pattern2, text, re.IGNORECASE)
        if match:
            unit = match.group(1).strip()
            ingredient_name = match.group(2).strip()
            
            ingredient_name = self._clean_ingredient_name(ingredient_name)
            
            return {
                'name': ingredient_name,
                'quantity': 1.0,  # Default to 1 unit
                'unit': self._standardize_unit(unit)
            }
        
        # Pattern 3: quantity ingredient without unit (e.g., "3-4 large eggs")
        pattern3 = r'^([\d\s/.,\-]+)\s+(.+)$'
        
        match = re.match(pattern3, text, re.IGNORECASE)
        if match:
            quantity_str = match.group(1).strip()
            ingredient_name = match.group(2).strip()
            
            quantity = self._parse_quantity(quantity_str)
            ingredient_name = self._clean_ingredient_name(ingredient_name)
            
            return {
                'name': ingredient_name,
                'quantity': quantity,
                'unit': 'piece'  # Default to pieces for countable items
            }
        
        # No quantity pattern found
        cleaned_name = self._clean_ingredient_name(text)
        return {'name': cleaned_name, 'quantity': None, 'unit': None}
    
    def _ai_parse(self, ingredient_text: str) -> Optional[Dict[str, any]]:
        """Use OpenAI to parse ingredient text."""
        try:
            prompt = f'''Parse this ingredient text and extract quantity, unit, and name:

"{ingredient_text}"

Return JSON with:
- quantity: number (convert fractions, use average for ranges)
- unit: standardized unit (cup, tbsp, tsp, oz, lb, kg, g, ml, l, piece)
- name: core ingredient name only

Examples:
"2 cups diced fresh tomatoes" → {{"quantity": 2, "unit": "cup", "name": "tomatoes"}}
"1/2 lb ground beef" → {{"quantity": 0.5, "unit": "lb", "name": "ground beef"}}
"3-4 large eggs" → {{"quantity": 3.5, "unit": "piece", "name": "eggs"}}

JSON:'''

            response = self.client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=[{"role": "user", "content": prompt}],
                max_tokens=100,
                temperature=0
            )
            
            result_text = response.choices[0].message.content.strip()
            
            # Parse JSON response
            import json
            try:
                result = json.loads(result_text)
                return {
                    'name': result.get('name', '').lower().strip(),
                    'quantity': result.get('quantity'),
                    'unit': result.get('unit', '').lower().strip() if result.get('unit') else None
                }
            except json.JSONDecodeError:
                logger.warning(f"Failed to parse AI JSON response: {result_text}")
                return None
                
        except Exception as e:
            logger.error(f"OpenAI parsing failed for '{ingredient_text}': {e}")
            return None
    
    def _basic_parse(self, text: str) -> Dict[str, any]:
        """Basic fallback parsing."""
        # Extract leading numbers
        quantity_match = re.match(r'^([\d\s/.,\-]+)', text.strip())
        quantity = None
        
        if quantity_match:
            quantity_str = quantity_match.group(1).strip()
            quantity = self._parse_quantity(quantity_str)
            # Remove quantity from text
            text = text[len(quantity_match.group(0)):].strip()
        
        # Remove common units at start
        text = re.sub(r'^(cups?|tbsp|tsp|oz|lb|kg|g|ml|l)\s+', '', text, flags=re.IGNORECASE)
        
        return {
            'name': self._clean_ingredient_name(text),
            'quantity': quantity,
            'unit': None
        }
    
    def _parse_quantity(self, quantity_str: str) -> Optional[float]:
        """Parse quantity string to float."""
        try:
            # Handle fractions
            if '/' in quantity_str:
                if ' ' in quantity_str:
                    # Mixed number like "1 1/2"
                    parts = quantity_str.split()
                    whole = float(parts[0])
                    frac_parts = parts[1].split('/')
                    fraction = float(frac_parts[0]) / float(frac_parts[1])
                    return whole + fraction
                else:
                    # Simple fraction like "1/2"
                    frac_parts = quantity_str.split('/')
                    return float(frac_parts[0]) / float(frac_parts[1])
            
            # Handle ranges like "2-3"
            if '-' in quantity_str:
                range_parts = quantity_str.split('-')
                if len(range_parts) == 2:
                    try:
                        low = float(range_parts[0].strip())
                        high = float(range_parts[1].strip())
                        return (low + high) / 2  # Use average
                    except ValueError:
                        pass
            
            # Simple number
            return float(quantity_str.strip())
            
        except (ValueError, IndexError):
            return None
    
    def _clean_ingredient_name(self, text: str) -> str:
        """Clean ingredient name by removing descriptors."""
        text = text.lower().strip()
        
        # Remove common descriptors and preparation methods
        descriptors = r'\b(fresh|dried|frozen|canned|chopped|diced|sliced|minced|grated|shredded|ground|whole|large|small|medium|raw|cooked|organic|free-range|to taste|thin|thick|about|peeled|with|tail|without|boneless|skinless)\b'
        text = re.sub(descriptors, '', text)
        
        # Remove measurement descriptors that often appear with ingredient names
        measure_descriptors = r'\b(slices?|pieces?|strips?|chunks?|cubes?|cloves?)\b'
        text = re.sub(measure_descriptors, '', text)
        
        # Remove extra whitespace and commas
        text = re.sub(r'[,]+', ' ', text)
        text = re.sub(r'\s+', ' ', text).strip()
        
        # Remove parenthetical information
        text = re.sub(r'\([^)]*\)', '', text).strip()
        
        # Remove leading/trailing non-letter characters
        text = re.sub(r'^[^a-zA-Z]+|[^a-zA-Z]+$', '', text).strip()
        
        return text
    
    def _standardize_unit(self, unit: str) -> str:
        """Standardize unit names."""
        if not unit:
            return None
            
        unit = unit.lower().strip()
        
        # Standardization mapping
        unit_map = {
            'cups': 'cup', 'c': 'cup',
            'tablespoons': 'tbsp', 'tablespoon': 'tbsp', 'tbsps': 'tbsp',
            'teaspoons': 'tsp', 'teaspoon': 'tsp', 'tsps': 'tsp',
            'ounces': 'oz', 'ounce': 'oz',
            'pounds': 'lb', 'pound': 'lb', 'lbs': 'lb',
            'grams': 'g', 'gram': 'g',
            'kilograms': 'kg', 'kilogram': 'kg',
            'milliliters': 'ml', 'milliliter': 'ml',
            'liters': 'l', 'liter': 'l',
            'pieces': 'piece', 'pcs': 'piece',
            'cloves': 'clove'
        }
        
        return unit_map.get(unit, unit)
    
    def _make_cache_key(self, key: str) -> str:
        """Create a safe cache key by hashing problematic characters."""
        # If key is safe (alphanumeric, underscore, hyphen), use as-is
        if re.match(r'^[a-zA-Z0-9_:-]+$', key) and len(key) <= 250:
            return key
        
        # Otherwise, create a hash-based key
        safe_prefix = re.sub(r'[^a-zA-Z0-9_-]', '_', key[:50])
        key_hash = hashlib.md5(key.encode('utf-8')).hexdigest()
        return f"{safe_prefix}_{key_hash}"
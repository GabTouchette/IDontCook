import re
import logging
from typing import Optional, Dict, Tuple
from openai import OpenAI
from django.conf import settings
from django.core.cache import cache

logger = logging.getLogger(__name__)

class AIIngredientNormalizer:
    def __init__(self):
        self.client = OpenAI(api_key=getattr(settings, 'OPENAI_API_KEY', None))
    
    def parse_ingredient(self, ingredient_text: str) -> Dict[str, any]:
        """
        Parse ingredient text to extract name, quantity, and unit.
        Returns: {'name': 'tomatoes', 'quantity': 2.0, 'unit': 'cups'}
        """
        if not ingredient_text or not ingredient_text.strip():
            return {'name': ingredient_text, 'quantity': None, 'unit': None}
        
        # Check cache first
        cache_key = f"ai_parse:{ingredient_text.lower()}"
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
                if ai_parsed:
                    cache.set(cache_key, ai_parsed, 60 * 60 * 24)
                    return ai_parsed
            
            # Fallback to basic parsing
            fallback = self._basic_parse(ingredient_text)
            cache.set(cache_key, fallback, 60 * 60 * 24)
            return fallback
            
        except Exception as e:
            logger.error(f"Error parsing ingredient '{ingredient_text}': {e}")
            return self._basic_parse(ingredient_text)
        
    def normalize_ingredient(self, ingredient_text: str) -> str:
        """
        Normalize ingredient text using AI to extract the core ingredient name.
        Example: "2 cups diced fresh tomatoes" -> "tomatoes"
        """
        if not ingredient_text or not ingredient_text.strip():
            return ingredient_text
        
        # Check cache first
        cache_key = f"ai_normalize:{ingredient_text.lower()}"
        cached_result = cache.get(cache_key)
        if cached_result:
            return cached_result
        
        try:
            # Quick regex-based normalization for common patterns
            quick_normalized = self._quick_normalize(ingredient_text)
            if quick_normalized != ingredient_text:
                cache.set(cache_key, quick_normalized, 60 * 60 * 24)  # Cache for 1 day
                return quick_normalized
            
            # Use AI for complex cases
            if self.client and hasattr(settings, 'OPENAI_API_KEY'):
                ai_normalized = self._ai_normalize(ingredient_text)
                if ai_normalized:
                    cache.set(cache_key, ai_normalized, 60 * 60 * 24)
                    return ai_normalized
            
            # Fallback to basic cleanup
            fallback = self._basic_normalize(ingredient_text)
            cache.set(cache_key, fallback, 60 * 60 * 24)
            return fallback
            
        except Exception as e:
            logger.error(f"Error normalizing ingredient '{ingredient_text}': {e}")
            return self._basic_normalize(ingredient_text)
    
    def _quick_normalize(self, text: str) -> str:
        """Quick regex-based normalization for common patterns."""
        text = text.lower().strip()
        
        # Remove quantities and units at the beginning
        text = re.sub(r'^[\d\s/.,]+\s*(cups?|tbsp|tsp|oz|lb|kg|g|ml|l|pounds?|ounces?|tablespoons?|teaspoons?|gallons?|quarts?|pints?)\s+', '', text)
        
        # Remove common descriptors
        descriptors = r'\b(fresh|dried|frozen|canned|chopped|diced|sliced|minced|grated|shredded|ground|whole|large|small|medium|raw|cooked|organic|free-range)\b'
        text = re.sub(descriptors, '', text)
        
        # Remove extra whitespace
        text = re.sub(r'\s+', ' ', text).strip()
        
        # Remove parenthetical information
        text = re.sub(r'\([^)]*\)', '', text).strip()
        
        return text
    
    def _ai_normalize(self, ingredient_text: str) -> Optional[str]:
        """Use OpenAI to normalize ingredient text."""
        try:
            prompt = f"""Extract the core ingredient name from this text: "{ingredient_text}"

Rules:
- Remove quantities, units, and measurements
- Remove cooking methods (chopped, diced, etc.)
- Remove descriptors (fresh, organic, etc.)
- Return only the basic ingredient name in singular form
- Keep it simple - just the food item

Examples:
"2 cups diced fresh tomatoes" -> "tomato"
"1 lb ground beef (80/20)" -> "ground beef"
"3 large eggs" -> "egg"
"1/2 cup olive oil" -> "olive oil"

Ingredient: {ingredient_text}
Core ingredient:"""

            response = self.client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=[{"role": "user", "content": prompt}],
                max_tokens=50,
                temperature=0
            )
            
            result = response.choices[0].message.content.strip().lower()
            
            # Basic validation
            if len(result) > 100 or not result.replace(' ', '').isalpha():
                return None
                
            return result
            
        except Exception as e:
            logger.error(f"OpenAI normalization failed for '{ingredient_text}': {e}")
            return None
    
    def _basic_normalize(self, text: str) -> str:
        """Basic fallback normalization."""
        text = text.lower().strip()
        
        # Remove everything before the last word if it contains numbers
        words = text.split()
        if len(words) > 1:
            # Find the first word that doesn't contain numbers or units
            for i, word in enumerate(words):
                if not re.search(r'[\d/]', word) and word not in ['cup', 'cups', 'tbsp', 'tsp', 'oz', 'lb', 'kg', 'g']:
                    return ' '.join(words[i:])
        
        return text
import re
import logging
from typing import Dict, List, Optional, Tuple
from django.conf import settings
import openai


class IngredientValidator:
    """
    Service for validating and normalizing ingredient formats to ensure
    accurate nutrition calculations and consistent data structure.
    """
    
    def __init__(self):
        self.openai_api_key = getattr(settings, 'OPENAI_API_KEY', None)
        if self.openai_api_key:
            openai.api_key = self.openai_api_key
    
    def validate_and_fix_ingredient(self, ingredient_text: str) -> Dict:
        """
        Validate and standardize ingredient format.
        
        Args:
            ingredient_text (str): Raw ingredient text
            
        Returns:
            dict: {
                'original': str,
                'fixed': str,
                'parsed': dict,
                'issues': list,
                'confidence': float,
                'method': str
            }
        """
        try:
            result = {
                'original': ingredient_text,
                'fixed': ingredient_text,
                'parsed': None,
                'issues': [],
                'confidence': 1.0,
                'method': 'no_change'
            }
            
            # Step 1: Basic validation
            validation_result = self._validate_format(ingredient_text)
            
            if validation_result['is_valid']:
                result['parsed'] = validation_result['parsed']
                result['confidence'] = validation_result['confidence']
                result['method'] = 'regex_parse'
                return result
            
            # Step 2: Try to fix common issues
            fixed_text = self._fix_common_issues(ingredient_text)
            if fixed_text != ingredient_text:
                validation_result = self._validate_format(fixed_text)
                if validation_result['is_valid']:
                    result['fixed'] = fixed_text
                    result['parsed'] = validation_result['parsed']
                    result['issues'] = ['fixed_common_formatting']
                    result['confidence'] = validation_result['confidence'] * 0.9
                    result['method'] = 'common_fixes'
                    return result
            
            # Step 3: Use AI to fix complex issues
            if self.openai_api_key:
                ai_result = self._ai_fix_ingredient(ingredient_text)
                if ai_result['success']:
                    validation_result = self._validate_format(ai_result['fixed_text'])
                    if validation_result['is_valid']:
                        result['fixed'] = ai_result['fixed_text']
                        result['parsed'] = validation_result['parsed']
                        result['issues'] = ['ai_fixed'] + ai_result.get('issues', [])
                        result['confidence'] = validation_result['confidence'] * 0.8
                        result['method'] = 'ai_fix'
                        return result
            
            # Step 4: Create best-effort parse
            fallback_parsed = self._fallback_parse(ingredient_text)
            result['parsed'] = fallback_parsed
            result['issues'] = ['fallback_parse', 'low_confidence']
            result['confidence'] = 0.3
            result['method'] = 'fallback'
            
            return result
            
        except Exception as e:
            return {
                'original': ingredient_text,
                'fixed': ingredient_text,
                'parsed': self._fallback_parse(ingredient_text),
                'issues': ['validation_error'],
                'confidence': 0.1,
                'method': 'error_fallback'
            }
    
    def _validate_format(self, ingredient_text: str) -> Dict:
        """
        Validate if ingredient text has proper format.
        
        Expected format: "quantity unit ingredient_name"
        Examples: "1 cup flour", "2 tablespoons olive oil", "3 medium onions"
        """
        if not ingredient_text or not isinstance(ingredient_text, str):
            return {'is_valid': False, 'parsed': None, 'confidence': 0.0}
        
        text = ingredient_text.strip()
        if len(text) < 3:
            return {'is_valid': False, 'parsed': None, 'confidence': 0.0}
        
        # Try to parse with regex
        parsed = self._regex_parse(text)
        
        if not parsed:
            return {'is_valid': False, 'parsed': None, 'confidence': 0.0}
        
        # Validate parsed components
        validation_score = self._calculate_validation_score(parsed)
        
        return {
            'is_valid': validation_score >= 0.7,
            'parsed': parsed,
            'confidence': validation_score
        }
    
    def _regex_parse(self, text: str) -> Optional[Dict]:
        """Parse ingredient text using regex patterns."""
        
        # Comprehensive regex patterns for ingredient parsing
        patterns = [
            # Pattern 1: "2 cups all-purpose flour"
            r'^(\d+(?:\.\d+)?(?:\s*-\s*\d+(?:\.\d+)?)?(?:\s+\d+/\d+)?)\s+([a-zA-Z\s-]+?)\s+(.+)$',
            
            # Pattern 2: "1/2 cup butter"
            r'^(\d+/\d+|\d+\s+\d+/\d+)\s+([a-zA-Z\s-]+?)\s+(.+)$',
            
            # Pattern 3: "3 large eggs"
            r'^(\d+(?:\.\d+)?)\s+(large|medium|small|whole|piece|pieces|items?)\s+(.+)$',
            
            # Pattern 4: "1 tablespoon olive oil"
            r'^(\d+(?:\.\d+)?)\s+([a-zA-Z]+)\s+(.+)$',
            
            # Pattern 5: "2-3 medium onions"
            r'^(\d+\s*-\s*\d+)\s+(large|medium|small|whole|pieces?)\s+(.+)$',
            
            # Pattern 6: Just quantity and ingredient (no unit)
            r'^(\d+(?:\.\d+)?(?:\s*-\s*\d+(?:\.\d+)?)?)\s+(.+)$'
        ]
        
        for pattern in patterns:
            match = re.match(pattern, text.strip(), re.IGNORECASE)
            if match:
                groups = match.groups()
                
                if len(groups) == 3:
                    quantity_str, unit, name = groups
                elif len(groups) == 2:
                    quantity_str, name = groups
                    unit = None
                else:
                    continue
                
                # Parse quantity
                quantity = self._parse_quantity(quantity_str)
                if quantity is None:
                    continue
                
                # Clean unit and name
                unit = self._clean_unit(unit) if unit else None
                name = self._clean_ingredient_name(name)
                
                if name:  # Must have a valid ingredient name
                    return {
                        'quantity': quantity,
                        'unit': unit,
                        'name': name,
                        'original_text': text
                    }
        
        return None
    
    def _parse_quantity(self, quantity_str: str) -> Optional[float]:
        """Parse quantity string to float."""
        try:
            quantity_str = quantity_str.strip()
            
            # Handle ranges like "2-3" -> take average
            if '-' in quantity_str:
                parts = quantity_str.split('-')
                if len(parts) == 2:
                    low = float(parts[0].strip())
                    high = float(parts[1].strip())
                    return (low + high) / 2
            
            # Handle fractions like "1/2" or "1 1/2"
            if '/' in quantity_str:
                parts = quantity_str.split()
                total = 0
                
                for part in parts:
                    if '/' in part:
                        frac_parts = part.split('/')
                        if len(frac_parts) == 2:
                            total += float(frac_parts[0]) / float(frac_parts[1])
                    else:
                        total += float(part)
                
                return total
            
            # Simple decimal number
            return float(quantity_str)
            
        except (ValueError, ZeroDivisionError):
            return None
    
    def _clean_unit(self, unit: str) -> Optional[str]:
        """Clean and standardize unit names."""
        if not unit:
            return None
        
        unit = unit.lower().strip()
        
        # Unit standardization mapping
        unit_mappings = {
            # Volume
            'cups': 'cup', 'c': 'cup',
            'tablespoons': 'tablespoon', 'tbsp': 'tablespoon', 'tb': 'tablespoon',
            'teaspoons': 'teaspoon', 'tsp': 'teaspoon', 't': 'teaspoon',
            'milliliters': 'ml', 'milliliter': 'ml',
            'liters': 'liter', 'l': 'liter',
            
            # Weight
            'grams': 'gram', 'g': 'gram',
            'kilograms': 'kilogram', 'kg': 'kilogram',
            'ounces': 'ounce', 'oz': 'ounce',
            'pounds': 'pound', 'lbs': 'pound', 'lb': 'pound',
            
            # Count/Size
            'pieces': 'piece', 'items': 'piece', 'item': 'piece',
            'whole': 'piece', 'each': 'piece',
            'large': 'large', 'medium': 'medium', 'small': 'small',
            
            # Slices/cuts
            'slices': 'slice', 'strips': 'strip', 'chunks': 'chunk',
            'cloves': 'clove', 'stalks': 'stalk', 'leaves': 'leaf'
        }
        
        return unit_mappings.get(unit, unit)
    
    def _clean_ingredient_name(self, name: str) -> Optional[str]:
        """Clean ingredient name by removing unnecessary descriptors."""
        if not name:
            return None
        
        name = name.strip().lower()
        
        # Remove parenthetical information
        name = re.sub(r'\([^)]*\)', '', name)
        
        # Remove common descriptors that don't affect nutrition
        descriptors_to_remove = [
            r'\b(fresh|dried|frozen|canned|raw|cooked)\b',
            r'\b(organic|free-range|grass-fed)\b',
            r'\b(chopped|diced|sliced|minced|grated|shredded)\b',
            r'\b(finely|coarsely|roughly)\b',
            r'\b(about|approximately|around)\b',
            r'\b(or to taste|to taste)\b',
            r'\b(optional)\b'
        ]
        
        for pattern in descriptors_to_remove:
            name = re.sub(pattern, ' ', name, flags=re.IGNORECASE)
        
        # Clean up extra whitespace
        name = re.sub(r'\s+', ' ', name).strip()
        
        # Remove leading/trailing articles and prepositions
        name = re.sub(r'^(a|an|the|of|for)\s+', '', name)
        name = re.sub(r'\s+(a|an|the|of|for)$', '', name)
        
        return name if len(name) > 1 else None
    
    def _calculate_validation_score(self, parsed: Dict) -> float:
        """Calculate confidence score for parsed ingredient."""
        score = 0.0
        
        # Quantity validation (30%)
        if parsed.get('quantity') and parsed['quantity'] > 0:
            score += 0.3
            # Bonus for reasonable quantities
            if 0.1 <= parsed['quantity'] <= 100:
                score += 0.1
        
        # Unit validation (30%)
        unit = parsed.get('unit')
        if unit:
            known_units = {
                'cup', 'tablespoon', 'teaspoon', 'gram', 'kilogram', 'ounce', 'pound',
                'piece', 'large', 'medium', 'small', 'clove', 'slice', 'ml', 'liter'
            }
            if unit.lower() in known_units:
                score += 0.3
            else:
                score += 0.1  # Unknown but present unit
        
        # Name validation (40%)
        name = parsed.get('name')
        if name and len(name) >= 2:
            score += 0.2
            # Bonus for reasonable length
            if 3 <= len(name) <= 50:
                score += 0.1
            # Bonus for common ingredient patterns
            if any(word in name for word in ['oil', 'flour', 'sugar', 'salt', 'pepper', 'onion', 'garlic']):
                score += 0.1
        
        return min(score, 1.0)
    
    def _fix_common_issues(self, text: str) -> str:
        """Fix common formatting issues in ingredient text."""
        fixed = text.strip()
        
        # Fix spacing issues
        fixed = re.sub(r'\s+', ' ', fixed)
        
        # Fix fraction formatting
        fixed = re.sub(r'(\d)\s*\/\s*(\d)', r'\1/\2', fixed)
        
        # Fix unit abbreviations
        unit_fixes = {
            r'\btbs\b': 'tablespoon',
            r'\btbsp\.\b': 'tablespoon',
            r'\btsp\.\b': 'teaspoon',
            r'\bc\.\b': 'cup',
            r'\boz\.\b': 'ounce',
            r'\blb\.\b': 'pound',
            r'\bg\.\b': 'gram',
        }
        
        for pattern, replacement in unit_fixes.items():
            fixed = re.sub(pattern, replacement, fixed, flags=re.IGNORECASE)
        
        # Remove extra punctuation
        fixed = re.sub(r'[,;]', '', fixed)
        
        # Fix capitalization (capitalize first letter only)
        if fixed:
            fixed = fixed[0].upper() + fixed[1:].lower()
        
        return fixed
    
    def _ai_fix_ingredient(self, ingredient_text: str) -> Dict:
        """Use OpenAI to fix malformed ingredient text."""
        try:
            prompt = f"""
Fix this ingredient to have clear quantity, unit, and name in the format "quantity unit ingredient_name":

Original: "{ingredient_text}"

Requirements:
- Must include a number for quantity
- Should include a standard cooking unit (cup, tablespoon, teaspoon, ounce, pound, gram, piece, etc.)
- Must include the ingredient name
- Remove unnecessary descriptors (fresh, chopped, etc.)
- Use standard abbreviations (tbsp, tsp, oz, lb)

Examples of good format:
- "1 cup all-purpose flour"
- "2 tablespoons olive oil"
- "3 medium onions"
- "1/2 teaspoon salt"

Return only the fixed ingredient text, nothing else.
"""

            response = openai.ChatCompletion.create(
                model="gpt-3.5-turbo",
                messages=[{"role": "user", "content": prompt}],
                max_tokens=50,
                temperature=0.1
            )
            
            fixed_text = response.choices[0].message.content.strip()
            
            # Basic validation that AI response is reasonable
            if len(fixed_text) > 100 or not re.search(r'\d', fixed_text):
                return {'success': False, 'error': 'Invalid AI response'}
            
            return {
                'success': True,
                'fixed_text': fixed_text,
                'issues': ['ai_formatting']
            }
            
        except Exception as e:
            return {'success': False, 'error': str(e)}
    
    def _fallback_parse(self, text: str) -> Dict:
        """Create a best-effort parse when all else fails."""
        # Extract any numbers as potential quantities
        numbers = re.findall(r'\d+(?:\.\d+)?', text)
        quantity = float(numbers[0]) if numbers else 1.0
        
        # Look for potential units
        text_lower = text.lower()
        unit = None
        for potential_unit in ['cup', 'tablespoon', 'teaspoon', 'ounce', 'pound', 'gram', 'piece']:
            if potential_unit in text_lower:
                unit = potential_unit
                break
        
        # Use entire text as ingredient name (cleaned)
        name = self._clean_ingredient_name(text) or text.strip()
        
        return {
            'quantity': quantity,
            'unit': unit,
            'name': name,
            'original_text': text
        }
    
    def validate_recipe_ingredients(self, ingredients: List[str]) -> Dict:
        """Validate all ingredients in a recipe."""
        results = {
            'ingredients': [],
            'summary': {
                'total_count': len(ingredients),
                'valid_count': 0,
                'fixed_count': 0,
                'error_count': 0,
                'average_confidence': 0.0
            }
        }
        
        total_confidence = 0.0
        
        for ingredient_text in ingredients:
            validation_result = self.validate_and_fix_ingredient(ingredient_text)
            results['ingredients'].append(validation_result)
            
            total_confidence += validation_result['confidence']
            
            if validation_result['confidence'] >= 0.8:
                results['summary']['valid_count'] += 1
            elif validation_result['confidence'] >= 0.5:
                results['summary']['fixed_count'] += 1
            else:
                results['summary']['error_count'] += 1
        
        if ingredients:
            results['summary']['average_confidence'] = total_confidence / len(ingredients)
        
        return results
    
    def suggest_improvements(self, validation_result: Dict) -> List[str]:
        """Suggest improvements for ingredient formatting."""
        suggestions = []
        
        if validation_result['confidence'] < 0.7:
            suggestions.append("Consider using standard format: 'quantity unit ingredient'")
        
        if 'fallback_parse' in validation_result['issues']:
            suggestions.append("Ingredient format not recognized - please verify quantity and unit")
        
        if 'ai_fixed' in validation_result['issues']:
            suggestions.append("Ingredient was auto-corrected - please verify accuracy")
        
        parsed = validation_result.get('parsed', {})
        
        if not parsed.get('unit'):
            suggestions.append("Consider adding a measurement unit (cup, tablespoon, ounce, etc.)")
        
        if parsed.get('quantity', 0) > 50:
            suggestions.append("Large quantity detected - please verify measurement")
        
        return suggestions
import re
from typing import List, Tuple
from recipes.models import Recipe
from rapidfuzz import fuzz

class RecipeSearchEngine:
    def __init__(self):
        # Increased weights for title matches
        self.field_weights = {
            'title': 5.0,  # Much higher weight for titles
            'description': 1.0,
            'ingredients': 2.0,
            'tags': 1.5
        }
        
        # Lower threshold for title matches
        self.similarity_thresholds = {
            'title': 0.55,  # More forgiving for titles
            'default': 0.65
        }
        
        # For stemming and typos
        self.common_typos = {
            'cheicken': 'chicken',
            'chicen': 'chicken',
            'beff': 'beef',
            'pota': 'potato',
            'tomatos': 'tomato',
            # Add more common typos
        }
        
        # For synonyms
        self.synonyms = {
            'aubergine': 'eggplant',
            'courgette': 'zucchini',
            'capsicum': 'bell pepper',
        }

    def _normalize_text(self, text: str) -> List[str]:
        """Improved text normalization"""
        if not text:
            return []
            
        text = text.lower()
        text = re.sub(r'[^\w\s]', ' ', text)  # Remove punctuation
        tokens = text.split()
        
        # Handle common typos
        processed_tokens = []
        for token in tokens:
            # Fix common typos first
            token = self.common_typos.get(token, token)
            # Then handle synonyms
            token = self.synonyms.get(token, token)
            processed_tokens.append(token)
            
        return processed_tokens

    def _score_field(self, field_value: str, query_tokens: List[str], field_type: str) -> float:
        """Score a single field with improved fuzzy matching"""
        if not field_value:
            return 0.0
            
        field_tokens = self._normalize_text(field_value)
        threshold = self.similarity_thresholds.get(field_type, self.similarity_thresholds['default'])
        field_score = 0.0
        
        for field_token in field_tokens:
            for query_token in query_tokens:
                # Use rapidfuzz for better fuzzy matching
                similarity = fuzz.ratio(field_token, query_token) / 100
                
                # Partial matches (e.g. "chick" matches "chicken")
                partial_similarity = fuzz.partial_ratio(field_token, query_token) / 100
                
                # Use the higher of the two similarity scores
                current_similarity = max(similarity, partial_similarity)
                
                if current_similarity >= threshold:
                    weight = self.field_weights[field_type]
                    
                    # Bonus for exact matches
                    if field_token == query_token:
                        current_similarity *= 1.5
                    
                    # Bonus for title matches
                    if field_type == 'title':
                        current_similarity *= 2.0
                    
                    field_score += current_similarity * weight
        
        return field_score

    def _score_recipe(self, recipe: Recipe, query_tokens: List[str]) -> float:
        """Calculate search score with improved field scoring"""
        total_score = 0.0
        
        # Title gets special handling for higher priority
        if recipe.title:
            title_score = self._score_field(recipe.title, query_tokens, 'title')
            total_score += title_score * 2  # Additional title boost
        
        # Description
        if recipe.description:
            total_score += self._score_field(recipe.description, query_tokens, 'description')
        
        # Ingredients
        for ingredient in recipe.ingredients.all():
            if ingredient.name:
                total_score += self._score_field(ingredient.name, query_tokens, 'ingredients')
        
        # Tags
        if hasattr(recipe, 'tags') and recipe.tags:
            for tag in recipe.tags:
                if tag:
                    total_score += self._score_field(tag, query_tokens, 'tags')
        
        return total_score

    def search(self, query: str, recipes: List[Recipe], limit: int = 50) -> List[Tuple[Recipe, float]]:
        """Improved search with better ranking"""
        if not query.strip():
            return []
            
        query_tokens = self._normalize_text(query)
        
        # Score all recipes
        scored_recipes = []
        for recipe in recipes:
            score = self._score_recipe(recipe, query_tokens)
            if score > 0:
                scored_recipes.append((recipe, score))
        
        # Sort by score (descending) and get top results
        scored_recipes.sort(key=lambda x: x[1], reverse=True)
        
        return scored_recipes[:limit]
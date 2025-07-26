from typing import List, Tuple
from recipes.models import Recipe

class RecipeSearchEngine:
    def search(self, query: str, recipes: List[Recipe], limit: int = 50) -> List[Tuple[Recipe, float]]:
        """Ultra-simple search that prioritizes exact matches"""
        query = query.lower().strip()
        if not query:
            return []

        scored_recipes = []
        
        for recipe in recipes:
            score = 0
            title = recipe.title.lower() if recipe.title else ""
            
            # 1. Exact phrase match in title (highest priority)
            if query in title:
                score += 100
            
            # 2. All query words in title (very high priority)
            query_words = query.split()
            if all(word in title for word in query_words):
                score += 50
            
            # 3. Any query word in title (medium priority)
            for word in query_words:
                if word in title:
                    score += 10
            
            # 4. Exact phrase match in ingredients/description
            ingredients_text = " ".join([i.name.lower() for i in recipe.ingredients.all() if i.name])
            if query in ingredients_text:
                score += 5
            
            # 5. Any query word in ingredients
            for word in query_words:
                if word in ingredients_text:
                    score += 1
            
            if score > 0:
                scored_recipes.append((recipe, score))
        
        # Sort by score (descending) and then by title (ascending) for consistency
        scored_recipes.sort(key=lambda x: (-x[1], x[0].title))
        
        return scored_recipes[:limit]
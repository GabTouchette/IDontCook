import os
import requests
from celery import shared_task

from recipes.models import Recipe
from ai_chatbot.api import OpenAIService

USDA_API_KEY = os.getenv('USDA_API_KEY')
SEARCH_URL = "https://api.nal.usda.gov/fdc/v1/foods/search"

@shared_task
def format_recipe_ingredients(recipe_id):
    recipe = Recipe.objects.get(id=recipe_id)
    if not recipe.is_formatted:
        recipe = OpenAIService().llm_format_ingredients(recipe)
        recipe.is_formatted = True
        recipe.save()

@shared_task
def get_recipe_nutrition_info(recipe_id):
    """Calculate nutrition for a recipe using the nutrition service."""
    try:
        recipe = Recipe.objects.get(id=recipe_id)
        
        # Import here to avoid circular imports
        from recipes.nutrition_service import NutritionService
        
        service = NutritionService()
        nutrition = service.calculate_recipe_nutrition(recipe)
        
        # Update recipe with calculated nutrition
        recipe.calories = nutrition.get('calories')
        recipe.protein = nutrition.get('protein')
        recipe.fat = nutrition.get('fat')
        recipe.carbs = nutrition.get('carbs')
        recipe.save()
        
        return f"Updated nutrition for recipe {recipe.title}: {nutrition.get('calories', 0):.1f} calories"
        
    except Recipe.DoesNotExist:
        return f"Recipe with ID {recipe_id} not found"
    except Exception as e:
        return f"Error calculating nutrition for recipe {recipe_id}: {str(e)}"
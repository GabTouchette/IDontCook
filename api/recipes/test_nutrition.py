from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
import json
from .nutrition_service import NutritionService
from .ingredient_parser import IngredientParser

@csrf_exempt
@require_http_methods(["POST"])
def test_nutrition_parsing(request):
    """Test endpoint for nutrition parsing - no auth required."""
    try:
        data = json.loads(request.body)
        ingredient_text = data.get('ingredient', '')
        
        if not ingredient_text:
            return JsonResponse({'error': 'ingredient field is required'}, status=400)
        
        # Parse ingredient
        parser = IngredientParser()
        parsed = parser.parse_ingredient(ingredient_text)
        
        # Get nutrition
        nutrition_service = NutritionService()
        nutrition = nutrition_service.get_nutrition_for_ingredient(ingredient_text)
        
        return JsonResponse({
            'input': ingredient_text,
            'parsed': parsed,
            'nutrition': nutrition,
            'success': True
        })
        
    except Exception as e:
        return JsonResponse({
            'error': str(e),
            'success': False
        }, status=500)

@csrf_exempt
@require_http_methods(["POST"])
def test_recipe_creation(request):
    """Test endpoint for recipe creation with nutrition - no auth required."""
    try:
        data = json.loads(request.body)
        
        # Import here to avoid circular imports
        from .models import Recipe, Ingredient
        from .nutrition_service import NutritionService
        
        # Create recipe
        recipe = Recipe.objects.create(
            title=data.get('title', 'Test Recipe'),
            instructions=data.get('instructions', []),
            servings=data.get('servings', 1)
        )
        
        # Add ingredients
        ingredients_data = data.get('ingredients', [])
        for ing_data in ingredients_data:
            # If only name is provided, parse it to extract quantity/unit
            if 'quantity' not in ing_data and 'unit' not in ing_data:
                from .ingredient_parser import IngredientParser
                parser = IngredientParser()
                parsed = parser.parse_ingredient(ing_data.get('name', ''))
                ingredient = Ingredient.objects.create(
                    name=parsed['name'],
                    quantity=parsed['quantity'],
                    unit=parsed['unit']
                )
            else:
                ingredient = Ingredient.objects.create(
                    name=ing_data.get('name', ''),
                    quantity=ing_data.get('quantity'),
                    unit=ing_data.get('unit')
                )
            recipe.ingredients.add(ingredient)
        
        # Calculate nutrition
        service = NutritionService()
        nutrition = service.calculate_recipe_nutrition(recipe)
        
        # Update recipe
        recipe.calories = nutrition.get('calories')
        recipe.protein = nutrition.get('protein')
        recipe.fat = nutrition.get('fat')
        recipe.carbs = nutrition.get('carbs')
        recipe.save()
        
        return JsonResponse({
            'recipe_id': recipe.id,
            'title': recipe.title,
            'total_nutrition': nutrition,
            'per_serving': {
                'calories': nutrition.get('calories', 0) / recipe.servings if recipe.servings else 0,
                'protein': nutrition.get('protein', 0) / recipe.servings if recipe.servings else 0,
                'fat': nutrition.get('fat', 0) / recipe.servings if recipe.servings else 0,
                'carbs': nutrition.get('carbs', 0) / recipe.servings if recipe.servings else 0,
            },
            'ingredients_count': recipe.ingredients.count(),
            'success': True
        })
        
    except Exception as e:
        return JsonResponse({
            'error': str(e),
            'success': False
        }, status=500)
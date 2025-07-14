from rest_framework.views import APIView
from django.http import JsonResponse
from rest_framework.permissions import IsAuthenticated
from .recommendation_engine import get_hybrid_recommendations
from recipes.models import Recipe
from recipes.serializers import RecipePreviewSerializer

class RecommendRecipesAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user

        recommended_recipe_ids = get_hybrid_recommendations(user.id)
        recipes = Recipe.objects.filter(id__in=recommended_recipe_ids)
        sorted_recipes = sorted(recipes, key=lambda recipe: recommended_recipe_ids.index(recipe.id))

        serializer = RecipePreviewSerializer(sorted_recipes, many=True, context={'request': request})

        return JsonResponse({'recommendations': serializer.data}, safe=False)
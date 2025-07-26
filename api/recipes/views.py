import random
from rest_framework.views import APIView
from rest_framework import status, generics
from rest_framework.permissions import IsAuthenticated
from rest_framework.parsers import MultiPartParser, FormParser
from django.shortcuts import get_object_or_404
from django.http import JsonResponse
from django.utils.timezone import now
from django.core.files.base import ContentFile
from django.db.models import Case, When, Q
from django.db.models.functions import Random

from PIL import Image, ExifTags
from io import BytesIO

from ai_chatbot.api import OpenAIService
from recipes.models import Recipe, SavedRecipe
from recipes.search import RecipeSearchEngine
from recipes.serializers import RecipeSerializer, RecipePreviewSerializer
from recipes.tasks import format_recipe_ingredients, get_recipe_nutrition_info
from recommendations.models import MixedRecommendationPagination
from recommendations.api import get_similar_recipes

class RecipeListAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        # Only show recipes the user has saved (their personal copies)
        saved_recipe_ids = SavedRecipe.objects.filter(user=user).values_list('recipe_id', flat=True)
        recipes = Recipe.objects.filter(id__in=saved_recipe_ids)
        serializer = RecipePreviewSerializer(recipes, many=True, context={'request': request})
        return JsonResponse(serializer.data, safe=False)

    def post(self, request):
        user = request.user
        data = request.data
        parent_id = data.get('parent_id')
        parent = None

        # Try to fetch parent recipe if given
        if parent_id is not None and parent_id > 0:
            try:
                parent = Recipe.objects.get(id=parent_id)
            except Recipe.DoesNotExist:
                return JsonResponse(
                    {"error": "Parent recipe not found"},
                    status=status.HTTP_404_NOT_FOUND
                )

        serializer = RecipeSerializer(data=data, context={'request': request})
        if serializer.is_valid():
            new_recipe = serializer.save(created_by=user, parent=parent)

            format_recipe_ingredients.delay(new_recipe.id)

            get_recipe_nutrition_info.delay(new_recipe.id)
            
            SavedRecipe.objects.create(
                user=user,
                recipe=new_recipe,
                original_recipe=parent
            )

            return JsonResponse(serializer.data, status=status.HTTP_201_CREATED)

        return JsonResponse(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class RecipeDetailAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        user = request.user
        original_recipe = get_object_or_404(Recipe, pk=pk)

        # Check if the user has saved this recipe
        try:
            saved_entry = SavedRecipe.objects.get(user=user, original_recipe=original_recipe)
            recipe = saved_entry.recipe  # Use user's copy
        except SavedRecipe.DoesNotExist:
            recipe = original_recipe

        # Update last_visited only if user owns this recipe
        if recipe.created_by == user:
            recipe.last_visited_at = now()
            recipe.save(update_fields=['last_visited_at'])

        serializer = RecipeSerializer(recipe, context={'request': request})
        return JsonResponse(serializer.data)

    def put(self, request, pk):
        recipe = get_object_or_404(Recipe, pk=pk)

        # Only allow editing user's own recipe
        if recipe.created_by != request.user:
            return JsonResponse({"error": "You do not have permission to edit this recipe."},
                            status=status.HTTP_403_FORBIDDEN)

        serializer = RecipeSerializer(recipe, data=request.data, context={'request': request})
        if serializer.is_valid():
            serializer.save()
            return JsonResponse(serializer.data)
        return JsonResponse(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def patch(self, request, pk):
        recipe = get_object_or_404(Recipe, pk=pk)

        if recipe.created_by != request.user:
            return JsonResponse({"error": "You do not have permission to edit this recipe."},
                            status=status.HTTP_403_FORBIDDEN)

        serializer = RecipeSerializer(recipe, data=request.data, partial=True, context={'request': request})
        if serializer.is_valid():
            serializer.save()
            return JsonResponse(serializer.data)
        return JsonResponse(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk):
        recipe = get_object_or_404(Recipe, pk=pk)

        if recipe.created_by != request.user:
            return JsonResponse({"error": "You do not have permission to delete this recipe."},
                            status=status.HTTP_403_FORBIDDEN)

        recipe.delete()
        return JsonResponse({"message": "Recipe deleted successfully."}, status=status.HTTP_204_NO_CONTENT)


class RecipeImageUploadAPIView(APIView):
    parser_classes = (MultiPartParser, FormParser)

    def post(self, request, recipe_id):
        try:
            recipe = Recipe.objects.get(id=recipe_id)
            image = request.FILES.get('image')

            if image:
                img = Image.open(image)
                img = self.correct_image_orientation(img)
                img_io = BytesIO()
                img.save(img_io, format='JPEG', quality=90)
                img_file = ContentFile(img_io.getvalue(), name=image.name)
              
                recipe.image = img_file
                recipe.thumbnail = img_file
                recipe.save()

                return JsonResponse(
                    {
                        "image_url": recipe.image.url,
                        "thumbnail_url": recipe.thumbnail.url
                    },
                    status=status.HTTP_200_OK
                )

            return JsonResponse({"error": "No image provided."}, status=status.HTTP_400_BAD_REQUEST)

        except Recipe.DoesNotExist:
            return JsonResponse({"error": "Recipe not found."}, status=status.HTTP_404_NOT_FOUND)

    def correct_image_orientation(self, img):
        """Auto-rotate image based on EXIF data."""
        try:
            exif = img._getexif()
            if exif is not None:
                for tag, value in exif.items():
                    if tag in ExifTags.TAGS and ExifTags.TAGS[tag] == 'Orientation':
                        if value == 3:
                            img = img.rotate(180, expand=True)
                        elif value == 6:
                            img = img.rotate(270, expand=True)
                        elif value == 8:
                            img = img.rotate(90, expand=True)
                        break
        except (AttributeError, KeyError, IndexError):
            pass

        return img


class FilteredRecommendationsAPIView(generics.GenericAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = RecipePreviewSerializer
    pagination_class = MixedRecommendationPagination

    def get_filtered_recipes(self, request):
        """
        Apply filtering params from query params and return a queryset.
        """
        search_query = request.query_params.get('search', '').strip()
        tags = request.query_params.get('tags', '').split(',') if request.query_params.get('tags') else []
        prep_time = float(request.query_params.get('prep_time', 60))
        cook_time = float(request.query_params.get('cook_time', 60))
        calories_min = float(request.query_params.get('calories_min', 0))
        calories_max = float(request.query_params.get('calories_max', 1000))
        exclude_ai_generated = request.query_params.get('exclude_ai_generated', 'false').lower() == 'true'
        exclude_own_recipes = request.query_params.get('exclude_own_recipes', 'true').lower() == 'true'

        recipes = Recipe.objects.filter(parent__isnull=True).prefetch_related('ingredients')

        # Tags filter
        if tags:
            query = Q()
            # TODO: Switch to PostgreSQL to use this.
            # for tag in tags:
            #     query |= Q(tags__contains=tag)
            # recipes = recipes.filter(query)

        # Time filters
        if prep_time < 60:
            recipes = recipes.filter(preparation_time__lte=prep_time)
        if cook_time < 60:
            recipes = recipes.filter(cooking_time__lte=cook_time)

        # Calories filters
        if calories_max != 1000 or calories_min != 0:
            recipes = recipes.filter(
                calories__gte=calories_min,
                calories__lte=calories_max
            )

        # Exclude AI generated
        if exclude_ai_generated:
            recipes = recipes.exclude(Q(id=-1) | Q(parent=-1))

        # Exclude own recipes
        if exclude_own_recipes:
            recipes = recipes.exclude(created_by=request.user)

        # Apply search if query exists
        if search_query:
            search_engine = RecipeSearchEngine()
            recipe_list = list(recipes)
            scored_recipes = search_engine.search(search_query, recipe_list)
            
            # Get just the recipes (without scores) in order
            sorted_recipes = [r[0] for r in scored_recipes]
            recipe_ids = [r.id for r in sorted_recipes]
            
            # Create new queryset preserving order
            preserved_order = Case(*[When(pk=pk, then=pos) for pos, pk in enumerate(recipe_ids)])
            return Recipe.objects.filter(id__in=recipe_ids).order_by(preserved_order)
    
        return recipes.distinct()
    
    def get_combined_recipe_ids(self, user):
        # 1. Recommended recipe IDs
        recommended_ids = get_similar_recipes(user.id, top_n=500)

        # 2. Random recipe IDs excluding recommended
        excluded_ids = set(recommended_ids)
        random_ids = list(
            Recipe.objects.exclude(id__in=excluded_ids).values_list('id', flat=True)
        )

        # Recommended first, then random
        combined = list(recommended_ids) + random_ids
        return combined

    def get(self, request, *args, **kwargs):
        user = request.user
        filtered_recipes = self.get_filtered_recipes(request)
        
        # If there's a search query, return those results directly without recommendations
        if request.query_params.get('search'):
            # Paginate the already-sorted search results
            paginator = self.pagination_class()
            page_recipes = paginator.paginate_queryset(list(filtered_recipes), request, view=self)
            
            # Handle user-saved versions
            recipe_ids = [r.id for r in page_recipes]
            user_saved = SavedRecipe.objects.filter(
                user=user,
                original_recipe_id__in=recipe_ids
            ).select_related('recipe')
            saved_map = {s.original_recipe_id: s.recipe for s in user_saved}

            final_recipes = [saved_map.get(r.id, r) for r in page_recipes]
            
            serializer = self.serializer_class(final_recipes, many=True, context={'request': request})
            return paginator.get_paginated_response(serializer.data)
        
        # Original recommendation logic for non-search cases
        combined_ids = self.get_combined_recipe_ids(user)
        filtered_ids = set(filtered_recipes.values_list('id', flat=True))
        filtered_combined_ids = [rid for rid in combined_ids if rid in filtered_ids]
        
        # Rest of your original non-search logic...
        random.shuffle(filtered_combined_ids)
        paginator = self.pagination_class()
        page_ids = paginator.paginate_queryset(filtered_combined_ids, request, view=self)
        
        if not page_ids:
            return JsonResponse({
                'count': len(filtered_combined_ids),
                'next': None,
                'previous': None,
                'results': []
            })
        
        preserved_order = Case(*[When(pk=pk, then=pos) for pos, pk in enumerate(page_ids)])
        page_recipes = Recipe.objects.filter(id__in=page_ids).order_by(preserved_order)
        
        num_random = random.randint(4, 10)
        random_recipes = (
            filtered_recipes.exclude(id__in=page_ids)
            .order_by(Random())[:num_random]
        )
        
        all_recipes = list(page_recipes) + list(random_recipes)
        random.shuffle(all_recipes)
        
        recipe_ids = [r.id for r in all_recipes]
        user_saved = SavedRecipe.objects.filter(
            user=user,
            original_recipe_id__in=recipe_ids
        ).select_related('recipe')
        saved_map = {s.original_recipe_id: s.recipe for s in user_saved}
        
        final_recipes = [saved_map.get(r.id, r) for r in all_recipes]
        
        serializer = self.serializer_class(final_recipes, many=True, context={'request': request})
        return paginator.get_paginated_response(serializer.data)
    
class RecipeTagsAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        """
        Return a list of all unique tags used in recipes.
        """
        tags = Recipe.objects.values_list('tags', flat=True).distinct()
        unique_tags = set(tag for sublist in tags for tag in sublist)
        return JsonResponse(list(unique_tags), safe=False, status=status.HTTP_200_OK)
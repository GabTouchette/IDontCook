from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, generics
from rest_framework.permissions import IsAuthenticated
from rest_framework.parsers import MultiPartParser, FormParser
from django.shortcuts import get_object_or_404
from django.http import JsonResponse
from django.utils.timezone import now
from django.core.files.base import ContentFile
from django.db.models import Q, Case, When

from PIL import Image, ExifTags
from io import BytesIO

from recipes.models import Recipe, SavedRecipe
from recipes.serializers import RecipeSerializer, RecipePreviewSerializer
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
        print(parent_id)

        # Case: Saving a copy of someone else's recipe
        if parent_id > 0:
            try:
                parent = Recipe.objects.get(id=parent_id)
            except Recipe.DoesNotExist:
                return Response(
                    {"error": "Parent recipe not found"},
                    status=status.HTTP_404_NOT_FOUND
                )

            # Prevent saving same recipe multiple times
            already_saved = SavedRecipe.objects.filter(
                user=user,
                original_recipe=parent
            ).exists()

            if already_saved:
                return Response(
                    {"error": "You have already saved this recipe."},
                    status=status.HTTP_400_BAD_REQUEST
                )

            serializer = RecipeSerializer(data=data, context={'request': request})
            if serializer.is_valid():
                # Clone the recipe with parent link
                cloned_recipe = serializer.save(created_by=user, parent=parent)
                
                # Create SavedRecipe link
                SavedRecipe.objects.create(
                    user=user,
                    recipe=cloned_recipe,
                    original_recipe=parent
                )

                return Response(serializer.data, status=status.HTTP_201_CREATED)

            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        # Case: User creating a new recipe from scratch (no parent)
        serializer = RecipeSerializer(data=data, context={'request': request})
        if serializer.is_valid():
            recipe = serializer.save(created_by=user)
            
            SavedRecipe.objects.create(
                user=user,
                recipe=recipe,
                original_recipe=None
            )

            return Response(serializer.data, status=status.HTTP_201_CREATED)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)



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
            return Response({"error": "You do not have permission to edit this recipe."},
                            status=status.HTTP_403_FORBIDDEN)

        serializer = RecipeSerializer(recipe, data=request.data, context={'request': request})
        if serializer.is_valid():
            serializer.save()
            return JsonResponse(serializer.data)
        return JsonResponse(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def patch(self, request, pk):
        recipe = get_object_or_404(Recipe, pk=pk)

        if recipe.created_by != request.user:
            return Response({"error": "You do not have permission to edit this recipe."},
                            status=status.HTTP_403_FORBIDDEN)

        serializer = RecipeSerializer(recipe, data=request.data, partial=True, context={'request': request})
        if serializer.is_valid():
            serializer.save()
            return JsonResponse(serializer.data)
        return JsonResponse(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk):
        recipe = get_object_or_404(Recipe, pk=pk)

        if recipe.created_by != request.user:
            return Response({"error": "You do not have permission to delete this recipe."},
                            status=status.HTTP_403_FORBIDDEN)

        recipe.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


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

                return Response(
                    {
                        "image_url": recipe.image.url,
                        "thumbnail_url": recipe.thumbnail.url
                    },
                    status=status.HTTP_200_OK
                )
            
            return Response({"error": "No image provided."}, status=status.HTTP_400_BAD_REQUEST)

        except Recipe.DoesNotExist:
            return Response({"error": "Recipe not found."}, status=status.HTTP_404_NOT_FOUND)
        
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
        search_query = request.query_params.get('search', '')
        tags = request.query_params.get('tags', '').split(',') if request.query_params.get('tags') else []
        prep_time = float(request.query_params.get('prep_time', 60))
        cook_time = float(request.query_params.get('cook_time', 120))
        calories_min = float(request.query_params.get('calories_min', 0))
        calories_max = float(request.query_params.get('calories_max', 1000))
        exclude_ai_generated = request.query_params.get('exclude_ai_generated', 'false').lower() == 'true'
        exclude_own_recipes = request.query_params.get('exclude_own_recipes', 'true').lower() == 'true'

        recipes = Recipe.objects.all()

        # Keyword search
        if search_query:
            keywords = search_query.strip().split()
            for word in keywords:
                recipes = recipes.filter(
                    Q(title__icontains=word) |
                    Q(description__icontains=word) |
                    Q(ingredients__name__icontains=word)
                ).distinct()

        # Tags filter
        if tags:
            for tag in tags:
                recipes = recipes.filter(tags__icontains=f'"{tag}"')

        # Time filters
        if prep_time < 60:
            recipes = recipes.filter(preparation_time__lte=prep_time)
        if cook_time < 120:
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
        combined_ids = self.get_combined_recipe_ids(user)

        # Intersect filtered queryset with combined_ids while preserving order

        # Get filtered recipe IDs
        filtered_ids = set(filtered_recipes.values_list('id', flat=True))

        # Filter combined_ids to those that pass filters, preserve order
        filtered_combined_ids = [rid for rid in combined_ids if rid in filtered_ids]

        paginator = self.pagination_class()

        page_ids = paginator.paginate_queryset(filtered_combined_ids, request, view=self)

        if not page_ids:
            return Response({
                'count': len(filtered_combined_ids),
                'next': None,
                'previous': None,
                'results': []
            })

        # Query recipes preserving order
        preserved_order = Case(*[When(pk=pk, then=pos) for pos, pk in enumerate(page_ids)])

        recipes_page = Recipe.objects.filter(id__in=page_ids).order_by(preserved_order)

        # Replace originals with saved versions if any
        recipe_ids = list(recipes_page.values_list('id', flat=True))
        user_saved = SavedRecipe.objects.filter(
            user=user,
            original_recipe_id__in=recipe_ids
        ).select_related('recipe')

        saved_map = {s.original_recipe_id: s.recipe for s in user_saved}

        final_recipes = []
        for recipe in recipes_page:
            if recipe.id in saved_map:
                final_recipes.append(saved_map[recipe.id])
            else:
                final_recipes.append(recipe)

        serializer = self.serializer_class(final_recipes, many=True, context={'request': request})

        return paginator.get_paginated_response(serializer.data)
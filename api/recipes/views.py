from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404
from django.db import models
from .models import Recipe
from .serializers import RecipeSerializer
from django.utils.timezone import now
from .serializers import RecipePreviewSerializer
from django.http import JsonResponse
from rest_framework.parsers import MultiPartParser, FormParser
from PIL import ExifTags, Image
from io import BytesIO
from django.core.files.base import ContentFile
from django.db import connection
from django.db.models import Q

class RecipeListAPIView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        user = request.user
        recipes = Recipe.objects.filter(created_by=user)
        serializer = RecipePreviewSerializer(recipes, many=True)
        return JsonResponse(serializer.data, safe=False)

    def post(self, request):
        user = request.user
        data = request.data

        parent_id = data.get('parent_id', None)

        if parent_id is not None and parent_id > 0:
            try:
                parent = Recipe.objects.get(id=parent_id)
            except Recipe.DoesNotExist:
                return Response(
                    {"error": "Parent recipe not found"},
                    status=status.HTTP_404_NOT_FOUND
                )
          
            if Recipe.objects.filter(
                    created_by=user
                ).filter(
                    models.Q(id=parent.id) | models.Q(parent_id=parent.id)
                ).exists():

                return Response(
                    {"error": "You have already saved this recipe"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            serializer = RecipeSerializer(data=data, context={'request': request})
            if serializer.is_valid():
                serializer.save(created_by=user, parent=parent)
                return Response(serializer.data, status=status.HTTP_201_CREATED)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        else:
            serializer = RecipeSerializer(data=data, context={'request': request})
            if serializer.is_valid():
                serializer.save(created_by=user)
                return Response(serializer.data, status=status.HTTP_201_CREATED)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class RecipeDetailAPIView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request, pk):
        user = request.user
        recipe = get_object_or_404(Recipe, pk=pk)

        if recipe.created_by != user:
            user_recipe = Recipe.objects.filter(created_by=user, parent=recipe.id).first()            
            if user_recipe:
                recipe = user_recipe

        if recipe.created_by == user:
            recipe.last_visited_at = now()
            recipe.save(update_fields=['last_visited_at'])

        serializer = RecipeSerializer(recipe)
        return JsonResponse(serializer.data)

    def put(self, request, pk):
        recipe = get_object_or_404(Recipe, pk=pk)
        serializer = RecipeSerializer(recipe, data=request.data)
        if serializer.is_valid():
            serializer.save()
            return JsonResponse(serializer.data)
        return JsonResponse(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def patch(self, request, pk):
        recipe = get_object_or_404(Recipe, pk=pk)
        serializer = RecipeSerializer(recipe, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return JsonResponse(serializer.data)
        return JsonResponse(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk):
        recipe = get_object_or_404(Recipe, pk=pk)
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

class HasSavedRecipeAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, recipe_id):
        user = request.user
        exists = Recipe.objects.filter(created_by=user).filter(
            models.Q(id=recipe_id) | models.Q(parent=recipe_id)
        ).exists()

        return JsonResponse({"is_saved": exists})


class GlobalFilteredRecipesView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        search_query = request.query_params.get('search', '')
        tags = request.query_params.get('tags', '').split(',') if request.query_params.get('tags') else []
        prep_time = float(request.query_params.get('prep_time', 60))
        cook_time = float(request.query_params.get('cook_time', 120))
        calories_min = float(request.query_params.get('calories_min', 0))
        calories_max = float(request.query_params.get('calories_max', 1000))
        exclude_ai_generated = request.query_params.get('exclude_ai_generated', 'false').lower() == 'true'
        exclude_own_recipes = request.query_params.get('exclude_own_recipes', 'true').lower() == 'true'

        recipes = Recipe.objects.all()
        if search_query:
            if connection.vendor == 'postgresql':
                recipes = recipes.filter(
                    Q(title__icontains=search_query) |
                    Q(tags__contains=[search_query])
                ).distinct()
            else:
                recipes = recipes.filter(
                    Q(title__icontains=search_query) |
                    Q(tags__icontains=f'"{search_query}"')
                ).distinct()

        if tags:
            if connection.vendor == 'postgresql':
                for tag in tags:
                    recipes = recipes.filter(tags__contains=[tag])
            else:
                for tag in tags:
                    recipes = recipes.filter(tags__icontains=f'"{tag}"')
      
        if prep_time < 60:
            recipes = recipes.filter(preparation_time__lte=prep_time)

        if cook_time < 120:
            recipes = recipes.filter(cooking_time__lte=cook_time)

        if calories_max != 1000 or calories_min != 0:
            recipes = recipes.filter(
                calories__gte=calories_min,
                calories__lte=calories_max
            )
      
        if exclude_ai_generated:
            recipes = recipes.exclude(models.Q(id=-1) | models.Q(parent=-1))
      
        if exclude_own_recipes:
            recipes = recipes.exclude(created_by=request.user)

        recipes = recipes[:30]

        serializer = RecipePreviewSerializer(recipes, many=True)

        return Response(serializer.data, status=status.HTTP_200_OK)
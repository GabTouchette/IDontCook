import logging
import threading
from recipes.tasks import format_recipe_ingredients, dispatch_nutrition_calculation
from rest_framework.views import APIView
from rest_framework import status, generics
from rest_framework.permissions import IsAuthenticated
from rest_framework.parsers import MultiPartParser, FormParser
from django.shortcuts import get_object_or_404
from django.http import JsonResponse
from django.utils.timezone import now
# Removed timezone import - no longer needed
from django.core.files.base import ContentFile
from django.db.models import Case, When, Q, ExpressionWrapper, F, IntegerField, Count
from django.db import connection

from PIL import Image, ExifTags
from io import BytesIO

from ai_chatbot.api import AnthropicService
from recipes.models import Recipe, SavedRecipe, CanonicalIngredient
from recipes.search import RecipeSearchEngine
from recipes.serializers import RecipeSerializer, RecipePreviewSerializer
from recommendations.models import MixedRecommendationPagination, RecipeEvent, UserRecipeInteraction
from recommendations.api import get_similar_recipes, invalidate_user_recommendation_cache

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
            new_recipe = serializer.save(created_by=user, parent=parent, source=Recipe.SOURCE_USER)
            
            # Format ingredients in background only if not already formatted by LLM
            if not new_recipe.is_formatted:
                print(f"📤 DISPATCHING format_recipe_ingredients for recipe_id={new_recipe.id} ('{new_recipe.title}')")
                try:
                    task = format_recipe_ingredients.delay(new_recipe.id)
                    print(f"📤 CELERY TASK DISPATCHED: task_id={task.id}")
                except Exception as e:
                    print(f"⚠️ CELERY TASK DISPATCH FAILED: {e}")
                    print(f"🔄 FALLING BACK TO BACKGROUND THREAD")
                    # Fallback: run in a background thread so the response is not blocked
                    threading.Thread(
                        target=format_recipe_ingredients,
                        args=(new_recipe.id,),
                        daemon=True,
                    ).start()
            else:
                print(f"⏭️ Skipping LLM formatting — recipe already formatted (is_formatted=True)")
            
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

        if recipe.created_by != request.user and not request.user.is_staff:
            return JsonResponse({"error": "You do not have permission to delete this recipe."},
                            status=status.HTTP_403_FORBIDDEN)

        recipe.delete()
        return JsonResponse({"message": "Recipe deleted successfully."}, status=status.HTTP_204_NO_CONTENT)


class RecipeReformatAPIView(APIView):
    """Force-reformat a recipe's ingredients with the LLM — the same formatting
    pass that runs in the background on create (`format_recipe_ingredients` /
    `llm_format_ingredients`), exposed as an on-demand action for the
    "Recipe improperly formatted" banner in the app.

    Runs synchronously so the response carries the reformatted recipe and the
    detail page can refresh immediately (prod has no Celery worker). Nutrition
    is recalculated in the background afterwards since the ingredient set changed.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        recipe = get_object_or_404(Recipe, pk=pk)

        # Only the owner can reformat their own copy.
        if recipe.created_by != request.user:
            return JsonResponse(
                {"error": "You do not have permission to reformat this recipe."},
                status=status.HTTP_403_FORBIDDEN,
            )

        if not recipe.ingredients.exists():
            return JsonResponse(
                {"error": "Recipe has no ingredients to format."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            result = AnthropicService().llm_format_ingredients(recipe)
        except Exception as exc:
            logging.getLogger(__name__).error(
                "Reformat failed for recipe %s: %s", pk, exc, exc_info=True
            )
            return JsonResponse(
                {"error": "Failed to reformat recipe. Please try again."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

        # llm_format_ingredients returns an error string instead of a Recipe when
        # the LLM response can't be parsed — treat that as a failure.
        if not isinstance(result, Recipe):
            return JsonResponse(
                {"error": "Failed to reformat recipe. Please try again."},
                status=status.HTTP_502_BAD_GATEWAY,
            )

        recipe = result
        recipe.is_formatted = True
        recipe.save()

        # Ingredient names/units changed, so cached nutrition is stale.
        try:
            dispatch_nutrition_calculation(recipe.id)
        except Exception as exc:
            logging.getLogger(__name__).warning(
                "Nutrition re-dispatch after reformat failed for recipe %s: %s",
                recipe.id, exc,
            )

        serializer = RecipeSerializer(recipe, context={'request': request})
        return JsonResponse(serializer.data, status=status.HTTP_200_OK)


class RecipeImageUploadAPIView(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = (MultiPartParser, FormParser)

    def post(self, request, recipe_id):
        try:
            recipe = Recipe.objects.get(id=recipe_id)

            if recipe.created_by != request.user:
                return JsonResponse(
                    {"error": "You do not have permission to upload an image for this recipe."},
                    status=status.HTTP_403_FORBIDDEN,
                )

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

    @staticmethod
    def _parse_int(value):
        if value is None:
            return None
        try:
            return int(value)
        except (TypeError, ValueError):
            return None

    def get_filtered_recipes(self, request):
        """
        Apply filtering params from query params and return a queryset.
        """
        search_query = request.query_params.get('search', '').strip()
        tags = request.query_params.get('tags', '').split(',') if request.query_params.get('tags') else []
        total_time = float(request.query_params.get('total_time', 0))
        max_calories = float(request.query_params.get('max_calories', 0))
        # Legacy params kept for backward compatibility
        prep_time = float(request.query_params.get('prep_time', 60))
        cook_time = float(request.query_params.get('cook_time', 60))
        calories_min = float(request.query_params.get('calories_min', 0))
        calories_max = float(request.query_params.get('calories_max', 1000))
        exclude_ai_generated = request.query_params.get('exclude_ai_generated', 'false').lower() == 'true'
        exclude_own_recipes = request.query_params.get('exclude_own_recipes', 'true').lower() == 'true'

        recipes = Recipe.objects.filter(parent__isnull=True).prefetch_related('ingredients')

        # Tags filter (SQLite-friendly using JSON1; PostgreSQL uses JSON contains; fallback to string matching)
        if tags:
            db_vendor = connection.vendor
            # Normalize tags (trim + lower) for case-insensitive match
            norm_tags = [t.strip() for t in tags if t and t.strip()]
            if norm_tags:
                if db_vendor == 'sqlite':
                    # Use json_each to test membership in the JSON array (OR semantics across provided tags)
                    table = Recipe._meta.db_table
                    clause_parts = [
                        f"EXISTS (SELECT 1 FROM json_each({table}.\"tags\") AS je WHERE lower(je.value) = lower(%s))"
                        for _ in norm_tags
                    ]
                    or_clause = " OR ".join(clause_parts)
                    recipes = recipes.extra(where=[f"({or_clause})"], params=norm_tags)
                elif db_vendor == 'postgresql':
                    or_q = Q()
                    for t in norm_tags:
                        # JSON array contains the single tag
                        or_q |= Q(tags__contains=[t])
                    recipes = recipes.filter(or_q)
                else:
                    # Fallback: string contains on JSON text, match quotes to reduce false positives
                    or_q = Q()
                    for t in norm_tags:
                        or_q |= Q(tags__icontains=f'"{t}"')
                    recipes = recipes.filter(or_q)

        # Time filters
        if total_time > 0:
            recipes = recipes.annotate(
                total_time_sum=ExpressionWrapper(
                    F('preparation_time') + F('cooking_time'),
                    output_field=IntegerField()
                )
            ).filter(total_time_sum__lte=int(total_time))
        else:
            # Legacy individual time filters
            if prep_time < 60:
                recipes = recipes.filter(preparation_time__lte=prep_time)
            if cook_time < 60:
                recipes = recipes.filter(cooking_time__lte=cook_time)

        # Calories filters
        if max_calories > 0:
            recipes = recipes.filter(calories__lte=max_calories)
        elif calories_max != 1000 or calories_min != 0:
            recipes = recipes.filter(
                calories__gte=calories_min,
                calories__lte=calories_max
            )

        # Exclude AI generated
        if exclude_ai_generated:
            recipes = recipes.exclude(source=Recipe.SOURCE_AI)

        # Exclude own recipes
        if exclude_own_recipes:
            recipes = recipes.exclude(created_by=request.user)

        # Exclude recipes the user has downvoted
        downvoted_ids = UserRecipeInteraction.objects.filter(
            user=request.user, interaction_type='downvote'
        ).values_list('recipe_id', flat=True)
        if downvoted_ids:
            recipes = recipes.exclude(id__in=downvoted_ids)

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
    
    def _preview_context(self, request, recipes, saved_map):
        """Bulk-resolve the two per-recipe fields the preview serializer needs so
        it never issues a query per recipe (the N+1 that made explore crawl on
        networked Postgres). One COUNT-grouped query for ingredient counts; the
        user's saved versions come from the saved_map already fetched above.
        """
        ids = [r.id for r in recipes]
        ingredient_counts = dict(
            Recipe.objects.filter(id__in=ids)
            .annotate(_ic=Count('ingredients'))
            .values_list('id', '_ic')
        )
        return {
            'request': request,
            'ingredient_counts': ingredient_counts,
            # The recipe objects that ARE the user's saved copy of an original
            # (saved_map swaps them in below). Membership => is_saved.
            'saved_version_ids': {r.id for r in saved_map.values()},
        }

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

            serializer = self.serializer_class(
                final_recipes, many=True,
                context=self._preview_context(request, final_recipes, saved_map),
            )
            return paginator.get_paginated_response(serializer.data)

        # Recommendation path (non-search). Order the FILTERED queryset in the DB
        # so the user's recommended recipes come first (relevance order), then the
        # rest, and let the paginator slice one page with LIMIT/OFFSET. This
        # replaces the old approach that pulled the entire catalog id-space into
        # Python just to return a single 20-item page.
        #
        # `seed` is a per-session variety seed from the client (stable across
        # pages of one browse session, regenerated on pull-to-refresh). It drives
        # the ranker's band-shuffle + exploration slice so a refresh reshuffles
        # the feed while pagination within a session stays consistent — this is
        # what replaces the old per-page "inject 4-10 random recipes" hack.
        seed = self._parse_int(request.query_params.get('seed'))
        recommended_ids = get_similar_recipes(user.id, top_n=500, seed=seed)
        if recommended_ids:
            rec_rank = Case(
                *[When(pk=pk, then=pos) for pos, pk in enumerate(recommended_ids)],
                default=len(recommended_ids),
                output_field=IntegerField(),
            )
            ordered = filtered_recipes.annotate(_rec_rank=rec_rank).order_by('_rec_rank', 'id')
        else:
            ordered = filtered_recipes.order_by('id')

        paginator = self.pagination_class()
        page_recipes = paginator.paginate_queryset(ordered, request, view=self)
        if not page_recipes:
            return paginator.get_paginated_response([])
        all_recipes = list(page_recipes)

        recipe_ids = [r.id for r in all_recipes]
        user_saved = SavedRecipe.objects.filter(
            user=user,
            original_recipe_id__in=recipe_ids
        ).select_related('recipe')
        saved_map = {s.original_recipe_id: s.recipe for s in user_saved}
        
        final_recipes = [saved_map.get(r.id, r) for r in all_recipes]

        serializer = self.serializer_class(
            final_recipes, many=True,
            context=self._preview_context(request, final_recipes, saved_map),
        )
        return paginator.get_paginated_response(serializer.data)
    
class RecipeInteractionAPIView(APIView):
    """Record or toggle a user's thumbs-up / thumbs-down on a recipe."""
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        recipe = get_object_or_404(Recipe, pk=pk)
        interaction_type = request.data.get('interaction_type')

        if interaction_type not in ('upvote', 'downvote'):
            return JsonResponse({'error': 'interaction_type must be upvote or downvote'},
                                status=status.HTTP_400_BAD_REQUEST)

        # Toggle: if same type already exists, remove it
        existing = UserRecipeInteraction.objects.filter(
            user=request.user, recipe=recipe, interaction_type=interaction_type
        ).first()

        if existing:
            existing.delete()
            invalidate_user_recommendation_cache(request.user.id)
            return JsonResponse({'interaction_type': interaction_type, 'active': False})

        # Remove the opposite interaction before adding the new one
        opposite = 'downvote' if interaction_type == 'upvote' else 'upvote'
        UserRecipeInteraction.objects.filter(
            user=request.user, recipe=recipe, interaction_type=opposite
        ).delete()

        UserRecipeInteraction.objects.create(
            user=request.user, recipe=recipe, interaction_type=interaction_type
        )
        invalidate_user_recommendation_cache(request.user.id)
        return JsonResponse({'interaction_type': interaction_type, 'active': True},
                            status=status.HTTP_201_CREATED)


class RecipeClickAPIView(APIView):
    """Record a 'click' — the user opened a recipe's detail — as a weak,
    recency-weighted ranking signal (docs/plans/recommendation-algo-v2.md §1.3).

    Append-only and fire-and-forget: it never toggles, always returns 201, and
    does NOT invalidate the user-profile cache (clicks are high-volume and only
    a weak signal, so they fold in naturally on the next profile rebuild rather
    than busting the cache on every open).
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        recipe = get_object_or_404(Recipe, pk=pk)
        RecipeEvent.objects.create(
            user=request.user, recipe=recipe, kind=RecipeEvent.KIND_CLICK
        )
        return JsonResponse({'recorded': True}, status=status.HTTP_201_CREATED)


class RecipeTagsAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        """
        Return a list of all unique tags used in recipes.
        """
        tags = Recipe.objects.values_list('tags', flat=True).distinct()
        unique_tags = set(tag for sublist in tags for tag in sublist)
        return JsonResponse(list(unique_tags), safe=False, status=status.HTTP_200_OK)


class CanonicalIngredientAutocompleteAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        q = (request.GET.get('q') or '').strip()
        limit = int(request.GET.get('limit') or 5)
        if not q:
            return JsonResponse([], safe=False)

        # Simple case-insensitive startswith/contains match on English and French names
        qs = CanonicalIngredient.objects.all()
        qs = qs.filter(
            Q(canonical_name_en__icontains=q) | Q(canonical_name_fr__icontains=q)
        ).order_by('canonical_name_en')[:max(1, min(limit, 25))]

        results = [
            {
                'id': ci.id,
                'canonical_name_en': ci.canonical_name_en,
                'canonical_name_fr': ci.canonical_name_fr,
                'category': ci.category,
            }
            for ci in qs
        ]
        return JsonResponse(results, safe=False)


class RecipeNutritionAPIView(APIView):
    """GET /api/recipes/<pk>/nutrition/

    Returns cached per-serving macros plus a per-ingredient breakdown.
    If nutrition has not been calculated yet, triggers a background calculation
    and returns is_calculated=false so the client can poll.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        recipe = get_object_or_404(Recipe, pk=pk)

        # Security: only the owner (or admins) may query nutrition
        if recipe.created_by != request.user and not request.user.is_staff:
            return JsonResponse({'error': 'Forbidden'}, status=status.HTTP_403_FORBIDDEN)

        if not recipe.is_nutrition_calculated:
            # Queue calculation (Celery, with a thread fallback in dev). Idempotent —
            # safe to fire multiple times; the client polls until is_calculated=true.
            dispatch_nutrition_calculation(recipe.id)

            return JsonResponse({'is_calculated': False}, status=status.HTTP_202_ACCEPTED)

        # Build per-ingredient breakdown from cached FKs
        per_ingredient = []
        from recipes.nutrition_service import NutritionService
        service = NutritionService()
        for ing in recipe.ingredients.select_related('nutrition_data', 'canonical').all():
            if ing.nutrition_data and ing.quantity:
                nd = ing.nutrition_data
                scaled = service._scale_nutrition(
                    service._nutrition_to_dict(nd),
                    ing.quantity,
                    ing.unit or '',
                    (ing.canonical.canonical_name_en if ing.canonical else ing.name) or '',
                    canonical=ing.canonical,
                )
                per_ingredient.append({
                    'ingredient_id': ing.id,
                    'name': ing.name,
                    'quantity': ing.quantity,
                    'unit': ing.unit,
                    'calories': round(scaled.get('calories', 0), 1),
                    'protein': round(scaled.get('protein', 0), 1),
                    'fat': round(scaled.get('fat', 0), 1),
                    'carbs': round(scaled.get('carbs', 0), 1),
                })

        return JsonResponse({
            'is_calculated': True,
            'calories': recipe.calories,
            'protein': recipe.protein,
            'fat': recipe.fat,
            'carbs': recipe.carbs,
            'servings': recipe.servings,
            'per_ingredient': per_ingredient,
        })


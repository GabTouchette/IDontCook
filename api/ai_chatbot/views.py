import os
import tempfile

from dotenv import load_dotenv
from rest_framework.views import APIView
from rest_framework import status
from rest_framework.parsers import MultiPartParser
from rest_framework.permissions import IsAuthenticated
from django.http import JsonResponse, StreamingHttpResponse
from .api import AnthropicService, PromptTemplates
from .url_fetcher import import_recipe_from_url
from .models import Conversation, ChatHistory
from recipes.models import Recipe
import json

load_dotenv()

class ChatbotView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        """
        Handles incoming chatbot queries and routes them to OCR or chat response.
        """
        query = request.data.get("query")
        chat_history = request.data.get("chat_history", None)
        recipe_id = request.data.get("recipe_id", None)

        if not query:
            return JsonResponse({"error": "Query is required"}, status=status.HTTP_400_BAD_REQUEST)

        recipe_context = None
        if recipe_id:
            try:
                recipe = Recipe.objects.get(id=recipe_id, created_by=request.user)
                recipe_context = {
                    "id": recipe.id,
                    "title": recipe.title,
                    "ingredients": [
                        {"name": ing.name, "quantity": ing.quantity}
                        for ing in recipe.ingredients.all()
                    ],
                    "instructions": recipe.instructions,
                    "tags": recipe.tags,
                    "description": recipe.description,
                    "notes": recipe.notes,
                    "preparation_time": recipe.preparation_time,
                    "cooking_time": recipe.cooking_time,
                }
            except Recipe.DoesNotExist:
                return JsonResponse({"error": "Recipe not found"}, status=404)

        return self.process_chat_response(request.user, query, chat_history, recipe_context)

    def process_chat_response(self, user, query, chat_history=None, recipe_context=None):
        """
        Handles chatbot queries and streams the AI response.
        """
        conversation = Conversation.objects.create(user=user, user_query=query, ai_response="loading")

        saved_recipes = Recipe.objects.filter(created_by=user)
        recipes_list = [
            {
                "id": recipe.id,
                "title": recipe.title,
            }
            for recipe in saved_recipes
        ]

        try:
            settings = user.settings
            user_settings = {
                "age": settings.age,
                "gender": settings.gender,
                "city": settings.city,
                "country": settings.country,
                "ethnicity": settings.ethnicity,
                "is_vegan": settings.is_vegan,
                "is_vegetarian": settings.is_vegetarian,
                "is_gluten_free": settings.is_gluten_free,
                "is_lactose_intolerant": settings.is_lactose_intolerant,
                "has_peanut_allergy": settings.has_peanut_allergy,
                "has_tree_nut_allergy": settings.has_tree_nut_allergy,
                "has_shellfish_allergy": settings.has_shellfish_allergy,
                "has_egg_allergy": settings.has_egg_allergy,
                "has_milk_allergy": settings.has_milk_allergy,
                "has_soy_allergy": settings.has_soy_allergy,
                "has_wheat_allergy": settings.has_wheat_allergy,
                "has_fish_allergy": settings.has_fish_allergy,
            }
        except Exception:
            user_settings = {}

        # 🔹 Build prompt
        prompt = PromptTemplates.chatbot_prompt(
            user_recipes=recipes_list,
            query=query,
            user_settings=user_settings,
            recipe_context=recipe_context
        ) if recipe_context is None else query

        def event_stream():
            try:
                anthropic_service = AnthropicService()
                full_response = ""
                for chunk in anthropic_service.ask_stream(prompt, chat_history, recipe_context, use_web_search=(recipe_context is None)):
                    full_response += chunk
                    yield f"data: {json.dumps({'token': chunk})}\n\n"

                try:
                    conversation.ai_response = full_response
                    conversation.save()
                    ChatHistory.objects.create(user=user, conversation=conversation, sender="ai", message=full_response)
                except Exception as db_err:
                    import logging
                    logging.getLogger(__name__).error("Failed to save chat history: %s", db_err)
            except Exception as e:
                import logging
                logging.getLogger(__name__).error("event_stream error: %s", e, exc_info=True)
                yield f"data: {json.dumps({'token': f'Error: {e}'})}\n\n"

        return StreamingHttpResponse(event_stream(), content_type="text/event-stream")

class RecipeOCRView(APIView):
    parser_classes = [MultiPartParser]

    def post(self, request, *args, **kwargs):
        images = request.FILES.getlist('images')
        if not images:
            # backward compat: single 'image' field
            single = request.FILES.get('image')
            if single:
                images = [single]
        if not images:
            return JsonResponse({"error": "No images provided"}, status=400)

        temp_paths = []
        try:
            for image in images:
                with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as tmp:
                    for chunk in image.chunks():
                        tmp.write(chunk)
                    temp_paths.append(tmp.name)

            return self.process_ocr_response(request.user, temp_paths)

        except Exception as e:
            return JsonResponse({"error": f"An error occurred: {str(e)}"}, status=500)

        finally:
            for path in temp_paths:
                if os.path.exists(path):
                    os.remove(path)

    def process_ocr_response(self, user, image_paths):
        """
        Processes one or more images for OCR and returns a JSON response.
        """
        anthropic_service = AnthropicService()
        response = anthropic_service.ask_ocr(image_paths)
        return JsonResponse({"response": response}, status=status.HTTP_200_OK)


class RecipeURLImportView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        url = request.data.get("url", "").strip()
        if not url:
            return JsonResponse({"error": "url is required"}, status=400)

        try:
            anthropic_service = AnthropicService()
            result = import_recipe_from_url(url, anthropic_service)
            return JsonResponse({"response": result}, status=200)
        except ValueError as e:
            return JsonResponse({"error": str(e)}, status=422)
        except Exception as e:
            import requests as req_lib
            if isinstance(e, req_lib.exceptions.ConnectionError):
                return JsonResponse({"error": "Could not reach that URL."}, status=502)
            if isinstance(e, req_lib.exceptions.HTTPError):
                return JsonResponse({"error": f"URL returned an error: {e}"}, status=502)
            return JsonResponse({"error": f"Import failed: {e}"}, status=500)
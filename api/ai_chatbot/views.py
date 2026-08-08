import os
import tempfile

from dotenv import load_dotenv
from rest_framework.views import APIView
from rest_framework import status
from rest_framework.parsers import MultiPartParser
from rest_framework.permissions import IsAuthenticated
from django.http import JsonResponse, StreamingHttpResponse
from .api import (
    AnthropicService,
    PromptTemplates,
    CREATE_RECIPE_TOOL,
    UPDATE_RECIPE_TOOL,
    REFERENCE_RECIPE_TOOL,
    SEARCH_RECIPES_TOOL,
    WEB_SEARCH_TOOL,
    MOOD_DESCRIPTIONS,
)
from .url_fetcher import import_recipe_from_url
from .models import Conversation, ChatHistory, ChatMessage
from recipes.models import Recipe, SavedRecipe
import json
import logging

load_dotenv()

logger = logging.getLogger(__name__)


def get_user_settings_dict(user):
    """User settings dict shared by the chatbot prompts (mirrors v1 behavior)."""
    try:
        settings = user.settings
        return {
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
        return {}


def build_taste_summary(user, max_tags=8):
    """
    Compact taste summary for chat v2 global/home context (catalog-first-pivot.md
    §2 WS-P2): counts + top tags instead of embedding the user's full saved-recipe
    list as the model's recipe universe. Cheap in-view aggregation over recipes
    already queryable — no new infrastructure.
    """
    try:
        own_qs = Recipe.objects.filter(created_by=user)
        own_count = own_qs.count()

        saved_recipe_ids = list(
            SavedRecipe.objects.filter(user=user).values_list("recipe_id", flat=True)
        )
        saved_count = len(saved_recipe_ids)

        tag_lists = list(own_qs.values_list("tags", flat=True))
        if saved_recipe_ids:
            tag_lists += list(
                Recipe.objects.filter(id__in=saved_recipe_ids).values_list("tags", flat=True)
            )

        tag_counts = {}
        for tags in tag_lists:
            for tag in (tags or []):
                key = str(tag).strip()
                if not key:
                    continue
                tag_counts[key] = tag_counts.get(key, 0) + 1

        top_tags = [
            tag for tag, _ in sorted(tag_counts.items(), key=lambda kv: kv[1], reverse=True)
        ][:max_tags]

        return {
            "own_recipe_count": own_count,
            "saved_recipe_count": saved_count,
            "top_tags": top_tags,
        }
    except Exception:
        logger.exception("build_taste_summary failed for user_id=%s", getattr(user, "id", None))
        return {"own_recipe_count": 0, "saved_recipe_count": 0, "top_tags": []}


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


class ChatbotV2View(APIView):
    """
    Chat v2 (plan §1.6): Anthropic tool use + typed SSE events + server-side history.

    POST body:
        {
          "message": "...",
          "conversation_id": 123 | null,
          "context": "home" | "global" | "recipe_edit",
          "recipe_id": 456,            // recipe_edit only
          "mood": "rushed" | null,
          "home_feed": {...} | null
        }

    SSE events (each a `data:` JSON line):
        {"type": "message_start", "conversation_id": 123}
        {"type": "text_delta", "text": "..."}
        {"type": "block", "block": <Block>}
        {"type": "error", "message": "..."}
        {"type": "done"}
    """
    permission_classes = [IsAuthenticated]

    VALID_CONTEXTS = {"home", "global", "recipe_edit"}

    def post(self, request):
        message = request.data.get("message")
        if not message or not isinstance(message, str):
            return JsonResponse({"error": "message is required"}, status=status.HTTP_400_BAD_REQUEST)

        context = request.data.get("context") or "global"
        if context not in self.VALID_CONTEXTS:
            return JsonResponse(
                {"error": f"context must be one of {sorted(self.VALID_CONTEXTS)}"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        mood = request.data.get("mood")
        if mood is not None and mood not in MOOD_DESCRIPTIONS:
            return JsonResponse(
                {"error": f"mood must be one of {sorted(MOOD_DESCRIPTIONS)} or null"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        home_feed = request.data.get("home_feed")
        recipe_id = request.data.get("recipe_id")
        conversation_id = request.data.get("conversation_id")

        # --- Conversation (server-side history) ---
        if conversation_id is not None:
            try:
                conversation = Conversation.objects.get(id=conversation_id, user=request.user)
            except Conversation.DoesNotExist:
                return JsonResponse({"error": "Conversation not found"}, status=status.HTTP_404_NOT_FOUND)
        else:
            conversation = Conversation.objects.create(
                user=request.user, user_query=message, ai_response=""
            )

        # --- Context-specific setup ---
        recipe_context = None
        if context == "recipe_edit":
            if not recipe_id:
                return JsonResponse(
                    {"error": "recipe_id is required for recipe_edit context"},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            try:
                recipe = Recipe.objects.get(id=recipe_id, created_by=request.user)
            except Recipe.DoesNotExist:
                return JsonResponse({"error": "Recipe not found"}, status=status.HTTP_404_NOT_FOUND)
            recipe_context = {
                "id": recipe.id,
                "title": recipe.title,
                "ingredients": [
                    {"name": ing.name, "quantity": ing.quantity, "unit": ing.unit}
                    for ing in recipe.ingredients.all()
                ],
                "instructions": recipe.instructions,
                "tags": recipe.tags,
                "description": recipe.description,
                "notes": recipe.notes,
                "preparation_time": recipe.preparation_time,
                "cooking_time": recipe.cooking_time,
            }

        user_settings = get_user_settings_dict(request.user)

        if context == "recipe_edit":
            system = PromptTemplates.recipe_edit_v2_system(
                recipe_context, user_settings=user_settings, mood=mood
            )
            tools = [UPDATE_RECIPE_TOOL]
        else:
            taste_summary = build_taste_summary(request.user)
            system = PromptTemplates.chatbot_v2_system(
                taste_summary=taste_summary,
                user_settings=user_settings,
                mood=mood,
                home_feed=home_feed,
            )
            tools = [SEARCH_RECIPES_TOOL, CREATE_RECIPE_TOOL, REFERENCE_RECIPE_TOOL, WEB_SEARCH_TOOL]

        # --- Rebuild Anthropic messages from stored history (client sends only the new message) ---
        messages = self.build_anthropic_messages(conversation)
        messages.append({"role": "user", "content": message})

        # Persist the user turn.
        ChatMessage.objects.create(
            conversation=conversation, user=request.user,
            role=ChatMessage.ROLE_USER, text=message,
        )

        resolve_block = self.make_block_resolver(request.user, default_recipe_id=recipe_id)
        resolve_data_tool = self.make_data_tool_resolver(request.user)

        def event_stream():
            full_text = []
            blocks = []
            yield f"data: {json.dumps({'type': 'message_start', 'conversation_id': conversation.id})}\n\n"
            try:
                service = AnthropicService()
                for event in service.ask_stream_v2(
                    system, messages, tools,
                    resolve_block=resolve_block, resolve_data_tool=resolve_data_tool,
                ):
                    if event["type"] == "text_delta":
                        full_text.append(event["text"])
                    elif event["type"] == "block":
                        blocks.append(event["block"])
                    yield f"data: {json.dumps(event)}\n\n"
            except Exception as e:
                logger.error("chat v2 event_stream error: %s", e, exc_info=True)
                yield f"data: {json.dumps({'type': 'error', 'message': str(e)})}\n\n"
            finally:
                try:
                    ChatMessage.objects.create(
                        conversation=conversation, user=request.user,
                        role=ChatMessage.ROLE_ASSISTANT,
                        text="".join(full_text), blocks=blocks,
                    )
                    conversation.ai_response = "".join(full_text)
                    conversation.save()
                except Exception as db_err:
                    logger.error("Failed to save chat v2 history: %s", db_err)
            yield f"data: {json.dumps({'type': 'done'})}\n\n"

        return StreamingHttpResponse(event_stream(), content_type="text/event-stream")

    @staticmethod
    def build_anthropic_messages(conversation):
        """
        Rebuilds the Anthropic messages array from stored ChatMessage rows.
        Assistant blocks are rendered as compact bracketed JSON so the model
        retains what it previously created/referenced/updated.
        """
        messages = []
        for msg in conversation.messages.all():
            if msg.role == ChatMessage.ROLE_USER:
                if msg.text:
                    messages.append({"role": "user", "content": msg.text})
                continue
            parts = []
            if msg.text:
                parts.append(msg.text)
            for block in msg.blocks or []:
                block_type = block.get("block_type")
                if block_type == "recipe":
                    parts.append(f"[create_recipe: {json.dumps(block.get('recipe'), separators=(',', ':'))}]")
                elif block_type == "recipe_update":
                    parts.append(
                        f"[update_recipe recipe_id={block.get('recipe_id')}: "
                        f"{json.dumps(block.get('changes'), separators=(',', ':'))}]"
                    )
                elif block_type == "recipe_ref":
                    recipe = block.get("recipe") or {}
                    parts.append(f"[reference_recipe: {recipe.get('title')} (ID: {recipe.get('id')})]")
            content = "\n".join(parts)
            if content:
                messages.append({"role": "assistant", "content": content})
        return messages

    @staticmethod
    def make_block_resolver(user, default_recipe_id=None):
        """Maps completed tool calls to plan-§1.1 blocks. Raises ValueError on bad input."""

        def resolve(tool_name, tool_input):
            if tool_name == "create_recipe":
                return AnthropicService.build_recipe_block(tool_input)

            if tool_name == "update_recipe":
                return AnthropicService.build_recipe_update_block(
                    tool_input, default_recipe_id=default_recipe_id
                )

            if tool_name == "reference_recipe":
                rid = tool_input.get("id")
                if not isinstance(rid, int):
                    raise ValueError("`id` must be an integer")
                try:
                    recipe = Recipe.objects.get(id=rid)
                except Recipe.DoesNotExist:
                    raise ValueError(f"Recipe {rid} does not exist")
                # Catalog-first pivot (§1.2): any catalog recipe is referenceable,
                # but another user's AI-generated recipe is generated slop, not
                # curated catalog content — never surface it as if it were.
                # Users may still reference their own AI-generated recipes.
                if recipe.source == Recipe.SOURCE_AI and recipe.created_by_id != getattr(user, "id", None):
                    raise ValueError(
                        f"Recipe {rid} is an AI-generated recipe that does not belong to this user "
                        "and cannot be referenced"
                    )
                image_url = None
                try:
                    if recipe.image:
                        image_url = recipe.image.url
                    elif recipe.web_image_url:
                        image_url = recipe.web_image_url
                except Exception:
                    image_url = recipe.web_image_url or None
                total_time = (recipe.preparation_time or 0) + (recipe.cooking_time or 0)
                return {
                    "block_type": "recipe_ref",
                    "recipe": {
                        "id": recipe.id,
                        "title": recipe.title,
                        "image_url": image_url,
                        "total_time": total_time or None,
                        "calories": int(recipe.calories) if recipe.calories is not None else None,
                        "tags": recipe.tags or [],
                    },
                }

            raise ValueError(f"Unknown tool: {tool_name}")

        return resolve

    @staticmethod
    def make_data_tool_resolver(user):
        """Maps completed data-tool calls to tool_result data (plan §1.1). Raises
        ValueError on bad input; never emits a `block`."""

        def resolve(tool_name, tool_input):
            if tool_name == "search_recipes":
                return AnthropicService.build_search_recipes_result(tool_input, user=user)
            raise ValueError(f"Unknown data tool: {tool_name}")

        return resolve


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
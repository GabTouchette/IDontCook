import os
import base64
import io as _io
import json
import re
from typing import List, Dict, Any
from django.conf import settings
from recipes.models import Ingredient, Recipe
from recipes.search_service import search_catalog
import anthropic
from PIL import Image as _PILImage


ANTHROPIC_IMG_LIMIT = 5 * 1024 * 1024   # 5 MB (base64 bytes)
_IMG_SAFE_LIMIT = int(ANTHROPIC_IMG_LIMIT * 0.85)  # leave 15 % headroom

CHAT_MODEL  = "claude-sonnet-5"    # recipe-generating chat calls (v1 + v2)
LIGHT_MODEL = "claude-haiku-4-5"   # lightweight formatting / OCR paths

# ---------------------------------------------------------------------------
# Chat v2 — Anthropic tool definitions (plan §1.6)
#
# Input schemas mirror the delimiter-protocol JSON shapes so tool output stays
# compatible with RecipeSerializer:
#   create_recipe    -> full recipe shape previously emitted inside $$...$$
#   update_recipe    -> changed-fields shape previously emitted inside @@...@@
#   reference_recipe -> {id, title} previously emitted inside &&...&&
# ---------------------------------------------------------------------------

_INGREDIENT_SCHEMA = {
    "type": "object",
    "properties": {
        "name": {"type": "string", "description": "Ingredient name"},
        "quantity": {"type": "number", "description": "Decimal quantity, e.g. 0.75, 1.0"},
        "unit": {
            "type": "string",
            "description": (
                "Abbreviated unit: tbsp, tsp, cup, oz, lb, g, kg, ml, L, pc, "
                "clove, pinch, bunch, can, pkg. Empty string if not applicable."
            ),
        },
    },
    "required": ["name", "quantity", "unit"],
    "additionalProperties": False,
}

_RECIPE_FIELDS_SCHEMA = {
    "title": {"type": "string"},
    "ingredients": {"type": "array", "items": _INGREDIENT_SCHEMA},
    "instructions": {"type": "array", "items": {"type": "string"}},
    "preparation_time": {"type": ["integer", "null"], "description": "Minutes"},
    "cooking_time": {"type": ["integer", "null"], "description": "Minutes"},
    "servings": {"type": ["integer", "null"]},
    "tags": {"type": "array", "items": {"type": "string"}},
    "description": {"type": ["string", "null"]},
    "notes": {"type": ["string", "null"]},
}

CREATE_RECIPE_TOOL = {
    "name": "create_recipe",
    "description": (
        "Create a brand-new recipe for the user. Use this whenever you compose a "
        "recipe yourself (not one from the user's saved list). All numeric ingredient "
        "quantities must be decimals (1.0, not 1). Provide every field; use null or "
        "empty values when unknown."
    ),
    "strict": True,
    "input_schema": {
        "type": "object",
        "properties": _RECIPE_FIELDS_SCHEMA,
        "required": [
            "title", "ingredients", "instructions", "preparation_time",
            "cooking_time", "servings", "tags", "description", "notes",
        ],
        "additionalProperties": False,
    },
}

UPDATE_RECIPE_TOOL = {
    "name": "update_recipe",
    "description": (
        "Propose modifications to the recipe currently being edited. Include ONLY the "
        "fields that changed in `changes`. If you change `ingredients` or `tags`, "
        "return the full updated list. `recipe_id` may be null when the recipe is "
        "implicit from the conversation context."
    ),
    "input_schema": {
        "type": "object",
        "properties": {
            "recipe_id": {
                "type": ["integer", "null"],
                "description": "ID of the recipe being updated; null if implicit from context.",
            },
            "changes": {
                "type": "object",
                "description": "Only the recipe fields that changed.",
                "properties": _RECIPE_FIELDS_SCHEMA,
                "additionalProperties": False,
            },
        },
        "required": ["changes"],
        "additionalProperties": False,
    },
}

REFERENCE_RECIPE_TOOL = {
    "name": "reference_recipe",
    "description": (
        "Reference an existing recipe by id and title so it is shown to the user as a "
        "card — e.g. one of the results returned by `search_recipes`, or one of the "
        "user's own saved recipes. Only reference recipe ids you actually obtained from "
        "`search_recipes` results or from the conversation/system-prompt context; never "
        "invent an id."
    ),
    "strict": True,
    "input_schema": {
        "type": "object",
        "properties": {
            "id": {"type": "integer", "description": "Recipe ID"},
            "title": {"type": "string", "description": "Recipe title"},
        },
        "required": ["id", "title"],
        "additionalProperties": False,
    },
}

SEARCH_RECIPES_TOOL = {
    "name": "search_recipes",
    "description": (
        "Search the full recipe catalog (thousands of existing recipes — hybrid lexical "
        "+ semantic retrieval) for matches to a free-text description. ALWAYS try this "
        "before create_recipe when the user is asking what to cook, for a suggestion, or "
        "to find something to eat. The results are returned to YOU as data, not shown to "
        "the user — read them and call `reference_recipe` for the ones worth presenting."
    ),
    "input_schema": {
        "type": "object",
        "properties": {
            "query": {
                "type": "string",
                "description": "Free-text description of what to find, e.g. 'cozy winter soup'.",
            },
            "tags": {
                "type": "array",
                "items": {"type": "string"},
                "description": "Optional tag filters.",
            },
            "max_total_time": {
                "type": ["integer", "null"],
                "description": "Optional max total time in minutes.",
            },
            "max_calories": {
                "type": ["integer", "null"],
                "description": "Optional max calories.",
            },
            "exclude_ids": {
                "type": "array",
                "items": {"type": "integer"},
                "description": "Recipe ids already shown or rejected earlier this conversation.",
            },
            "limit": {
                "type": "integer",
                "description": "Max results to return (default 8, max 15).",
            },
        },
        "required": ["query"],
        "additionalProperties": False,
    },
}

WEB_SEARCH_TOOL = {"type": "web_search_20250305", "name": "web_search"}

# UI tools: a completed call becomes a `block` SSE event shown to the user.
V2_CLIENT_TOOL_NAMES = {"create_recipe", "update_recipe", "reference_recipe"}

# Data tools: a completed call's result goes back to the model as tool_result
# data (never a `block` event); the model reads it and decides what to do next
# (catalog-first-pivot.md §1.1/§2 WS-P2).
V2_DATA_TOOL_NAMES = {"search_recipes"}

# All tool_use blocks the streaming loop buffers JSON input for (server tools
# like web_search are executed by Anthropic and never surface here).
V2_TRACKED_TOOL_NAMES = V2_CLIENT_TOOL_NAMES | V2_DATA_TOOL_NAMES

# Mood meanings per plan §1.3
MOOD_DESCRIPTIONS = {
    "rushed": "The user is in a hurry and wants quick, simple recipes (total time under ~30 minutes).",
    "ambitious": "The user feels ambitious and wants to attempt something challenging or new.",
    "cooking_for_someone": "The user is cooking for someone else and wants to impress; suggest shareable, crowd-pleasing dishes.",
    "comfort": "The user wants cozy, comforting food.",
    "healthy": "The user wants light, nutritious, health-conscious options.",
    "surprise_me": "The user is open to anything — feel free to be creative and surprising.",
}


def encode_image(image_path):
    """Encode image as Base64, resizing/compressing to stay under Anthropic's 5 MB limit."""
    with _PILImage.open(image_path) as img:
        if img.mode in ('RGBA', 'P', 'LA', 'CMYK'):
            img = img.convert('RGB')
        # Work on a copy so we don't keep the file handle open
        img = img.copy()

    # Resize if very large
    max_dim = 1568
    if img.width > max_dim or img.height > max_dim:
        img.thumbnail((max_dim, max_dim), _PILImage.LANCZOS)

    for quality in (85, 75, 65, 55):
        buf = _io.BytesIO()
        img.save(buf, format='JPEG', quality=quality)
        raw = buf.getvalue()
        # base64 adds ~33 % overhead
        if ((len(raw) + 2) // 3) * 4 <= _IMG_SAFE_LIMIT:
            return base64.b64encode(raw).decode('utf-8')

    # Last resort: shrink hard
    img.thumbnail((1024, 1024), _PILImage.LANCZOS)
    buf = _io.BytesIO()
    img.save(buf, format='JPEG', quality=55)
    return base64.b64encode(buf.getvalue()).decode('utf-8')

class AnthropicService:
    def __init__(self):
        """Initialize the Anthropic client with the API key."""
        self.client = anthropic.Anthropic(api_key=getattr(settings, "ANTHROPIC_API_KEY", None))

    def ask_ocr(self, image_paths):
        """
        Processes one or more images for OCR using Anthropic and returns a JSON string.
        Accepts a single path string or a list of paths.
        Raises on any error so callers receive a proper HTTP error response.
        """
        if isinstance(image_paths, str):
            image_paths = [image_paths]

        content = []
        for path in image_paths:
            base64_image = encode_image(path)
            content.append({
                "type": "image",
                "source": {
                    "type": "base64",
                    "media_type": "image/jpeg",
                    "data": base64_image,
                },
            })
        content.append({"type": "text", "text": PromptTemplates.ocr_prompt()})

        response = self.client.messages.create(
            model=LIGHT_MODEL,
            max_tokens=4096,
            messages=[{"role": "user", "content": content}]
        )

        response_content = response.content[0].text
        response_content = re.sub(r"^```json\s*|\s*```$", "", response_content).strip()
        recipe_json = json.loads(response_content)  # raises JSONDecodeError if invalid
        return json.dumps(recipe_json)

    # Keep backward-compat alias
    def ask_openai_ocr(self, image_path):
        return self.ask_ocr(image_path)

    def ask_stream(self, prompt, chat_history=None, recipe_context=None, use_web_search=False):
        """
        Handles chatbot conversation with streaming response.
        If a recipe_context is provided, it uses a recipe-editing prompt.
        """
        try:
            messages = []

            if chat_history:
                for entry in chat_history:
                    role = "user" if entry["sender"] == "user" else "assistant"
                    messages.append({"role": role, "content": entry["message"]})

            if recipe_context:
                final_prompt = PromptTemplates.recipe_edit_prompt(recipe_context, prompt)
            else:
                final_prompt = prompt

            messages.append({"role": "user", "content": final_prompt})

            stream_kwargs = {
                "model": CHAT_MODEL,
                "max_tokens": 2048,
                "messages": messages,
                # v1 predates thinking; claude-sonnet-5 runs adaptive thinking when
                # the field is omitted, which would spend the small v1 token budget.
                # Disable it explicitly to keep v1 behavior unchanged.
                "thinking": {"type": "disabled"},
            }
            if use_web_search:
                stream_kwargs["tools"] = [{"type": "web_search_20250305", "name": "web_search"}]

            with self.client.messages.stream(**stream_kwargs) as stream:
                for text in stream.text_stream:
                    yield text

        except anthropic.APIError as e:
            yield f"Error communicating with Anthropic: {e}"
        except Exception as e:
            yield f"An unexpected error occurred: {e}"

    # Keep backward-compat alias
    def ask_openai_stream(self, prompt, chat_history=None, recipe_context=None):
        yield from self.ask_stream(prompt, chat_history, recipe_context)

    # ------------------------------------------------------------------
    # Chat v2 — tool-use streaming (plan §1.6)
    # ------------------------------------------------------------------

    # Retrieval (search -> read -> reference, possibly refining once) can take
    # more turns than the old create/update/reference loop.
    MAX_V2_TURNS = 7

    def ask_stream_v2(self, system, messages, tools, resolve_block=None, resolve_data_tool=None):
        """
        Streams a chat v2 turn using Anthropic tool use.

        Yields typed event dicts (not SSE-encoded):
            {"type": "text_delta", "text": str}
            {"type": "block", "block": {...}}            # completed UI tool call
            {"type": "tool_activity", "tool": str}        # a data tool call started
            {"type": "error", "message": str}

        Two disjoint tool families:
          - UI tools (`V2_CLIENT_TOOL_NAMES`: create_recipe/update_recipe/
            reference_recipe) — a completed call is resolved via
            `resolve_block(tool_name, tool_input)` into a plan-§1.1 block dict,
            emitted as a `block` event, and acknowledged back to the model with
            a plain "Displayed to the user." tool_result.
          - Data tools (`V2_DATA_TOOL_NAMES`: search_recipes) — no block is
            emitted; instead `resolve_data_tool(tool_name, tool_input)` returns
            JSON-serializable data that is fed back to the model as the real
            tool_result content, and the model keeps going (typically calling
            reference_recipe next). A `tool_activity` event fires as soon as
            the call begins, before its result comes back.

        Both resolvers may raise ValueError for invalid input, which is
        surfaced as an "error" event and an `is_error` tool_result (never
        crashes the stream).

        Runs an agentic loop: when the model stops with `tool_use`, tool_result
        acknowledgements/data are fed back so the model can continue or finish.
        """
        resolve_block = resolve_block or default_resolve_block
        resolve_data_tool = resolve_data_tool or default_resolve_data_tool
        messages = list(messages)

        for _ in range(self.MAX_V2_TURNS):
            tool_buffers = {}      # stream index -> {"id", "name", "json"}
            assistant_content = []  # replayable content blocks for continuation
            tool_results = []       # tool_result blocks for the follow-up user turn
            stop_reason = None
            current_text_parts = {}  # stream index -> [str]

            try:
                stream = self.client.messages.create(
                    model=CHAT_MODEL,
                    max_tokens=8192,
                    system=system,
                    messages=messages,
                    tools=tools,
                    stream=True,
                )

                for event in stream:
                    etype = getattr(event, "type", None)

                    if etype == "content_block_start":
                        block = event.content_block
                        if block.type == "tool_use" and block.name in V2_TRACKED_TOOL_NAMES:
                            tool_buffers[event.index] = {
                                "id": block.id,
                                "name": block.name,
                                "json": "",
                            }
                            if block.name in V2_DATA_TOOL_NAMES:
                                yield {"type": "tool_activity", "tool": block.name}
                        elif block.type == "text":
                            current_text_parts[event.index] = []

                    elif etype == "content_block_delta":
                        delta = event.delta
                        dtype = getattr(delta, "type", None)
                        if dtype == "text_delta":
                            if event.index in current_text_parts:
                                current_text_parts[event.index].append(delta.text)
                            yield {"type": "text_delta", "text": delta.text}
                        elif dtype == "input_json_delta" and event.index in tool_buffers:
                            tool_buffers[event.index]["json"] += delta.partial_json

                    elif etype == "content_block_stop":
                        if event.index in current_text_parts:
                            text = "".join(current_text_parts.pop(event.index))
                            if text:
                                assistant_content.append({"type": "text", "text": text})
                        if event.index in tool_buffers:
                            buf = tool_buffers.pop(event.index)
                            is_data_tool = buf["name"] in V2_DATA_TOOL_NAMES
                            raw = buf["json"].strip() or "{}"
                            tool_input, parse_error = None, None
                            try:
                                tool_input = json.loads(raw)
                                if not isinstance(tool_input, dict):
                                    raise ValueError("tool input must be a JSON object")
                            except (json.JSONDecodeError, ValueError) as e:
                                parse_error = f"Malformed {buf['name']} tool input: {e}"

                            result_payload = None
                            if parse_error is None:
                                try:
                                    if is_data_tool:
                                        result_payload = resolve_data_tool(buf["name"], tool_input)
                                    else:
                                        result_payload = resolve_block(buf["name"], tool_input)
                                except ValueError as e:
                                    parse_error = f"Invalid {buf['name']} tool input: {e}"

                            assistant_content.append({
                                "type": "tool_use",
                                "id": buf["id"],
                                "name": buf["name"],
                                "input": tool_input if isinstance(tool_input, dict) else {},
                            })
                            if parse_error is not None:
                                yield {"type": "error", "message": parse_error}
                                tool_results.append({
                                    "type": "tool_result",
                                    "tool_use_id": buf["id"],
                                    "content": parse_error,
                                    "is_error": True,
                                })
                            elif is_data_tool:
                                # Data tools: no block, real data goes back to the model.
                                tool_results.append({
                                    "type": "tool_result",
                                    "tool_use_id": buf["id"],
                                    "content": json.dumps(result_payload),
                                })
                            else:
                                yield {"type": "block", "block": result_payload}
                                tool_results.append({
                                    "type": "tool_result",
                                    "tool_use_id": buf["id"],
                                    "content": "Displayed to the user.",
                                })

                    elif etype == "message_delta":
                        stop_reason = getattr(event.delta, "stop_reason", None) or stop_reason

            except anthropic.APIError as e:
                yield {"type": "error", "message": f"Error communicating with Anthropic: {e}"}
                return

            if stop_reason == "tool_use" and tool_results:
                messages.append({"role": "assistant", "content": assistant_content})
                messages.append({"role": "user", "content": tool_results})
                continue
            return

    @staticmethod
    def build_recipe_block(recipe_data):
        """create_recipe tool input -> {"block_type": "recipe", ...} (validated)."""
        validated = AnthropicService.validate_recipe_format(recipe_data)
        return {"block_type": "recipe", "recipe": validated}

    @staticmethod
    def build_recipe_update_block(tool_input, default_recipe_id=None):
        """update_recipe tool input -> {"block_type": "recipe_update", ...}."""
        changes = tool_input.get("changes")
        if not isinstance(changes, dict) or not changes:
            raise ValueError("`changes` must be a non-empty object of changed recipe fields")
        recipe_id = tool_input.get("recipe_id") or default_recipe_id
        return {"block_type": "recipe_update", "recipe_id": recipe_id, "changes": changes}

    @staticmethod
    def build_search_recipes_result(tool_input, *, user=None):
        """search_recipes tool input -> compact tool_result data (plan §1.1).

        Calls `search_catalog` (WS-P1, never raises) and returns a short list
        of dicts the model reads directly. Never rendered to the user.
        """
        query = tool_input.get("query")
        if not isinstance(query, str) or not query.strip():
            raise ValueError("`query` must be a non-empty string")

        tags = tool_input.get("tags")
        if tags is not None and not isinstance(tags, list):
            raise ValueError("`tags` must be a list of strings")

        exclude_ids = tool_input.get("exclude_ids")
        if exclude_ids is not None and not isinstance(exclude_ids, list):
            raise ValueError("`exclude_ids` must be a list of integers")
        exclude_ids = [i for i in (exclude_ids or []) if isinstance(i, int)]

        max_total_time = tool_input.get("max_total_time")
        if max_total_time is not None and not isinstance(max_total_time, int):
            max_total_time = None

        max_calories = tool_input.get("max_calories")
        if max_calories is not None and not isinstance(max_calories, int):
            max_calories = None

        limit = tool_input.get("limit", 8)
        if not isinstance(limit, int) or limit <= 0:
            limit = 8
        limit = min(limit, 15)

        recipes = search_catalog(
            query,
            user=user,
            tags=tags,
            max_total_time=max_total_time,
            max_calories=max_calories,
            exclude_ids=exclude_ids,
            limit=limit,
        )

        results = []
        for r in recipes:
            prep, cook = r.preparation_time, r.cooking_time
            total_time = (prep or 0) + (cook or 0) if (prep is not None or cook is not None) else None
            desc = (r.description or "").strip()[:120]
            results.append({
                "id": r.id,
                "title": r.title,
                "tags": r.tags or [],
                "total_time": total_time,
                "calories": int(r.calories) if r.calories is not None else None,
                "desc": desc,
            })
        return results

    def llm_format_ingredients(self, recipe) -> Recipe:
        # STEP 1 – Turn list of raw ingredient strings into a single string
        if not recipe.ingredients:
            raise ValueError("Recipe must have ingredients to format.")

        raw_ingredient_text = "\n".join(f"{str(ingredient.quantity)} {str(ingredient.name)}" for ingredient in recipe.ingredients.all())
        response = self.client.messages.create(
                model=LIGHT_MODEL,
                max_tokens=2048,
                messages=[
                    {"role": "user", "content": PromptTemplates.format_ingredients_with_llm_prompt(raw_ingredient_text)}
                ]
            )
        
        response_content = response.content[0].text
        response_content = re.sub(r"^```json\s*|\s*```$", "", response_content).strip()
        try:
            ingredient_data = json.loads(response_content)
        except json.JSONDecodeError:
            return "Error: The response was not valid JSON."

        # STEP 4 – Convert to Ingredient model instances (without saving yet)
        ingredients: List[Ingredient] = []
        for item in ingredient_data:
            ingredient = Ingredient(
                name=item.get("name"),
                quantity=item.get("quantity"),
                unit=item.get("unit"),
                usda_name=item.get("usda_name"),
                substitutes=item.get("substitutes", [])
            )
            ingredient.save()

            ingredients.append(ingredient)

        # STEP 5 – Replace recipe.ingredients
        recipe.ingredients.set(ingredients)
        return recipe

    @staticmethod
    def validate_recipe_format(recipe_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Validates and normalizes recipe data format to ensure consistency.
        Returns the validated/corrected recipe data.
        """
        if not isinstance(recipe_data, dict):
            raise ValueError("Recipe data must be a dictionary")
        
        # Required fields with default values
        validated_recipe = {
            "title": recipe_data.get("title", "Untitled Recipe"),
            "ingredients": [],
            "instructions": recipe_data.get("instructions", []),
            "preparation_time": recipe_data.get("preparation_time"),
            "cooking_time": recipe_data.get("cooking_time"), 
            "servings": recipe_data.get("servings"),
            "tags": recipe_data.get("tags", []),
            "description": recipe_data.get("description"),
            "notes": recipe_data.get("notes")
        }
        
        # Validate title
        if not validated_recipe["title"] or not isinstance(validated_recipe["title"], str):
            raise ValueError("Recipe must have a valid title")
        
        # Validate and normalize ingredients
        ingredients = recipe_data.get("ingredients", [])
        if not ingredients:
            raise ValueError("Recipe must have at least one ingredient")
        
        for i, ingredient in enumerate(ingredients):
            if not isinstance(ingredient, dict):
                raise ValueError(f"Ingredient {i+1} must be an object")
            
            if not ingredient.get("name"):
                raise ValueError(f"Ingredient {i+1} must have a name")
            
            # Ensure quantity is present and numeric
            quantity = ingredient.get("quantity")
            if quantity is None:
                raise ValueError(f"Ingredient {i+1} ({ingredient.get('name')}) must have a quantity")
            
            try:
                quantity = float(quantity)
            except (TypeError, ValueError):
                raise ValueError(f"Ingredient {i+1} ({ingredient.get('name')}) quantity must be a number")
            
            validated_ingredient = {
                "name": str(ingredient["name"]).strip(),
                "quantity": quantity,
                "unit": str(ingredient.get("unit", "")).strip()
            }
            
            validated_recipe["ingredients"].append(validated_ingredient)
        
        # Validate instructions
        if not validated_recipe["instructions"]:
            raise ValueError("Recipe must have at least one instruction")
        
        if not isinstance(validated_recipe["instructions"], list):
            raise ValueError("Instructions must be a list")
        
        # Ensure all instructions are strings
        validated_recipe["instructions"] = [str(inst).strip() for inst in validated_recipe["instructions"] if str(inst).strip()]
        
        if not validated_recipe["instructions"]:
            raise ValueError("Recipe must have at least one non-empty instruction")
        
        # Validate numeric fields
        for field in ["preparation_time", "cooking_time", "servings"]:
            value = validated_recipe[field]
            if value is not None:
                try:
                    validated_recipe[field] = int(value)
                except (TypeError, ValueError):
                    validated_recipe[field] = None
        
        # Ensure tags is a list
        if not isinstance(validated_recipe["tags"], list):
            validated_recipe["tags"] = []
        
        return validated_recipe


def default_resolve_block(tool_name, tool_input):
    """Fallback block resolver used when the caller doesn't provide one."""
    if tool_name == "create_recipe":
        return AnthropicService.build_recipe_block(tool_input)
    if tool_name == "update_recipe":
        return AnthropicService.build_recipe_update_block(tool_input)
    if tool_name == "reference_recipe":
        if not isinstance(tool_input.get("id"), int):
            raise ValueError("`id` must be an integer")
        return {
            "block_type": "recipe_ref",
            "recipe": {
                "id": tool_input["id"],
                "title": tool_input.get("title", ""),
                "image_url": None,
                "total_time": None,
                "calories": None,
                "tags": [],
            },
        }
    raise ValueError(f"Unknown tool: {tool_name}")


def default_resolve_data_tool(tool_name, tool_input):
    """Fallback data-tool resolver used when the caller doesn't provide one."""
    if tool_name == "search_recipes":
        return AnthropicService.build_search_recipes_result(tool_input, user=None)
    raise ValueError(f"Unknown data tool: {tool_name}")


class PromptTemplates:
    @staticmethod
    def chatbot_prompt(user_recipes, query, user_settings=None, recipe_context=None):
        """Generates a prompt for the AI chatbot with recipe and user context."""
        recipe_info = "\n".join([f"- {r['title']} (ID: {r['id']})" for r in user_recipes]) if user_recipes else "No saved recipes."

        settings = ""
        if user_settings:
            prefs = [k.replace("_", " ").capitalize() for k, v in user_settings.items() if isinstance(v, bool) and v]
            demographics = [f"{k.capitalize()}: {v}" for k, v in user_settings.items() if v and not isinstance(v, bool)]
            settings = (
                "User profile:\n" +
                (", ".join(demographics) if demographics else "") + "\n" +
                ("Dietary preferences / allergies: " + ", ".join(prefs) if prefs else "")
            )

        return (
            "You are a cookbook AI chatbot that helps users with their cooking and recipe needs.\n\n"
            f"{settings}\n\n"
            f"User's saved recipes:\n{recipe_info}\n\n"
            "You can:\n"
            "- Suggest an existing recipe\n"
            "- Create a new recipe\n"
            "- Answer general cooking/food questions\n\n"
            "Rules:\n"
            "- Use this format for existing recipes: &&{ \"id\": recipeId, \"title\": \"recipeTitle\" }&&\n"
            "- Only reference recipes from the list above.\n"
            "- For new recipes, use this format: $$ { ... } $$ with valid JSON.\n"
            "- Use decimal format for ingredient quantities (e.g. 0.75, 1.0).\n"
            "- Use abbreviated units in ingredients: tbsp (tablespoon), tsp (teaspoon), cup, oz, lb, g, kg, ml, L, pc (piece), clove, pinch, bunch, can, pkg (package). Avoid full unit names like 'tablespoon' or 'teaspoon'.\n"
            "- When answering general questions, you may remind the user you can generate or suggest recipes.\n"
            "- You have access to a web search tool. Use it when the user asks about recipes not in their saved list or when current information would improve your answer.\n\n"
            "**IMPORTANT: Recipe Format Requirements:**\n"
            "- ALL numeric values must be decimals (use 1.0, not 1)\n"
            "- quantity field is REQUIRED for every ingredient\n"
            "- unit field can be empty string \"\" if not applicable\n"
            "- ALL fields must be present, use null or empty values if unknown\n\n"
            "**Example of a new recipe (inside $$ ... $$):**\n"
            "$$ {\n"
            "  \"title\": \"Spaghetti Bolognese\",\n"
            "  \"ingredients\": [\n"
            "    {\"name\": \"spaghetti\", \"quantity\": 100.0, \"unit\": \"g\"},\n"
            "    {\"name\": \"ground turkey\", \"quantity\": 0.5, \"unit\": \"kg\"},\n"
            "    {\"name\": \"tomato sauce\", \"quantity\": 1.0, \"unit\": \"cup\"}\n"
            "  ],\n"
            "  \"instructions\": [\n"
            "    \"Boil the spaghetti until al dente.\",\n"
            "    \"Cook ground beef in a pan.\",\n"
            "    \"Add tomato sauce and simmer.\"\n"
            "  ],\n"
            "  \"preparation_time\": 10,\n"
            "  \"cooking_time\": 20,\n"
            "  \"servings\": 2,\n"
            "  \"tags\": [\"italian\", \"pasta\"],\n"
            "  \"description\": \"A classic Italian pasta dish with meat sauce.\",\n"
            "  \"notes\": \"You can substitute beef with lentils for a vegetarian version.\"\n"
            "} $$\n\n"
            f"User question:\n{query}"
        )

    @staticmethod
    def recipe_edit_prompt(recipe, query):
        return (
            "You are an AI assistant helping a user modify or answer questions about a recipe.\n"
            "You can respond to the user, suggest changes to the recipe or ask for more details.\n"
            "When responding with a modified recipe:\n"
            "- Respond only with fields that changed, wrapped in @@{...}@@.\n"
            "- Use valid JSON keys like: title, ingredients, instructions, cooking_time, preparation_time, servings, tags, description, notes.\n"
            "- If you change `ingredients` or `tags`, return the full updated list.\n"
            "- Each ingredient must be: {\"name\": \"ingredient name\", \"quantity\": 1.0, \"unit\": \"unit\"} — quantity must be a decimal, unit can be empty if not applicable.\n"
            "- Use abbreviated units: tbsp (tablespoon), tsp (teaspoon), cup, oz, lb, g, kg, ml, L, pc (piece), clove, pinch, bunch, can, pkg (package).\n"
            "- Instructions must be a list of strings.\n\n"
            "**Example of a modified recipe response (only changed fields):**\n"
            "@@ {\n"
            "  \"ingredients\": [\n"
            "    {\"name\": \"spaghetti\", \"quantity\": 100.0, \"unit\": \"g\"},\n"
            "    {\"name\": \"ground turkey\", \"quantity\": 0.5, \"unit\": \"kg\"},\n"
            "    {\"name\": \"tomato sauce\", \"quantity\": 1.0, \"unit\": \"cup\"}\n"
            "  ],\n"
            "  \"cooking_time\": 25\n"
            "} @@\n\n"
            f"Current recipe:\n{json.dumps(recipe, indent=2)}\n\n"
            f"User request:\n{query}"
        )

    # ------------------------------------------------------------------
    # Chat v2 prompts (tool-use protocol — no $$ / @@ / && delimiters)
    # ------------------------------------------------------------------

    @staticmethod
    def _user_profile_section(user_settings):
        if not user_settings:
            return ""
        prefs = [k.replace("_", " ").capitalize() for k, v in user_settings.items() if isinstance(v, bool) and v]
        demographics = [f"{k.capitalize()}: {v}" for k, v in user_settings.items() if v and not isinstance(v, bool)]
        return (
            "User profile:\n" +
            (", ".join(demographics) if demographics else "") + "\n" +
            ("Dietary preferences / allergies: " + ", ".join(prefs) if prefs else "")
        )

    @staticmethod
    def mood_section(mood):
        """Mood statement per plan §1.3."""
        description = MOOD_DESCRIPTIONS.get(mood)
        if not description:
            return ""
        return f"Current user mood: {mood}. {description}"

    @staticmethod
    def home_feed_section(home_feed):
        """
        Compact serialization of the home feed the user is replying to
        (greeting + modules: module_type, reason, recipe titles/ids), so replies
        like "something vegetarian instead" resolve against what was shown.
        """
        if not isinstance(home_feed, dict):
            return ""
        lines = ["The user is replying to their home feed, which currently shows:"]
        greeting = home_feed.get("greeting")
        if greeting:
            lines.append(f'Greeting: "{greeting}"')

        def _recipe_line(recipe):
            if not isinstance(recipe, dict):
                return None
            rid = recipe.get("id")
            title = recipe.get("title", "")
            return f"{title} (ID: {rid})"

        for block in home_feed.get("blocks", []) or []:
            if not isinstance(block, dict):
                continue
            if block.get("block_type") == "text" and block.get("text"):
                lines.append(f'Feed text: "{block["text"]}"')
                continue
            if block.get("block_type") != "module":
                continue
            module = block.get("module") or {}
            payload = module.get("payload") or {}
            recipes = []
            if isinstance(payload.get("recipe"), dict):
                recipes.append(payload["recipe"])
            for r in payload.get("recipes", []) or []:
                recipes.append(r)
            recipe_strs = [s for s in (_recipe_line(r) for r in recipes) if s]
            line = f"- Module [{module.get('module_type', 'unknown')}]"
            reason = module.get("reason")
            if reason:
                line += f" (reason: {reason})"
            if recipe_strs:
                line += ": " + "; ".join(recipe_strs)
            lines.append(line)
        return "\n".join(lines)

    @staticmethod
    def taste_summary_section(taste_summary):
        """
        Compact taste-summary section (catalog-first-pivot.md §2 WS-P2) —
        replaces embedding the user's full saved-recipe list as the model's
        recipe universe. `taste_summary` is a dict from
        `ChatbotV2View.build_taste_summary`: own_recipe_count,
        saved_recipe_count, top_tags.
        """
        if not taste_summary:
            return ""
        own_count = taste_summary.get("own_recipe_count", 0)
        saved_count = taste_summary.get("saved_recipe_count", 0)
        top_tags = taste_summary.get("top_tags") or []

        lines = [
            "User's personal collection (secondary signal — NOT the recipe universe):",
            f"- {own_count} recipe(s) they created/own; {saved_count} recipe(s) bookmarked from the catalog.",
        ]
        if top_tags:
            lines.append(f"- Tags that show up often in their cooking: {', '.join(top_tags)}.")
        lines.append(
            "This collection is personalization signal only, not something to search directly. "
            "The full recipe catalog (thousands of recipes) is what `search_recipes` searches."
        )
        return "\n".join(lines)

    @staticmethod
    def chatbot_v2_system(taste_summary=None, user_settings=None, mood=None, home_feed=None):
        """System prompt for chat v2 in 'global' / 'home' context (tool use).

        Librarian-first policy (catalog-first-pivot.md §2 WS-P2): search the
        real catalog before ever generating a new recipe.
        """
        sections = [
            "You are a cookbook AI chatbot that helps users with their cooking and recipe needs.",
            PromptTemplates._user_profile_section(user_settings),
            PromptTemplates.taste_summary_section(taste_summary),
            (
                "You can:\n"
                "- Search the recipe catalog with the `search_recipes` tool and present real matches "
                "using `reference_recipe`.\n"
                "- Create a brand-new recipe with the `create_recipe` tool (fallback only — see policy below).\n"
                "- Answer general cooking/food questions in plain text.\n\n"
                "Retrieval-first policy (follow this order):\n"
                "- For ANY \"what should I cook\", \"find me something\", \"suggest a recipe\" type request, "
                "call `search_recipes` FIRST, before writing any recipe yourself.\n"
                "- If your first search doesn't return good matches, refine the query (different "
                "wording, fewer filters) and search once more before giving up on retrieval.\n"
                "- Present 2-4 of the best results using `reference_recipe`, each with one short line "
                "explaining why it fits what the user asked for (their mood, dietary constraints, or "
                "what they said).\n"
                "- After presenting suggestions, end your reply with ONE short, helpful follow-up "
                "question that moves the user forward — e.g. offering to adjust for time, servings, or "
                "a dietary need, to search a different direction, or asking which one they'd like to "
                "open. Exactly one question, kept to a single sentence.\n"
                "- `create_recipe` is the FALLBACK, not the default: only generate a brand-new recipe "
                "when `search_recipes` has already been tried and didn't surface a good match, OR the "
                "user explicitly asks for something custom/original/an invention (e.g. \"invent a "
                "recipe using only these 3 ingredients\", \"make up something weird\"). When you do "
                "fall back to `create_recipe`, say so in your reply (e.g. \"I didn't find a great "
                "match in the cookbook, so here's a custom one\").\n"
                "- NEVER write recipe JSON in your text; always use the tools for recipes.\n"
                "- Use decimal ingredient quantities (e.g. 0.75, 1.0) and abbreviated units: "
                "tbsp, tsp, cup, oz, lb, g, kg, ml, L, pc, clove, pinch, bunch, can, pkg.\n"
                "- The web search tool is for genuinely current-events or need-fresh-info questions "
                "only (e.g. \"what's a trending ingredient right now\", \"current food safety "
                "guidance\") — it is NOT a recipe-discovery mechanism; use `search_recipes` for "
                "finding recipes.\n"
                "- When answering general questions, you may remind the user you can search the "
                "cookbook or generate recipes."
            ),
            PromptTemplates.mood_section(mood),
            PromptTemplates.home_feed_section(home_feed),
        ]
        return "\n\n".join(s for s in sections if s)

    @staticmethod
    def recipe_edit_v2_system(recipe, user_settings=None, mood=None):
        """System prompt for chat v2 in 'recipe_edit' context (update_recipe tool)."""
        sections = [
            (
                "You are an AI assistant helping a user modify or answer questions about a recipe.\n"
                "You can respond to the user, suggest changes to the recipe, or ask for more details.\n\n"
                "Rules:\n"
                "- When proposing changes to the recipe, use the `update_recipe` tool with ONLY the changed fields in `changes`.\n"
                "- If you change `ingredients` or `tags`, return the full updated list.\n"
                "- Each ingredient must be {\"name\": ..., \"quantity\": <decimal>, \"unit\": ...}; unit can be an empty string.\n"
                "- Use abbreviated units: tbsp, tsp, cup, oz, lb, g, kg, ml, L, pc, clove, pinch, bunch, can, pkg.\n"
                "- Instructions must be a list of strings.\n"
                "- NEVER write recipe JSON in your text; always use the tool."
            ),
            PromptTemplates._user_profile_section(user_settings),
            f"Current recipe:\n{json.dumps(recipe, indent=2)}",
            PromptTemplates.mood_section(mood),
        ]
        return "\n\n".join(s for s in sections if s)

    @staticmethod
    def format_ingredients_with_llm_prompt(raw_ingredient_text: str) -> str:
        prompt = f"""
            You are a recipe assistant that transforms unstructured ingredient lists into a structured JSON list of Ingredient objects.

            Each ingredient must follow this format:
            - name: string
            - quantity: float (e.g. 2.5)
            - unit: string — use standard abbreviations: tbsp, tsp, cup, oz, lb, g, kg, ml, L, pc, clove, pinch, bunch, can, pkg. Can be empty if not applicable (e.g. "2 eggs" → "")
            - usda_name: string (simplified name for USDA nutrition lookup, e.g. "flour" for "all-purpose flour, sifted")

            Important formatting rules:
            1. Units must use standard abbreviations: tbsp, tsp, cup, oz, lb, g, kg, ml, L, pc, clove, pinch, bunch, can, pkg. Do NOT use full words like "tablespoon", "teaspoon", "piece(s)", "clove(s)", etc.
            2. usda_name should be the core food item without qualifiers (sifted, chopped, etc.)
            3. Translate French ingredients in usda_name: "porc" → "pork", "boeuf" → "beef", etc.
            4. Make sure the unit is not contained in the name and in the unit field

            Examples:
            - "2 cups all-purpose flour, sifted" → name: "all-purpose flour, sifted", quantity: 2, unit: "cup(s)", usda_name: "flour"
            - "3 large eggs" → name: "large eggs", quantity: 3, unit: "piece(s)", usda_name: "egg"
            - "1 lb porc haché" → name: "porc haché", quantity: 1, unit: "lb", usda_name: "pork ground"

            Here is the ingredient list:

            \"\"\"{raw_ingredient_text}\"\"\"

            Return **only** a valid JSON list of ingredients.
        """
        return prompt

    @staticmethod
    def ocr_prompt():
        """Generates a prompt for extracting and structuring recipe data from one or more images."""
        return (
            "Extract and structure the complete recipe from the image(s) into a valid JSON object.\n"
            "If multiple images are provided, treat them as pages of the same recipe and combine all information.\n\n"
            "Rules:\n"
            "- ALL ingredient quantities must be decimals (e.g. 1.0, 0.5, 2.0)\n"
            "- Use standard abbreviated units: tbsp, tsp, cup, oz, lb, g, kg, ml, L, pc, clove, pinch, bunch, can, pkg. Use empty string \"\" if no unit applies.\n"
            "- Instructions must be a list of strings, one step per entry\n"
            "- cooking_time and preparation_time must be integers (minutes)\n"
            "- servings must be an integer; if not stated in the recipe, estimate it based on the ingredient quantities\n"
            "- Return ONLY the JSON object — no markdown, no explanation\n\n"
            'Example output:\n'
            '{\n'
            '  "title": "Spaghetti Bolognese",\n'
            '  "ingredients": [\n'
            '    {"name": "spaghetti", "quantity": 200.0, "unit": "g"},\n'
            '    {"name": "ground beef", "quantity": 0.5, "unit": "lb"},\n'
            '    {"name": "eggs", "quantity": 2.0, "unit": ""}\n'
            '  ],\n'
            '  "instructions": ["Boil spaghetti until al dente.", "Brown the beef in a pan."],\n'
            '  "cooking_time": 20,\n'
            '  "preparation_time": 10,\n'
            '  "servings": 2,\n'
            '  "tags": ["italian", "pasta"],\n'
            '  "description": "Classic Italian pasta with meat sauce.",\n'
            '  "notes": ""\n'
            '}'
        )

    @staticmethod
    def url_import_prompt(page_content: str, image_url: str = "") -> str:
        return (
            "You are a recipe extraction assistant. Extract the recipe from the webpage text below "
            "and output it wrapped in $$ ... $$ with valid JSON — no other text.\n\n"
            "JSON schema (all fields required, use null/empty if unknown):\n"
            "{\n"
            '  "title": string,\n'
            '  "image_url": string (URL if provided, empty string if none),\n'
            '  "ingredients": [{"name": string, "quantity": decimal, "unit": string}],\n'
            '  "instructions": [string],\n'
            '  "preparation_time": integer (minutes),\n'
            '  "cooking_time": integer (minutes),\n'
            '  "servings": integer (IMPORTANT: extract from content;\n'
            '  "tags": [string],\n'
            '  "description": string,\n'
            '  "notes": string\n'
            "}\n\n"
            "Rules:\n"
            "- ALL ingredient quantities must be decimals (e.g. 1.0, 0.5)\n"
            "- Use abbreviated units: tbsp, tsp, cup, oz, lb, g, kg, ml, L, pc, clove, pinch, bunch, can, pkg\n"
            "- Instructions must be a list of strings, one step per entry\n"
            "- SERVINGS: Look for 'servings', 'serves', 'makes', 'feeds' in the text. If found, use that number.\n"
            "  If not found, default to 4 (don't use 1 unless explicitly stated).\n"
            "- If no recipe is found in the text, output: $$ null $$\n\n"
            f"Image URL available: {image_url if image_url else '(none found)'}\n"
            f"Use the image_url field to store: {image_url if image_url else '(empty string if not available)'}\n\n"
            f"Webpage content:\n{page_content}"
        )

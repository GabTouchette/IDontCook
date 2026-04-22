import os
import base64
import json
import re
from typing import List, Dict, Any
from django.conf import settings
from recipes.models import Ingredient, Recipe
import anthropic


def encode_image(image_path):
    """Encode an image to Base64."""
    with open(image_path, "rb") as image_file:
        return base64.b64encode(image_file.read()).decode("utf-8")

class AnthropicService:
    def __init__(self):
        """Initialize the Anthropic client with the API key."""
        self.client = anthropic.Anthropic(api_key=getattr(settings, "ANTHROPIC_API_KEY", None))

    def ask_ocr(self, image_path):
        """
        Processes an image for OCR using Anthropic and returns a JSON response.
        """
        try:
            base64_image = encode_image(image_path)
            ocr_prompt = PromptTemplates.ocr_prompt()

            response = self.client.messages.create(
                model="claude-sonnet-4-5",
                max_tokens=2048,
                messages=[{
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": base64_image,
                            },
                        },
                        {"type": "text", "text": ocr_prompt},
                    ],
                }]
            )

            response_content = response.content[0].text
            response_content = re.sub(r"^```json\s*|\s*```$", "", response_content).strip()

            try:
                recipe_json = json.loads(response_content)
                return json.dumps(recipe_json)
            except json.JSONDecodeError:
                return "Error: The response was not valid JSON."

        except anthropic.APIError as e:
            return f"Error communicating with Anthropic: {e}"
        except Exception as e:
            return f"An unexpected error occurred: {e}"

    # Keep backward-compat alias
    def ask_openai_ocr(self, image_path):
        return self.ask_ocr(image_path)

    def ask_stream(self, prompt, chat_history=None, recipe_context=None):
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

            with self.client.messages.stream(
                model="claude-sonnet-4-5",
                max_tokens=2048,
                messages=messages,
            ) as stream:
                for text in stream.text_stream:
                    yield text

        except anthropic.APIError as e:
            yield f"Error communicating with Anthropic: {e}"
        except Exception as e:
            yield f"An unexpected error occurred: {e}"

    # Keep backward-compat alias
    def ask_openai_stream(self, prompt, chat_history=None, recipe_context=None):
        yield from self.ask_stream(prompt, chat_history, recipe_context)


    def llm_format_ingredients(self, recipe) -> Recipe:
        # STEP 1 – Turn list of raw ingredient strings into a single string
        if not recipe.ingredients:
            raise ValueError("Recipe must have ingredients to format.")

        raw_ingredient_text = "\n".join(f"{str(ingredient.quantity)} {str(ingredient.name)}" for ingredient in recipe.ingredients.all())
        response = self.client.messages.create(
                model="claude-haiku-4-5",
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
            "- When answering general questions, you may remind the user you can generate or suggest recipes.\n\n"
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

    @staticmethod
    def format_ingredients_with_llm_prompt(raw_ingredient_text: str) -> str:
        prompt = f"""
            You are a recipe assistant that transforms unstructured ingredient lists into a structured JSON list of Ingredient objects.

            Each ingredient must follow this format:
            - name: string
            - quantity: float (e.g. 2.5)
            - unit: string (e.g. "cup(s)", "tbsp", "g", "ml", "clove(s)", "oz", etc.) ** Can be empty if not applicable (e.g. "2 eggs" → "" **)
            - usda_name: string (simplified name for USDA nutrition lookup, e.g. "flour" for "all-purpose flour, sifted")

            Important formatting rules:
            1. Units should be in format: "cup(s)", "clove(s)", "piece(s)", etc. with (s) suffix
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
        """Generates a prompt for extracting and structuring recipe data from OCR text."""
        return (
            "Extract and structure the text from the recipe image into the recipe format below:\n\n"
            "The format should be a valid JSON object and not a JSON string, just like in this example:\n"
            '{\n'
            '  "title": "Recipe Name",\n'
            '  "ingredients": [{"name": "Ingredient", "quantity": 1}],\n'
            '  "instructions": ["Step 1", "Step 2"],\n'
            '  "cooking_time": 30,\n'
            '  "servings": 2,\n'
            '  "preparation_time": 15,\n'
            '  "tags": ["tag1", "tag2"],\n'
            '  "description": "Brief description",\n'
            '  "notes": "Additional notes"\n'
            '}'
        )
       
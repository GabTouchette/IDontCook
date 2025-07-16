import os
import base64
import json
import re
from openai import OpenAI, OpenAIError


def encode_image(image_path):
    """Encode an image to Base64."""
    with open(image_path, "rb") as image_file:
        return base64.b64encode(image_file.read()).decode("utf-8")

class OpenAIService:
    def __init__(self):
        """Initialize the OpenAI client with the API key."""
        self.client = OpenAI(api_key=os.getenv("OPENAI_KEY"))

    def ask_openai_ocr(self, image_path):
        """
        Processes an image for OCR using OpenAI and returns a JSON response.
        """
        try:
            messages = []
            base64_image = encode_image(image_path)
            ocr_prompt = PromptTemplates.ocr_prompt()

            messages.append({
                "role": "user",
                "content": [
                    {"type": "text", "text": ocr_prompt},
                    {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{base64_image}"}}
                ]
            })
            completion = self.client.chat.completions.create(
                model="gpt-4o-mini",
                messages=messages
            )

            response_content = completion.choices[0].message.content
            response_content = re.sub(r"^```json\s*|\s*```$", "", response_content).strip()

            try:
                recipe_json = json.loads(response_content)
                return json.dumps(recipe_json)
            except json.JSONDecodeError:
                return "Error: The response was not valid JSON."

        except OpenAIError as e:
            return f"Error communicating with OpenAI: {e}"
        except Exception as e:
            return f"An unexpected error occurred: {e}"

    def ask_openai_stream(self, prompt, chat_history=None, recipe_context=None):
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

            print(f"Final Prompt: {final_prompt}")
            messages.append({"role": "user", "content": final_prompt})

            completion = self.client.chat.completions.create(
                model="gpt-4o",
                messages=messages,
                stream=True
            )

            for chunk in completion:
                if chunk.choices and chunk.choices[0].delta.content:
                    yield chunk.choices[0].delta.content

        except OpenAIError as e:
            yield f"Error communicating with OpenAI: {e}"
        except Exception as e:
            yield f"An unexpected error occurred: {e}"



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
            "**Example of a new recipe (inside $$ ... $$):**\n"
            "$$ {\n"
            "  \"title\": \"Spaghetti Bolognese\",\n"
            "  \"ingredients\": [\n"
            "    {\"name\": \"ounce spaghetti\", \"quantity\": 1.0},\n"
            "    {\"name\": \"kg ground beef\", \"quantity\": 0.5},\n"
            "    {\"name\": \"L tomato sauce\", \"quantity\": 1.0}\n"
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
            "- Each ingredient must be: {\"name\": \"ingredient name\", \"quantity\": 1.0} — quantity must be a decimal.\n"
            "- Instructions must be a list of strings.\n\n"
            "**Example of a modified recipe response (only changed fields):**\n"
            "@@ {\n"
            "  \"ingredients\": [\n"
            "    {\"name\": \"g spaghetti\", \"quantity\": 100.0},\n"
            "    {\"name\": \"kg ground turkey\", \"quantity\": 0.5},\n"
            "    {\"name\": \"L tomato sauce\", \"quantity\": 1.0}\n"
            "  ],\n"
            "  \"cooking_time\": 25\n"
            "} @@\n\n"
            f"Current recipe:\n{json.dumps(recipe, indent=2)}\n\n"
            f"User request:\n{query}"
        )



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
       
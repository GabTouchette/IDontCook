import os
import base64
from openai import OpenAI, OpenAIError
from io import BytesIO
import json
import re


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
    def chatbot_prompt(user_recipes, query):
        """Generates a prompt for the AI chatbot."""
        recipe_info = "\n".join([
            f"- {r['title']} (ID: {r['id']}) | Ingredients: {', '.join([i['name'] for i in r['ingredients']])}"
            for r in user_recipes
        ]) if user_recipes else "The user has no saved recipes yet."

        return (
            "You are a cookbook AI chatbot tasked with helping users with their cooking and recipe needs.\n\n"
            f"Here is a list of the user's saved recipes:\n{recipe_info}\n\n"
            "Your task is to assist the user by either:\n"
            "- Suggesting an existing recipe\n"
            "- Creating a new recipe\n"
            "- Answering general food and cooking-related questions\n\n"
            "Rules:\n"
            "- If you provide an existing recipe, use the following format wrapped in && tags:\n"
            "  &&{ \"id\": recipeId, \"title\": \"recipeTitle\" }&&\n"
            "- Do not provide an existing recipe that is not in the list above as this will give an error.\n"
            "- If you create a new recipe, use the following format wrapped in ** tags:\n"
            "  **{\n"
            '    "title": "Recipe Name",\n'
            '    "ingredients": [\n'
            '      {"name": "cups Flour", "quantity": 0.75},\n'
            '      {"name": "tbps Sugar", "quantity": 0.5}\n'
            '      ...\n'
            '    ],\n'
            '    "instructions": ["Step 1", "Step 2"],\n'
            '    "cooking_time": 30,\n'
            '    "preparation_time": 15,\n'
            '    "servings": 2,\n'
            '    "tags": ["vegetarian", "easy"],\n'
            '    "description": "A brief description of the recipe",\n'
            '    "notes": "Any extra notes for the recipe"\n'
            "  }**\n\n"
            "Important: Ensure that the quantity for each ingredient is a decimal (e.g., 0.75, 1.0, 0.25). "
            "Do not use fractions (e.g., 1/2, 3/4) or integers (e.g., 1). Always represent quantities as doubles.\n\n"
            "You are not limited to choosing only one option; you can provide both an existing and a new recipe in the same response.\n"
            "Additionally, when answering general cooking questions, remind the user that you can also assist with finding or creating recipes.\n\n"
            f"Answer the following user query:\n{query}"
        )
    
    @staticmethod
    def recipe_edit_prompt(recipe, query):
        return (
            "You are an AI cooking assistant helping the user modify a recipe.\n\n"
            "The user might ask to:\n"
            "- Change ingredients or quantities\n"
            "- Adjust servings, times, or tags\n"
            "- Update title, description, or notes\n"
            "- Remove steps, add comments, etc.\n\n"
            "Rules:\n"
            "- Return only the fields you changed, not the entire recipe.\n"
            "- Wrap your response in double at-signs like this: @@{ JSON }@@\n"
            "- Format as valid JSON with only the updated fields.\n"
            "- Ingredient quantities must be decimals (e.g. 1.0, 0.5).\n"
            "- Use proper keys like `title`, `ingredients`, `instructions`, etc.\n\n"
            f"Here is the current recipe:\n{json.dumps(recipe, indent=2)}\n\n"
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
       
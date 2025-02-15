import os
import base64
from openai import OpenAI, OpenAIError
from io import BytesIO
from PIL import Image
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

    def ask_openai(self, prompt=None, chat_history=None, image_path=None):
        """
        Send a prompt or an image to OpenAI and return a structured response.
        
        Args:
            prompt (str): The text prompt to send to OpenAI.
            chat_history (list): A list of previous chat messages for context.
            image_path (str): The path to the image file to process.
        
        Returns:
            str: The response content from OpenAI.
        """
        try:
            messages = []

            if chat_history:
                for entry in chat_history:
                    role = "user" if entry["sender"] == "user" else "assistant"
                    messages.append({"role": role, "content": entry["message"]})

            if image_path:
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

                recipe_json = json.loads(response_content)
                return recipe_json

            else:
                chatbot_prompt = PromptTemplates.chatbot_prompt([], prompt)
                messages.append({"role": "user", "content": chatbot_prompt})

                completion = self.client.chat.completions.create(
                    model="gpt-3.5-turbo",
                    messages=messages
                )

                response_content = completion.choices[0].message.content
                return response_content

        except json.JSONDecodeError:
            return "Error: The response was not valid JSON."
        except OpenAIError as e:
            return f"Error communicating with OpenAI: {e}"
        except Exception as e:
            return f"An unexpected error occurred: {e}"

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
            "- If you provide an existing recipe, use the following format wrapped in <userRecipe> tags:\n"
            "  <userRecipe>{ \"id\": <recipeId>, \"title\": \"<recipeTitle>\" }</userRecipe>\n"
            "- Do not provide an existing recipe that is not in the list above as this will give an error.\n"
            "- If you create a new recipe, use the following format wrapped in <recipe> tags:\n"
            "  <recipe>{\n"
            '    "title": "Recipe Name",\n'
            '    "ingredients": [\n'
            '      {"name": "Ingredient Name", "quantity": "1", "unit_of_measure": "unit", "substitutes": []}\n'
            '    ],\n'
            '    "instructions": ["Step 1", "Step 2"],\n'
            '    "cooking_time": 30,\n'
            '    "preparation_time": 15,\n'
            '    "tags": ["vegetarian", "easy"],\n'
            '    "description": "A brief description of the recipe",\n'
            '    "notes": "Any extra notes for the recipe"\n'
            "  }</recipe>\n\n"
            "You are not limited to choosing only one option; you can provide both an existing and a new recipe in the same response.\n"
            "Additionally, when answering general cooking questions, remind the user that you can also assist with finding or creating recipes.\n\n"
            f"Answer the following user query:\n{query}"
        )

    @staticmethod
    def ocr_prompt():
        """Generates a prompt for extracting and structuring recipe data from OCR text."""
        return (
            "Extract and structure the text from the recipe image into the recipe format below:\n\n"
            "The format should be a valid JSON object and not a JSON string, just like in this example:\n"
            '{\n'
            '  "title": "Recipe Name",\n'
            '  "ingredients": [{"name": "Ingredient", "quantity": "Amount", "unit_of_measure": "Unit"}],\n'
            '  "instructions": ["Step 1", "Step 2"],\n'
            '  "cooking_time": 30,\n'
            '  "preparation_time": 15,\n'
            '  "tags": ["tag1", "tag2"],\n'
            '  "description": "Brief description",\n'
            '  "notes": "Additional notes"\n'
            '}'
        )
       
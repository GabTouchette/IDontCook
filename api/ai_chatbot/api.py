import os
from openai import OpenAI, OpenAIError

class OpenAIService:
    def __init__(self):
        self.client = OpenAI(api_key=os.getenv("OPENAI_KEY"))

    def ask_openai(self, prompt, chat_history=None):
        """Send a prompt to OpenAI and return a structured response."""
        try:
            messages = [{"role": "user", "content": prompt}]
            if chat_history:
                for entry in chat_history:
                    role = "user" if entry["sender"] == "user" else "assistant"
                    messages.append({"role": role, "content": entry["message"]})

            completion = self.client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=messages
            )

            response_content = completion.choices[0].message.content
            return response_content.encode("utf-8").decode("utf-8")

        except OpenAIError as e:
            return f"Error communicating with OpenAI: {e}"

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
    def ocr_prompt(extracted_text):
        """Generates a prompt for extracting and structuring recipe data from OCR text."""
        return (
            "Extract and structure the following text into a valid JSON recipe format:\n\n"
            f"{extracted_text}\n\n"
            "Format:\n"
            "{\n"
            '  "title": "Recipe Name",\n'
            '  "ingredients": [{"name": "Ingredient", "quantity": "Amount", "unit_of_measure": "Unit"}],\n'
            '  "instructions": ["Step 1", "Step 2"],\n'
            '  "cooking_time": 30,\n'
            '  "preparation_time": 15,\n'
            '  "tags": ["tag1", "tag2"],\n'
            '  "description": "Brief description",\n'
            '  "notes": "Additional notes"\n'
            "}"
        )

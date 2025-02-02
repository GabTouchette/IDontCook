from openai import OpenAI, OpenAIError

import os
from dotenv import load_dotenv
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .serializers import ChatbotRequestSerializer
from recipes.models import Recipe
from recipes.serializers import RecipeSerializer

load_dotenv()

class ChatbotView(APIView):
    def post(self, request):
        serializer = ChatbotRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        query = serializer.validated_data['query']
        chat_history = serializer.validated_data.get('chat_history', None)
        return self.chat_response(query, chat_history)

    def chat_response(self, query, chat_history=None):
        """Handles general chatbot queries using OpenAI"""
        
        # Fetch user's saved recipes
        saved_recipes = Recipe.objects.all()  # Adjust this to fetch only the user's recipes
        recipes_list = [
            {
                "id": recipe.id,
                "title": recipe.title,
                "ingredients": [
                    {"name": ing.name, "quantity": ing.quantity, "unit_of_measure": ing.unit_of_measure}
                    for ing in recipe.ingredients.all()
                ],
            }
            for recipe in saved_recipes
        ]

        # Format recipes into prompt
        recipe_info = "\n".join([
            f"- {r['title']} (ID: {r['id']}) | Ingredients: {', '.join([i['name'] for i in r['ingredients']])}"
            for r in recipes_list
        ])

        prompt = (
            f"You are a cookbook AI chatbot tasked with helping users with their cooking and recipe needs. "
            f"Here is a list of the user's saved recipes:\n\n"
            f"{recipe_info if recipe_info else 'The user has no saved recipes yet.'}\n\n"
            f"Your task is to either suggest an existing recipe or create a new one based on the query:\n"
            f"- If the query matches an existing recipe, respond with the following format surrounded with <userRecipe> tags:\n"
            f"  <userRecipe>{{ \"id\": <recipeId>, \"title\": \"<recipeTitle>\" }}</userRecipe>\n"
            f"- If a new recipe is needed, create it and respond in the following format surrounded with <recipe> tags:\n"
            f"  <recipe>{{\n"
            f'    "title": "Recipe Name",\n'
            f'    "ingredients": [\n'
            f'      {{"name": "Ingredient Name", "quantity": "1", "unit_of_measure": "unit", "substitutes": []}}\n'
            f'    ],\n'
            f'    "instructions": ["Step 1", "Step 2"],\n'
            f'    "cooking_time": 30,\n'
            f'    "preparation_time": 15,\n'
            f'    "tags": ["vegetarian", "easy"],\n'
            f'    "description": "A brief description of the recipe",\n'
            f'    "notes": "Any extra notes for the recipe"\n'
            f"  }}</recipe>\n\n"
            f"Now, answer the following query:\n\n"
            f"{query}"
        )

        openai_response = self.ask_openai(prompt, chat_history)
        return Response({"response": openai_response}, status=status.HTTP_200_OK)



    def get_recipe(self, query):
        """Retrieves an existing recipe by name"""
        recipe = Recipe.objects.filter(title__icontains=query).first()
        if not recipe:
            return Response({"error": "Recipe not found"}, status=status.HTTP_404_NOT_FOUND)

        serializer = RecipeSerializer(recipe)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def ask_openai(self, prompt, chat_history=None):
        """Sends a prompt to OpenAI's GPT model and returns the cleaned response"""
        try:
            client = OpenAI(api_key=os.getenv('OPENAI_KEY'))
            message = {
                'role': 'user',
                'content': prompt
            }
            if chat_history:
                messages = [message, {
                    'role': 'assistant',
                    'content': chat_history
                }]
            else:
                messages = [message]  
            
            completion = client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=messages
            )
            return completion.choices[0].message.content

        except OpenAIError as e:
            return f"Error communicating with OpenAI: {e}"


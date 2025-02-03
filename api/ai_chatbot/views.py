from openai import OpenAI, OpenAIError

import os
from dotenv import load_dotenv
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .serializers import ChatbotRequestSerializer
from recipes.models import Recipe
from recipes.serializers import RecipeSerializer
from .models import Conversation, ChatHistory
from rest_framework.permissions import IsAuthenticated

load_dotenv()

class ChatbotView(APIView):
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        serializer = ChatbotRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        query = serializer.validated_data['query']
        chat_history = serializer.validated_data.get('chat_history', None)
        return self.chat_response(request.user, query, chat_history)

    def chat_response(self, user, query, chat_history=None):
        """Handles general chatbot queries using OpenAI"""
        
        conversation = Conversation.objects.create(user=user, user_query=query, ai_response="loading")
        saved_recipes = Recipe.objects.all()
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

        recipe_info = "\n".join([
            f"- {r['title']} (ID: {r['id']}) | Ingredients: {', '.join([i['name'] for i in r['ingredients']])}"
            for r in recipes_list
        ])

        prompt = (
            "You are a cookbook AI chatbot tasked with helping users with their cooking and recipe needs.\n\n"
            f"Here is a list of the user's saved recipes:\n{recipe_info if recipe_info else 'The user has no saved recipes yet.'}\n\n"
            "Your task is to assist the user by:\n"
            "- Suggesting an existing recipe\n"
            "- Creating a new recipe\n"
            "- Answering general food and cooking-related questions\n\n"
            "Rules:\n"
            "- If you provide an existing recipe, use the following format wrapped in <userRecipe> tags:\n"
            "  <userRecipe>{ \"id\": <recipeId>, \"title\": \"<recipeTitle>\" }</userRecipe>\n"
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

        print(prompt)
        openai_response = self.ask_openai(prompt, chat_history)

        conversation.ai_response = openai_response
        conversation.save()

        ChatHistory.objects.create(user=user, conversation=conversation, sender="ai", message=openai_response)

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
                    'content': "\n".join(chat_history)
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


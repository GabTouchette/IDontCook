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
        return self.chat_response(query)

    def chat_response(self, query):
        """Handles general chatbot queries using OpenAI"""
        prompt = (
            f"You are a cookbook AI chatbot. Always try to provide a recipe if possible, and include it in your response. "
            f"If the response is related to a recipe, provide it in the following JSON format, wrapped in a <recipe></recipe> tag:\n"
            f"<recipe>{{\n"
            f"  'title': 'Recipe Name',\n"
            f"  'ingredients': [\n"
            f"    {{'name': 'Ingredient Name', 'quantity': 1, 'unit_of_measure': 'unit', 'substitutes': []}},\n"
            f"    ...\n"
            f"  ],\n"
            f"  'instructions': ['Step 1', 'Step 2', ...],\n"
            f"  'cooking_time': 30,\n"
            f"  'preparation_time': 15,\n"
            f"  'tags': ['vegetarian', 'easy'],\n"
            f"  'description': 'A brief description of the recipe',\n"
            f"  'notes': 'Any extra notes for the recipe'\n"
            f"}}</recipe>\n\n"
            f"Please answer the user on the following query: {query}."
        )

        openai_response = self.ask_openai(prompt)
        return Response({"response": openai_response }, status=status.HTTP_200_OK)


    def get_recipe(self, query):
        """Retrieves an existing recipe by name"""
        recipe = Recipe.objects.filter(title__icontains=query).first()
        if not recipe:
            return Response({"error": "Recipe not found"}, status=status.HTTP_404_NOT_FOUND)

        serializer = RecipeSerializer(recipe)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def ask_openai(self, prompt):
        """Sends a prompt to OpenAI's GPT model and returns the cleaned response"""
        try:
            client = OpenAI(api_key=os.getenv('OPENAI_KEY'))
            message = {
                'role': 'user',
                'content': prompt
            }
            completion = client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=[message]
            )
            return completion.choices[0].message.content

        except OpenAIError as e:
            return f"Error communicating with OpenAI: {e}"

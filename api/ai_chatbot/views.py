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
        intent = serializer.validated_data.get('intent', 'general') 

        if intent == "generate_recipe":
            return self.generate_recipe(query)
        elif intent == "get_recipe":
            return self.get_recipe(query)
        else:
            return self.chat_response(query)

    def chat_response(self, query):
        """Handles general chatbot queries using OpenAI"""
        response_text = self.ask_openai(query)
        return Response({"response": response_text}, status=status.HTTP_200_OK)

    def generate_recipe(self, query):
        """Generates a new recipe using OpenAI"""
        prompt = f"Generate a detailed recipe based on this request: {query}"
        recipe_text = self.ask_openai(prompt)
        return Response({"recipe": recipe_text}, status=status.HTTP_200_OK)

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

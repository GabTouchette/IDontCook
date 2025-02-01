import json
import subprocess
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .serializers import ChatbotRequestSerializer
from recipes.models import Recipe
from recipes.serializers import RecipeSerializer

class ChatbotView(APIView):
    def post(self, request):
        serializer = ChatbotRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        query = serializer.validated_data['query']
        intent = serializer.validated_data.get('intent', 'general')  # Optional intent field

        if intent == "generate_recipe":
            return self.generate_recipe(query)
        elif intent == "get_recipe":
            return self.get_recipe(query)
        else:
            return self.chat_response(query)

    def chat_response(self, query):
        """Handles general chatbot queries"""
        response_text = self.ask_ollama(query)
        return Response({"response": response_text}, status=status.HTTP_200_OK)

    def generate_recipe(self, query):
        """Generates a new recipe using AI"""
        prompt = f"Generate a detailed recipe based on this request: {query}"
        recipe_text = self.ask_ollama(prompt)
        return Response({"recipe": recipe_text}, status=status.HTTP_200_OK)

    def get_recipe(self, query):
        """Retrieves an existing recipe by name"""
        recipe = Recipe.objects.filter(title__icontains=query).first()
        if not recipe:
            return Response({"error": "Recipe not found"}, status=status.HTTP_404_NOT_FOUND)
        
        serializer = RecipeSerializer(recipe)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def ask_ollama(self, prompt):
        """Sends a prompt to Ollama and returns the response"""
        try:
            result = subprocess.run(
                ["ollama", "run", "deepseek", prompt],  # Adjust model name if needed
                capture_output=True,
                text=True,
                check=True
            )
            return result.stdout.strip()
        except subprocess.CalledProcessError as e:
            return f"Error communicating with Ollama: {e}"

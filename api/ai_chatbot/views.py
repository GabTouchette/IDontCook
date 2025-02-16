import os
import tempfile

from dotenv import load_dotenv
from rest_framework.views import APIView
from rest_framework import status
from rest_framework.parsers import MultiPartParser
from rest_framework.permissions import IsAuthenticated
from django.http import JsonResponse
from .api import OpenAIService, PromptTemplates
from .models import Conversation, ChatHistory
from recipes.models import Recipe

load_dotenv()

class ChatbotView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        query = request.data.get("query")
        chat_history = request.data.get("chat_history", None)

        if not query:
            return JsonResponse({"error": "Query is required"}, status=status.HTTP_400_BAD_REQUEST)

        return self.chat_response(request.user, query, chat_history)

    def chat_response(self, user, query, chat_history=None):
        """Handles chatbot queries with structured AI responses."""

        conversation = Conversation.objects.create(user=user, user_query=query, ai_response="loading")

        saved_recipes = Recipe.objects.filter(created_by=user)
        recipes_list = [
            {
                "id": recipe.id,
                "title": recipe.title,
                "ingredients": [{"name": ing.name, "quantity": ing.quantity, "unit_of_measure": ing.unit_of_measure} for ing in recipe.ingredients.all()],
            }
            for recipe in saved_recipes
        ]

        prompt = PromptTemplates.chatbot_prompt(recipes_list, query)
        openai_response = OpenAIService().ask_openai(prompt, chat_history)

        conversation.ai_response = openai_response
        conversation.save()

        ChatHistory.objects.create(user=user, conversation=conversation, sender="ai", message=openai_response)

        return JsonResponse(openai_response, status=status.HTTP_200_OK, safe=False)



class RecipeOCRView(APIView):
    parser_classes = [MultiPartParser]

    def post(self, request, *args, **kwargs):
        image = request.FILES.get('image')

        if not image:
            return JsonResponse({"error": "No image provided"}, status=400)

        with tempfile.NamedTemporaryFile(delete=False, suffix=".png") as temp_image:
            for chunk in image.chunks():
                temp_image.write(chunk)
            temp_image_path = temp_image.name

        try:
            openai_service = OpenAIService()
            structured_recipe = openai_service.ask_openai(image_path=temp_image_path)
            if structured_recipe:
                return JsonResponse({"response": structured_recipe}, status=200, safe=False)
            else:
                return JsonResponse({"error": "Failed to generate structured recipe"}, status=500)

        except Exception as e:
            return JsonResponse({"error": f"An error occurred: {str(e)}"}, status=500)

        finally:
            if os.path.exists(temp_image_path):
                os.remove(temp_image_path)
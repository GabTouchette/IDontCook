import pytesseract
from PIL import Image
from rest_framework.views import APIView
from rest_framework import status
from rest_framework.parsers import MultiPartParser
from rest_framework.permissions import IsAuthenticated
from django.http import JsonResponse
from django.core.files.storage import default_storage
from .api import OpenAIService, PromptTemplates
from .models import Conversation, ChatHistory
from recipes.models import Recipe
from recipes.serializers import RecipeSerializer

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

        return JsonResponse({"response": openai_response}, status=status.HTTP_200_OK)

class RecipeOCRView(APIView):
    parser_classes = [MultiPartParser]

    def post(self, request):
        if "image" not in request.FILES:
            return JsonResponse({"error": "No image provided"}, status=status.HTTP_400_BAD_REQUEST)

        image_file = request.FILES["image"]
        image_path = default_storage.save("temp_recipe.jpg", image_file)
        extracted_text = pytesseract.image_to_string(Image.open(image_path))

        prompt = PromptTemplates.ocr_prompt(extracted_text)
        structured_recipe = OpenAIService().ask_openai(prompt)

        return JsonResponse(structured_recipe, status=status.HTTP_200_OK)

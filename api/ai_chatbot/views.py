import os
import tempfile

from dotenv import load_dotenv
from rest_framework.views import APIView
from rest_framework import status
from rest_framework.parsers import MultiPartParser
from rest_framework.permissions import IsAuthenticated
from django.http import JsonResponse, StreamingHttpResponse
from .api import OpenAIService, PromptTemplates
from .models import Conversation, ChatHistory
from recipes.models import Recipe
import json

load_dotenv()

class ChatbotView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        """
        Handles incoming chatbot queries and routes them to OCR or chat response.
        """
        query = request.data.get("query")
        chat_history = request.data.get("chat_history", None)

        if not query:
            return JsonResponse({"error": "Query is required"}, status=status.HTTP_400_BAD_REQUEST)

        return self.process_chat_response(request.user, query, chat_history)

    def process_chat_response(self, user, query, chat_history=None):
        """
        Handles chatbot queries and streams the AI response.
        """
        conversation = Conversation.objects.create(user=user, user_query=query, ai_response="loading")

        saved_recipes = Recipe.objects.filter(created_by=user)
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

        prompt = PromptTemplates.chatbot_prompt(recipes_list, query)

        def event_stream():
            openai_service = OpenAIService()
            full_response = ""
            for chunk in openai_service.ask_openai_stream(prompt, chat_history):
                full_response += chunk
                yield f"data: {json.dumps({'token': chunk})}\n\n"

            conversation.ai_response = full_response
            conversation.save()

            ChatHistory.objects.create(user=user, conversation=conversation, sender="ai", message=conversation.ai_response)

        return StreamingHttpResponse(event_stream(), content_type="text/event-stream")

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
            return self.process_ocr_response(request.user, temp_image_path)

        except Exception as e:
            return JsonResponse({"error": f"An error occurred: {str(e)}"}, status=500)

        finally:
            if os.path.exists(temp_image_path):
                os.remove(temp_image_path)
                
    def process_ocr_response(self, user, image_path):
        """
        Processes an image for OCR and returns a JSON response.
        """
        openai_service = OpenAIService()
        response = openai_service.ask_openai_ocr(image_path)
        return JsonResponse({"response": response}, status=status.HTTP_200_OK)
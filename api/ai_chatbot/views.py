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
        # response = openai_service.ask_openai_ocr(image_path)
        response = {"title": "Mathematical Formulas", "ingredients": [], "instructions": ["Calculate C[ES], using the formula: C[ES] = k[ES] + [ES] + [ES]^2 / k[S]", "Calculate the value of Vmax[ES] as Vmax[ES] = Vi * (k[m] + [S] + k[m]/k[S]^2)", "Calculate Vi using the formula: Vi = Vmax[ES] / (k[m] + [S]^2 + k[m]/k[S]^2)", "Determine V by using the formula: V = Vmax * (k[m]/[S] + 1 + k[m]/k[S])", "Define [I] = 1 \u03bcM", "Calculate points: (x1,y1)=(0,1,62) and (x2,y2)=(0.15,2.028)", "Solve for y as y = 10.16 * e^b", "Calculate b with the equation 1.52 = 10.16 * 0.1 + b"], "cooking_time": 0, "servings": 0, "preparation_time": 0, "tags": ["mathematics", "formulas"], "description": "Collection of mathematical derivations and calculations.", "notes": "All calculations require careful handling of variables."}
        return JsonResponse({"response": response}, status=status.HTTP_200_OK)
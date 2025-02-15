from django.urls import path
from .views import ChatbotView, RecipeOCRView

urlpatterns = [
    path('chat/', ChatbotView.as_view(), name='chatbot'),
    path('ocr/', RecipeOCRView.as_view(), name='ocr'),
]

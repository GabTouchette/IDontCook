from django.urls import path
from .views import ChatbotView, ChatbotV2View, RecipeOCRView, RecipeURLImportView

urlpatterns = [
    path('chat/', ChatbotView.as_view(), name='chatbot'),
    path('chat/v2/', ChatbotV2View.as_view(), name='chatbot_v2'),
    path('ocr/', RecipeOCRView.as_view(), name='ocr'),
    path('import-url/', RecipeURLImportView.as_view(), name='import_url'),
]

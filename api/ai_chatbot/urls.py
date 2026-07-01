from django.urls import path
from .views import ChatbotView, RecipeOCRView, RecipeURLImportView

urlpatterns = [
    path('chat/', ChatbotView.as_view(), name='chatbot'),
    path('ocr/', RecipeOCRView.as_view(), name='ocr'),
    path('import-url/', RecipeURLImportView.as_view(), name='import_url'),
]

from django.urls import path
from .views import RecommendRecipesAPIView

urlpatterns = [
    path('', RecommendRecipesAPIView.as_view(), name='recommend_recipes'),
]
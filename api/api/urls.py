from django.contrib import admin
from django.urls import path, include
from .views import RegisterView, CustomAuthToken

urlpatterns = [
    path("admin/", admin.site.urls),
    
    path('api/login/', CustomAuthToken.as_view(), name='login'),
    path('api/register/', RegisterView.as_view(), name='register'),

    path("api/", include("recipes.urls")),
    path('api/ai/', include('ai_chatbot.urls')),
    path('api/social/', include('social.urls')),
]

from django.contrib import admin
from django.urls import path, include
from rest_framework.authtoken.views import obtain_auth_token
from django.urls import path
from rest_framework.authtoken.views import obtain_auth_token
from .views import RegisterView 

urlpatterns = [
    path("admin/", admin.site.urls),
    
    path('api/login/', obtain_auth_token, name='login'),
    path('api/register/', RegisterView.as_view(), name='register'),

    path("api/", include("recipes.urls")),
    path('api/ai/', include('ai_chatbot.urls')),
    path('api/social/', include('social.urls')),
]

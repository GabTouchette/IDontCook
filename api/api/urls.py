from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/", include("recipes.urls")),
    path('api/ai/', include('ai_chatbot.urls')),
]

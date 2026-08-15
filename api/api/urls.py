from django.contrib import admin
from django.urls import path, include

from .image_proxy import image_proxy

urlpatterns = [
    path("admin/", admin.site.urls),

    path("api/images/proxy/", image_proxy, name="image-proxy"),
    path("api/recipes/", include("recipes.urls")),
    path('api/ai/', include('ai_chatbot.urls')),
    path('api/social/', include('social.urls')),
    path('api/accounts/', include('accounts.urls')),
    path('api/', include('meal_planning.urls')),
    path('api/home/', include('home.urls')),
]

from django.contrib import admin
from django.urls import path, include
from dj_rest_auth.views import LoginView, LogoutView
from dj_rest_auth.registration.views import RegisterView

urlpatterns = [
    path('api/auth/login/', LoginView.as_view(), name='login'),
    path('api/auth/logout/', LogoutView.as_view(), name='logout'),
    path('api/auth/registration/', RegisterView.as_view(), name='registration'),
    path('accounts/', include('allauth.urls')),
    path("admin/", admin.site.urls),
    path("api/", include("recipes.urls")),
    path('api/ai/', include('ai_chatbot.urls')),
]

from django.urls import path, include
from .views import RegisterView, CustomAuthToken, UserSettingsView, GoogleAuthView

urlpatterns = [
    path('login/', CustomAuthToken.as_view(), name='login'),
    path('register/', RegisterView.as_view(), name='register'),
    path('settings/', UserSettingsView.as_view(), name='settings'),
    path('google-auth/', GoogleAuthView.as_view(), name='google-auth'),
]

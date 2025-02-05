from django.urls import path, include
from .views import RegisterView, CustomAuthToken

urlpatterns = [
    path('login/', CustomAuthToken.as_view(), name='login'),
    path('register/', RegisterView.as_view(), name='register'),
]

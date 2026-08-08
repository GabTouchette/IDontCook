from django.urls import path

from .views import HomeFeedView

urlpatterns = [
    path('feed/', HomeFeedView.as_view(), name='home-feed'),
]

from django.urls import path

from .views import DealsListView, HomeFeedView, StoreSearchView

urlpatterns = [
    path('feed/', HomeFeedView.as_view(), name='home-feed'),
    path('stores/', StoreSearchView.as_view(), name='home-stores'),
    path('deals/', DealsListView.as_view(), name='home-deals'),
]

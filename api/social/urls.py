from django.urls import path
from .views import (
    PostListCreateAPIView, PostDetailAPIView, 
    CommentListCreateAPIView,
    LikeCreateAPIView, LikeListAPIView, LikeDeleteAPIView,
    VoteCreateAPIView, VoteDeleteAPIView,
    UserSearchAPIView
)

urlpatterns = [
    # Post URLs
    path('posts/', PostListCreateAPIView.as_view(), name='post-list-create'),
    path('posts/<int:pk>/', PostDetailAPIView.as_view(), name='post-detail'),

    # Comment URLs
    path('posts/<int:post_id>/comments/', CommentListCreateAPIView.as_view(), name='comment-list-create'),

    # Like URLs
    path('posts/<int:post_id>/like/', LikeCreateAPIView.as_view(), name='like-create'),
    path('posts/<int:post_id>/like/delete/', LikeDeleteAPIView.as_view(), name='like-delete'),

    # Vote URLs
    path('posts/<int:post_id>/vote/', VoteCreateAPIView.as_view(), name='vote-create'),
    path('posts/<int:post_id>/vote/delete/', VoteDeleteAPIView.as_view(), name='vote-delete'),

    # User Search URL
    path('users/search/', UserSearchAPIView.as_view(), name='user-search'),
]
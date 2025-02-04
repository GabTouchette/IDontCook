from django.urls import path
from .views import (
    PostListCreateAPIView, PostDetailAPIView, 
    CommentListCreateAPIView, CommentDetailAPIView,
    LikeCreateAPIView, LikeListAPIView, LikeDeleteAPIView,
    VoteCreateAPIView, VoteDeleteAPIView
)

urlpatterns = [
    # Post URLs
    path('posts/', PostListCreateAPIView.as_view(), name='post-list-create'),
    path('posts/<int:pk>/', PostDetailAPIView.as_view(), name='post-detail'),

    # Comment URLs
    path('comments/', CommentListCreateAPIView.as_view(), name='comment-list-create'),
    path('comments/<int:pk>/', CommentDetailAPIView.as_view(), name='comment-detail'),

    # Like URLs
    path('posts/<int:post_id>/like/', LikeCreateAPIView.as_view(), name='like-create'),
    path('posts/<int:post_id>/like/delete/', LikeDeleteAPIView.as_view(), name='like-delete'),

    # Vote URLs
    path('posts/<int:post_id>/vote/', VoteCreateAPIView.as_view(), name='vote-create'),
    path('posts/<int:post_id>/vote/delete/', VoteDeleteAPIView.as_view(), name='vote-delete'),
]

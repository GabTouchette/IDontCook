from django.urls import path
from .views import PostListCreateAPIView, PostDetailAPIView, CommentListCreateAPIView, CommentDetailAPIView, LikeCreateAPIView, LikeListAPIView, VoteCreateAPIView, VoteDetailAPIView

urlpatterns = [
    # Post URLs
    path('posts/', PostListCreateAPIView.as_view(), name='post-list-create'),
    path('posts/<int:pk>/', PostDetailAPIView.as_view(), name='post-detail'),

    # Comment URLs
    path('comments/', CommentListCreateAPIView.as_view(), name='comment-list-create'),
    path('comments/<int:pk>/', CommentDetailAPIView.as_view(), name='comment-detail'),

    # Like URLs
    path('likes/', LikeCreateAPIView.as_view(), name='like-create'),
    path('likes/<int:pk>/', LikeListAPIView.as_view(), name='like-list'),

    # Vote URLs
    path('posts/<int:post_id>/vote/', VoteCreateAPIView.as_view(), name='vote-create'),
    path('posts/<int:post_id>/vote/delete/', VoteDetailAPIView.as_view(), name='vote-delete'),
]

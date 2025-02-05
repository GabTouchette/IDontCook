from django.urls import path
from .views import (
    PostListCreateAPIView, PostDetailAPIView, 
    CommentListCreateAPIView,
    LikeCreateAPIView, LikeListAPIView, LikeDeleteAPIView,
    VoteCreateAPIView, VoteDeleteAPIView,
    UserSearchAPIView,
    UserPostsAPIView, UserRecipesAPIView, IsUserFollowingAPIView,
    CreateFollowAPIView, DeleteFollowAPIView
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

    # User URL
    path('users/search/', UserSearchAPIView.as_view(), name='user-search'),
    path('users/<int:user_id>/posts/', UserPostsAPIView.as_view(), name='user-posts'),
    path('users/<int:user_id>/recipes/', UserRecipesAPIView.as_view(), name='user-recipes'),
    path('users/<int:user_id>/is_following/', IsUserFollowingAPIView.as_view(), name='is-following'),
    path('users/<int:user_id>/follow/', CreateFollowAPIView.as_view(), name='create-follow'),
    path('users/<int:user_id>/follow/delete/', DeleteFollowAPIView.as_view(), name='delete-follow'),

]

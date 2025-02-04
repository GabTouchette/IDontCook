from rest_framework import serializers
from .models import Post, Comment, Like, Vote
from django.contrib.auth.models import User
from recipes.serializers import RecipeSerializer


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email']       


class PostSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    recipe_id = serializers.IntegerField(source='recipe.id', read_only=True)
    recipe_title = serializers.CharField(source='recipe.title', read_only=True)
    recipe_description = serializers.CharField(source='recipe.description', required=False, allow_blank=True)
    recipe_image_url = serializers.CharField(source='recipe.image_url', required=False, allow_blank=True)
    upvote_count = serializers.ReadOnlyField()
    downvote_count = serializers.ReadOnlyField()
    net_vote_count = serializers.ReadOnlyField()

    class Meta:
        model = Post
        fields = [
            'id', 'recipe_id', 'user', 'recipe_title', 'recipe_description', 'recipe_image_url', 
            'content', 'created_at', 'updated_at', 'upvote_count', 'downvote_count', 'net_vote_count'
        ]


class CommentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Comment
        fields = ['id', 'user', 'post', 'content', 'created_at']


class LikeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Like
        fields = ['id', 'user', 'post', 'comment', 'created_at']


class VoteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Vote
        fields = ['id', 'user', 'post', 'is_upvote', 'created_at']

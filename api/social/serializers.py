from rest_framework import serializers
from .models import Post, Comment, Like, Vote
from accounts.models import CustomUser
from recipes.serializers import RecipeSerializer      
from accounts.serializers import UserSerializer
from recipes.models import Recipe

class PostSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    recipe_id = serializers.IntegerField(source='recipe.id', read_only=True, required=False)
    recipe_title = serializers.CharField(source='recipe.title', read_only=True, required=False, allow_blank=True)
    recipe_description = serializers.CharField(source='recipe.description', required=False, allow_blank=True)
    recipe_image_url = serializers.CharField(source='recipe.image_url', required=False, allow_blank=True)
    upvote_count = serializers.ReadOnlyField()
    downvote_count = serializers.ReadOnlyField()
    user_vote = serializers.SerializerMethodField()
    user_liked = serializers.SerializerMethodField()
    comment_count = serializers.SerializerMethodField()
    like_count = serializers.SerializerMethodField()

    class Meta:
        model = Post
        fields = [
            'id', 'user', 'user_vote', 'user_liked',
            'upvote_count', 'downvote_count', 'recipe_id', 'recipe_title',
            'recipe_description', 'recipe_image_url', 'content', 'created_at', 
            'updated_at', 'comment_count', 'like_count'
        ]

    def create(self, validated_data):
        recipe_id = self.context['request'].data.get('recipe_id')
        recipe = None
        if recipe_id:
            recipe = Recipe.objects.get(id=recipe_id)

        validated_data['user'] = self.context['request'].user
        validated_data['recipe'] = recipe

        return super().create(validated_data)
    
    def get_user_vote(self, obj):
        """Returns -1 if the user downvoted, 1 if upvoted, 0 otherwise"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            vote = obj.votes.filter(user=request.user).first()
            return vote.value if vote else 0
        return 0

    def get_user_liked(self, obj):
        """Returns True if the user liked the post, False otherwise"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.likes.filter(user=request.user).exists()
        return False
    
    def get_comment_count(self, obj):
        return obj.comments.count()
    
    def get_like_count(self, obj):
        return obj.likes.count()


class CommentSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    post_id = serializers.IntegerField(source='post.id', read_only=True)

    class Meta:
        model = Comment
        fields = ['id', 'user', 'post_id', 'content', 'created_at']


class LikeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Like
        fields = ['id', 'user', 'post', 'comment', 'created_at']

    def validate(self, data):
        """
        Ensure that at least one of 'post' or 'comment' is provided.
        """
        post = data.get('post')
        comment = data.get('comment')

        if not post and not comment:
            raise serializers.ValidationError("At least one of 'post' or 'comment' must be provided.")

        if post and comment:
            raise serializers.ValidationError("Only one of 'post' or 'comment' can be provided, not both.")

        return data


class VoteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Vote
        fields = ['id', 'user', 'post', 'value', 'created_at']

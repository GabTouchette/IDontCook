from django.contrib import admin
from .models import Post, Comment, Like, Follow, Vote

@admin.register(Post)
class PostAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'recipe', 'created_at', 'updated_at', 'net_vote_count')
    search_fields = ('user__username', 'content')
    list_filter = ('created_at', 'updated_at')
    ordering = ('-created_at',)

@admin.register(Comment)
class CommentAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'post', 'created_at')
    search_fields = ('user__username', 'content')
    list_filter = ('created_at',)
    ordering = ('-created_at',)

@admin.register(Like)
class LikeAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'post', 'comment', 'created_at')
    search_fields = ('user__username',)
    list_filter = ('created_at',)
    ordering = ('-created_at',)

@admin.register(Follow)
class FollowAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'followed_user', 'created_at')
    search_fields = ('user__username', 'followed_user__username')
    list_filter = ('created_at',)
    ordering = ('-created_at',)

@admin.register(Vote)
class VoteAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'post', 'is_upvote', 'created_at')
    search_fields = ('user__username',)
    list_filter = ('created_at', 'is_upvote')
    ordering = ('-created_at',)

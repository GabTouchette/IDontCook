from django.contrib import admin
from .models import Conversation, ChatHistory

@admin.register(Conversation)
class ConversationAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'created_at')
    search_fields = ('user__username', 'user_query', 'ai_response')
    list_filter = ('created_at',)
    ordering = ('-created_at',)

@admin.register(ChatHistory)
class ChatHistoryAdmin(admin.ModelAdmin):
    list_display = ('id', 'conversation', 'user', 'sender', 'created_at')
    search_fields = ('user__username', 'sender', 'message')
    list_filter = ('created_at', 'sender')
    ordering = ('-created_at',)

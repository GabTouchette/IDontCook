from rest_framework import serializers
from .models import ChatHistory, Conversation

class ChatbotRequestSerializer(serializers.Serializer):
    query = serializers.CharField()
    chat_history = serializers.CharField(required=False, allow_blank=True)

class ChatHistorySerializer(serializers.ModelSerializer):
    class Meta:
        model = ChatHistory
        fields = ['sender', 'message', 'created_at']

class ConversationSerializer(serializers.ModelSerializer):
    history = ChatHistorySerializer(many=True, read_only=True)

    class Meta:
        model = Conversation
        fields = ['user_query', 'ai_response', 'created_at', 'history']
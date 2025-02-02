from rest_framework import serializers

class ChatbotRequestSerializer(serializers.Serializer):
    query = serializers.CharField()
    chat_history = serializers.CharField(required=False, allow_blank=True)

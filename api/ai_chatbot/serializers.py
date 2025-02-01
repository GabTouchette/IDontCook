from rest_framework import serializers

class ChatbotRequestSerializer(serializers.Serializer):
    query = serializers.CharField()
    intent = serializers.ChoiceField(
        choices=['general', 'generate_recipe', 'get_recipe'],
        required=False,
        default='general'
    )

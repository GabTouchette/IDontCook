from rest_framework import serializers
from django.contrib.auth.models import User
from social.models import Follow

class UserSerializer(serializers.ModelSerializer):
    follower_count = serializers.SerializerMethodField(allow_null=True, read_only=True)

    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'follower_count']

    def get_follower_count(self, obj):
        return obj.followers.count()

from rest_framework import serializers
from accounts.models import CustomUser
from .models import UserSettings

class UserSerializer(serializers.ModelSerializer):
    follower_count = serializers.SerializerMethodField(allow_null=True, read_only=True)
    avatar_icon = serializers.SerializerMethodField()
    
    class Meta:
        model = CustomUser
        fields = ['id', 'username', 'email', 'avatar_icon', 'follower_count']

    def get_follower_count(self, obj):
        return obj.followers.count()

    def get_avatar_icon(self, obj):
        return obj.avatar_icon if obj.avatar_icon else ""
    

class UserSettingsSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserSettings
        fields = '__all__'
        read_only_fields = ['user']

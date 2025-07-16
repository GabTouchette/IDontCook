import random

from django.http import JsonResponse

from rest_framework import status
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.authtoken.models import Token
from rest_framework.authtoken.views import ObtainAuthToken

from accounts.models import CustomUser
from .models import UserSettings
from .serializers import UserSettingsSerializer

class RegisterView(APIView):
    permission_classes = []

    def post(self, request):
        username = request.data.get('username')
        email = request.data.get('email')
        password = request.data.get('password')

        if not username or not email or not password:
            print("Please provide all fields (username, email, password)")
            return JsonResponse(
                {'error': 'Please provide all fields (username, email, password)'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if CustomUser.objects.filter(username=username).exists():
            print("Username already exists")
            return JsonResponse(
                {'error': 'Username already exists'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        avatar_icon = self.get_random_avatar_icon()

        user = CustomUser.objects.create_user(
            username=username, email=email, password=password, avatar_icon=avatar_icon
        )
        
        token, _ = Token.objects.get_or_create(user=user)

        return JsonResponse({
            'token': token.key,
            'message': 'User created successfully',
            'user': {
                'id': user.id,
                'username': user.username,
                'email': user.email,
                'avatar_icon': user.avatar_icon,
            }
        }, status=status.HTTP_201_CREATED)

    def get_random_avatar_icon(self):
        icons = [
            'burger', 'pizza', 'apple', 'iceCream', 'carrot', 'fish', 
            'lemon', 'coffee', 'cake', 'hotdog'
        ]
        return random.choice(icons)



class CustomAuthToken(ObtainAuthToken):
    permission_classes = []

    def post(self, request, *args, **kwargs):
        response = super().post(request, *args, **kwargs)
        token = Token.objects.get(key=response.data['token'])
        user = token.user
        return JsonResponse({
            'token': token.key,
            'user': {
                'id': user.id,
                'username': user.username,
                'email': user.email,
                'avatar_icon': user.avatar_icon,
            }
        })


class UserSettingsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        settings, _ = UserSettings.objects.get_or_create(user=request.user)
        serializer = UserSettingsSerializer(settings)
        return JsonResponse(serializer.data)

    def patch(self, request):
        settings, _ = UserSettings.objects.get_or_create(user=request.user)
        serializer = UserSettingsSerializer(settings, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return JsonResponse(serializer.data)
        return JsonResponse(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

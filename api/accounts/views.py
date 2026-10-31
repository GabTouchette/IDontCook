import base64
import json
import logging
import random
import string

from django.conf import settings as django_settings
from django.http import JsonResponse

logger = logging.getLogger(__name__)

import requests as http_requests
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests

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
            return JsonResponse(
                {'error': 'Please provide all fields (username, email, password)'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if CustomUser.objects.filter(username=username).exists():
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
        data = dict(serializer.data)
        data['first_name'] = request.user.first_name
        data['last_name'] = request.user.last_name
        return JsonResponse(data)

    def patch(self, request):
        # Optionally update first_name / last_name on the user model itself
        first_name = request.data.pop('first_name', None)
        last_name = request.data.pop('last_name', None)
        if first_name is not None:
            request.user.first_name = first_name
        if last_name is not None:
            request.user.last_name = last_name
        if first_name is not None or last_name is not None:
            request.user.save(update_fields=[
                f for f, v in [('first_name', first_name), ('last_name', last_name)] if v is not None
            ])

        settings, _ = UserSettings.objects.get_or_create(user=request.user)
        serializer = UserSettingsSerializer(settings, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return JsonResponse(serializer.data)
        return JsonResponse(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class GoogleAuthView(APIView):
    permission_classes = []

    def post(self, request):
        # TEMP DIAGNOSTIC: prove whether the request reaches this endpoint at all.
        logger.warning('google-auth endpoint HIT (has_id_token=%s)',
                       bool(request.data.get('id_token')))
        token = request.data.get('id_token')
        # Flutter web (google_sign_in_web / Google Identity Services) can only
        # obtain an OAuth access token from its popup flow — GIS mints id_tokens
        # solely through its own rendered button. Web therefore sends
        # access_token instead, verified against Google's tokeninfo endpoint
        # with the same audience allowlist as the id_token path.
        access_token = request.data.get('access_token')
        if not token and not access_token:
            return JsonResponse(
                {'error': 'id_token or access_token is required'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Accept id_tokens from any configured client id (mobile/web + macOS
        # desktop). Falls back to the single GOOGLE_OAUTH_CLIENT_ID if the list
        # isn't configured.
        client_ids = list(getattr(django_settings, 'GOOGLE_OAUTH_CLIENT_IDS', []) or [])
        single_client_id = getattr(django_settings, 'GOOGLE_OAUTH_CLIENT_ID', '')
        if not client_ids and single_client_id:
            client_ids = [single_client_id]
        if not client_ids:
            return JsonResponse(
                {'error': 'Google OAuth is not configured on this server'},
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )

        try:
            if token:
                # Verify signature/issuer/expiry without a fixed audience, then
                # assert the token's audience is one we allow (google-auth's
                # audience arg only accepts a single value).
                payload = id_token.verify_oauth2_token(
                    token,
                    google_requests.Request(),
                )
                if payload.get('aud') not in client_ids:
                    raise ValueError(
                        f"token aud {payload.get('aud')} is not an allowed client id"
                    )
            else:
                payload = self._verify_access_token(access_token, client_ids)
        except ValueError as exc:
            # TEMP DIAGNOSTIC: log why verification failed and decode the token's
            # own (unverified) claims so we can compare what Google minted against
            # the client_id the server expects. Remove once Google login is fixed.
            if not token:
                logger.warning(
                    'Google auth access_token verify failed: %s | allowed_client_ids=%s',
                    exc, client_ids,
                )
                return JsonResponse(
                    {'error': f'Invalid Google token: {exc}'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            try:
                payload_b64 = token.split('.')[1]
                payload_b64 += '=' * (-len(payload_b64) % 4)  # restore padding
                unverified = json.loads(base64.urlsafe_b64decode(payload_b64))
                logger.warning(
                    'Google auth verify failed: %s | allowed_client_ids=%s | '
                    'token aud=%s iss=%s azp=%s exp=%s email=%s',
                    exc, client_ids,
                    unverified.get('aud'), unverified.get('iss'),
                    unverified.get('azp'), unverified.get('exp'),
                    unverified.get('email'),
                )
            except Exception as decode_err:  # noqa: BLE001 - diagnostic only
                logger.warning(
                    'Google auth verify failed: %s | (claims decode failed: %s)',
                    exc, decode_err,
                )
            return JsonResponse(
                {'error': f'Invalid Google token: {exc}'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        email = payload.get('email')
        if not email:
            return JsonResponse(
                {'error': 'Google token did not contain an email'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user, created = CustomUser.objects.get_or_create(
            email=email,
            defaults={
                'username': self._generate_username(email),
                'avatar_icon': self._get_random_avatar_icon(),
                'first_name': payload.get('given_name', ''),
                'last_name': payload.get('family_name', ''),
            },
        )

        token_obj, _ = Token.objects.get_or_create(user=user)

        return JsonResponse({
            'token': token_obj.key,
            'user': {
                'id': user.id,
                'username': user.username,
                'email': user.email,
                'avatar_icon': user.avatar_icon,
            },
            'created': created,
        }, status=status.HTTP_200_OK)

    def _verify_access_token(self, access_token: str, client_ids: list) -> dict:
        """Verify a Google OAuth access token (Flutter web flow) and return a
        payload shaped like the id_token one (email / given_name / family_name).

        tokeninfo validates the token and exposes its audience so we can apply
        the same client-id allowlist as the id_token path.
        """
        try:
            resp = http_requests.get(
                'https://oauth2.googleapis.com/tokeninfo',
                params={'access_token': access_token},
                timeout=10,
            )
        except http_requests.RequestException as exc:
            raise ValueError(f'could not reach Google tokeninfo: {exc}')
        if resp.status_code != 200:
            raise ValueError('Google rejected the access token')
        info = resp.json()
        if info.get('aud') not in client_ids:
            raise ValueError(
                f"token aud {info.get('aud')} is not an allowed client id"
            )

        payload = {'email': info.get('email')}
        # Best-effort profile fetch for first/last name on first sign-in; the
        # token already carries the `profile` scope requested by the app.
        try:
            prof = http_requests.get(
                'https://www.googleapis.com/oauth2/v3/userinfo',
                headers={'Authorization': f'Bearer {access_token}'},
                timeout=10,
            )
            if prof.status_code == 200:
                prof_data = prof.json()
                payload['given_name'] = prof_data.get('given_name', '')
                payload['family_name'] = prof_data.get('family_name', '')
        except http_requests.RequestException:
            pass
        return payload

    def _generate_username(self, email: str) -> str:
        base = email.split('@')[0][:12].replace('.', '_').replace('+', '_')
        suffix = ''.join(random.choices(string.ascii_lowercase + string.digits, k=4))
        candidate = f'{base}_{suffix}'
        # Ensure uniqueness (retry once on collision — astronomically unlikely)
        if CustomUser.objects.filter(username=candidate).exists():
            suffix = ''.join(random.choices(string.ascii_lowercase + string.digits, k=6))
            candidate = f'{base}_{suffix}'
        return candidate

    def _get_random_avatar_icon(self) -> str:
        icons = [
            'burger', 'pizza', 'apple', 'iceCream', 'carrot', 'fish',
            'lemon', 'coffee', 'cake', 'hotdog',
        ]
        return random.choice(icons)

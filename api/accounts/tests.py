from django.contrib.auth import get_user_model
from django.test import override_settings
from django.urls import reverse
from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.test import APIClient, APITestCase

from accounts.models import UserSettings


@override_settings(SECURE_SSL_REDIRECT=False)
class AccountsApiTests(APITestCase):
	def setUp(self):
		self.client = APIClient()
		self.user_model = get_user_model()

	def test_register_returns_token_and_user_payload(self):
		response = self.client.post(
			reverse('register'),
			{
				'username': 'new-user',
				'email': 'new-user@example.com',
				'password': 'safe-password-123',
			},
			format='json',
		)

		self.assertEqual(response.status_code, status.HTTP_201_CREATED)
		self.assertIn('token', response.json())
		self.assertEqual(response.json()['user']['username'], 'new-user')
		self.assertTrue(self.user_model.objects.filter(username='new-user').exists())

	def test_login_returns_existing_token_and_user_payload(self):
		user = self.user_model.objects.create_user(
			username='cook',
			email='cook@example.com',
			password='safe-password-123',
		)
		token = Token.objects.create(user=user)

		response = self.client.post(
			reverse('login'),
			{'username': 'cook', 'password': 'safe-password-123'},
			format='json',
		)

		self.assertEqual(response.status_code, status.HTTP_200_OK)
		self.assertEqual(response.json()['token'], token.key)
		self.assertEqual(response.json()['user']['email'], 'cook@example.com')

	def test_user_settings_get_and_patch_round_trip(self):
		user = self.user_model.objects.create_user(
			username='settings-user',
			email='settings@example.com',
			password='safe-password-123',
		)
		token = Token.objects.create(user=user)
		self.client.credentials(HTTP_AUTHORIZATION=f'Token {token.key}')

		get_response = self.client.get(reverse('settings'))

		self.assertEqual(get_response.status_code, status.HTTP_200_OK)
		self.assertTrue(UserSettings.objects.filter(user=user).exists())
		self.assertEqual(get_response.json()['is_vegan'], False)

		patch_response = self.client.patch(
			reverse('settings'),
			{'is_vegan': True, 'city': 'Montreal'},
			format='json',
		)

		self.assertEqual(patch_response.status_code, status.HTTP_200_OK)
		self.assertEqual(patch_response.json()['city'], 'Montreal')
		self.assertEqual(patch_response.json()['is_vegan'], True)

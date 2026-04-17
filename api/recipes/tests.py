import shutil
import tempfile
from io import BytesIO
from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import override_settings
from django.urls import reverse
from PIL import Image
from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.test import APIClient, APITestCase

from recipes.models import Recipe, SavedRecipe


@override_settings(SECURE_SSL_REDIRECT=False)
class RecipesApiTests(APITestCase):
	def setUp(self):
		self.client = APIClient()
		self.user_model = get_user_model()
		self.media_root = tempfile.mkdtemp()
		self.override = override_settings(MEDIA_ROOT=self.media_root)
		self.override.enable()

		self.user = self.user_model.objects.create_user(
			username='chef',
			email='chef@example.com',
			password='safe-password-123',
		)
		self.token = Token.objects.create(user=self.user)
		self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.token.key}')

	def tearDown(self):
		self.override.disable()
		shutil.rmtree(self.media_root, ignore_errors=True)

	def test_recipe_create_creates_saved_copy_and_enqueues_tasks(self):
		with patch('recipes.views.format_recipe_ingredients.delay') as format_delay, patch(
			'recipes.views.get_recipe_nutrition_info.delay'
		) as nutrition_delay:
			response = self.client.post(
				reverse('recipe-list'),
				{
					'title': 'Tomato Pasta',
					'ingredients': [
						{'name': 'pasta', 'quantity': 200, 'unit': 'g'},
						{'name': 'tomato sauce', 'quantity': 1, 'unit': 'cup'},
					],
					'instructions': ['Boil pasta', 'Add sauce'],
					'preparation_time': 10,
					'cooking_time': 15,
					'tags': ['pasta'],
					'description': 'Simple pasta',
				},
				format='json',
			)

		self.assertEqual(response.status_code, status.HTTP_201_CREATED)
		recipe = Recipe.objects.get(title='Tomato Pasta')
		self.assertTrue(SavedRecipe.objects.filter(user=self.user, recipe=recipe).exists())
		format_delay.assert_called_once_with(recipe.id)
		nutrition_delay.assert_called_once_with(recipe.id)

	def test_recipe_list_returns_user_saved_recipes(self):
		recipe = Recipe.objects.create(title='Saved Soup', created_by=self.user)
		SavedRecipe.objects.create(user=self.user, recipe=recipe)

		response = self.client.get(reverse('recipe-list'))

		self.assertEqual(response.status_code, status.HTTP_200_OK)
		self.assertEqual(len(response.json()), 1)
		self.assertEqual(response.json()[0]['title'], 'Saved Soup')

	def test_recipe_image_upload_requires_authentication(self):
		recipe = Recipe.objects.create(title='Private Recipe', created_by=self.user)
		self.client.credentials()

		response = self.client.post(reverse('recipe-image', kwargs={'recipe_id': recipe.id}))

		self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

	def test_recipe_image_upload_requires_recipe_owner(self):
		owner = self.user_model.objects.create_user(
			username='other-chef',
			email='other@example.com',
			password='safe-password-123',
		)
		recipe = Recipe.objects.create(title='Other Recipe', created_by=owner)

		response = self.client.post(
			reverse('recipe-image', kwargs={'recipe_id': recipe.id}),
			{'image': self._build_test_image()},
		)

		self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

	def test_recipe_image_upload_succeeds_for_owner(self):
		recipe = Recipe.objects.create(title='My Recipe', created_by=self.user)

		response = self.client.post(
			reverse('recipe-image', kwargs={'recipe_id': recipe.id}),
			{'image': self._build_test_image()},
		)

		self.assertEqual(response.status_code, status.HTTP_200_OK)
		recipe.refresh_from_db()
		self.assertTrue(bool(recipe.image))
		self.assertIn('image_url', response.json())
		self.assertIn('thumbnail_url', response.json())

	def _build_test_image(self):
		buffer = BytesIO()
		image = Image.new('RGB', (16, 16), color='red')
		image.save(buffer, format='JPEG')
		buffer.seek(0)
		return SimpleUploadedFile('recipe.jpg', buffer.read(), content_type='image/jpeg')

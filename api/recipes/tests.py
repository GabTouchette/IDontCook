import shutil
import tempfile
from io import BytesIO
from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase, override_settings
from django.urls import reverse
from PIL import Image
from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.test import APIClient, APIRequestFactory, APITestCase

from recipes.models import Ingredient, Recipe, SavedRecipe
from recipes.serializers import RecipeSerializer


class IngredientPayloadValidationTests(TestCase):
        def setUp(self):
                self.client = APIClient()
                User = get_user_model()
                self.user = User.objects.create_user(
                        username="tester",
                        email="tester@example.com",
                        password="pass1234",
                )
                self.client.force_authenticate(user=self.user)

        def test_rejects_string_ingredients(self):
                payload = {
                        "title": "Test",
                        "ingredients": ["2 cups flour", "1 egg"],
                        "instructions": ["Mix", "Bake"],
                        "preparation_time": 5,
                        "cooking_time": 10,
                        "tags": ["Dinner"],
                }
                res = self.client.post("/api/recipes/", payload, format="json")
                self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
                self.assertIn("ingredients", res.json())

        def test_accepts_object_ingredients(self):
                payload = {
                        "title": "Test",
                        "ingredients": [
                                {"name": "flour", "quantity": 2, "unit": "cup"},
                                {"name": "egg", "quantity": 1, "unit": "piece"},
                        ],
                        "instructions": ["Mix", "Bake"],
                        "preparation_time": 5,
                        "cooking_time": 10,
                        "tags": ["Dinner"],
                }
                res = self.client.post("/api/recipes/", payload, format="json")
                self.assertIn(res.status_code, (status.HTTP_201_CREATED, status.HTTP_200_OK))


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
		# Ingredient formatting is dispatched by the create view; nutrition
		# calculation is dispatched by the serializer via dispatch_nutrition_calculation.
		with patch('recipes.views.format_recipe_ingredients.delay') as format_delay, patch(
			'recipes.tasks.dispatch_nutrition_calculation'
		) as nutrition_dispatch:
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
		nutrition_dispatch.assert_called_once_with(recipe.id)

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


class IngredientOrphanCleanupTests(TestCase):
    """Editing a recipe must not leave orphaned Ingredient rows behind."""

    def setUp(self):
        User = get_user_model()
        self.user = User.objects.create_user(
            username="orphan-chef",
            email="orphan@example.com",
            password="pass1234",
        )
        self.factory = APIRequestFactory()

    @patch("recipes.tasks.dispatch_nutrition_calculation")
    def test_update_deletes_orphaned_ingredient_rows(self, _mock_dispatch):
        recipe = Recipe.objects.create(title="Soup", created_by=self.user, servings=1)
        old = [
            Ingredient.objects.create(name="carrot", quantity=2, unit="piece"),
            Ingredient.objects.create(name="onion", quantity=1, unit="piece"),
        ]
        recipe.ingredients.add(*old)
        self.assertEqual(Ingredient.objects.count(), 2)

        request = self.factory.put("/api/recipes/")
        request.user = self.user
        serializer = RecipeSerializer(instance=recipe, context={"request": request})
        serializer.update(
            recipe,
            {
                "ingredients": [
                    {"name": "potato", "quantity": 3, "unit": "piece"},
                ],
                "instructions": ["Boil"],
            },
        )

        # The two old rows must be gone (not just detached), and only the new
        # ingredient should remain in the table.
        self.assertFalse(
            Ingredient.objects.filter(id__in=[i.id for i in old]).exists()
        )
        self.assertEqual(Ingredient.objects.count(), 1)
        self.assertEqual(recipe.ingredients.count(), 1)
        self.assertEqual(recipe.ingredients.first().name, "potato")


class RecipeClickEventTests(APITestCase):
    """POST /api/recipes/<id>/click/ records an append-only click event."""

    def setUp(self):
        User = get_user_model()
        self.user = User.objects.create_user(username="clicker", password="pw")
        self.client = APIClient()
        self.client.force_authenticate(user=self.user)
        self.recipe = Recipe.objects.create(title="Tacos", created_by=self.user)

    def test_click_creates_event_and_is_append_only(self):
        from recommendations.models import RecipeEvent

        url = reverse("recipe-click", kwargs={"pk": self.recipe.id})

        res = self.client.post(url)
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.json(), {"recorded": True})
        self.assertEqual(
            RecipeEvent.objects.filter(
                user=self.user, recipe=self.recipe, kind=RecipeEvent.KIND_CLICK
            ).count(),
            1,
        )

        # Append-only: a second open records a second row (not a toggle).
        self.client.post(url)
        self.assertEqual(
            RecipeEvent.objects.filter(user=self.user, recipe=self.recipe).count(),
            2,
        )

    def test_click_requires_auth(self):
        self.client.force_authenticate(user=None)
        res = self.client.post(
            reverse("recipe-click", kwargs={"pk": self.recipe.id})
        )
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_click_unknown_recipe_404s(self):
        res = self.client.post(reverse("recipe-click", kwargs={"pk": 999999}))
        self.assertEqual(res.status_code, status.HTTP_404_NOT_FOUND)

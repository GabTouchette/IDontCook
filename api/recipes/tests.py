from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status


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

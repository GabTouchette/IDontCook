from django.db import models
import json

class Ingredient(models.Model):
    name = models.CharField(max_length=255, unique=True, blank=True, null=True)
    substitutes = models.JSONField(default=list, blank=True, null=True)
    quantity = models.FloatField(blank=True, null=True)
    unit_of_measure = models.CharField(max_length=50, blank=True, null=True)

    def __str__(self):
        return f"{self.quantity or ''} {self.unit_of_measure or ''} {self.name}".strip()


class Recipe(models.Model):
    title = models.CharField(max_length=255, blank=True, null=True)
    ingredients = models.ManyToManyField(Ingredient, related_name="recipes", blank=True)
    instructions = models.TextField(blank=True, null=True)
    cooking_time = models.IntegerField(blank=True, null=True)
    preparation_time = models.IntegerField(blank=True, null=True)
    tags = models.JSONField(default=list, blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    image_url = models.URLField(blank=True, null=True)
    notes = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True, blank=True, null=True)

    def __str__(self):
        return self.title

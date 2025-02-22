from django.db import models
from accounts.models import CustomUser
from storages.backends.gcloud import GoogleCloudStorage
from imagekit.models import ProcessedImageField
from imagekit.processors import ResizeToFill

class Ingredient(models.Model):
    name = models.CharField(max_length=255, blank=True, null=True)
    substitutes = models.JSONField(default=list, blank=True, null=True)
    quantity = models.FloatField(blank=True, null=True)
    unit_of_measure = models.CharField(max_length=50, blank=True, null=True)

    def __str__(self):
        return f"{self.quantity or ''} {self.unit_of_measure or ''} {self.name}".strip()


class Recipe(models.Model):
    title = models.CharField(max_length=255, blank=True, null=True)
    ingredients = models.ManyToManyField('Ingredient', related_name="recipes", blank=True)
    instructions = models.JSONField(blank=True, null=True)
    cooking_time = models.IntegerField(blank=True, null=True)
    preparation_time = models.IntegerField(blank=True, null=True)
    servings = models.IntegerField(blank=True, null=True)
    tags = models.JSONField(default=list, blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    image = models.ImageField(upload_to="recipe_images/", storage=GoogleCloudStorage(), blank=True, null=True)
    thumbnail = ProcessedImageField(
        storage=GoogleCloudStorage(),
        upload_to='recipe_images/thumbnails/',
        processors=[ResizeToFill(200, 200)],
        format='JPEG',
        options={'quality': 60},
        null=True,
        blank=True
    )
    notes = models.TextField(blank=True, null=True)
    is_favorite = models.BooleanField(default=False)
    parent = models.ForeignKey("self", null=True, blank=True, on_delete=models.SET_NULL, related_name="clones")
    created_at = models.DateTimeField(auto_now_add=True, blank=True, null=True)
    last_visited_at = models.DateTimeField(blank=True, null=True)
    created_by = models.ForeignKey(CustomUser, on_delete=models.CASCADE, null=True)
    
    def __str__(self):
        return self.title

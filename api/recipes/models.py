from django.db import models
from accounts.models import CustomUser
from rest_framework.pagination import PageNumberPagination
from storages.backends.gcloud import GoogleCloudStorage
from imagekit.models import ProcessedImageField
from imagekit.processors import ResizeToFill

class NutritionData(models.Model):
    name = models.CharField(max_length=255, unique=True)
    normalized_name = models.CharField(max_length=255, db_index=True)
    calories_per_100g = models.FloatField()
    protein_per_100g = models.FloatField(default=0)
    fat_per_100g = models.FloatField(default=0)
    carbs_per_100g = models.FloatField(default=0)
    fiber_per_100g = models.FloatField(default=0)
    sugar_per_100g = models.FloatField(default=0)
    usda_fdc_id = models.CharField(max_length=50, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return self.name

class Ingredient(models.Model):
    name = models.CharField(max_length=255, blank=True, null=True)
    substitutes = models.JSONField(default=list, blank=True, null=True)
    quantity = models.FloatField(blank=True, null=True)  # Keep for backward compatibility
    unit = models.CharField(max_length=50, blank=True, null=True)  # Keep for backward compatibility
    quantity_unit = models.CharField(max_length=100, blank=True, null=True)  # New combined field
    preparation = models.CharField(max_length=255, blank=True, null=True)  # New preparation field
    original_text = models.CharField(max_length=500, blank=True, null=True)  # Full ingredient string
    usda_name = models.CharField(max_length=255, blank=True, null=True)  # Simplified name for USDA lookup
    nutrition_data = models.ForeignKey(NutritionData, on_delete=models.SET_NULL, null=True, blank=True)

    def __str__(self):
        parts = []

        # Use new quantity_unit field if available, otherwise fall back to old format
        if self.quantity_unit:
            parts.append(self.quantity_unit)
        else:
            if self.quantity is not None:
                parts.append(str(self.quantity))
            if self.unit:
                parts.append(self.unit)

        if self.name:
            parts.append(self.name)

        if self.preparation:
            parts.append(f", {self.preparation}")

        return " ".join(parts)


class Recipe(models.Model):
    # Basic Info
    title = models.CharField(max_length=255, blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    notes = models.TextField(blank=True, null=True)
    tags = models.JSONField(default=list, blank=True, null=True)
    created_by = models.ForeignKey(CustomUser, on_delete=models.CASCADE, null=True)
    created_at = models.DateTimeField(auto_now_add=True, blank=True, null=True)
    last_visited_at = models.DateTimeField(blank=True, null=True)
    parent = models.ForeignKey("self", null=True, blank=True, on_delete=models.SET_NULL, related_name="clones")
    is_favorite = models.BooleanField(default=False)
    is_formatted = models.BooleanField(default=False)
    is_nutrition_calculated = models.BooleanField(default=False)

    # Ingredients & Instructions
    ingredients = models.ManyToManyField('Ingredient', related_name="recipes", blank=True)
    instructions = models.JSONField(blank=True, null=True)
    recipe_yield = models.CharField(max_length=255, blank=True, null=True)
    servings = models.IntegerField(blank=True, null=True)

    # Timing
    preparation_time = models.IntegerField(blank=True, null=True)
    cooking_time = models.IntegerField(blank=True, null=True)

    # Images
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
    web_image_url = models.URLField(blank=True, null=True)

    # Nutrition Info (calculated from ingredients)
    calories = models.FloatField(blank=True, null=True)
    protein = models.FloatField(null=True, blank=True)
    fat = models.FloatField(null=True, blank=True)
    carbs = models.FloatField(null=True, blank=True)
    
    def __str__(self):
        return self.title

class SavedRecipe(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name="saved_recipes")
    recipe = models.ForeignKey(Recipe, on_delete=models.CASCADE, related_name="saved_by")
    saved_at = models.DateTimeField(auto_now_add=True)
    original_recipe = models.ForeignKey(Recipe, null=True, blank=True, on_delete=models.SET_NULL, related_name="saves")

    class Meta:
        unique_together = ("user", "recipe")

    def __str__(self):
        return f"{self.user.username} saved {self.recipe.title}"

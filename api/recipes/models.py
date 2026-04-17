from django.db import models
from accounts.models import CustomUser
from rest_framework.pagination import PageNumberPagination
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
    quantity = models.FloatField(blank=True, null=True)
    unit = models.CharField(max_length=50, blank=True, null=True)
    nutrition_data = models.ForeignKey(NutritionData, on_delete=models.SET_NULL, null=True, blank=True)

    def get_nutrition_per_quantity(self):
        """Get nutrition data for this ingredient's quantity."""
        if not self.nutrition_data or not self.name:
            return None
            
        from .nutrition_service import NutritionService
        service = NutritionService()
        return service.get_nutrition_for_ingredient(
            self.name, 
            self.quantity or 100, 
            self.unit or 'g'
        )

    def __str__(self):
        parts = []

        if self.quantity is not None:
            parts.append(str(self.quantity))

        if self.unit:
            parts.append(self.unit)

        if self.name:
            parts.append(self.name)

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

    # Ingredients & Instructions
    ingredients = models.ManyToManyField('Ingredient', related_name="recipes", blank=True)
    instructions = models.JSONField(blank=True, null=True)
    recipe_yield = models.CharField(max_length=255, blank=True, null=True)
    servings = models.IntegerField(blank=True, null=True)

    # Timing
    preparation_time = models.IntegerField(blank=True, null=True)
    cooking_time = models.IntegerField(blank=True, null=True)

    # Images
    image = models.ImageField(upload_to="recipe_images/", blank=True, null=True)
    thumbnail = ProcessedImageField(
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
    
    def calculate_nutrition(self):
        """Calculate and update nutrition fields from ingredients."""
        from .nutrition_service import NutritionService
        service = NutritionService()
        nutrition = service.calculate_recipe_nutrition(self)
        
        self.calories = nutrition.get('calories')
        self.protein = nutrition.get('protein')
        self.fat = nutrition.get('fat')
        self.carbs = nutrition.get('carbs')
        self.save()
        
        return nutrition
    
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

from django.db import models
from django.core.exceptions import ValidationError
from accounts.models import CustomUser
from rest_framework.pagination import PageNumberPagination
from storages.backends.gcloud import GoogleCloudStorage
from imagekit.models import ProcessedImageField
from imagekit.processors import ResizeToFill
import os
import joblib

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

class CanonicalIngredient(models.Model):
    """Catalog entry for a canonical ingredient concept (multilingual)."""
    canonical_name_en = models.CharField(max_length=255, db_index=True)
    canonical_name_fr = models.CharField(max_length=255, blank=True, null=True)
    # category now stores a 2-letter code (e.g., PR, MS, DE, ... HO)
    category = models.CharField(max_length=2, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [
            models.Index(fields=["canonical_name_en"]),
        ]

    def __str__(self):
        return self.canonical_name_en or (self.canonical_name_fr or "Ingredient")

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
    # New fields for catalog architecture
    language = models.CharField(max_length=8, blank=True, null=True)  # e.g., 'en', 'fr'
    normalized_name = models.CharField(max_length=255, blank=True, null=True, db_index=True)
    category = models.CharField(max_length=100, blank=True, null=True)
    match_confidence = models.FloatField(blank=True, null=True)
    canonical = models.ForeignKey(CanonicalIngredient, on_delete=models.SET_NULL, null=True, blank=True, related_name="ingredients")

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
    web_image_url = models.URLField(max_length=500, blank=True, null=True)

    # Nutrition Info (calculated from ingredients)
    calories = models.FloatField(blank=True, null=True)
    protein = models.FloatField(null=True, blank=True)
    fat = models.FloatField(null=True, blank=True)
    carbs = models.FloatField(null=True, blank=True)

    # Required meal type tags
    REQUIRED_MEAL_TYPES = ['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Dessert']
    
    def clean(self):
        """Validate that recipe has exactly one meal type tag (except for drinks/cocktails)"""
        if self.tags:
            meal_type_tags = [tag for tag in self.tags if tag in self.REQUIRED_MEAL_TYPES]
            # Check if this is a drink/cocktail - if so, allow no meal type tags
            if self._is_drink_or_cocktail():
                if len(meal_type_tags) > 1:
                    raise ValidationError("Drink/cocktail recipes can have at most one meal type tag")
                # Allow 0 or 1 meal type tags for drinks/cocktails
            else:
                # Regular recipes must have exactly one meal type tag
                if len(meal_type_tags) == 0:
                    raise ValidationError("Recipe must have exactly one meal type tag: Breakfast, Lunch, Dinner, Snack, or Dessert")
                elif len(meal_type_tags) > 1:
                    raise ValidationError("Recipe can only have one meal type tag")

    def _is_drink_or_cocktail(self):
        """Check if this recipe is a drink or cocktail"""
        # Check title for drink keywords
        drink_keywords = [
            'cocktail', 'drink', 'drinks', 'beverage', 'bloody mary', 'margarita',
            'martini', 'mojito', 'whiskey', 'vodka', 'rum', 'gin', 'tequila',
            'wine', 'beer', 'sangria', 'punch', 'juice', 'smoothie', 'shake',
            'lemonade', 'iced tea', 'coffee drink', 'hot chocolate', 'eggnog'
        ]
        
        if self.title:
            title_lower = self.title.lower()
            for keyword in drink_keywords:
                if keyword in title_lower:
                    return True
        
        # Check existing tags for drink indicators
        if self.tags:
            for tag in self.tags:
                tag_lower = str(tag).lower()
                if any(drink_keyword in tag_lower for drink_keyword in ['drink', 'cocktail', 'beverage']):
                    return True
        
        # Check ingredients for alcohol indicators (only if recipe has been saved)
        if self.pk:
            try:
                if self.ingredients.exists():
                    ingredients_text = ' '.join([ing.name.lower() for ing in self.ingredients.all()])
                    alcohol_keywords = ['vodka', 'whiskey', 'rum', 'gin', 'tequila', 'wine', 'beer', 'liquor', 'alcohol']
                    for keyword in alcohol_keywords:
                        if keyword in ingredients_text:
                            return True
            except (ValueError, AttributeError):
                # Skip ingredient check if relationship not available
                pass
        
        return False
    
    def calculate_nutrition(self):
        """Placeholder for nutrition calculation - preserves existing nutrition data"""
        # This method is called by the serializer but currently does nothing
        # to preserve existing nutrition data and serving sizes
        pass
    
    def save(self, *args, **kwargs):
        """Auto-assign meal type if missing before save (except for drinks/cocktails)"""
        if self.tags:
            meal_type_tags = [tag for tag in self.tags if tag in self.REQUIRED_MEAL_TYPES]
            if len(meal_type_tags) == 0 and not self._is_drink_or_cocktail():
                # Auto-predict meal type using ML model (only for non-drinks)
                predicted_meal_type = self._predict_meal_type()
                if predicted_meal_type:
                    self.tags.append(predicted_meal_type)
                else:
                    # Fallback to Dinner if prediction fails
                    self.tags.append('Dinner')
        elif not self._is_drink_or_cocktail():
            # No tags at all, start with Dinner (only for non-drinks)
            self.tags = ['Dinner']
        
        # Call clean to validate
        self.full_clean()
        super().save(*args, **kwargs)
    
    def _predict_meal_type(self):
        """Predict meal type using the trained ML model"""
        try:
            # Load the model
            model_path = os.path.join(os.path.dirname(__file__), 'models', 'meal_type_tfidf_logreg.joblib')
            model = joblib.load(model_path)
            
            # Build text features
            text_parts = []
            if self.title:
                text_parts.append(str(self.title))
            if self.description:
                text_parts.append(str(self.description))
            if self.instructions:
                if isinstance(self.instructions, list):
                    text_parts.extend([str(inst) for inst in self.instructions])
                else:
                    text_parts.append(str(self.instructions))
            
            # Add ingredient names
            try:
                ingredient_names = [ing.name for ing in self.ingredients.all() if ing.name]
                text_parts.extend(ingredient_names)
            except:
                pass  # Ignore if ingredients not available yet
            
            if text_parts:
                text = ' '.join(text_parts)
                prediction = model.predict([text])[0]
                return prediction.title()  # Ensure proper capitalization
        except Exception as e:
            print(f"Meal type prediction failed: {e}")
        
        return None
    
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

from django.db import models
from accounts.models import CustomUser
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
    """Catalog entry for a canonical ingredient concept (multilingual).

    This is the single resolution hub: free-text ingredient lines resolve to one
    of these rows (see ``recipes.ingredient_resolver``), and nutrition + grocery
    merging key off the row rather than off raw strings. ``usda_fdc_id`` pins the
    concept to one stable USDA FoodData Central entry so nutrition no longer
    depends on a per-name search returning the right first hit, and ``portions``
    carries that entry's real gram-weights per household unit (USDA foodPortions)
    instead of the global density guesses in ``nutrition_service``.
    """
    canonical_name_en = models.CharField(max_length=255, db_index=True)
    canonical_name_fr = models.CharField(max_length=255, blank=True, null=True)
    # category now stores a 2-letter code (e.g., PR, MS, DE, ... HO)
    category = models.CharField(max_length=2, blank=True, null=True)
    # Alias/synonym surface forms used for resolution (EN + FR). Lowercased.
    aliases_en = models.JSONField(default=list, blank=True)
    aliases_fr = models.JSONField(default=list, blank=True)
    # Stable nutrition linkage. usda_fdc_id anchors one FoodData Central entry;
    # off_gtin optionally anchors a branded Open Food Facts product (barcode).
    usda_fdc_id = models.CharField(max_length=50, blank=True, null=True, db_index=True)
    off_gtin = models.CharField(max_length=32, blank=True, null=True)
    # Path B — per-ingredient portions. density_g_per_ml converts volumetric units
    # for this specific food; portions maps a household unit label -> grams
    # (e.g. {"cup": 136.0, "medium": 118.0, "clove": 3.0}), sourced from USDA
    # foodPortions by backfill_canonical_portions.
    density_g_per_ml = models.FloatField(blank=True, null=True)
    portions = models.JSONField(default=dict, blank=True)
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
    # quantity/unit are the parsed numeric amount; quantity_unit/original_text
    # preserve the raw amount string for lines that never got a numeric quantity
    # ("pinch of", "salt to taste"); preparation is the trailing note ("minced").
    quantity = models.FloatField(blank=True, null=True)
    unit = models.CharField(max_length=50, blank=True, null=True)
    quantity_unit = models.CharField(max_length=100, blank=True, null=True)
    preparation = models.CharField(max_length=255, blank=True, null=True)
    original_text = models.CharField(max_length=500, blank=True, null=True)
    nutrition_data = models.ForeignKey(NutritionData, on_delete=models.SET_NULL, null=True, blank=True)
    # Resolution hub: the canonical concept this line maps to, plus how the link
    # was made (exact/alias/fuzzy/llm — see recipes.ingredient_resolver) and how
    # much to trust it (0..1). This FK replaced the old usda_name / normalized_name
    # free-text fields — the catalog is now the single matching anchor for
    # nutrition and grocery merging.
    canonical = models.ForeignKey(CanonicalIngredient, on_delete=models.SET_NULL, null=True, blank=True, related_name="ingredients")
    canonical_confidence = models.FloatField(blank=True, null=True)
    resolution_method = models.CharField(max_length=16, blank=True, null=True)

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

    # Catalog-first pivot (docs/plans/catalog-first-pivot.md §1.4): distinguishes
    # curated catalog content from AI-generated / private / imported recipes so
    # discovery surfaces (recommender, search_catalog, explore filters) can
    # exclude what shouldn't be suggested to other users as if it were catalog
    # content. Existing rows are backfilled by a data migration; new creation
    # call sites should set this explicitly going forward.
    SOURCE_CATALOG = "catalog"
    SOURCE_USER = "user"
    SOURCE_AI = "ai"
    SOURCE_IMPORT = "import"
    SOURCE_OCR = "ocr"
    SOURCE_CHOICES = [
        (SOURCE_CATALOG, "Catalog"),
        (SOURCE_USER, "User"),
        (SOURCE_AI, "AI-generated"),
        (SOURCE_IMPORT, "URL import"),
        (SOURCE_OCR, "OCR import"),
    ]
    source = models.CharField(max_length=16, choices=SOURCE_CHOICES, default=SOURCE_USER, db_index=True)

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
    web_image_url = models.URLField(max_length=500, blank=True, null=True)

    # Nutrition Info (calculated from ingredients)
    calories = models.FloatField(blank=True, null=True)
    protein = models.FloatField(null=True, blank=True)
    fat = models.FloatField(null=True, blank=True)
    carbs = models.FloatField(null=True, blank=True)

    class Meta:
        # Discovery/filter surfaces (explore, home rails, "new" rails) order and
        # filter on these columns; without indexes they force sequential scans as
        # the catalog grows. `source` already has db_index=True on the field. The
        # `tags` JSONField needs a Postgres GIN index for `tags__contains` — added
        # separately (Postgres-only) since GIN isn't supported on sqlite dev DBs.
        indexes = [
            models.Index(fields=["-created_at"], name="recipe_created_at_idx"),
            models.Index(fields=["-last_visited_at"], name="recipe_last_visited_idx"),
            models.Index(fields=["is_favorite"], name="recipe_is_favorite_idx"),
            models.Index(fields=["source", "-created_at"], name="recipe_source_created_idx"),
        ]

    # Required meal type tags
    REQUIRED_MEAL_TYPES = ['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Dessert']

    def clean(self):
        """Validate and auto-correct meal type tags (keep only one)"""
        if self.tags:
            meal_type_tags = [tag for tag in self.tags if tag in self.REQUIRED_MEAL_TYPES]
            non_meal_type_tags = [tag for tag in self.tags if tag not in self.REQUIRED_MEAL_TYPES]

            if self._is_drink_or_cocktail():
                # For drinks: keep at most one meal type tag
                if len(meal_type_tags) > 1:
                    self.tags = [meal_type_tags[0]] + non_meal_type_tags
            else:
                # For regular recipes: ensure exactly one meal type tag
                if len(meal_type_tags) == 0:
                    # No meal type tags, add Dinner
                    self.tags.append('Dinner')
                elif len(meal_type_tags) > 1:
                    # Multiple meal type tags, keep only the first
                    self.tags = [meal_type_tags[0]] + non_meal_type_tags

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
        """Calculate nutrition from ingredients"""
        from .nutrition_service import NutritionService
        from .ingredient_resolver import resolve
        service = NutritionService()

        print(f"🥦 [CALC] Nutrition for: {self.title} (ID: {self.id})")

        total_calories = 0.0
        total_protein = 0.0
        total_fat = 0.0
        total_carbs = 0.0
        ingredients_found = 0
        ingredients_missed = 0

        for ingredient in self.ingredients.all():
            qty = ingredient.quantity
            if not qty:
                continue

            # Resolve to a canonical concept once (the catalog is the hub). Only
            # resolve when not already linked, and persist the link + confidence
            # so repeat calls and grocery merging reuse it.
            if ingredient.canonical_id is None:
                res = resolve(ingredient.name)
                if res.matched:
                    ingredient.canonical_id = res.canonical_id
                    ingredient.canonical_confidence = res.confidence
                    ingredient.resolution_method = res.method
                    ingredient.save(update_fields=[
                        'canonical', 'canonical_confidence', 'resolution_method'
                    ])

            data = None
            nutrition_obj = None

            # Preferred path: nutrition pinned to the canonical entry's USDA id.
            if ingredient.canonical and ingredient.canonical.usda_fdc_id:
                data, nutrition_obj = service.get_nutrition_for_canonical(
                    ingredient.canonical, qty, ingredient.unit
                )

            # Fallback: legacy per-name search (unlinked / not-yet-pinned foods).
            if data is None:
                # Prefer the canonical concept name; otherwise the raw name.
                search_name = ingredient.name
                if ingredient.canonical:
                    search_name = ingredient.canonical.canonical_name_en

                data, nutrition_obj = service._lookup_ingredient(
                    ingredient_name=search_name,
                    quantity=qty,
                    unit=ingredient.unit,
                )

            # Cache the FK so future calls skip USDA entirely
            if nutrition_obj and ingredient.nutrition_data_id != nutrition_obj.pk:
                ingredient.nutrition_data = nutrition_obj
                ingredient.save(update_fields=['nutrition_data'])

            if data:
                cal = data.get('calories', 0)
                total_calories += cal
                total_protein += data.get('protein', 0)
                total_fat += data.get('fat', 0)
                total_carbs += data.get('carbs', 0)
                ingredients_found += 1
                print(f"   + {ingredient.name} ({qty} {ingredient.unit}): {cal:.1f} cal")
            else:
                ingredients_missed += 1
                print(f"   ? {ingredient.name}: No data found")

        # Per serving calculation
        serv_count = self.servings
        if not serv_count or serv_count < 1:
            serv_count = 1

        cal_per_serving = total_calories / serv_count

        # --- Anomaly detection: trigger LLM fallback when USDA results look wrong ---
        usda_coverage = ingredients_found / max(ingredients_found + ingredients_missed, 1)
        anomaly = (
            total_calories == 0 and ingredients_found < 2
            or cal_per_serving > 3000
            or (ingredients_found > 0 and cal_per_serving < 10)
        )
        if anomaly:
            print(f"⚠️  Anomaly detected (cal/serving={cal_per_serving:.0f}, coverage={usda_coverage:.0%}), trying LLM fallback…")
            llm_totals = service.estimate_nutrition_with_llm(self)
            if llm_totals:
                total_calories = llm_totals['calories']
                total_protein = llm_totals['protein']
                total_fat = llm_totals['fat']
                total_carbs = llm_totals['carbs']
                print(f"✅ LLM fallback returned: {total_calories:.0f} cal total")

        self.calories = round(total_calories / serv_count, 1)
        self.protein = round(total_protein / serv_count, 1)
        self.fat = round(total_fat / serv_count, 1)
        self.carbs = round(total_carbs / serv_count, 1)
        self.is_nutrition_calculated = True
        self.save()  # Persist to DB

        print(f"✅ SAVED: {self.calories} cal/serving (Servings: {serv_count}) | Found: {ingredients_found}, Missed: {ingredients_missed}")
    
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

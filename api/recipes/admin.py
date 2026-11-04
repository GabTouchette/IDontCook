from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse
from django.utils.safestring import mark_safe
from .models import Recipe, Ingredient, SavedRecipe, NutritionData, CanonicalIngredient


@admin.register(NutritionData)
class NutritionDataAdmin(admin.ModelAdmin):
    list_display = (
        'name', 'get_nutrition_bar', 'calories_per_100g', 'protein_per_100g', 
        'fat_per_100g', 'carbs_per_100g', 'usda_fdc_id', 'created_at'
    )
    search_fields = ('name', 'normalized_name', 'usda_fdc_id')
    list_filter = ('created_at',)
    ordering = ('name',)
    readonly_fields = ('created_at',)
    list_per_page = 50
    actions = ['duplicate_nutrition_data']
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('name', 'normalized_name', 'usda_fdc_id')
        }),
        ('Nutrition per 100g', {
            'fields': (
                'calories_per_100g', 'protein_per_100g', 'fat_per_100g', 
                'carbs_per_100g', 'fiber_per_100g', 'sugar_per_100g'
            )
        }),
        ('Metadata', {
            'fields': ('created_at',)
        }),
    )

    def get_nutrition_bar(self, obj):
        """Display a visual nutrition breakdown."""
        total = obj.protein_per_100g + obj.fat_per_100g + obj.carbs_per_100g
        if total == 0:
            return '—'
        
        protein_pct = (obj.protein_per_100g / total) * 100
        fat_pct = (obj.fat_per_100g / total) * 100
        carbs_pct = (obj.carbs_per_100g / total) * 100
        
        return format_html(
            '<div style="width: 100px; height: 20px; border: 1px solid #ccc; display: flex;">'
            '<div style="background: #4CAF50; width: {:.0f}%; height: 100%;" title="Protein: {:.1f}g"></div>'
            '<div style="background: #FF9800; width: {:.0f}%; height: 100%;" title="Fat: {:.1f}g"></div>'
            '<div style="background: #2196F3; width: {:.0f}%; height: 100%;" title="Carbs: {:.1f}g"></div>'
            '</div>',
            protein_pct, obj.protein_per_100g,
            fat_pct, obj.fat_per_100g, 
            carbs_pct, obj.carbs_per_100g
        )
    get_nutrition_bar.short_description = 'Macro Breakdown'

    def duplicate_nutrition_data(self, request, queryset):
        """Duplicate selected nutrition data entries."""
        duplicated_count = 0
        for nutrition in queryset:
            nutrition.pk = None
            nutrition.name = f"Copy of {nutrition.name}"
            nutrition.normalized_name = nutrition.name.lower().strip()
            nutrition.save()
            duplicated_count += 1
        
        self.message_user(request, f"Successfully duplicated {duplicated_count} nutrition data entries.")
    duplicate_nutrition_data.short_description = "Duplicate selected nutrition data"

    def get_readonly_fields(self, request, obj=None):
        if obj:  # Editing existing object
            return self.readonly_fields + ('normalized_name',)
        return self.readonly_fields

class IngredientInline(admin.TabularInline):
    model = Recipe.ingredients.through
    extra = 1
    autocomplete_fields = ('ingredient',)
    verbose_name = "Recipe Ingredient"
    verbose_name_plural = "Recipe Ingredients"

@admin.register(Ingredient)
class IngredientAdmin(admin.ModelAdmin):
    list_display = (
        'name', 'quantity', 'unit', 'get_canonical_link', 'get_nutrition_link', 'get_recipes_count', 'get_substitutes'
    )
    search_fields = ('name',)
    list_filter = ('unit', 'nutrition_data', 'canonical', 'resolution_method')
    ordering = ('name',)
    autocomplete_fields = ('nutrition_data',)
    actions = ['link_to_nutrition_data']

    def get_substitutes(self, obj):
        return ', '.join(obj.substitutes) if obj.substitutes else 'None'
    get_substitutes.short_description = 'Substitutes'
    
    def get_nutrition_link(self, obj):
        if obj.nutrition_data:
            url = reverse('admin:recipes_nutritiondata_change', args=[obj.nutrition_data.id])
            return format_html('<a href="{}">{}</a>', url, obj.nutrition_data.name)
        return format_html('<span style="color: #999;">No nutrition data</span>')
    get_nutrition_link.short_description = 'Nutrition Data'
    get_nutrition_link.admin_order_field = 'nutrition_data__name'

    def get_canonical_link(self, obj):
        if obj.canonical:
            url = reverse('admin:recipes_canonicalingredient_change', args=[obj.canonical.id])
            return format_html('<a href="{}">{}</a>', url, obj.canonical.canonical_name_en)
        return format_html('<span style="color: #999;">Unlinked</span>')
    get_canonical_link.short_description = 'Canonical'
    get_canonical_link.admin_order_field = 'canonical__canonical_name_en'

    def get_recipes_count(self, obj):
        count = obj.recipes.count()
        if count > 0:
            url = f"/admin/recipes/recipe/?ingredients__id__exact={obj.id}"
            return format_html('<a href="{}">{} recipes</a>', url, count)
        return '0 recipes'
    get_recipes_count.short_description = 'Used in Recipes'

    def link_to_nutrition_data(self, request, queryset):
        """Help link ingredients to nutrition data."""
        from .nutrition_service import NutritionService
        service = NutritionService()
        
        linked_count = 0
        for ingredient in queryset:
            if not ingredient.nutrition_data and ingredient.name:
                # Try to find existing nutrition data
                nutrition_data = service._find_exact_match(ingredient.name)
                if not nutrition_data:
                    nutrition_data = service._find_fuzzy_match(ingredient.name)
                
                if nutrition_data:
                    ingredient.nutrition_data = nutrition_data
                    ingredient.save()
                    linked_count += 1
        
        if linked_count:
            self.message_user(request, f"Successfully linked {linked_count} ingredients to nutrition data.")
        else:
            self.message_user(request, "No matching nutrition data found for selected ingredients.")
    link_to_nutrition_data.short_description = "Auto-link to nutrition data"


@admin.register(Recipe)
class RecipeAdmin(admin.ModelAdmin):
    list_display = (
        'title', 'created_by', 'get_nutrition_summary', 'cooking_time', 
        'servings', 'is_favorite', 'is_formatted', 'created_at'
    )
    search_fields = ('title', 'description', 'created_by__username', 'tags')
    list_filter = ('created_by', 'is_favorite', 'is_formatted', 'created_at')
    filter_horizontal = ('ingredients',)
    ordering = ('-created_at',)
    actions = ['calculate_nutrition', 'recalculate_all_nutrition']

    fieldsets = (
        ('Basic Information', {
            'fields': ('title', 'description', 'instructions', 'notes', 'is_favorite', 'created_by', 'parent')
        }),
        ('Time & Yield', {
            'fields': ('cooking_time', 'preparation_time', 'servings', 'recipe_yield')
        }),
        ('Nutrition (Calculated)', {
            'fields': ('calories', 'protein', 'fat', 'carbs'),
            'description': 'These values are automatically calculated from ingredients. Use "Calculate Nutrition" action to update.'
        }),
        ('Ingredients & Media', {
            'fields': ('ingredients', 'tags', 'image', 'web_image_url', 'thumbnail')
        }),
        ('Flags', {
            'fields': ('is_formatted',),
            'classes': ('collapse',)
        }),
    )

    def get_nutrition_summary(self, obj):
        if obj.calories:
            return format_html(
                '<strong>{}cal</strong> | {}p | {}f | {}c',
                int(obj.calories) if obj.calories else 0,
                f"{obj.protein:.1f}g" if obj.protein else "0g",
                f"{obj.fat:.1f}g" if obj.fat else "0g",
                f"{obj.carbs:.1f}g" if obj.carbs else "0g"
            )
        from django.utils.safestring import mark_safe
        return mark_safe('<span style="color: #999;">No nutrition data</span>')
    get_nutrition_summary.short_description = 'Nutrition Summary'
    get_nutrition_summary.admin_order_field = 'calories'

    def calculate_nutrition(self, request, queryset):
        """Calculate nutrition for selected recipes."""
        updated_count = 0
        for recipe in queryset:
            try:
                recipe.calculate_nutrition()
                updated_count += 1
            except Exception as e:
                self.message_user(request, f"Error calculating nutrition for '{recipe.title}': {e}", level='ERROR')
        
        if updated_count:
            self.message_user(request, f"Successfully calculated nutrition for {updated_count} recipe(s).", level='SUCCESS')
    calculate_nutrition.short_description = "Calculate nutrition for selected recipes"

    def recalculate_all_nutrition(self, request, queryset):
        """Recalculate nutrition for all recipes."""
        from django.core.management import call_command
        try:
            self.message_user(request, "Successfully triggered nutrition calculation for all recipes.", level='SUCCESS')
        except Exception as e:
            self.message_user(request, f"Error triggering nutrition calculation: {e}", level='ERROR')
    recalculate_all_nutrition.short_description = "Recalculate ALL recipe nutrition (background task)"

    def get_readonly_fields(self, request, obj=None):
        # Make nutrition fields readonly since they're calculated
        readonly = ['calories', 'protein', 'fat', 'carbs']
        if obj and obj.parent:  # If this is a cloned recipe
            readonly.append('parent')
        return readonly

@admin.register(SavedRecipe)
class SavedRecipeAdmin(admin.ModelAdmin):
    list_display = ('user', 'get_recipe_link', 'get_recipe_nutrition', 'saved_at')
    search_fields = ('user__username', 'recipe__title')
    list_filter = ('saved_at', 'user')
    ordering = ('-saved_at',)
    autocomplete_fields = ('user', 'recipe')

    def get_recipe_link(self, obj):
        url = reverse('admin:recipes_recipe_change', args=[obj.recipe.id])
        return format_html('<a href="{}">{}</a>', url, obj.recipe.title)
    get_recipe_link.short_description = 'Recipe'
    get_recipe_link.admin_order_field = 'recipe__title'

    def get_recipe_nutrition(self, obj):
        if obj.recipe.calories:
            return f"{int(obj.recipe.calories)}cal"
        return 'No nutrition'
    get_recipe_nutrition.short_description = 'Calories'
    get_recipe_nutrition.admin_order_field = 'recipe__calories'


# Customize the admin site header and title
admin.site.site_header = "ICantCook Recipe Management"
admin.site.site_title = "ICantCook Admin"
admin.site.index_title = "Recipe & Nutrition Management"


@admin.register(CanonicalIngredient)
class CanonicalIngredientAdmin(admin.ModelAdmin):
    list_display = (
        'canonical_name_en', 'canonical_name_fr', 'category', 'ingredient_count'
    )
    search_fields = (
        'canonical_name_en', 'canonical_name_fr', 'category'
    )
    list_filter = ('category', 'created_at')
    ordering = ('canonical_name_en',)
    readonly_fields = ('created_at',)
    list_per_page = 50

    fieldsets = (
        ('Names', {
            'fields': (
                'canonical_name_en', 'canonical_name_fr'
            )
        }),
        ('Classification', {
            'fields': ('category',)
        }),
        ('Metadata', {
            'fields': ('created_at',)
        }),
    )

    def ingredient_count(self, obj):
        count = obj.ingredients.count()
        if count:
            url = f"/admin/recipes/ingredient/?canonical__id__exact={obj.id}"
            return format_html('<a href="{}">{} linked</a>', url, count)
        return '0 linked'
    ingredient_count.short_description = 'Ingredients'

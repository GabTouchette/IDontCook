from django.contrib import admin
from django.utils.html import format_html
from .models import Recipe, Ingredient
from imagekit.admin import AdminThumbnail


class IngredientAdmin(admin.ModelAdmin):
    list_display = ('name', 'quantity',  'get_substitutes')
    search_fields = ('name',)
    list_filter = ()
    ordering = ('name',)

    def get_substitutes(self, obj):
        return ', '.join(obj.substitutes) if obj.substitutes else 'None'
    get_substitutes.short_description = 'Substitutes'


class RecipeAdmin(admin.ModelAdmin):
    list_display = (
        'title', 'created_by', 'cooking_time', 'servings', 'is_favorite', 'created_at'
    )
    search_fields = ('title', 'description', 'created_by__username', 'tags')
    list_filter = ('created_by', 'is_favorite', 'created_at')
    filter_horizontal = ('ingredients',)
    ordering = ('-created_at',)

    fieldsets = (
        (None, {
            'fields': ('title', 'description', 'instructions', 'notes', 'is_favorite', 'created_by', 'parent')
        }),
        ('Time & Yield', {
            'fields': ('cooking_time', 'preparation_time', 'servings', 'recipe_yield')
        }),
        ('Nutritional Information', {
            'fields': (
                'calories', 'fat_content', 'saturated_fat_content', 'cholesterol_content',
                'sodium_content', 'carbohydrate_content', 'fiber_content', 'sugar_content', 'protein_content'
            )
        }),
        ('Tags & Images', {
            'fields': ('tags', 'image', 'web_image_url', 'thumbnail')
        }),
    )

    inlines = []


admin.site.register(Recipe, RecipeAdmin)
admin.site.register(Ingredient, IngredientAdmin)

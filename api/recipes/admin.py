from django.contrib import admin
from .models import Recipe, Ingredient

class RecipeAdmin(admin.ModelAdmin):
    list_display = ('id', 'title', 'cooking_time', 'created_at')  
    search_fields = ('title', 'tags')  
    list_filter = ('tags', 'cooking_time')  
    filter_horizontal = ('ingredients',)

class IngredientAdmin(admin.ModelAdmin):
    list_display = ('name',)  
    search_fields = ('name',)  

admin.site.register(Recipe, RecipeAdmin)
admin.site.register(Ingredient, IngredientAdmin)

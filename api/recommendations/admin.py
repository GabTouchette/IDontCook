from django.contrib import admin
from .models import UserRecipeInteraction

@admin.register(UserRecipeInteraction)
class UserRecipeInteractionAdmin(admin.ModelAdmin):
    list_display = ('user', 'recipe', 'interaction_type', 'created_at')
    list_filter = ('interaction_type', 'created_at')
    search_fields = ('user__username', 'recipe__title')
    ordering = ('-created_at',)

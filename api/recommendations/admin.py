from django.contrib import admin
from .models import RecipeVector, UserRecipeInteraction, VectorizerArtifact

@admin.register(UserRecipeInteraction)
class UserRecipeInteractionAdmin(admin.ModelAdmin):
    list_display = ('user', 'recipe', 'interaction_type', 'created_at')
    list_filter = ('interaction_type', 'created_at')
    search_fields = ('user__username', 'recipe__title')
    ordering = ('-created_at',)


@admin.register(VectorizerArtifact)
class VectorizerArtifactAdmin(admin.ModelAdmin):
    list_display = ('version', 'created_at')
    ordering = ('-created_at',)


@admin.register(RecipeVector)
class RecipeVectorAdmin(admin.ModelAdmin):
    list_display = ('recipe', 'vectorizer_version', 'updated_at')
    list_filter = ('vectorizer_version',)
    search_fields = ('recipe__title',)
    ordering = ('-updated_at',)

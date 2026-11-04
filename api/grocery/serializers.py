from rest_framework import serializers

from .models import GroceryBagRecipe


class GroceryBagRecipeSerializer(serializers.ModelSerializer):
    """A recipe queued in the bag, with the minimal fields the list UI needs."""
    recipe_id = serializers.IntegerField(source="recipe.id", read_only=True)
    title = serializers.CharField(source="recipe.title", read_only=True)
    base_servings = serializers.IntegerField(source="recipe.servings", read_only=True)
    image = serializers.SerializerMethodField()

    class Meta:
        model = GroceryBagRecipe
        fields = ["id", "recipe_id", "title", "base_servings", "servings", "image", "added_at"]

    def get_image(self, obj):
        recipe = obj.recipe
        try:
            if recipe.thumbnail:
                return recipe.thumbnail.url
        except Exception:
            pass
        return recipe.web_image_url or None

from rest_framework import serializers
from .models import Recipe, Ingredient

class IngredientSerializer(serializers.ModelSerializer):
    class Meta:
        model = Ingredient
        fields = ["id", "name"]

class RecipeSerializer(serializers.ModelSerializer):
    ingredients = IngredientSerializer(many=True)

    class Meta:
        model = Recipe
        fields = "__all__"

    def create(self, validated_data):
        ingredient_data = validated_data.pop("ingredients")
        recipe = Recipe.objects.create(**validated_data)

        for ingredient in ingredient_data:
            ingredient_obj, _ = Ingredient.objects.get_or_create(name=ingredient["name"])
            recipe.ingredients.add(ingredient_obj)

        return recipe

    def update(self, instance, validated_data):
        ingredient_data = validated_data.pop("ingredients")
        instance.title = validated_data.get("title", instance.title)
        instance.instructions = validated_data.get("instructions", instance.instructions)
        instance.cooking_time = validated_data.get("cooking_time", instance.cooking_time)
        instance.tags = validated_data.get("tags", instance.tags)
        instance.save()

        instance.ingredients.clear()
        for ingredient in ingredient_data:
            ingredient_obj, _ = Ingredient.objects.get_or_create(name=ingredient["name"])
            instance.ingredients.add(ingredient_obj)

        return instance

from rest_framework import serializers
from .models import Recipe, Ingredient

class IngredientSerializer(serializers.ModelSerializer):
    class Meta:
        model = Ingredient
        fields = ['id', 'name', 'quantity', 'unit_of_measure', 'substitutes']

class RecipeSerializer(serializers.ModelSerializer):
    ingredients = IngredientSerializer(many=True)  
    instructions = serializers.SerializerMethodField()

    class Meta:
        model = Recipe
        fields = [
            'id', 
            'title', 
            'ingredients', 
            'instructions', 
            'cooking_time', 
            'preparation_time',  
            'tags', 
            'description',  
            'image_url',  
            'notes',  
            'created_at'
        ]

    def get_instructions(self, obj):
        return eval(obj.instructions) if isinstance(obj.instructions, str) else obj.instructions

    def create(self, validated_data):
        ingredients_data = validated_data.pop("ingredients")
        recipe = Recipe.objects.create(**validated_data)
        
        for ingredient_data in ingredients_data:
            ingredient_obj, _ = Ingredient.objects.get_or_create(name=ingredient_data["name"])
            recipe.ingredients.add(ingredient_obj)
        
        return recipe

    def update(self, instance, validated_data):
        ingredients_data = validated_data.pop("ingredients")
        instance.title = validated_data.get("title", instance.title)
        instance.instructions = validated_data.get("instructions", instance.instructions)
        instance.cooking_time = validated_data.get("cooking_time", instance.cooking_time)
        instance.preparation_time = validated_data.get("preparation_time", instance.preparation_time)  
        instance.tags = validated_data.get("tags", instance.tags)
        instance.description = validated_data.get("description", instance.description)  
        instance.image_url = validated_data.get("image_url", instance.image_url)  
        instance.notes = validated_data.get("notes", instance.notes)  
        instance.save()

        instance.ingredients.clear()
        for ingredient_data in ingredients_data:
            ingredient_obj, _ = Ingredient.objects.get_or_create(name=ingredient_data["name"])
            instance.ingredients.add(ingredient_obj)

        return instance

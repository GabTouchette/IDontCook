from rest_framework import serializers
from .models import Recipe, Ingredient

class IngredientSerializer(serializers.ModelSerializer):
    class Meta:
        model = Ingredient
        fields = ['id', 'name', 'quantity', 'unit_of_measure', 'substitutes']

from rest_framework import serializers
from .models import Recipe, Ingredient

class RecipeSerializer(serializers.ModelSerializer):
    ingredients = IngredientSerializer(many=True)

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

    def to_representation(self, instance):
        """ Customize the GET response to properly format instructions as a list """
        representation = super().to_representation(instance)
        

        if isinstance(instance.instructions, str):
    
            representation['instructions'] = eval(instance.instructions)
        
        return representation
    
    def create(self, validated_data):
        ingredients_data = validated_data.pop("ingredients")
        instructions = validated_data.pop("instructions")
        validated_data["instructions"] = str(instructions)
        
        validated_data["user"] = self.context["request"].user

        recipe = Recipe.objects.create(**validated_data)

        for ingredient_data in ingredients_data:
            ingredient_obj = Ingredient.objects.create(
                name=ingredient_data["name"],
                quantity=ingredient_data.get("quantity"),
                unit_of_measure=ingredient_data.get("unit_of_measure"),
            )
            recipe.ingredients.add(ingredient_obj)

        return recipe

    def update(self, instance, validated_data):
        ingredients_data = validated_data.pop("ingredients")
        instructions = validated_data.pop("instructions")
        validated_data["instructions"] = str(instructions)

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
            ingredient_obj = Ingredient.objects.create(
                name=ingredient_data["name"],
                quantity=ingredient_data.get("quantity"),
                unit_of_measure=ingredient_data.get("unit_of_measure"),
            )
            instance.ingredients.add(ingredient_obj)

        return instance
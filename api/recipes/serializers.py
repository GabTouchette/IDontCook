from rest_framework import serializers
from .models import Recipe, Ingredient, NutritionData
from accounts.serializers import UserSerializer

class IngredientSerializer(serializers.ModelSerializer):
    nutrition = serializers.SerializerMethodField()
    
    class Meta:
        model = Ingredient
        fields = ['id', 'name', 'unit', 'quantity', 'substitutes', 'nutrition']
    
    def get_nutrition(self, obj):
        """Get nutrition data for this ingredient's quantity."""
        return obj.get_nutrition_per_quantity()


class RecipeSerializer(serializers.ModelSerializer):
    ingredients = IngredientSerializer(many=True)
    created_by = UserSerializer(read_only=True)
    image_url = serializers.SerializerMethodField()
    thumnbnail_url = serializers.SerializerMethodField()
    is_saved = serializers.SerializerMethodField()

    class Meta:
        model = Recipe
        fields = '__all__'

    def get_image_url(self, obj):
        if obj.image and hasattr(obj.image, 'url'):
            return obj.image.url
        return obj.web_image_url
    
    def get_thumnbnail_url(self, obj):
        if obj.thumbnail and hasattr(obj.thumbnail, 'url'):
            return obj.thumbnail.url
        return obj.web_image_url
    
    def get_is_saved(self, obj):
        user = self.context.get('request').user
        if not user or not user.is_authenticated:
            return False

        # Either the user created it or has saved a version of it
        return obj.created_by == user or Recipe.objects.filter(created_by=user, parent=obj.id).exists()

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
        
        validated_data["created_by"] = self.context["request"].user

        recipe = Recipe.objects.create(**validated_data)

        for ingredient_data in ingredients_data:
            ingredient_obj = Ingredient.objects.create(
                name=ingredient_data["name"],
                quantity=ingredient_data.get("quantity"),
                unit=ingredient_data.get("unit"),
            )
            recipe.ingredients.add(ingredient_obj)

        # Calculate nutrition after ingredients are added
        try:
            recipe.calculate_nutrition()
        except Exception:
            pass  # Don't fail recipe creation if nutrition calculation fails

        return recipe

    def update(self, instance, validated_data):
        """ Handle regular updates (PUT) """
        is_favorite = validated_data.pop("is_favorite", None)
        if is_favorite is not None:
            instance.is_favorite = is_favorite

        ingredients_data = validated_data.pop("ingredients", [])
        instructions = validated_data.pop("instructions", None)
        if instructions:
            validated_data["instructions"] = str(instructions)

        instance.title = validated_data.get("title", instance.title)
        instance.instructions = validated_data.get("instructions", instance.instructions)
        instance.cooking_time = validated_data.get("cooking_time", instance.cooking_time)
        instance.preparation_time = validated_data.get("preparation_time", instance.preparation_time)  
        instance.tags = validated_data.get("tags", instance.tags)
        instance.description = validated_data.get("description", instance.description)  
        instance.notes = validated_data.get("notes", instance.notes)  
        instance.save()

        # Update ingredients if necessary
        instance.ingredients.clear()
        for ingredient_data in ingredients_data:
            ingredient_obj = Ingredient.objects.create(
                name=ingredient_data["name"],
                quantity=ingredient_data.get("quantity"),
                unit=ingredient_data.get("unit"),
            )
            instance.ingredients.add(ingredient_obj)

        # Recalculate nutrition after ingredients are updated
        try:
            instance.calculate_nutrition()
        except Exception:
            pass  # Don't fail update if nutrition calculation fails

        return instance
    
    def patch(self, instance, validated_data):
        """ Handle partial update (PATCH) requests to only update 'is_favorite' """
        is_favorite = validated_data.get("is_favorite", None)
        if is_favorite is not None:
            instance.is_favorite = is_favorite

        instance.save()

        return instance
    

class RecipePreviewSerializer(serializers.ModelSerializer):
    thumbnail_url = serializers.SerializerMethodField()
    ingredients_count = serializers.SerializerMethodField()
    is_saved = serializers.SerializerMethodField()

    class Meta:
        model = Recipe
        fields = [
            'id', 
            'title', 
            'description', 
            'preparation_time', 
            'cooking_time', 
            'thumbnail_url',
            'tags', 
            'is_favorite', 
            'last_visited_at',
            'ingredients_count',
            'calories',
            'protein',
            'fat',
            'carbs',
            'is_saved'
        ]

    def get_thumbnail_url(self, obj):
        if obj.thumbnail and hasattr(obj.thumbnail, 'url'):
            return obj.thumbnail.url
        return obj.web_image_url

    def get_ingredients_count(self, obj):
        return obj.ingredients.count()
    
    def get_is_saved(self, obj):
        user = self.context.get('request').user
        if not user or not user.is_authenticated:
            return False

        return Recipe.objects.filter(parent=obj.id).exists()
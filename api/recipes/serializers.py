from rest_framework import serializers
from .models import Recipe, Ingredient, NutritionData
from accounts.serializers import UserSerializer

class IngredientSerializer(serializers.ModelSerializer):
    class Meta:
        model = Ingredient
        fields = ['id', 'name', 'unit', 'quantity', 'substitutes']


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
            # Apply smart unit defaults if unit is missing or empty
            unit = ingredient_data.get("unit", "").strip()
            name = ingredient_data.get("name", "").strip()
            
            if not unit and name:
                unit = self._get_smart_unit_default(name)
            
            ingredient_obj = Ingredient.objects.create(
                name=name,
                quantity=ingredient_data.get("quantity"),
                unit=unit,
            )
            recipe.ingredients.add(ingredient_obj)

        # Calculate nutrition after ingredients are added
        try:
            recipe.calculate_nutrition()
        except Exception:
            pass  # Don't fail recipe creation if nutrition calculation fails

        return recipe

    def _get_smart_unit_default(self, ingredient_name):
        """
        Assign smart default units based on ingredient name patterns.
        Mirrors the logic from the Flutter frontend for consistency.
        """
        if not ingredient_name:
            return "piece"
        
        name_lower = ingredient_name.lower()
        
        # Smart ingredient defaults based on ingredient type
        ingredient_defaults = {
            # Fruits & Vegetables (pieces)
            'avocado': 'piece', 'avocados': 'piece', 'ripe avocado': 'piece', 'ripe avocados': 'piece',
            'onion': 'piece', 'onions': 'piece', 'large onion': 'piece', 'medium onion': 'piece', 'small onion': 'piece',
            'tomato': 'piece', 'tomatoes': 'piece', 'large tomato': 'piece', 'cherry tomatoes': 'cup',
            'apple': 'piece', 'apples': 'piece', 'green apple': 'piece', 'red apple': 'piece',
            'banana': 'piece', 'bananas': 'piece', 'ripe banana': 'piece', 'ripe bananas': 'piece',
            'lemon': 'piece', 'lemons': 'piece', 'large lemon': 'piece',
            'lime': 'piece', 'limes': 'piece', 'fresh lime': 'piece',
            'potato': 'piece', 'potatoes': 'piece', 'large potato': 'piece', 'medium potato': 'piece',
            'carrot': 'piece', 'carrots': 'piece', 'large carrot': 'piece', 'baby carrots': 'cup',
            'bell pepper': 'piece', 'peppers': 'piece', 'red bell pepper': 'piece', 'green pepper': 'piece',
            'cucumber': 'piece', 'cucumbers': 'piece', 'large cucumber': 'piece',
            'garlic': 'clove', 'garlic clove': 'clove', 'garlic cloves': 'clove', 'fresh garlic': 'clove',
            
            # Proteins (pieces/lbs for larger cuts, pieces for individual items)
            'chicken breast': 'piece', 'chicken breasts': 'piece', 'boneless chicken breast': 'piece',
            'boneless chicken breasts': 'piece', 'skinless chicken breast': 'piece', 'skinless chicken breasts': 'piece',
            'boneless skinless chicken breast': 'piece', 'boneless skinless chicken breasts': 'piece',
            'chicken thigh': 'piece', 'chicken thighs': 'piece', 'boneless chicken thigh': 'piece', 'boneless chicken thighs': 'piece',
            'chicken wing': 'piece', 'chicken wings': 'piece',
            'ground chicken': 'lb', 'ground beef': 'lb', 'ground turkey': 'lb', 'ground pork': 'lb',
            'beef': 'lb', 'pork': 'lb', 'lamb': 'lb',
            'steak': 'piece', 'steaks': 'piece', 'ribeye': 'piece', 'sirloin': 'piece',
            'egg': 'piece', 'eggs': 'piece', 'large egg': 'piece', 'large eggs': 'piece',
            'salmon fillet': 'piece', 'salmon fillets': 'piece', 'cod fillet': 'piece', 'tilapia fillet': 'piece',
            'pork chop': 'piece', 'pork chops': 'piece', 'lamb chop': 'piece', 'lamb chops': 'piece',
            'bacon': 'slice', 'bacon strips': 'slice', 'ham': 'slice',
            'shrimp': 'lb', 'prawns': 'lb', 'scallops': 'piece',
            
            # Dairy & Cheese
            'cheese': 'cup', 'cheddar cheese': 'cup', 'mozzarella cheese': 'cup', 'parmesan cheese': 'cup',
            'cream cheese': 'oz', 'butter': 'tbsp', 'unsalted butter': 'tbsp', 'salted butter': 'tbsp',
            'heavy cream': 'cup', 'sour cream': 'cup', 'greek yogurt': 'cup', 'yogurt': 'cup',
            
            # Liquids (cups/tbsp)
            'olive oil': 'tbsp', 'extra virgin olive oil': 'tbsp',
            'vegetable oil': 'tbsp', 'canola oil': 'tbsp', 'coconut oil': 'tbsp',
            'water': 'cup', 'warm water': 'cup', 'cold water': 'cup',
            'milk': 'cup', 'whole milk': 'cup', 'skim milk': 'cup', 'almond milk': 'cup',
            'broth': 'cup', 'chicken broth': 'cup', 'beef broth': 'cup', 'vegetable broth': 'cup',
            'stock': 'cup', 'chicken stock': 'cup', 'beef stock': 'cup', 'vegetable stock': 'cup',
            'juice': 'cup', 'lemon juice': 'tbsp', 'lime juice': 'tbsp', 'orange juice': 'cup',
            'vinegar': 'tbsp', 'apple cider vinegar': 'tbsp', 'white vinegar': 'tbsp', 'balsamic vinegar': 'tbsp',
            'soy sauce': 'tbsp', 'worcestershire sauce': 'tbsp', 'hot sauce': 'tsp',
            'wine': 'cup', 'white wine': 'cup', 'red wine': 'cup',
            
            # Spices & Small Items (tsp)
            'salt': 'tsp', 'sea salt': 'tsp', 'kosher salt': 'tsp', 'table salt': 'tsp',
            'pepper': 'tsp', 'black pepper': 'tsp', 'white pepper': 'tsp', 'ground black pepper': 'tsp',
            'garlic powder': 'tsp', 'onion powder': 'tsp', 'paprika': 'tsp', 'smoked paprika': 'tsp',
            'cumin': 'tsp', 'ground cumin': 'tsp', 'oregano': 'tsp', 'dried oregano': 'tsp',
            'thyme': 'tsp', 'dried thyme': 'tsp', 'fresh thyme': 'tbsp',
            'basil': 'tsp', 'dried basil': 'tsp', 'fresh basil': 'tbsp', 'basil leaves': 'tbsp',
            'rosemary': 'tsp', 'dried rosemary': 'tsp', 'fresh rosemary': 'tbsp',
            'parsley': 'tbsp', 'fresh parsley': 'tbsp', 'dried parsley': 'tsp',
            'cilantro': 'tbsp', 'fresh cilantro': 'tbsp',
            'chili powder': 'tsp', 'cayenne pepper': 'tsp', 'red pepper flakes': 'tsp',
            'cinnamon': 'tsp', 'ground cinnamon': 'tsp', 'nutmeg': 'tsp', 'vanilla extract': 'tsp',
            
            # Pantry Items (cups)
            'flour': 'cup', 'all-purpose flour': 'cup', 'bread flour': 'cup', 'wheat flour': 'cup',
            'sugar': 'cup', 'white sugar': 'cup', 'brown sugar': 'cup', 'granulated sugar': 'cup',
            'powdered sugar': 'cup', 'confectioners sugar': 'cup',
            'rice': 'cup', 'white rice': 'cup', 'brown rice': 'cup', 'jasmine rice': 'cup',
            'pasta': 'cup', 'spaghetti': 'cup', 'penne': 'cup', 'fettuccine': 'cup',
            'breadcrumbs': 'cup', 'panko breadcrumbs': 'cup',
            'oats': 'cup', 'rolled oats': 'cup', 'quick oats': 'cup',
            'quinoa': 'cup', 'barley': 'cup', 'lentils': 'cup', 'black beans': 'cup',
            'chickpeas': 'cup', 'kidney beans': 'cup',
        }
        
        # Check for exact matches first
        if name_lower in ingredient_defaults:
            return ingredient_defaults[name_lower]
        
        # Check for partial matches
        for key, unit in ingredient_defaults.items():
            if key in name_lower:
                return unit
        
        # Final fallback based on common patterns
        if any(word in name_lower for word in ['oil', 'sauce', 'vinegar', 'syrup']):
            return 'tbsp'
        elif any(word in name_lower for word in ['powder', 'spice', 'herb', 'seasoning']):
            return 'tsp'
        elif any(word in name_lower for word in ['flour', 'sugar', 'rice', 'pasta']):
            return 'cup'
        else:
            return 'piece'  # Default fallback

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
            # Apply smart unit defaults if unit is missing or empty
            unit = ingredient_data.get("unit", "").strip()
            name = ingredient_data.get("name", "").strip()
            
            if not unit and name:
                unit = self._get_smart_unit_default(name)
            
            ingredient_obj = Ingredient.objects.create(
                name=name,
                quantity=ingredient_data.get("quantity"),
                unit=unit,
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
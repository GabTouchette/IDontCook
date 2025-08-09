from rest_framework import serializers
from .models import MealPlan, PlannedMeal, GroceryList
from recipes.models import Recipe


class PlannedMealSerializer(serializers.ModelSerializer):
    class Meta:
        model = PlannedMeal
        fields = ["id", "recipe", "day_of_week", "meal_type", "servings"]


class MealPlanSerializer(serializers.ModelSerializer):
    planned_meals = PlannedMealSerializer(many=True)

    class Meta:
        model = MealPlan
        fields = ["id", "name", "week_start_date", "is_active", "planned_meals"]

    def create(self, validated_data):
        meals_data = validated_data.pop('planned_meals', [])
        meal_plan = MealPlan.objects.create(**validated_data)
        for m in meals_data:
            PlannedMeal.objects.create(meal_plan=meal_plan, **m)
        return meal_plan

    def update(self, instance, validated_data):
        meals_data = validated_data.pop('planned_meals', None)
        for attr, val in validated_data.items():
            setattr(instance, attr, val)
        instance.save()
        if meals_data is not None:
            # naive replace strategy
            instance.planned_meals.all().delete()
            for m in meals_data:
                PlannedMeal.objects.create(meal_plan=instance, **m)
        return instance


class GroceryListSerializer(serializers.ModelSerializer):
    class Meta:
        model = GroceryList
        fields = ["id", "ingredients", "purchased_items", "created_at"]

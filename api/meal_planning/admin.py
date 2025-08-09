from django.contrib import admin
from .models import MealPlan, PlannedMeal, GroceryList

@admin.register(MealPlan)
class MealPlanAdmin(admin.ModelAdmin):
    list_display = ("user", "name", "week_start_date", "is_active", "created_at")
    list_filter = ("is_active", "week_start_date")

@admin.register(PlannedMeal)
class PlannedMealAdmin(admin.ModelAdmin):
    list_display = ("meal_plan", "recipe", "day_of_week", "meal_type", "servings")
    list_filter = ("day_of_week", "meal_type")

@admin.register(GroceryList)
class GroceryListAdmin(admin.ModelAdmin):
    list_display = ("meal_plan", "created_at")

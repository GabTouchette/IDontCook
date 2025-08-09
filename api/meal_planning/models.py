from django.db import models
from accounts.models import CustomUser
from recipes.models import Recipe


class MealPlan(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    name = models.CharField(max_length=255, default="My Meal Plan")
    week_start_date = models.DateField()
    created_at = models.DateTimeField(auto_now_add=True)
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.user.username} - {self.name} ({self.week_start_date})"


class PlannedMeal(models.Model):
    MEAL_TYPES = (
        ("breakfast", "Breakfast"),
        ("lunch", "Lunch"),
        ("dinner", "Dinner"),
        ("snack", "Snack"),
    )
    meal_plan = models.ForeignKey(MealPlan, related_name="planned_meals", on_delete=models.CASCADE)
    recipe = models.ForeignKey(Recipe, on_delete=models.CASCADE)
    day_of_week = models.IntegerField(choices=[(i, day) for i, day in enumerate([
        'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ])])
    meal_type = models.CharField(max_length=20, choices=MEAL_TYPES)
    servings = models.IntegerField(default=1)


class GroceryList(models.Model):
    meal_plan = models.OneToOneField(MealPlan, on_delete=models.CASCADE)
    ingredients = models.JSONField(default=list)
    purchased_items = models.JSONField(default=list)
    created_at = models.DateTimeField(auto_now_add=True)

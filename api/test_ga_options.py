#!/usr/bin/env python3
"""
Focused test for option validation in GA solver.
Tests how each dietary preference and goal affects recipe selection.
"""

import os
import sys
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'api.settings')
django.setup()

from meal_planning.ga_solver import (
    Slot, FitnessOptions, evolve_plan, comp_goals
)

# Mock classes from previous test
class MockRecipe:
    def __init__(self, id: int, title: str, calories: float = None, protein: float = None,
                 preparation_time: int = None, cooking_time: int = None, 
                 tags: list = None, servings: int = 4, ingredients: list = None):
        self.id = id
        self.title = title
        self.calories = calories
        self.protein = protein
        self.preparation_time = preparation_time
        self.cooking_time = cooking_time
        self.tags = tags or []
        self.servings = servings
        self._ingredients = ingredients or []
    
    class MockIngredients:
        def __init__(self, ingredients):
            self._ingredients = ingredients
        def all(self):
            return self._ingredients
    
    @property
    def ingredients(self):
        return self.MockIngredients(self._ingredients)

class MockIngredient:
    def __init__(self, name: str, usda_name: str = None):
        self.name = name
        self.usda_name = usda_name or name

def create_diverse_recipes():
    """Create recipes with specific tags for testing"""
    return [
        # Vegetarian options
        MockRecipe(1, "Veggie Stir Fry", 320, 12, 10, 15, ["dinner", "vegetarian"]),
        MockRecipe(2, "Quinoa Salad", 380, 16, 15, 0, ["lunch", "vegetarian", "healthy"]),
        
        # Vegan options  
        MockRecipe(3, "Tofu Curry", 420, 20, 15, 25, ["dinner", "vegan"]),
        MockRecipe(4, "Oat Smoothie", 280, 8, 5, 0, ["breakfast", "vegan", "quick"]),
        
        # High protein
        MockRecipe(5, "Protein Bowl", 450, 35, 10, 0, ["lunch", "high-protein"]),
        MockRecipe(6, "Chicken Breast", 380, 40, 5, 20, ["dinner", "high-protein"]),
        
        # Low carb
        MockRecipe(7, "Zucchini Noodles", 180, 15, 8, 12, ["dinner", "low-carb"]),
        MockRecipe(8, "Egg Salad", 220, 18, 10, 0, ["lunch", "low-carb"]),
        
        # Gluten free
        MockRecipe(9, "Rice Bowl", 420, 22, 12, 18, ["dinner", "gluten-free"]),
        MockRecipe(10, "GF Pancakes", 380, 12, 10, 15, ["breakfast", "gluten-free"]),
        
        # Budget friendly
        MockRecipe(11, "Bean Soup", 280, 14, 10, 30, ["dinner", "budget-friendly"], 
                  ingredients=[MockIngredient("beans"), MockIngredient("onion")]),
        MockRecipe(12, "Pasta Simple", 350, 12, 5, 12, ["dinner", "budget-friendly"],
                  ingredients=[MockIngredient("pasta"), MockIngredient("tomato")]),
        
        # Quick meals
        MockRecipe(13, "Toast Avocado", 250, 8, 3, 0, ["breakfast", "quick"]),
        MockRecipe(14, "Wrap Turkey", 320, 18, 5, 0, ["lunch", "quick"]),
        
        # Regular options (no special tags)
        MockRecipe(15, "Regular Chicken", 420, 28, 10, 25, ["dinner"]),
        MockRecipe(16, "Basic Sandwich", 350, 16, 8, 0, ["lunch"]),
    ]

def test_goal_selection():
    """Test how different goals affect recipe selection"""
    print("=== Goal-Based Selection Test ===")
    
    recipes = create_diverse_recipes()
    
    # Create slots with all recipes as candidates
    slots = [
        Slot(day=0, meal_type="breakfast", candidates=[r for r in recipes if "breakfast" in r.tags]),
        Slot(day=0, meal_type="lunch", candidates=[r for r in recipes if "lunch" in r.tags]),
        Slot(day=0, meal_type="dinner", candidates=[r for r in recipes if "dinner" in r.tags]),
    ]
    
    test_goals = [
        [],
        ["vegetarian"],
        ["vegan"],
        ["high-protein"],
        ["low-carb"],
        ["gluten-free"],
        ["budget-friendly"],
        ["quick"],
        ["vegetarian", "budget-friendly"],
        ["high-protein", "quick"],
    ]
    
    for goals in test_goals:
        print(f"\nGoals: {goals or 'None'}")
        
        fit_opts = FitnessOptions(goals=set(goals) if goals else None)
        
        result = evolve_plan(
            slots=slots,
            servings=1,
            saved_set=set(),
            focus_on_saved=False,
            fitness_options=fit_opts
        )
        
        for day, meal_type, recipe in result:
            # Calculate goal alignment score
            if goals:
                goal_score = comp_goals(recipe, meal_type, fit_opts)
                print(f"  {meal_type}: {recipe.title} (tags: {recipe.tags}, goal_score: {goal_score:.2f})")
            else:
                print(f"  {meal_type}: {recipe.title} (tags: {recipe.tags})")

def test_time_constraints():
    """Test how time limits affect selection"""
    print("\n=== Time Constraint Test ===")
    
    recipes = create_diverse_recipes()
    dinner_recipes = [r for r in recipes if "dinner" in r.tags]
    
    slots = [Slot(day=0, meal_type="dinner", candidates=dinner_recipes)]
    
    time_configs = [
        {"dinner": 60},   # Very relaxed
        {"dinner": 30},   # Moderate  
        {"dinner": 15},   # Strict
        {"dinner": 5},    # Very strict
    ]
    
    for time_limits in time_configs:
        print(f"\nTime limit: {time_limits['dinner']} minutes")
        
        fit_opts = FitnessOptions(time_limits=time_limits)
        
        result = evolve_plan(
            slots=slots,
            servings=1,
            saved_set=set(),
            focus_on_saved=False,
            fitness_options=fit_opts
        )
        
        for day, meal_type, recipe in result:
            total_time = (recipe.preparation_time or 0) + (recipe.cooking_time or 0)
            print(f"  Selected: {recipe.title} ({total_time} min total)")

def test_budget_constraints():
    """Test budget-based selection"""
    print("\n=== Budget Constraint Test ===")
    
    recipes = create_diverse_recipes()
    dinner_recipes = [r for r in recipes if "dinner" in r.tags]
    
    slots = [Slot(day=0, meal_type="dinner", candidates=dinner_recipes)]
    
    budgets = [None, 5.0, 2.0, 1.0, 0.5]
    
    for budget in budgets:
        print(f"\nBudget per meal: ${budget if budget else 'No limit'}")
        
        if budget:
            fit_opts = FitnessOptions(budget_per_meal=budget)
        else:
            fit_opts = FitnessOptions(goals={"budget-friendly"})  # Test goal-based budget
        
        result = evolve_plan(
            slots=slots,
            servings=1,
            saved_set=set(),
            focus_on_saved=False,
            fitness_options=fit_opts
        )
        
        for day, meal_type, recipe in result:
            from meal_planning.ga_solver import _estimate_cost_per_serving
            cost = _estimate_cost_per_serving(recipe)
            print(f"  Selected: {recipe.title} (${cost:.2f} estimated)")

def test_all_combinations():
    """Test realistic combinations of constraints"""
    print("\n=== Realistic Combination Test ===")
    
    recipes = create_diverse_recipes()
    slots = [
        Slot(day=0, meal_type="breakfast", candidates=[r for r in recipes if "breakfast" in r.tags]),
        Slot(day=0, meal_type="lunch", candidates=[r for r in recipes if "lunch" in r.tags]),
        Slot(day=0, meal_type="dinner", candidates=[r for r in recipes if "dinner" in r.tags]),
    ]
    
    scenarios = [
        {
            "name": "Busy professional",
            "goals": {"quick"},
            "time_limits": {"breakfast": 5, "lunch": 10, "dinner": 20},
            "budget_per_meal": 4.0
        },
        {
            "name": "Vegetarian athlete", 
            "goals": {"vegetarian", "high-protein"},
            "time_limits": {"breakfast": 15, "lunch": 20, "dinner": 45},
            "budget_per_meal": None
        },
        {
            "name": "Budget-conscious vegan",
            "goals": {"vegan", "budget-friendly"},
            "time_limits": {"breakfast": 20, "lunch": 30, "dinner": 60},
            "budget_per_meal": 2.5
        },
        {
            "name": "Low-carb quick meals",
            "goals": {"low-carb", "quick"},
            "time_limits": {"breakfast": 8, "lunch": 15, "dinner": 25},
            "budget_per_meal": 6.0
        }
    ]
    
    for scenario in scenarios:
        print(f"\n{scenario['name']}:")
        print(f"  Goals: {scenario['goals']}")
        print(f"  Time limits: {scenario['time_limits']}")
        print(f"  Budget: ${scenario['budget_per_meal'] or 'No limit'}")
        
        fit_opts = FitnessOptions(
            goals=scenario['goals'],
            time_limits=scenario['time_limits'],
            budget_per_meal=scenario['budget_per_meal']
        )
        
        result = evolve_plan(
            slots=slots,
            servings=1,
            saved_set=set(),
            focus_on_saved=False,
            fitness_options=fit_opts
        )
        
        print("  Selected meals:")
        for day, meal_type, recipe in result:
            from meal_planning.ga_solver import _estimate_cost_per_serving
            cost = _estimate_cost_per_serving(recipe)
            total_time = (recipe.preparation_time or 0) + (recipe.cooking_time or 0)
            goal_score = comp_goals(recipe, meal_type, fit_opts) or 0
            print(f"    {meal_type}: {recipe.title}")
            print(f"      Tags: {recipe.tags}")
            print(f"      Time: {total_time}min, Cost: ${cost:.2f}, Goal match: {goal_score:.2f}")

def main():
    print("GA Solver Option Validation Test")
    print("=" * 50)
    
    test_goal_selection()
    test_time_constraints()
    test_budget_constraints()
    test_all_combinations()
    
    print("\n" + "=" * 50)
    print("Option validation tests completed!")

if __name__ == "__main__":
    main()

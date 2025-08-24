#!/usr/bin/env python3
"""
Test script for the GA meal planning solver.
Tests performance, option handling, and correctness.
"""

import os
import sys
import time
import django
from typing import List, Dict, Any

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'api.settings')
django.setup()

from meal_planning.ga_solver import (
    Slot, GAParams, FitnessOptions, evolve_plan, 
    derive_targets_from_profile, DEFAULT_TARGETS,
    comp_nutrition, comp_time, comp_cost, comp_difficulty, comp_goals, comp_saved,
    _estimate_cost_per_serving
)
from recipes.models import Recipe
from accounts.models import CustomUser

class MockRecipe:
    """Mock recipe for testing without database dependencies"""
    def __init__(self, id: int, title: str, calories: float = None, protein: float = None,
                 preparation_time: int = None, cooking_time: int = None, 
                 tags: List[str] = None, servings: int = 4, ingredients: List = None):
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

def create_test_recipes() -> List[MockRecipe]:
    """Create diverse test recipes covering different scenarios"""
    recipes = [
        # Breakfast recipes
        MockRecipe(1, "Overnight Oats", 350, 15, 5, 0, ["breakfast", "quick", "healthy"], 
                  ingredients=[MockIngredient("oats"), MockIngredient("milk"), MockIngredient("banana")]),
        MockRecipe(2, "Bacon Pancakes", 520, 18, 10, 15, ["breakfast"], 
                  ingredients=[MockIngredient("bacon"), MockIngredient("flour"), MockIngredient("eggs")]),
        MockRecipe(3, "Salmon Avocado Toast", 420, 25, 8, 0, ["breakfast", "high-protein"], 
                  ingredients=[MockIngredient("salmon"), MockIngredient("avocado"), MockIngredient("bread")]),
        
        # Lunch recipes
        MockRecipe(4, "Quinoa Buddha Bowl", 480, 22, 15, 0, ["lunch", "vegetarian", "healthy"], 
                  ingredients=[MockIngredient("quinoa"), MockIngredient("chickpeas"), MockIngredient("kale")]),
        MockRecipe(5, "Chicken Caesar Salad", 380, 35, 12, 0, ["lunch", "high-protein"], 
                  ingredients=[MockIngredient("chicken"), MockIngredient("lettuce"), MockIngredient("parmesan")]),
        MockRecipe(6, "Veggie Wrap", 320, 12, 8, 0, ["lunch", "vegetarian", "quick"], 
                  ingredients=[MockIngredient("tortilla"), MockIngredient("hummus"), MockIngredient("vegetables")]),
        
        # Dinner recipes
        MockRecipe(7, "Beef Stir Fry", 650, 42, 15, 20, ["dinner"], 
                  ingredients=[MockIngredient("beef"), MockIngredient("broccoli"), MockIngredient("rice")]),
        MockRecipe(8, "Lentil Curry", 420, 18, 10, 30, ["dinner", "vegetarian", "budget-friendly"], 
                  ingredients=[MockIngredient("lentils"), MockIngredient("coconut milk"), MockIngredient("spices")]),
        MockRecipe(9, "Lobster Thermidor", 580, 38, 30, 45, ["dinner"], 
                  ingredients=[MockIngredient("lobster"), MockIngredient("cream"), MockIngredient("cheese")]),
        MockRecipe(10, "Pasta Primavera", 520, 16, 8, 15, ["dinner", "vegetarian"], 
                  ingredients=[MockIngredient("pasta"), MockIngredient("zucchini"), MockIngredient("tomatoes")]),
        
        # Snacks
        MockRecipe(11, "Trail Mix", 180, 8, 5, 0, ["snack", "budget-friendly"], 
                  ingredients=[MockIngredient("nuts"), MockIngredient("dried fruit")]),
        MockRecipe(12, "Protein Smoothie", 240, 25, 3, 0, ["snack", "high-protein", "quick"], 
                  ingredients=[MockIngredient("protein powder"), MockIngredient("banana"), MockIngredient("milk")]),
    ]
    return recipes

def test_profile_targets():
    """Test profile-based target derivation"""
    print("=== Testing Profile-Based Targets ===")
    
    profiles = [
        {"sex": "male", "age": 25, "weight_kg": 70, "height_cm": 175, "activity": "active"},
        {"sex": "female", "age": 30, "weight_kg": 60, "height_cm": 165, "activity": "moderate"},
        {"sex": "male", "age": 40, "weight_kg": 85, "height_cm": 180, "activity": "sedentary"},
    ]
    
    for i, profile in enumerate(profiles):
        targets = derive_targets_from_profile(profile)
        print(f"\nProfile {i+1}: {profile}")
        for meal_type, values in targets.items():
            print(f"  {meal_type}: {values['calories']:.0f} cal, {values['protein']:.1f}g protein")

def test_cost_estimation():
    """Test cost estimation heuristics"""
    print("\n=== Testing Cost Estimation ===")
    
    recipes = create_test_recipes()
    
    for recipe in recipes:
        cost = _estimate_cost_per_serving(recipe)
        print(f"{recipe.title}: ${cost:.2f} per serving")

def test_fitness_components():
    """Test individual fitness components"""
    print("\n=== Testing Fitness Components ===")
    
    recipes = create_test_recipes()
    
    # Test contexts
    contexts = [
        FitnessOptions(goals={"high-protein"}, budget_per_meal=5.0, difficulty_max=2),
        FitnessOptions(goals={"vegetarian", "budget-friendly"}),
        FitnessOptions(time_limits={"breakfast": 10, "lunch": 20, "dinner": 30}),
    ]
    
    for i, ctx in enumerate(contexts):
        print(f"\nContext {i+1}: goals={ctx.goals}, budget=${ctx.budget_per_meal}, difficulty_max={ctx.difficulty_max}")
        
        for recipe in recipes[:3]:  # Test first 3 recipes
            meal_type = recipe.tags[0] if recipe.tags else "dinner"
            
            scores = {
                'nutrition': comp_nutrition(recipe, meal_type, ctx),
                'time': comp_time(recipe, meal_type, ctx),
                'cost': comp_cost(recipe, meal_type, ctx),
                'goals': comp_goals(recipe, meal_type, ctx),
            }
            
            print(f"  {recipe.title} ({meal_type}):")
            for component, score in scores.items():
                if score is not None:
                    print(f"    {component}: {score:.3f}")

def test_ga_performance():
    """Test GA solver performance with different configurations"""
    print("\n=== Testing GA Performance ===")
    
    recipes = create_test_recipes()
    
    # Create slots for a week
    slots = []
    meal_types = ["breakfast", "lunch", "dinner"]
    
    for day in range(7):
        for meal_type in meal_types:
            # Filter recipes by meal type
            candidates = [r for r in recipes if meal_type in r.tags]
            if candidates:
                slots.append(Slot(day=day, meal_type=meal_type, candidates=candidates))
    
    print(f"Created {len(slots)} slots")
    
    # Test different GA configurations
    configs = [
        GAParams(pop_size=40, generations=30),  # Fast
        GAParams(pop_size=80, generations=60),  # Default
        GAParams(pop_size=120, generations=90), # Thorough
    ]
    
    for i, params in enumerate(configs):
        print(f"\nConfig {i+1}: pop_size={params.pop_size}, generations={params.generations}")
        
        start_time = time.time()
        result = evolve_plan(
            slots=slots,
            servings=2,
            saved_set=set([1, 4, 8]),  # Mock saved recipes
            focus_on_saved=True,
            params=params
        )
        end_time = time.time()
        
        print(f"  Time: {end_time - start_time:.3f}s")
        print(f"  Results: {len(result)} meals planned")
        
        # Check for duplicates
        recipe_ids = [r[2].id for r in result]
        duplicates = len(recipe_ids) - len(set(recipe_ids))
        print(f"  Duplicates: {duplicates}")
        
        # Show sample results
        for day, meal_type, recipe in result[:5]:
            print(f"    Day {day} {meal_type}: {recipe.title}")

def test_option_handling():
    """Test how different user options affect results"""
    print("\n=== Testing Option Handling ===")
    
    recipes = create_test_recipes()
    
    # Create minimal slots
    slots = [
        Slot(day=0, meal_type="breakfast", candidates=[r for r in recipes if "breakfast" in r.tags]),
        Slot(day=0, meal_type="lunch", candidates=[r for r in recipes if "lunch" in r.tags]),
        Slot(day=0, meal_type="dinner", candidates=[r for r in recipes if "dinner" in r.tags]),
    ]
    
    test_cases = [
        {"name": "No preferences", "options": {}},
        {"name": "High protein focus", "options": {"goals": {"high-protein"}}},
        {"name": "Vegetarian + budget", "options": {"goals": {"vegetarian", "budget-friendly"}}},
        {"name": "Quick meals", "options": {"time_limits": {"breakfast": 10, "lunch": 15, "dinner": 20}}},
        {"name": "Budget conscious", "options": {"budget_per_meal": 3.0}},
        {"name": "Focus on saved", "options": {"saved_set": {4, 8}, "focus_on_saved": True}},
    ]
    
    for case in test_cases:
        print(f"\n{case['name']}:")
        
        fit_opts = FitnessOptions(**case['options'])
        
        start_time = time.time()
        result = evolve_plan(
            slots=slots,
            servings=1,
            saved_set=fit_opts.saved_set or set(),
            focus_on_saved=fit_opts.focus_on_saved,
            fitness_options=fit_opts
        )
        end_time = time.time()
        
        print(f"  Time: {end_time - start_time:.3f}s")
        for day, meal_type, recipe in result:
            cost = _estimate_cost_per_serving(recipe)
            total_time = (recipe.preparation_time or 0) + (recipe.cooking_time or 0)
            print(f"    {meal_type}: {recipe.title} (${cost:.2f}, {total_time}min, {recipe.tags})")

def test_edge_cases():
    """Test edge cases and error handling"""
    print("\n=== Testing Edge Cases ===")
    
    # Empty slots
    result = evolve_plan(slots=[], servings=1, saved_set=set(), focus_on_saved=False)
    print(f"Empty slots: {len(result)} results")
    
    # Slots with no candidates
    empty_slots = [Slot(day=0, meal_type="breakfast", candidates=[])]
    result = evolve_plan(slots=empty_slots, servings=1, saved_set=set(), focus_on_saved=False)
    print(f"No candidates: {len(result)} results")
    
    # Single recipe per slot
    recipes = create_test_recipes()
    single_slots = [Slot(day=0, meal_type="breakfast", candidates=[recipes[0]])]
    result = evolve_plan(slots=single_slots, servings=1, saved_set=set(), focus_on_saved=False)
    print(f"Single candidate: {len(result)} results")
    
    # Very high servings
    result = evolve_plan(
        slots=[Slot(day=0, meal_type="dinner", candidates=recipes[6:8])],
        servings=20,
        saved_set=set(),
        focus_on_saved=False
    )
    print(f"High servings (20): {len(result)} results")

def main():
    """Run all tests"""
    print("GA Solver Test Suite")
    print("=" * 50)
    
    try:
        test_profile_targets()
        test_cost_estimation()
        test_fitness_components()
        test_ga_performance()
        test_option_handling()
        test_edge_cases()
        
        print("\n" + "=" * 50)
        print("All tests completed successfully!")
        
    except Exception as e:
        print(f"\nTest failed with error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()

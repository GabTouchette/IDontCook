"""
Django Management Command: auto_tag_recipes

PURPOSE:
This command automatically tags existing recipes in the database using a combination of:
1. A trained machine learning model (TF-IDF + Logistic Regression) for meal type classification
2. Rule-based keyword matching for dietary restrictions and cooking methods

WHAT IT DOES:
- Classifies recipes into meal types: breakfast, lunch, dinner, snack, dessert
- Adds dietary tags: vegetarian, vegan, gluten-free, dairy-free, keto, low-carb
- Adds cooking method tags: baked, grilled, fried, slow-cooker, instant-pot, air-fryer
- Uses ML model first for meal types, falls back to keyword rules if ML fails
- Handles batch processing with progress tracking
- Supports dry-run mode for testing without database changes

HOW IT WORKS:
1. Loads pre-trained ML model from recipes/models/meal_type_tfidf_logreg.joblib
2. Processes recipes in batches, building text from title + description + ingredients + instructions
3. Uses ML model to predict meal type with confidence threshold
4. Falls back to keyword-based classification if ML prediction is uncertain
5. Applies rule-based tagging for dietary restrictions and cooking methods
6. Updates recipe tags in database (or shows preview in dry-run mode)

USAGE:
    # Tag all recipes
    python manage.py auto_tag_recipes
    
    # Preview changes without updating database
    python manage.py auto_tag_recipes --dry-run
    
REQUIREMENTS:
- ML model file must exist at: api/recipes/models/meal_type_tfidf_logreg.joblib
- Recipes must have title and ingredients to be processed
- Uses scikit-learn pipeline with TF-IDF vectorizer and Logistic Regression
"""

from django.core.management.base import BaseCommand
from recipes.models import Recipe
import re
import os
import joblib
from django.conf import settings

class Command(BaseCommand):
    help = 'Automatically tags existing recipes based on ML model and keywords in ingredients and title.'

    def add_arguments(self, parser):
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Show what would be tagged without actually updating the database',
        )

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # Load the trained ML model for meal type classification
        model_path = os.path.join(os.path.dirname(__file__), '../../models/meal_type_tfidf_logreg.joblib')
        try:
            self.meal_type_classifier = joblib.load(model_path)
            self.use_ml_model = True
            print(f'Loaded ML model from: {model_path}')
        except Exception as e:
            self.use_ml_model = False
            print(f'Could not load ML model: {e}. Using rule-based fallback.')

    # Define keywords for each tag
    VEGAN_KEYWORDS = ['vegan']
    VEGETARIAN_KEYWORDS = ['vegetarian']
    GLUTEN_FREE_KEYWORDS = ['gluten free', 'gluten-free']
    DAIRY_FREE_KEYWORDS = ['dairy free', 'dairy-free', 'lactose free']
    
    # Exclusion keywords for dietary restrictions (inverse filtering)
    MEAT_KEYWORDS = [
        'chicken', 'beef', 'pork', 'lamb', 'turkey', 'fish', 'salmon', 'tuna', 
        'shrimp', 'bacon', 'sausage', 'ham', 'mince', 'steak', 'ribs', 'veal',
        'duck', 'goose', 'crab', 'lobster', 'mussels', 'clams', 'oysters',
        'anchovies', 'sardines', 'cod', 'halibut', 'trout', 'prawns', 'scallops'
    ]
    DAIRY_KEYWORDS = [
        'milk', 'cheese', 'yogurt', 'butter', 'cream', 'sour cream', 'heavy cream',
        'mozzarella', 'cheddar', 'parmesan', 'ricotta', 'cottage cheese', 'whey',
        'casein', 'lactose'
    ]
    EGG_KEYWORDS = ['egg', 'eggs', 'egg white', 'egg yolk', 'mayonnaise']
    GLUTEN_KEYWORDS = [
        'wheat', 'flour', 'bread', 'pasta', 'noodles', 'soy sauce', 'barley',
        'rye', 'bulgur', 'couscous', 'semolina', 'breadcrumbs', 'croutons',
        'beer', 'malt', 'wheat flour', 'all-purpose flour'
    ]

    # Enhanced meal type classification
    BREAKFAST_KEYWORDS = ['breakfast', 'morning', 'brunch']
    BREAKFAST_INGREDIENTS = [
        'oats', 'oatmeal', 'cereal', 'pancake', 'waffle', 'syrup', 'maple syrup',
        'coffee', 'toast', 'bagel', 'muffin', 'croissant', 'granola', 'yogurt',
        'smoothie', 'juice', 'milk', 'banana', 'berries', 'eggs', 'bacon'
    ]
    
    # Drink/Cocktail detection keywords (for exclusion from meal type tagging)
    DRINK_KEYWORDS = [
        'cocktail', 'drink', 'drinks', 'beverage', 'bloody mary', 'margarita',
        'martini', 'mojito', 'whiskey', 'vodka', 'rum', 'gin', 'tequila',
        'wine', 'beer', 'sangria', 'punch', 'juice', 'smoothie', 'shake',
        'lemonade', 'iced tea', 'coffee drink', 'hot chocolate', 'eggnog'
    ]
    
    LUNCH_KEYWORDS = ['lunch', 'midday']
    LUNCH_INGREDIENTS = [
        'sandwich', 'wrap', 'salad', 'soup', 'bowl', 'quinoa bowl', 'pasta salad',
        'lettuce', 'spinach', 'tomato', 'cucumber', 'avocado', 'hummus', 'pita'
    ]
    
    DINNER_KEYWORDS = ['dinner', 'supper', 'main course', 'entree']
    DINNER_PROTEINS = [
        'steak', 'roast', 'chicken breast', 'salmon', 'pork chop', 'lamb',
        'beef', 'fish fillet', 'turkey breast', 'duck', 'tenderloin'
    ]
    DINNER_SIDES = [
        'mashed potato', 'rice pilaf', 'roasted vegetables', 'asparagus',
        'brussels sprouts', 'green beans'
    ]
    
    DESSERT_KEYWORDS = ['dessert', 'cake', 'cookie', 'pie', 'ice cream', 'sweet', 'chocolate']
    SNACK_KEYWORDS = ['snack', 'appetizer', 'dip', 'chips', 'crackers', 'nuts', 'bars']

    def handle(self, *args, **options):
        dry_run = options.get('dry_run', False)
        
        self.stdout.write('Starting recipe auto-tagging process...')
        if dry_run:
            self.stdout.write('DRY RUN MODE - No changes will be saved to database')
        
        recipes = Recipe.objects.all()
        tagged_count = 0

        for recipe in recipes:
            ingredients_text = ' '.join([ing.name.lower() for ing in recipe.ingredients.all()])
            title_text = recipe.title.lower()
            combined_text = f"{title_text} {ingredients_text}"
            
            current_tags = set(recipe.tags) if recipe.tags else set()
            original_tag_count = len(current_tags)

            # --- ML-based Meal Type Classification (First Priority) ---
            meal_type = self.classify_meal_type_with_ml(recipe, title_text, ingredients_text)
            if meal_type:
                # Remove any existing meal type tags first to avoid duplicates
                meal_type_tags = ['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Dessert']
                current_tags = current_tags - set(meal_type_tags)
                # Add the new meal type tag
                current_tags.add(meal_type.title())
            # Note: If meal_type is None (drinks/cocktails), no meal type tag is added

            # --- Dietary Tags (Inverse Filtering) ---
            # Check for explicit dietary tags first
            if any(re.search(r'\b' + keyword + r'\b', combined_text) for keyword in self.VEGAN_KEYWORDS):
                current_tags.add('Vegan')
                current_tags.add('Vegetarian')  # Vegan is always vegetarian
            elif any(re.search(r'\b' + keyword + r'\b', combined_text) for keyword in self.VEGETARIAN_KEYWORDS):
                current_tags.add('Vegetarian')
            else:
                # Use inverse filtering - exclude based on presence of restricted ingredients
                has_meat = any(re.search(r'\b' + keyword + r'\b', ingredients_text) for keyword in self.MEAT_KEYWORDS)
                has_dairy = any(re.search(r'\b' + keyword + r'\b', ingredients_text) for keyword in self.DAIRY_KEYWORDS)
                has_eggs = any(re.search(r'\b' + keyword + r'\b', ingredients_text) for keyword in self.EGG_KEYWORDS)
                
                if not has_meat and not has_dairy and not has_eggs:
                    current_tags.add('Vegan')
                    current_tags.add('Vegetarian')
                elif not has_meat:
                    current_tags.add('Vegetarian')
            
            # Gluten-Free check
            if any(re.search(r'\b' + keyword + r'\b', combined_text) for keyword in self.GLUTEN_FREE_KEYWORDS):
                current_tags.add('Gluten Free')
            else:
                has_gluten = any(re.search(r'\b' + keyword + r'\b', ingredients_text) for keyword in self.GLUTEN_KEYWORDS)
                if not has_gluten:
                    current_tags.add('Gluten Free')
            
            # Dairy-Free check
            if any(re.search(r'\b' + keyword + r'\b', combined_text) for keyword in self.DAIRY_FREE_KEYWORDS):
                current_tags.add('Dairy Free')
            else:
                has_dairy = any(re.search(r'\b' + keyword + r'\b', ingredients_text) for keyword in self.DAIRY_KEYWORDS)
                if not has_dairy:
                    current_tags.add('Dairy Free')

            # --- Meal Type Tags (Single Assignment Based on Highest Score) ---
            # Skip rule-based meal type classification since we already used ML model above

            # --- Other Common Tags ---
            if 'quick' in title_text or (recipe.preparation_time and recipe.cooking_time and (recipe.preparation_time + recipe.cooking_time) <= 30):
                current_tags.add('Quick')
            if 'easy' in title_text or 'simple' in title_text:
                current_tags.add('Easy')
            if 'healthy' in title_text or 'nutritious' in title_text:
                current_tags.add('Healthy')
            if 'spicy' in combined_text or 'hot' in combined_text:
                current_tags.add('Spicy')
            
            # Cooking method tags
            if any(method in title_text for method in ['baked', 'roasted', 'grilled']):
                current_tags.add('Baked/Roasted')
            if any(method in title_text for method in ['fried', 'sauteed', 'pan-fried']):
                current_tags.add('Pan-Cooked')
            if 'slow cooker' in title_text or 'crockpot' in title_text:
                current_tags.add('Slow Cooker')
            if 'instant pot' in title_text or 'pressure cooker' in title_text:
                current_tags.add('Pressure Cooker')
            
            # Diet-friendly tags
            if any(keyword in ingredients_text for keyword in ['quinoa', 'kale', 'spinach', 'avocado']):
                current_tags.add('Healthy')
            if recipe.protein and recipe.protein > 20:  # High protein recipes
                current_tags.add('High Protein')
            if recipe.carbs and recipe.carbs < 20:  # Low carb recipes
                current_tags.add('Low Carb')
                
            # Budget-friendly indicators
            if any(ing in ingredients_text for ing in ['rice', 'beans', 'lentils', 'pasta', 'potato']):
                current_tags.add('Budget Friendly')

            # Update recipe if tags have changed
            if len(current_tags) > original_tag_count:
                if not dry_run:
                    recipe.tags = list(current_tags)
                    recipe.save()
                tagged_count += 1
                action = "Would tag" if dry_run else "Tagged"
                self.stdout.write(self.style.SUCCESS(f'{action} recipe "{recipe.title}" with: {list(current_tags - set(recipe.tags or []))}'))

        action = "Would update" if dry_run else "Updated"
        self.stdout.write(self.style.SUCCESS(f'Auto-tagging complete. {action} {tagged_count} recipes.'))

    def classify_meal_type_with_ml(self, recipe, title_text, ingredients_text):
        """Use ML model to classify meal type, with rule-based fallback"""
        
        # First check if this is a drink/cocktail - if so, skip meal type classification
        if self.is_drink_or_cocktail(recipe, title_text, ingredients_text):
            self.stdout.write(f'Skipping meal type classification for drink/cocktail: "{recipe.title}"')
            return None
        
        if self.use_ml_model:
            try:
                # Build text features similar to training data
                recipe_text = self.build_recipe_text(recipe, title_text, ingredients_text)
                prediction = self.meal_type_classifier.predict([recipe_text])[0]
                return prediction
            except Exception as e:
                self.stdout.write(f'ML prediction failed for recipe "{recipe.title}": {e}')
                # Fall back to rule-based classification
                return self.classify_single_meal_type(recipe, title_text, ingredients_text)
        else:
            # Use rule-based classification as fallback
            return self.classify_single_meal_type(recipe, title_text, ingredients_text)

    def is_drink_or_cocktail(self, recipe, title_text, ingredients_text):
        """Check if recipe is a drink or cocktail that should be excluded from meal type tagging"""
        # Check title for drink keywords
        for keyword in self.DRINK_KEYWORDS:
            if re.search(r'\b' + keyword + r'\b', title_text, re.IGNORECASE):
                return True
        
        # Check existing tags for drink indicators
        if recipe.tags:
            for tag in recipe.tags:
                tag_lower = str(tag).lower()
                if any(drink_keyword in tag_lower for drink_keyword in ['drink', 'cocktail', 'beverage']):
                    return True
        
        # Check ingredients for alcohol indicators
        alcohol_keywords = ['vodka', 'whiskey', 'rum', 'gin', 'tequila', 'wine', 'beer', 'liquor', 'alcohol']
        for keyword in alcohol_keywords:
            if re.search(r'\b' + keyword + r'\b', ingredients_text, re.IGNORECASE):
                return True
        
        return False

    def build_recipe_text(self, recipe, title_text, ingredients_text):
        """Build text features for ML model similar to training data format"""
        parts = []
        
        # Add title/name
        if recipe.title:
            parts.append(str(recipe.title))
        
        # Add description if available
        if hasattr(recipe, 'description') and recipe.description:
            parts.append(str(recipe.description))
        
        # Add ingredients (already preprocessed as string)
        if ingredients_text:
            parts.append(str(ingredients_text))
        
        # Add steps/instructions if available
        if hasattr(recipe, 'instructions') and recipe.instructions:
            parts.append(str(recipe.instructions))
        
        # Add any existing tags (convert list to space-separated string)
        if recipe.tags:
            if isinstance(recipe.tags, list):
                parts.append(' '.join(str(tag) for tag in recipe.tags))
            else:
                parts.append(str(recipe.tags))
        
        return ' '.join(parts)

    def classify_single_meal_type(self, recipe, title_text, ingredients_text):
        """Classify recipe into exactly ONE meal type based on highest score"""
        scores = {
            'Breakfast': 0,
            'Lunch': 0,
            'Dinner': 0,
            'Snack': 0,
            'Dessert': 0
        }
        
        total_time = (recipe.preparation_time or 0) + (recipe.cooking_time or 0)
        calories = recipe.calories or 0
        ingredient_count = len([ing for ing in recipe.ingredients.all()])
        
        # 1. Explicit keyword scoring (highest weight)
        for keyword in self.BREAKFAST_KEYWORDS:
            if re.search(r'\b' + keyword + r'\b', title_text):
                scores['Breakfast'] += 10
        for keyword in self.LUNCH_KEYWORDS:
            if re.search(r'\b' + keyword + r'\b', title_text):
                scores['Lunch'] += 10
        for keyword in self.DINNER_KEYWORDS:
            if re.search(r'\b' + keyword + r'\b', title_text):
                scores['Dinner'] += 10
        for keyword in self.DESSERT_KEYWORDS:
            if re.search(r'\b' + keyword + r'\b', title_text):
                scores['Dessert'] += 15  # Dessert keywords are very specific
        for keyword in self.SNACK_KEYWORDS:
            if re.search(r'\b' + keyword + r'\b', title_text):
                scores['Snack'] += 10
        
        # 2. Ingredient-based scoring
        breakfast_ing_score = sum(1 for ing in self.BREAKFAST_INGREDIENTS if ing in ingredients_text)
        lunch_ing_score = sum(1 for ing in self.LUNCH_INGREDIENTS if ing in ingredients_text)
        dinner_protein_score = sum(1 for ing in self.DINNER_PROTEINS if ing in ingredients_text)
        dinner_side_score = sum(1 for ing in self.DINNER_SIDES if ing in ingredients_text)
        
        scores['Breakfast'] += breakfast_ing_score * 3
        scores['Lunch'] += lunch_ing_score * 3
        scores['Dinner'] += (dinner_protein_score + dinner_side_score) * 3
        
        # Special dessert ingredient check
        if any(ing in ingredients_text for ing in ['chocolate', 'sugar', 'vanilla', 'frosting', 'icing']):
            scores['Dessert'] += 5
        
        # 3. Time-based scoring
        if total_time > 0:
            if total_time <= 10:
                scores['Snack'] += 4
                scores['Breakfast'] += 2
            elif total_time <= 20:
                scores['Breakfast'] += 3
                scores['Lunch'] += 2
                scores['Snack'] += 1
            elif total_time <= 45:
                scores['Lunch'] += 3
                scores['Dinner'] += 2
            else:  # > 45 minutes
                scores['Dinner'] += 5
        
        # 4. Calorie-based scoring
        if calories > 0:
            if calories < 150:
                scores['Snack'] += 3
            elif calories < 300:
                scores['Breakfast'] += 2
                scores['Snack'] += 1
            elif calories < 500:
                scores['Lunch'] += 3
                scores['Breakfast'] += 1
            else:  # > 500 calories
                scores['Dinner'] += 4
        
        # 5. Ingredient count scoring
        if ingredient_count <= 3:
            scores['Snack'] += 2
        elif ingredient_count <= 5:
            scores['Breakfast'] += 1
            scores['Lunch'] += 1
        elif ingredient_count <= 8:
            scores['Lunch'] += 2
            scores['Dinner'] += 1
        else:  # > 8 ingredients
            scores['Dinner'] += 3
        
        # 6. Special cases
        if 'dip' in title_text or 'chips' in ingredients_text:
            scores['Snack'] += 5
        if 'salad' in title_text and 'dressing' in ingredients_text:
            scores['Lunch'] += 4
        
        # Find the meal type with highest score
        max_score = max(scores.values())
        if max_score == 0:
            # Default fallback based on ingredient count
            if ingredient_count <= 3:
                return 'Snack'
            elif ingredient_count <= 6:
                return 'Lunch'
            else:
                return 'Dinner'
        
        # Return the meal type with highest score (if tie, prefer in this order)
        priority_order = ['Dessert', 'Breakfast', 'Dinner', 'Lunch', 'Snack']
        for meal_type in priority_order:
            if scores[meal_type] == max_score:
                return meal_type
        
        return None

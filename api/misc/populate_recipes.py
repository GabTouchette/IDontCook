import os
import re
import django
import csv
from django.contrib.auth.hashers import make_password

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'api.settings')
django.setup()

from accounts.models import CustomUser
from recipes.models import Recipe, Ingredient

allowed_tags_map = {
    "Convenience": [
        "5 Ingredients or Less", "5-Minute Meal", "10-Minute Meal", "30-Minute Meal",
        "Batch Cooking", "Budget-Friendly", "Easy Clean-Up", "Meal Prep",
        "Quick", "Under 1 Hour"
    ],
    "Cooking Methods": [
        "Air Fryer", "Baked", "Grilled", "Instant Pot", "No Cook", "One-Pot",
        "Raw", "Sheet Pan Meal", "Slow Cooker"
    ],
    "Cuisine & Style": [
        "Comfort Food", "Exotic", "Farm-to-Table", "Fusion", "Gourmet",
        "International Cuisine", "Luxury", "Street Food", "Traditional"
    ],
    "Dietary Preferences": [
        "Dairy-Free", "Diabetes-Friendly", "Gluten-Free", "High Fiber",
        "High Protein", "Keto", "Low Carb", "Low Fat", "Nut-Free", "Organic",
        "Paleo", "Sugar-Free", "Vegan", "Vegetarian", "Whole30", "GMO-Free"
    ],
    "Ethnic Cuisines": [
        "African", "American", "Asian", "Caribbean", "Chinese", "Ethiopian",
        "French", "Greek", "Indian", "Italian", "Japanese", "Korean",
        "Latin American", "Mediterranean", "Mexican", "Middle Eastern",
        "Moroccan", "Southern", "Spanish", "Thai", "Vietnamese", "Hawaiian"
    ],
    "Food Categories": [
        "Burger", "Burrito", "Casserole", "Curry", "Pizza", "Pasta",
        "Rice Dish", "Salad", "Sandwich", "Soup", "Stir-Fry", "Stew",
        "Sushi", "Taco", "Wrap"
    ],
    "Health Benefits": [
        "Anti-Inflammatory", "Brain-Boosting", "Energy-Boosting", "Gut Health",
        "Heart Healthy", "Immune-Boosting", "Mood-Boosting", "Post-Workout",
        "Pre-Workout", "Skin-Glowing"
    ],
    "Lifestyle & Audience": [
        "Athlete-Friendly", "Bodybuilding", "Detox", "Elderly-Friendly",
        "Kid-Friendly", "Pregnancy-Safe", "Toddler-Friendly", "Weight Gain",
        "Weight Loss", "Juicing"
    ],
    "Meal Types": [
        "Appetizer", "Beverage", "Brunch", "Cocktail", "Dessert", "Dinner",
        "Lunch", "Mocktail", "Snack", "Smoothie", "Breakfast"
    ],
    "Special Occasions": [
        "BBQ", "Holiday", "Picnic", "Seasonal"
    ],
}

# Flatten and create lowercase set for matching
all_allowed_tags_lower = {
    tag.lower() for tags in allowed_tags_map.values() for tag in tags
}

# Optional: map lowercase to original tag casing to restore proper casing
lower_to_proper_tag = {}
for tags in allowed_tags_map.values():
    for tag in tags:
        lower_to_proper_tag[tag.lower()] = tag



def parse_ingredient(ingredient_str):
    """Extracts quantity and name from an ingredient string."""
    ingredient_str = ingredient_str.strip()

    # Remove metric measurements in parentheses (e.g., "(90 ml)") without affecting the rest of the string
    ingredient_str = re.sub(r'\([^)]*\)', '', ingredient_str).strip()

    # Dictionary to map Unicode fraction symbols to their float values
    fraction_to_float = {
        '½': 0.5,
        '⅓': 1/3,
        '⅔': 2/3,
        '¼': 0.25,
        '¾': 0.75,
        '⅕': 0.2,
        '⅖': 0.4,
        '⅗': 0.6,
        '⅘': 0.8,
        '⅙': 1/6,
        '⅚': 5/6,
        '⅐': 1/7,
        '⅛': 0.125,
        '⅜': 0.375,
        '⅝': 0.625,
        '⅞': 0.875,
        '⅑': 1/9,
        '⅒': 0.1,
    }

    # Replace Unicode fractions with their float equivalents
    for symbol, value in fraction_to_float.items():
        ingredient_str = ingredient_str.replace(symbol, f' {str(value)} ')

    # Replace commas with periods for decimal numbers (e.g., "2,2" -> "2.2")
    # Only replace commas in numeric parts
    parts = ingredient_str.split()
    for i, part in enumerate(parts):
        if part.replace(',', '', 1).replace('.', '', 1).isdigit():
            parts[i] = part.replace(',', '.')
    ingredient_str = ' '.join(parts)

    # Split into parts
    parts = ingredient_str.split()

    # Initialize quantity and name
    quantity = None
    name = None

    # Extract quantity
    if parts:
        # Handle mixed numbers with Unicode fractions (e.g., "1 ½" -> "1.5")
        if len(parts) >= 2 and parts[1].replace('.', '', 1).isdigit():
            try:
                quantity = float(parts[0]) + float(parts[1])
                parts = parts[2:]  # Remove the processed parts
            except ValueError:
                pass
        # Handle fractions (e.g., "1/2" or "1/3")
        elif '/' in parts[0]:
            try:
                numerator, denominator = parts[0].split('/')
                quantity = float(numerator) / float(denominator)
                parts = parts[1:]  # Remove the processed part
            except (ValueError, IndexError):
                pass
        # Handle mixed numbers (e.g., "1 1/2" or "2 ½")
        elif len(parts) >= 2 and '/' in parts[1]:
            try:
                whole = float(parts[0])
                numerator, denominator = parts[1].split('/')
                fraction = float(numerator) / float(denominator)
                quantity = whole + fraction
                parts = parts[2:]  # Remove the processed parts
            except (ValueError, IndexError):
                pass
        elif len(parts) >= 2 and parts[1].replace('.', '', 1).isdigit():
            # Handle cases like "2.2 lb" or "1.5 tbsp"
            try:
                quantity = float(parts[0])
                parts = parts[1:]  # Remove the processed part
            except ValueError:
                pass
        elif parts[0].replace('.', '', 1).replace(',', '', 1).isdigit():
            # Handle simple numbers (e.g., "2", "1.5", "2,2")
            try:
                quantity = float(parts[0])
                parts = parts[1:]  # Remove the processed part
            except ValueError:
                pass

    # Extract name (everything else)
    if parts:
        name = ' '.join(parts)

    return name, quantity

def parse_time_to_minutes(time_str):
    """Convert a time string in PT format to minutes."""
    if not time_str or time_str == 'NA':
        return None
    hours = minutes = 0
    time_components = time_str[2:].split('H')  # Split on 'H' to get hours and remaining minutes

    if len(time_components) == 2:  # If there are both hours and minutes
        hours = int(time_components[0])
        minutes = int(time_components[1].rstrip('M')) if 'M' in time_components[1] else 0
    elif 'H' in time_str:  # If there's only hours
        hours = int(time_components[0])
    elif 'M' in time_str:  # If there's only minutes
        minutes = int(time_components[0].rstrip('M'))

    return hours * 60 + minutes  # Convert hours to minutes and add minutes


def load_recipes_from_csv(csv_file, created_user, max_recipe_count=1000):
    """Load recipes from a CSV file and format data properly."""

    with open(csv_file, newline='', encoding='utf-8') as file:
        reader = csv.DictReader(file)
        recipe_count = 0
        for row in reader:
            try:
                if recipe_count >= max_recipe_count:
                    print("Reached maximum limit of recipes.")
                    break

                # Parse ingredients
                ingredients_str = row['recipeIngredients'].split(";")
                ingredients = []
                for ingredient_str in ingredients_str:
                    name, quantity = parse_ingredient(ingredient_str)
                    ingredient, _ = Ingredient.objects.get_or_create(name=name)
                    if quantity:
                        ingredient.quantity = quantity
                    ingredient.save()
                    ingredients.append(ingredient)

                # Parse instructions
                instructions = row['recipeInstructions'].split(";")

                # Parse and filter tags (case-insensitive)
                tag_names = [tag for tag in row['tags'].split(";")] if row['tags'] else []
                filtered_tags = []
                for tag in tag_names:
                    name = tag.split('_')[-1]
                    formatted_name = ' '.join(word.capitalize() for word in name.split('-')).capitalize()
                    if formatted_name.lower() in all_allowed_tags_lower:
                        proper_cased_tag = lower_to_proper_tag.get(formatted_name.lower(), formatted_name)
                        filtered_tags.append(proper_cased_tag)

                # Parse servings (safe)
                match = re.search(r'\d+(\.\d+)?', row['recipeYield']) if row['recipeYield'] and row['recipeYield'] != 'NA' else None
                servings = float(match.group()) if match else None

                # Create the recipe
                recipe = Recipe.objects.create(
                    title=row['title'],
                    instructions=instructions,
                    tags=filtered_tags,
                    cooking_time=parse_time_to_minutes(row['cookTime']),
                    preparation_time=parse_time_to_minutes(row['prepTime']),
                    servings=servings,
                    created_by=created_user,
                    description=row['description'],
                    web_image_url=row['image'] if row['image'] else None,
                )

                recipe.ingredients.set(ingredients)

            except Exception as e:
                print(f"Error processing recipe '{row['title']}': {e}")
                continue

            recipe_count += 1


def main():
    print("Creating recipes...")

    # Create a fake user for recipe creation
    user, created = CustomUser.objects.get_or_create(
        username='recipe_scraper',
        defaults={'password': make_password('password123')},
    )

    # Load recipes from CSV
    load_recipes_from_csv('allrecipes.csv', created_user=user)

    print("Recipe creation complete!")

if __name__ == "__main__":
    main()
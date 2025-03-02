import os
import re
import django
import random
import csv
from faker import Faker
from django.contrib.auth.hashers import make_password
import json
import ast

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'api.settings')
django.setup()

from recipes.models import Recipe, Ingredient
from social.models import Post, Comment, Like, Vote, Follow
from accounts.models import CustomUser

fake = Faker()

def get_random_avatar_icon():
    icons = [
        'burger', 'pizza', 'apple', 'iceCream', 'carrot', 'fish', 
        'lemon', 'coffee', 'cake', 'hotdog'
    ]
    return random.choice(icons)

def create_mock_users(num_users=100):
    """Create mock users with unique usernames."""
    users = []
    for _ in range(num_users):
        while True:
            username = fake.user_name()
            if not CustomUser.objects.filter(username=username).exists():
                break  # Found a unique username

        email = fake.unique.email()  # Ensures unique emails
        password = make_password("password123")  # Hash the password
        avatar_icon = get_random_avatar_icon()
        
        user = CustomUser.objects.create(
            username=username,
            email=email,
            password=password,
            avatar_icon=avatar_icon
        )
        users.append(user)

    return users

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


def clean_r_vector_format(r_vector):
    """Convert R-style c(...) format to Python list format."""
    if r_vector == 'character(0)':
        return []

    # Replace R-style 'c(...)' with Python-style '[...]' and handle NA values
    r_vector = r_vector.replace('c(', '[').replace(')', ']')
    r_vector = r_vector.replace('NA', 'None')

    try:
        parsed_value = ast.literal_eval(r_vector)

        # Ensure it's a list of strings
        if isinstance(parsed_value, list) and all(isinstance(item, str) for item in parsed_value):
            return parsed_value
        else:
            return None  # Return None if it's not a list of strings

    except (SyntaxError, ValueError):
        return None  # Return None if parsing fails


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


def load_recipes_from_csv(csv_file, max_recipe_count=1000):
    """Load recipes from a CSV file and format data properly."""
    
    with open(csv_file, newline='', encoding='utf-8') as file:
        reader = csv.DictReader(file)
        recipe_count = 0
        for row in reader:  # Iterate through all rows in the CSV
            try:
                if recipe_count >= max_recipe_count:  # Check if max recipes limit reached
                    print("Reached maximum limit of recipes.")
                    break 

                # Parse ingredients: Split the string and parse each one
                ingredients_str = row['recipeIngredients'].split(";")
                ingredients = []
                
                for ingredient_str in ingredients_str:
                    name, quantity = parse_ingredient(ingredient_str)
                    ingredient, created = Ingredient.objects.get_or_create(name=name)
                    if quantity:
                        ingredient.quantity = quantity
                    ingredient.save()
                    ingredients.append(ingredient)

                # Extract instructions and tags
                instructions = row['recipeInstructions'].split(";")
                tag_names = [tag for tag in row['tags'].split(";")] if row['tags'] else []
                tags = []
                for tag in tag_names:
                    name = tag.split('_')[-1]
                    formatted_name = ' '.join(word.capitalize() for word in name.split('-')).capitalize()
                    tags.append(formatted_name)

                # Create the recipe
                recipe = Recipe.objects.create(
                    title=row['title'],
                    instructions=instructions,
                    tags=tags,
                    cooking_time=parse_time_to_minutes(row['cookTime']),
                    preparation_time=parse_time_to_minutes(row['prepTime']),                
                    servings=int(row['recipeYield'].split()[0]) if row['recipeYield'] and row['recipeYield'] != 'NA' else None,
                    description=row['description'],
                    web_image_url=row['image'] if row['image'] else None,
                )
                

                # Add ingredients to the recipe
                recipe.ingredients.set(ingredients)

            except Exception as e:
                print(f"Error processing recipe {row['title']}: {e}")
                continue
            
            recipe_count += 1


def create_mock_posts(num_posts=200, users=None, recipes=None):
    """Create mock posts."""
    for _ in range(num_posts):
        user = random.choice(users)
        recipe = random.choice(recipes)
        post = Post.objects.create(
            user=user,
            recipe=recipe,
            content=fake.text(max_nb_chars=200),
        )

        # Create mock comments (random 0-5 comments per post)
        for _ in range(random.randint(0, 5)):
            Comment.objects.create(
                user=random.choice(users),
                post=post,
                content=fake.text(max_nb_chars=100)
            )

        # Create mock likes (random 0-10 likes per post)
        for _ in range(random.randint(0, 10)):
            Like.objects.create(
                user=random.choice(users),
                post=post
            )

        # Create mock votes (random upvotes or downvotes)
        # Ensure each user only votes once per post
        voters = random.sample(users, k=random.randint(0, 5))  # Randomly select up to 5 unique users
        for voter in voters:
            Vote.objects.create(
                user=voter,
                post=post,
                value=random.choice([1, -1])  # Random upvote or downvote
            )

def create_mock_follows(users=None):
    """Create mock follows."""
    for user in users:
        # Each user follows 5-15 other users
        num_follows = random.randint(5, 15)
        for _ in range(num_follows):
            followed_user = random.choice(users)
            if followed_user != user:  # Ensure a user doesn't follow themselves
                Follow.objects.get_or_create(
                    follower=user,
                    followed=followed_user
                )

def create_mock_saves(users=None, recipes=None):
    """Create mock saves by duplicating recipes for users."""
    for user in users:
        # Each user saves 5-10 recipes
        num_saves = random.randint(5, 10)
        for _ in range(num_saves):
            original_recipe = random.choice(recipes)

            # Ensure the user is not saving their own recipe
            if original_recipe.created_by == user:
                continue

            cloned_recipe = Recipe.objects.create(
                created_by=user,
                title=original_recipe.title,
                description=original_recipe.description,
                instructions=original_recipe.instructions,
                parent=original_recipe  # Track original recipe
            )

            # Copy ingredients (if applicable)
            cloned_recipe.ingredients.set(original_recipe.ingredients.all())

def main():
    print("Creating mock data...")

    # Create mock users
    # users = create_mock_users(num_users=100)
    # print(f"Created {len(users)} users.")
    
    # Load recipes from CSV
    # load_recipes_from_csv('api/recipes.csv')
    print("Created recipes.")
    # Load the recipes CSV file
    import pandas as pd
    df = pd.read_csv('recipes.csv')

    # Select 1000 random rows
    random_sample = df.sample(n=1000, random_state=42)

    # Save the random sample to a new CSV
    random_sample.to_csv('random_recipes.csv', index=False)

    # # Create mock posts, comments, likes, and votes
    # recipes = Recipe.objects.all()
    # create_mock_posts(num_posts=200, users=users, recipes=recipes)
    # print("Created posts, comments, likes, and votes.")

    # # Create mock follows
    # create_mock_follows(users=users)
    # print("Created follows.")

    # # Create mock saves
    # create_mock_saves(users=users, recipes=recipes)
    # print("Created saves.")

    # print("Mock data creation complete!")

if __name__ == "__main__":
    main()
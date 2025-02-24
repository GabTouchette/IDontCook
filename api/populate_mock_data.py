import os
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
    """Extracts quantity, unit, and name from an ingredient string."""
    ingredient_str = ingredient_str.strip()
    
    # Check for a numeric value at the beginning
    parts = ingredient_str.split(" ", 2)  # Try to split into three parts: quantity, unit, name
    if len(parts) == 3 and parts[0].replace(".", "", 1).isdigit():
        quantity = float(parts[0])
        unit = parts[1]
        name = parts[2]
    else:
        quantity, unit, name = None, None, ingredient_str  # Default case: Just the name
    
    return name, quantity, unit


def clean_r_vector_format(r_vector):
    """Convert R-style c(...) format to Python list format."""
    if r_vector == 'character(0)':
        return []
    # Replace R-style 'c(...)' with Python-style '[...]' and handle NA values
    r_vector = r_vector.replace('c(', '[').replace(')', ']')
    r_vector = r_vector.replace('NA', 'None')
    return ast.literal_eval(r_vector)


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


def load_recipes_from_csv(csv_file, users):
    """Load recipes from a CSV file and format data properly."""
    with open(csv_file, newline='', encoding='utf-8') as file:
        reader = csv.DictReader(file)
        recipe_count = 0
        for row in reader:  # Iterate through all rows in the CSV
            try:
                if recipe_count >= 10000:  # Check if max recipes limit reached
                    print("Reached maximum limit of 10,000 recipes.")
                    break 
                recipe_count += 1

                raw_quantities = clean_r_vector_format(row['RecipeIngredientQuantities'])
                raw_parts = clean_r_vector_format(row['RecipeIngredientParts'])

                if raw_quantities is None or raw_parts is None:
                        print(f"Skipping recipe due to missing ingredients for row: {row}")
                        continue  # Skip this recipe
                
                ingredients = []
                
                for quantity, part in zip(raw_quantities, raw_parts):
                    ingredient, created = Ingredient.objects.get_or_create(name=part)
                    unit_of_measure = "part(s)"
                    ingredient.quantity = float(quantity) if quantity and quantity != 'NA' else 1
                    ingredient.unit_of_measure = unit_of_measure
                    ingredient.save()
                    ingredients.append(ingredient)


                # Extract instructions
                instructions = clean_r_vector_format(row['RecipeInstructions'])

                # Create the recipe
                recipe = Recipe.objects.create(
                    title=row['Name'],
                    instructions=instructions,
                    cooking_time=parse_time_to_minutes(row['CookTime']),
                    preparation_time=parse_time_to_minutes(row['PrepTime']),                
                    servings=int(row['RecipeServings']) if row['RecipeServings'] and row['RecipeServings'] != 'NA' else None,
                    tags=clean_r_vector_format(row['Keywords']),
                    description=row['Description'],
                    calories=float(row['Calories']) if row['Calories'] else None,
                    fat_content=float(row['FatContent']) if row['FatContent'] else None,
                    saturated_fat_content=float(row['SaturatedFatContent']) if row['SaturatedFatContent'] else None,
                    cholesterol_content=float(row['CholesterolContent']) if row['CholesterolContent'] else None,
                    sodium_content=float(row['SodiumContent']) if row['SodiumContent'] else None,
                    carbohydrate_content=float(row['CarbohydrateContent']) if row['CarbohydrateContent'] else None,
                    fiber_content=float(row['FiberContent']) if row['FiberContent'] else None,
                    sugar_content=float(row['SugarContent']) if row['SugarContent'] else None,
                    protein_content=float(row['ProteinContent']) if row['ProteinContent'] else None,
                    recipe_yield=row['RecipeYield'],
                    # created_by=random.choice(users),
                    image=None
                )

                # Add ingredients to the recipe
                recipe.ingredients.set(ingredients)

            except Exception:
                continue



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
    load_recipes_from_csv('recipes.csv', [])
    print("Created 10000 recipes.")

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

    print("Mock data creation complete!")

if __name__ == "__main__":
    main()
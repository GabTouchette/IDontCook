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

from recipes.models import Recipe, Ingredient, Save
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
    """Create mock users."""
    users = []
    for _ in range(num_users):
        username = fake.user_name()
        email = fake.email()
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

def load_recipes_from_csv(csv_file, users):
    """Load recipes from a CSV file and format data properly."""
    with open(csv_file, newline='', encoding='utf-8') as file:
        reader = csv.DictReader(file)
        for row in reader:
            # Extract ingredients (stored as a string list in the CSV)
            raw_ingredients = ast.literal_eval(row['ingredients'])  # Convert string list to actual list
            ingredients = []
            for ingredient_str in raw_ingredients:
                name, quantity, unit = parse_ingredient(ingredient_str)
                
                # Always create a new ingredient
                ingredient = Ingredient.objects.create(
                    name=name,
                    quantity=quantity,
                    unit_of_measure=unit
                )
                ingredients.append(ingredient)
            
            # Extract instructions
            instructions = ast.literal_eval(row['directions'])  # Convert string list to actual list
            
            # Create the recipe
            recipe = Recipe.objects.create(
                title=row['title'],
                instructions=instructions,  # Store as JSON
                cooking_time=random.randint(10, 60),  
                preparation_time=random.randint(5, 30),  
                servings=random.randint(1, 6),  
                tags=ast.literal_eval(row['NER']),  # Convert tag list from string to actual list
                description="Generated from dataset",
                image_url=None,  # Set later if needed
                created_by=random.choice(users)
            )

            # Add ingredients to the recipe
            recipe.ingredients.set(ingredients)


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
    """Create mock saves."""
    for user in users:
        # Each user saves 5-10 recipes
        num_saves = random.randint(5, 10)
        for _ in range(num_saves):
            recipe = random.choice(recipes)
            Save.objects.get_or_create(
                user=user,
                recipe=recipe
            )

def main():
    print("Creating mock data...")

    # Create mock users
    users = create_mock_users(num_users=100)
    print(f"Created {len(users)} users.")

    # Load recipes from CSV
    load_recipes_from_csv('recipes_data_truncated.csv', users)
    print("Loaded recipes from CSV.")

    # Create mock posts, comments, likes, and votes
    recipes = Recipe.objects.all()
    create_mock_posts(num_posts=200, users=users, recipes=recipes)
    print("Created posts, comments, likes, and votes.")

    # Create mock follows
    create_mock_follows(users=users)
    print("Created follows.")

    # Create mock saves
    create_mock_saves(users=users, recipes=recipes)
    print("Created saves.")

    print("Mock data creation complete!")

if __name__ == "__main__":
    main()
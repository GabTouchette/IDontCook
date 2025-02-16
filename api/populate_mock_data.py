import os
import django
import random
from faker import Faker
from django.contrib.auth.hashers import make_password

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

def create_mock_ingredients():
    """Create mock ingredients."""
    ingredients = [
        Ingredient.objects.create(name="Tomato", quantity="2", unit_of_measure="pieces"),
        Ingredient.objects.create(name="Cheese", quantity="100", unit_of_measure="grams"),
        Ingredient.objects.create(name="Olive Oil", quantity="50", unit_of_measure="ml"),
        Ingredient.objects.create(name="Basil", quantity="10", unit_of_measure="leaves"),
        Ingredient.objects.create(name="Garlic", quantity="2", unit_of_measure="cloves"),
    ]
    return ingredients

def create_mock_recipes(num_recipes=100, users=None, ingredients=None):
    """Create mock recipes."""
    recipes = []
    for _ in range(num_recipes):
        recipe = Recipe.objects.create(
            title=fake.sentence(nb_words=4),
            description=fake.paragraph(nb_sentences=3),
            cooking_time=random.randint(10, 60),
            preparation_time=random.randint(5, 30),
            created_by=random.choice(users)
        )
        recipe.ingredients.set(ingredients)
        recipes.append(recipe)
    return recipes

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

    # Create mock ingredients
    ingredients = create_mock_ingredients()
    print(f"Created {len(ingredients)} ingredients.")

    # Create mock recipes
    recipes = create_mock_recipes(num_recipes=100, users=users, ingredients=ingredients)
    print(f"Created {len(recipes)} recipes.")

    # Create mock posts, comments, likes, and votes
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
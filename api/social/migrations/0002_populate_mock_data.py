from django.db import migrations
from recipes.models import Recipe, Ingredient
from social.models import Post, Comment, Like, Vote, Follow
from faker import Faker
from accounts.models import CustomUser
import random

fake = Faker()

def populate_mock_data(apps, schema_editor):
    User = CustomUser
    
    def get_random_avatar_icon():
        icons = [
            'burger', 'pizza', 'apple', 'iceCream', 'carrot', 'fish', 
            'lemon', 'coffee', 'cake', 'hotdog'
        ]
        return random.choice(icons)

    # Create 100 mock users
    users = []
    for _ in range(100):
        username = fake.user_name()
        email = fake.email()
        password = "password123"
        avatar_icon = get_random_avatar_icon()
        user = User.objects.create_user(username=username, email=email, password=password, avatar_icon=avatar_icon)
        users.append(user)

    # Create mock ingredients
    ingredient1 = Ingredient.objects.create(name="Tomato", quantity="2", unit_of_measure="pieces")
    ingredient2 = Ingredient.objects.create(name="Cheese", quantity="100", unit_of_measure="grams")
    ingredient3 = Ingredient.objects.create(name="Olive Oil", quantity="50", unit_of_measure="ml")
    ingredient4 = Ingredient.objects.create(name="Basil", quantity="10", unit_of_measure="leaves")
    ingredient5 = Ingredient.objects.create(name="Garlic", quantity="2", unit_of_measure="cloves")

    # Create mock recipes (100 recipes)
    recipes = []
    for _ in range(100):
        recipe = Recipe.objects.create(
            title=fake.sentence(nb_words=4),
            description=fake.paragraph(nb_sentences=3),
            cooking_time=random.randint(10, 60),
            preparation_time=random.randint(5, 30),
            created_by=random.choice(users)
        )
        recipe.ingredients.set([ingredient1, ingredient2, ingredient3, ingredient4, ingredient5])
        recipes.append(recipe)

    # Create 200 mock posts
    for _ in range(200):
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
        Vote.objects.create(
            user=random.choice(users),
            post=post,
            value=random.choice([1, -1])  # Random upvote or downvote
        )


def reverse_populate_mock_data(apps, schema_editor):
    CustomUser.objects.all().delete()
    Ingredient.objects.all().delete()
    Recipe.objects.all().delete()
    Post.objects.all().delete()
    Comment.objects.all().delete()
    Like.objects.all().delete()
    Vote.objects.all().delete()
    Follow.objects.all().delete()

class Migration(migrations.Migration):

    dependencies = [
        ('social', '0001_initial'),
    ]

    operations = [
        migrations.RunPython(populate_mock_data, reverse_code=reverse_populate_mock_data),
    ]

# Generated manually for adding RecipeIngredient and IngredientValidationLog models

from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('recipes', '0009_recipe_is_formatted'),
    ]

    operations = [
        migrations.CreateModel(
            name='RecipeIngredient',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('quantity', models.FloatField(blank=True, null=True)),
                ('unit', models.CharField(blank=True, max_length=50, null=True)),
                ('order', models.PositiveIntegerField(default=0)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('ingredient', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='recipe_uses', to='recipes.ingredient')),
                ('recipe', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='recipe_ingredients', to='recipes.recipe')),
            ],
            options={
                'ordering': ['order'],
            },
        ),
        migrations.CreateModel(
            name='IngredientValidationLog',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('ingredient_name', models.CharField(db_index=True, max_length=255)),
                ('validation_type', models.CharField(choices=[('confirm', 'Confirmed Correct'), ('correct', 'User Correction'), ('reject', 'Rejected as Incorrect'), ('flag', 'Flagged for Review')], default='confirm', max_length=50)),
                ('original_nutrition', models.JSONField(blank=True, null=True)),
                ('corrected_nutrition', models.JSONField(blank=True, null=True)),
                ('confidence_score', models.FloatField(default=0.0)),
                ('feedback', models.TextField(blank=True)),
                ('ip_address', models.GenericIPAddressField(blank=True, null=True)),
                ('user_agent', models.TextField(blank=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('user', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'ordering': ['-created_at'],
            },
        ),
        migrations.AlterUniqueTogether(
            name='recipeingredient',
            unique_together={('recipe', 'ingredient', 'order')},
        ),
        migrations.AddIndex(
            model_name='ingredientvalidationlog',
            index=models.Index(fields=['ingredient_name', 'created_at'], name='recipes_ing_ingredi_b5e8f7_idx'),
        ),
        migrations.AddIndex(
            model_name='ingredientvalidationlog',
            index=models.Index(fields=['validation_type', 'created_at'], name='recipes_ing_validat_e8a9c2_idx'),
        ),
    ]
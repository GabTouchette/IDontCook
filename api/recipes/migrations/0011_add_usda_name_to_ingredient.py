# Generated manually for usda_name field addition

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('recipes', '0010_add_recipe_ingredient_and_validation_log'),
    ]

    operations = [
        migrations.AddField(
            model_name='ingredient',
            name='usda_name',
            field=models.CharField(blank=True, max_length=255, null=True),
        ),
    ]
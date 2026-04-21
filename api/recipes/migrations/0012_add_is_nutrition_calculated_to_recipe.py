# Generated manually for is_nutrition_calculated field addition

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('recipes', '0011_add_usda_name_to_ingredient'),
    ]

    operations = [
        migrations.AddField(
            model_name='recipe',
            name='is_nutrition_calculated',
            field=models.BooleanField(default=False),
        ),
    ]
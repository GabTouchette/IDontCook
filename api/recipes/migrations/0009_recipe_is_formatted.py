# Generated migration for is_formatted field

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('recipes', '0008_ingredientdensity'),
    ]

    operations = [
        migrations.AddField(
            model_name='recipe',
            name='is_formatted',
            field=models.BooleanField(default=False),
        ),
    ]
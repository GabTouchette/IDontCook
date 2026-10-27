# No-op migration.
#
# `is_formatted` is already added by 0006_recipe_is_formatted. This migration
# was a duplicate AddField that broke fresh databases with
# "column is_formatted already exists". Its operations are intentionally empty:
# the node is kept because 0010 depends on it, but it performs no database or
# state changes.

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('recipes', '0008_ingredientdensity'),
    ]

    operations = []

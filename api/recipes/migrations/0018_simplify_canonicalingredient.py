from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("recipes", "0017_rename_recipes_canon_name_en_idx_recipes_can_canonic_8777cf_idx_and_more"),
    ]

    operations = [
        migrations.RemoveField(
            model_name="canonicalingredient",
            name="aliases_en",
        ),
        migrations.RemoveField(
            model_name="canonicalingredient",
            name="aliases_fr",
        ),
        migrations.RemoveField(
            model_name="canonicalingredient",
            name="default_unit_class",
        ),
        migrations.RemoveField(
            model_name="canonicalingredient",
            name="default_unit_label",
        ),
        migrations.RemoveField(
            model_name="canonicalingredient",
            name="density_g_per_ml",
        ),
        migrations.RemoveField(
            model_name="canonicalingredient",
            name="usda_fdc_id",
        ),
        migrations.RemoveField(
            model_name="canonicalingredient",
            name="nutrition_data",
        ),
        migrations.AlterField(
            model_name="canonicalingredient",
            name="category",
            field=models.CharField(blank=True, max_length=2, null=True),
        ),
    ]

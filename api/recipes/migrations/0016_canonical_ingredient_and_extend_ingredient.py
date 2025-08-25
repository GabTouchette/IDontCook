from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('recipes', '0015_alter_recipe_web_image_url'),
    ]

    operations = [
        migrations.CreateModel(
            name='CanonicalIngredient',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('canonical_name_en', models.CharField(db_index=True, max_length=255)),
                ('canonical_name_fr', models.CharField(blank=True, max_length=255, null=True)),
                ('aliases_en', models.JSONField(blank=True, default=list, null=True)),
                ('aliases_fr', models.JSONField(blank=True, default=list, null=True)),
                ('category', models.CharField(blank=True, max_length=100, null=True)),
                ('default_unit_class', models.CharField(blank=True, max_length=16, null=True)),
                ('default_unit_label', models.CharField(blank=True, max_length=50, null=True)),
                ('density_g_per_ml', models.FloatField(blank=True, null=True)),
                ('usda_fdc_id', models.CharField(blank=True, max_length=50, null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('nutrition_data', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, to='recipes.nutritiondata')),
            ],
        ),
        migrations.AddIndex(
            model_name='canonicalingredient',
            index=models.Index(fields=['canonical_name_en'], name='recipes_canon_name_en_idx'),
        ),
        migrations.AddField(
            model_name='ingredient',
            name='language',
            field=models.CharField(blank=True, max_length=8, null=True),
        ),
        migrations.AddField(
            model_name='ingredient',
            name='normalized_name',
            field=models.CharField(blank=True, db_index=True, max_length=255, null=True),
        ),
        migrations.AddField(
            model_name='ingredient',
            name='category',
            field=models.CharField(blank=True, max_length=100, null=True),
        ),
        migrations.AddField(
            model_name='ingredient',
            name='match_confidence',
            field=models.FloatField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='ingredient',
            name='canonical',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='ingredients', to='recipes.canonicalingredient'),
        ),
    ]

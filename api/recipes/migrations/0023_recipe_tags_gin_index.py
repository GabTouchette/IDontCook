from django.db import migrations


# GIN index on the `tags` JSONField to support `tags__contains` (@>) lookups used
# by the home theme rail and discovery filters. GIN is Postgres-only, so this is
# applied via raw SQL guarded on connection.vendor — running it as a normal
# AddIndex(GinIndex(...)) would raise NotSupportedError on the sqlite dev/test DB.
# It is intentionally not reflected in model state (Meta.indexes); it is a pure
# database-level optimization.

CREATE_SQL = (
    "CREATE INDEX IF NOT EXISTS recipe_tags_gin "
    "ON recipes_recipe USING gin (tags jsonb_path_ops)"
)
DROP_SQL = "DROP INDEX IF EXISTS recipe_tags_gin"


def add_gin_index(apps, schema_editor):
    if schema_editor.connection.vendor != "postgresql":
        return
    schema_editor.execute(CREATE_SQL)


def drop_gin_index(apps, schema_editor):
    if schema_editor.connection.vendor != "postgresql":
        return
    schema_editor.execute(DROP_SQL)


class Migration(migrations.Migration):

    dependencies = [
        ("recipes", "0022_recipe_recipe_created_at_idx_and_more"),
    ]

    operations = [
        migrations.RunPython(add_gin_index, drop_gin_index),
    ]

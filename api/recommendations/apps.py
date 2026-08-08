import logging

from django.apps import AppConfig

logger = logging.getLogger(__name__)


class RecommendationsConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'recommendations'

    def ready(self):
        from django.db.models.signals import post_save

        # Local import: recipes app must already be loaded by the time this
        # app's ready() runs, which Django guarantees for INSTALLED_APPS.
        from recipes.models import Recipe

        post_save.connect(
            _on_recipe_saved,
            sender=Recipe,
            dispatch_uid='recommendations_recompute_recipe_vector',
        )


def _on_recipe_saved(sender, instance, **kwargs):
    """
    Keep RecipeVector in sync whenever a Recipe is created/updated.

    Deliberately synchronous (in-process), not the Celery-with-thread-fallback
    pattern used for `format_recipe_ingredients` (see recipes/tasks.py +
    recipes/views.py): this signal fires on *every* Recipe save across the
    whole app (including other apps' tests/fixtures/migrations), so:
      - Dispatching via `.delay()` is non-deterministic here — if a broker
        happens to be reachable (e.g. a developer's local Redis) the task is
        merely enqueued and nothing consumes it in-process, silently leaving
        the vector stale until a worker picks it up (or forever in tests,
        where no worker runs at all).
      - A background thread opening its own DB connection while the caller
        may be inside an atomic transaction (e.g. Django TestCase) risks
        flaky "database is locked" behavior on sqlite.
    Computing one recipe's TF-IDF vector is cheap (a single document
    transform + upsert), so running it inline is simple and deterministic.
    `recommendations.tasks.compute_recipe_vector` remains available as an
    actual Celery task for callers that want to dispatch it asynchronously
    themselves (e.g. a future bulk-reindex trigger).
    """
    from recommendations.tasks import _compute_recipe_vector_sync

    try:
        _compute_recipe_vector_sync(instance.id)
    except Exception:
        logger.exception("Failed to recompute RecipeVector for recipe_id=%s", instance.id)

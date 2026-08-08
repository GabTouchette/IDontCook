import logging

from celery import shared_task

logger = logging.getLogger(__name__)


def _compute_recipe_vector_sync(recipe_id):
    """Recompute and persist the TF-IDF vector for one recipe using the
    currently active (persisted) vectorizer. Never raises."""
    from recipes.models import Recipe
    from recommendations.api import get_active_vectorizer, store_recipe_vector

    try:
        recipe = Recipe.objects.get(id=recipe_id)
    except Recipe.DoesNotExist:
        logger.info("compute_recipe_vector: recipe %s no longer exists", recipe_id)
        return

    try:
        tfidf, version = get_active_vectorizer()
        if tfidf is None:
            logger.info("compute_recipe_vector: no active vectorizer (empty corpus?)")
            return
        store_recipe_vector(recipe, tfidf, version)
    except Exception:
        logger.exception("compute_recipe_vector failed for recipe_id=%s", recipe_id)


@shared_task
def compute_recipe_vector(recipe_id):
    """Celery task wrapper around _compute_recipe_vector_sync."""
    _compute_recipe_vector_sync(recipe_id)

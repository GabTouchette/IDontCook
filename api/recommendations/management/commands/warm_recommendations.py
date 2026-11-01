"""Pre-compute the per-user explore/home recommendation pools.

Scoring the whole catalog by cosine similarity (building a dense TF-IDF matrix
over every candidate) is the dominant cost of the explore page and home feed —
and it grows with the catalog, which is exactly why explore got slow as recipes
piled up. `get_similar_recipes` caches the ranked pool per user, but the first
request after an expiry/refit still pays the full cost.

This command warms that pool ahead of time for active users (and the global
trending ranking), so a user's first explore load of the day is a cache hit.
Pair it with a shared cache (Redis) — otherwise each gunicorn worker keeps its
own cold copy and the warm only helps the worker that ran it.

    python manage.py warm_recommendations                    # active users
    python manage.py warm_recommendations --rebuild-vectors  # refit vectors first
    python manage.py warm_recommendations --active-days 30 --limit 500

Run it on a schedule (Coolify scheduled task), e.g. nightly, ideally after any
vector rebuild. Cache TTLs are env-tunable (REC_PROFILE_CACHE_TTL /
REC_SIMILAR_CACHE_TTL) and default to 6h / 24h so a nightly warm stays hot.
"""

import logging

from django.core.management import call_command
from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta

from recipes.models import SavedRecipe
from recommendations.api import get_similar_recipes
from recommendations.models import UserRecipeInteraction

logger = logging.getLogger(__name__)

# Match the view's pool size so we warm exactly what explore reads.
POOL_TOP_N = 500


class Command(BaseCommand):
    help = "Pre-compute recommendation pools for active users (and trending)."

    def add_arguments(self, parser):
        parser.add_argument('--limit', type=int, default=None,
                            help='Max users to warm this run.')
        parser.add_argument('--active-days', type=int, default=45,
                            help='Only warm users with a signal in the last N days '
                                 '(0 = all users with any signal). Default 45.')
        parser.add_argument('--rebuild-vectors', action='store_true',
                            help='Run rebuild_recipe_vectors first (refit TF-IDF).')

    def handle(self, *args, **opts):
        if opts['rebuild_vectors']:
            self.stdout.write("Rebuilding recipe vectors first…")
            call_command('rebuild_recipe_vectors')

        # Warm the global trending ranking once (home feed reads it every load).
        try:
            from recommendations.api import _ranked_trending_ids
            _ranked_trending_ids()
            self.stdout.write("Warmed global trending ranking.")
        except Exception:
            logger.exception("Failed to warm trending ranking")

        user_ids = self._active_user_ids(opts['active_days'], opts['limit'])
        if not user_ids:
            self.stdout.write("No active users to warm.")
            return

        warmed = cold = failed = 0
        for uid in user_ids:
            try:
                pool = get_similar_recipes(uid, top_n=POOL_TOP_N, seed=None)
            except Exception:
                failed += 1
                logger.exception("warm_recommendations failed for user %s", uid)
                continue
            # A populated pool means the user had a taste profile (the expensive
            # path we just cached); an empty one is a cold-start user served from
            # trending — nothing per-user to warm.
            if pool:
                warmed += 1
            else:
                cold += 1

        self.stdout.write(self.style.SUCCESS(
            f"Done. warmed={warmed} cold_start={cold} failed={failed} "
            f"of {len(user_ids)} user(s)."
        ))

    @staticmethod
    def _active_user_ids(active_days, limit):
        """User ids with a taste signal (an interaction or a saved recipe),
        optionally limited to recent activity. Cold-start-only users are skipped
        here — they're served from trending and have no per-user pool to warm."""
        interaction_qs = UserRecipeInteraction.objects.all()
        if active_days and active_days > 0:
            since = timezone.now() - timedelta(days=active_days)
            interaction_qs = interaction_qs.filter(created_at__gte=since)

        ids = set(interaction_qs.values_list('user_id', flat=True))
        # Saved recipes are a strong taste signal too (and may predate the
        # activity window — a saved recipe still shapes the profile).
        ids.update(SavedRecipe.objects.values_list('user_id', flat=True))
        ids.discard(None)

        ordered = sorted(ids)
        return ordered[:limit] if limit else ordered

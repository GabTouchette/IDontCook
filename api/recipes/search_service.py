"""Shared hybrid retrieval service (docs/plans/catalog-first-pivot.md §1.5).

`search_catalog()` is the single place that answers "find me recipes that
match X" across the app. It is designed to be called from request-serving
code (chat tool, later the Explore endpoint) so it must never raise — bad or
empty input degrades to a best-effort result rather than an exception, and a
recipe pool that exists always yields *something* rather than nothing.

Scoring:
    combined = 0.6 * lexical_normalized + 0.4 * semantic_normalized

Lexical (title/ingredient trigram+prefix+exact scoring, see `recipes.search`)
is weighted higher than semantic because it is precise and cheap to trust —
when a query names an ingredient or dish plainly, matching the words that
were actually typed should win. The semantic pass (cosine similarity against
the shared TF-IDF vector space built for the recommender) adds recall for
queries that don't share vocabulary with any title ("cozy winter soup" vs.
a recipe titled "Butternut Squash Bisque") but is still just word-overlap
semantics — see catalog-first-pivot.md §5.2 for the known TF-IDF ceiling.
Both components are normalized to ~0..1 before blending so neither the
unbounded lexical score nor the [-1, 1] cosine similarity dominates by scale
alone.
"""

import logging

from recipes.models import Recipe
from recipes.search import RecipeSearchEngine
from recommendations.models import UserRecipeInteraction

logger = logging.getLogger(__name__)

LEXICAL_WEIGHT = 0.6
SEMANTIC_WEIGHT = 0.4

DEFAULT_LIMIT = 8


def _total_time(recipe):
    """Mirrors home/serializers.py's recipe_total_time: None when both legs
    are unknown, otherwise missing legs count as 0."""
    prep = recipe.preparation_time
    cook = recipe.cooking_time
    if prep is None and cook is None:
        return None
    return (prep or 0) + (cook or 0)


def _candidate_queryset(user, exclude_ids):
    """Base pool: never AI-generated, never an explicitly excluded id, and
    (best-effort) never something this user has downvoted."""
    qs = Recipe.objects.exclude(source=Recipe.SOURCE_AI)

    if exclude_ids:
        qs = qs.exclude(id__in=list(exclude_ids))

    user_id = getattr(user, "id", None)
    if user_id is not None:
        try:
            downvoted_ids = list(
                UserRecipeInteraction.objects.filter(
                    user_id=user_id, interaction_type="downvote"
                ).values_list("recipe_id", flat=True)
            )
            if downvoted_ids:
                qs = qs.exclude(id__in=downvoted_ids)
        except Exception:
            logger.exception(
                "search_catalog: failed to load downvotes for user_id=%s; "
                "continuing without that filter", user_id
            )

    return qs.prefetch_related("ingredients")


def _hard_filter(candidates, tags, max_total_time, max_calories):
    """Apply tags/time/calories as hard filters over an in-memory candidate
    list (the pool is small enough — a few thousand rows at most — that
    doing this in Python alongside the time-helper mirror is simpler and
    safer than juggling per-vendor JSON queries again)."""
    norm_tags = {
        str(t).strip().lower() for t in (tags or []) if t and str(t).strip()
    }

    filtered = []
    for r in candidates:
        if norm_tags:
            recipe_tags = {str(t).strip().lower() for t in (r.tags or [])}
            if not (recipe_tags & norm_tags):
                continue

        if max_total_time is not None:
            tt = _total_time(r)
            if tt is None or tt > max_total_time:
                continue

        if max_calories is not None:
            if r.calories is None or r.calories > max_calories:
                continue

        filtered.append(r)

    return filtered


def _lexical_scores(query, candidates):
    try:
        engine = RecipeSearchEngine()
        scored = engine.search(query, candidates, limit=len(candidates))
        return {r.id: score for r, score in scored}
    except Exception:
        logger.exception("search_catalog: lexical scoring failed; degrading to zero lexical scores")
        return {}


def _semantic_scores(query, candidates):
    try:
        from recommendations.api import get_active_vectorizer, _candidate_vectors
        from sklearn.metrics.pairwise import cosine_similarity

        tfidf, version = get_active_vectorizer()
        if tfidf is None or not candidates:
            return {}

        query_vec = tfidf.transform([query])
        matrix, ids = _candidate_vectors(candidates, tfidf, version)
        sims = cosine_similarity(query_vec, matrix).flatten()
        return {rid: float(sim) for rid, sim in zip(ids, sims)}
    except Exception:
        logger.exception("search_catalog: semantic scoring failed; degrading to zero semantic scores")
        return {}


def _scored_search(query, candidates, limit):
    lexical = _lexical_scores(query, candidates)
    semantic = _semantic_scores(query, candidates)

    max_lex = max(lexical.values(), default=0.0) or 1.0

    combined = []
    for r in candidates:
        lex_norm = lexical.get(r.id, 0.0) / max_lex
        sem_raw = semantic.get(r.id, 0.0)
        sem_norm = max(0.0, min(1.0, sem_raw))  # clamp cosine sim into 0..1
        score = LEXICAL_WEIGHT * lex_norm + SEMANTIC_WEIGHT * sem_norm
        combined.append((r, score))

    combined.sort(key=lambda pair: pair[1], reverse=True)

    ranked = [r for r, score in combined if score > 0]
    if not ranked:
        # Nothing scored positively (e.g. both scorers degraded, or the
        # query shares no vocabulary at all with anything) — never return
        # empty when candidates exist, fall back to recency.
        ranked = _recency_order(candidates)

    return ranked[:limit]


def _recency_order(candidates):
    import datetime

    epoch = datetime.datetime(1970, 1, 1, tzinfo=datetime.timezone.utc)

    def key(r):
        return r.created_at or epoch

    try:
        return sorted(candidates, key=key, reverse=True)
    except Exception:
        logger.exception("search_catalog: recency ordering failed; returning candidates unordered")
        return list(candidates)


def _personalized_or_recency_order(candidates, user, limit):
    user_id = getattr(user, "id", None)
    if user_id is not None:
        try:
            from recommendations.api import build_user_profile, _candidate_vectors, _vocab_version
            from sklearn.metrics.pairwise import cosine_similarity

            profile = build_user_profile(user_id)
            if profile:
                tfidf, user_vector = profile
                if tfidf is not None and user_vector is not None:
                    version = _vocab_version(tfidf)
                    matrix, ids = _candidate_vectors(candidates, tfidf, version)
                    sims = cosine_similarity(user_vector, matrix).flatten()
                    id_to_recipe = {r.id: r for r in candidates}
                    ranked_ids = [
                        rid for rid, _ in sorted(zip(ids, sims), key=lambda x: x[1], reverse=True)
                    ]
                    ordered = [id_to_recipe[rid] for rid in ranked_ids if rid in id_to_recipe]
                    if ordered:
                        return ordered[:limit]
        except Exception:
            logger.exception(
                "search_catalog: personalized empty-query ordering failed for user_id=%s; "
                "degrading to recency", user_id
            )

    return _recency_order(candidates)[:limit]


def search_catalog(query, *, user, tags=None, max_total_time=None, max_calories=None,
                    exclude_ids=(), limit=8):
    """Hybrid catalog retrieval (docs/plans/catalog-first-pivot.md §1.5).

    Never raises. Always returns a list of `Recipe` instances (possibly
    empty only if there is truly no candidate left after hard filters).
    """
    if not isinstance(limit, int) or limit <= 0:
        limit = DEFAULT_LIMIT

    try:
        candidates = list(_candidate_queryset(user, exclude_ids))
    except Exception:
        logger.exception("search_catalog: failed to build candidate pool")
        return []

    try:
        candidates = _hard_filter(candidates, tags, max_total_time, max_calories)
    except Exception:
        logger.exception("search_catalog: hard filtering failed; using unfiltered candidate pool")

    if not candidates:
        return []

    query_norm = (query or "").strip()
    if not query_norm:
        return _personalized_or_recency_order(candidates, user, limit)

    try:
        return _scored_search(query_norm, candidates, limit)
    except Exception:
        logger.exception("search_catalog: scored search failed; degrading to recency ordering")
        return _recency_order(candidates)[:limit]

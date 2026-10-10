import hashlib
import logging
import math
import pickle
import random
from collections import defaultdict

import numpy as np
from scipy import sparse
from django.conf import settings
from django.core.cache import cache  # Django's caching system
from django.db.models import Count, Q
from django.utils import timezone
from sklearn.cluster import KMeans
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.preprocessing import normalize as sk_normalize

from recipes.models import Recipe, SavedRecipe
from recommendations.models import (
    RecipeEvent,
    RecipeVector,
    UserRecipeInteraction,
    VectorizerArtifact,
)

logger = logging.getLogger(__name__)

# Weight applied to a recipe's TF-IDF vector when folding it into a user's
# taste profile. A recipe counts once, at the max weight across how the user
# has engaged with it (created/saved recipes always count at least 1.0).
INTERACTION_PROFILE_WEIGHTS = {
    'upvote': 2.0,
    'like': 1.5,
    'comment': 1.25,
}
CREATED_OR_SAVED_WEIGHT = 1.0

# Cold-start popularity fallback tuning.
COLD_START_INTERACTION_WEIGHTS = {
    'upvote': 2.0,
    'like': 1.5,
}
COLD_START_SAVE_WEIGHT = 1.0
COLD_START_HALF_LIFE_DAYS = 30.0

# Explore/recommendation surfaces are visually driven: a recipe card without a
# thumbnail reads as broken and converts poorly. We therefore heavily bias
# ranking toward recipes that have an image. A recipe "has an image" if it has
# either an uploaded file (`image`) or a scraped/catalog URL (`web_image_url`).
#
# The penalty is applied multiplicatively to a recipe's final score, so an
# imageless recipe keeps only IMAGELESS_SCORE_PENALTY of its score and is
# effectively sunk to the bottom of the ranking. This is intentionally
# aggressive: as of Aug 2026 ~99.8% of both the local and prod catalog already
# carry an image (all via `web_image_url`), so this only demotes the ~0.2%
# imageless tail rather than reshuffling the bulk of results. Tune here.
IMAGELESS_SCORE_PENALTY = 0.1

USER_PROFILE_CACHE_TIMEOUT = 60 * 60  # 1 hour
# The ranked similar-recipes list per user. Scoring the whole catalog by cosine
# similarity (loads every candidate + builds a dense TF-IDF matrix) is the
# dominant cost of the explore/home requests, so cache the ranking and slice it
# per caller instead of recomputing every request. Kept in line with the 1h
# profile cache — a refit (new vocab version) busts both.
SIMILAR_RECIPES_CACHE_TIMEOUT = 30 * 60  # 30 minutes
# Global (non-personalized) trending ranking. Recomputed at most twice an hour;
# invoked on every home-feed request via the trending rail, so caching it keeps
# the feed off the full interaction/save aggregation + Python sort each time.
TRENDING_CACHE_TIMEOUT = 30 * 60  # 30 minutes


# --- Recommender v2: multi-interest profile + directional downvote -----------
# See docs/plans/recommendation-algo-v2.md. Gated by RECOMMENDER_V2_ENABLED so
# the single-centroid v1 ranker can be restored without a deploy.
#
# Positive taste signals → base profile weight (before recency decay). A recipe
# counts once, at the max effective weight across however the user engaged with
# it (e.g. a recipe that was both clicked and upvoted counts as an upvote).
V2_SIGNAL_WEIGHTS = {
    "save": 2.0,     # saved a copy of someone else's recipe (strong intent)
    "upvote": 2.0,
    "like": 1.5,
    "comment": 1.25,
    "created": 1.0,
    "click": 0.5,    # opened a recipe's detail — weak, noisy, self-reinforcing
}
# Every signal's weight decays by its age so current taste outweighs old taste.
SIGNAL_HALF_LIFE_DAYS = 75.0
# Below this many engaged recipes a single centroid is used (not enough to
# meaningfully cluster tastes yet) — identical to v1 behaviour.
MIN_RECIPES_FOR_CLUSTERING = 8
MAX_TASTE_CLUSTERS = 5
# Clicks are high-volume; cap how many fold into one profile build (cost bound).
CLICK_LOOKBACK_LIMIT = 300
# λ_neg: how hard a downvote demotes recipes *similar* to the disliked one.
DISLIKE_PENALTY = 0.5

# --- Variety & diversity layer (docs/plans/recommendation-algo-v2.md §3) ------
# The ranked POOL (content + popularity/recency blend, MMR-diversified) is the
# expensive part and is cached; the per-request seeded transform (band-shuffle +
# exploration) is cheap and applied on top so a refresh reshuffles the feed
# without recomputing cosine. All three score components are min-max normalized
# before blending so these weights are directly comparable.
POPULARITY_WEIGHT = 0.15   # β: nudge toward globally popular recipes
RECENCY_WEIGHT = 0.10      # γ: nudge toward newer catalog recipes
RECENCY_HALF_LIFE_DAYS = 60.0
MMR_LAMBDA = 0.7           # α: relevance vs diversity in MMR (higher = more relevant)
MMR_POOL_SIZE = 300        # only the top-M by blended score is diversified (cost bound)
EXPLORATION_RATIO = 0.18   # ε: share of visible slots given to popular off-profile recipes
VARIETY_BAND_SIZE = 8      # per-request shuffle happens within contiguous relevance bands


def _recipe_ids_with_images(ids):
    """
    Return the subset of `ids` whose recipe has a usable image — either an
    uploaded file (`image`) or a scraped/catalog URL (`web_image_url`). Used to
    apply IMAGELESS_SCORE_PENALTY when ranking explore/recommendation results.
    """
    if not ids:
        return set()
    return set(
        Recipe.objects
        .filter(id__in=ids)
        .filter(Q(image__gt='') | Q(web_image_url__gt=''))
        .values_list('id', flat=True)
    )


def _image_multiplier(recipe_id, ids_with_images):
    """Score multiplier that demotes recipes lacking an image."""
    return 1.0 if recipe_id in ids_with_images else IMAGELESS_SCORE_PENALTY


def _recipe_text(recipe):
    """Build the bag-of-words text representation used for TF-IDF."""
    return (
        f"{recipe.title or ''} {recipe.description or ''} "
        f"{' '.join(recipe.tags or [])} "
        f"{' '.join(i.name for i in recipe.ingredients.all() if i.name)}"
    )


def _fit_vectorizer(texts):
    tfidf = TfidfVectorizer(stop_words='english')
    tfidf.fit(texts)
    return tfidf


def _vocab_version(tfidf):
    """A stable tag for a fitted vectorizer's vocabulary, used to invalidate
    cached profiles / stored RecipeVectors when the corpus changes shape."""
    vocab_items = sorted(tfidf.vocabulary_.items())
    digest = hashlib.sha256(repr(vocab_items).encode('utf-8')).hexdigest()
    return digest[:32]


def _fit_and_persist_vectorizer():
    """Fit a fresh TF-IDF vectorizer over the full recipe corpus and persist
    it (so every process/request shares the same vector space)."""
    recipes = list(Recipe.objects.all())
    texts = [_recipe_text(r) for r in recipes]
    if not texts:
        return None, None

    tfidf = _fit_vectorizer(texts)
    version = _vocab_version(tfidf)

    # Reuse an existing artifact for this exact vocabulary if present
    # (e.g. concurrent refit), otherwise create a new one.
    artifact, _ = VectorizerArtifact.objects.get_or_create(
        version=version,
        defaults={'blob': pickle.dumps(tfidf)},
    )
    try:
        tfidf = pickle.loads(artifact.blob)
    except Exception:
        logger.exception("Failed to reload persisted vectorizer artifact; using freshly fit one")

    return tfidf, version


def get_active_vectorizer():
    """
    Return (tfidf, version) for the vectorizer that should be used right now.
    Loads the most recently persisted artifact if one exists, otherwise fits
    and persists a new one from the current recipe corpus.
    """
    artifact = VectorizerArtifact.objects.order_by('-created_at').first()
    if artifact is not None:
        try:
            tfidf = pickle.loads(artifact.blob)
            return tfidf, artifact.version
        except Exception:
            logger.exception("Failed to unpickle VectorizerArtifact %s; refitting", artifact.pk)

    return _fit_and_persist_vectorizer()


def _sparse_entries(vector):
    """Convert a 1-row sparse/dense TF-IDF vector into [[index, weight], ...]."""
    dense = np.asarray(vector).reshape(-1)
    nonzero = np.nonzero(dense)[0]
    return [[int(i), float(dense[i])] for i in nonzero]


def _entries_to_sparse_row(entries, dim):
    """A 1 x dim sparse CSR row from stored [[index, weight], ...] entries.

    Sparse (not dense) so the candidate matrix stays tiny: a dense
    n_candidates x n_features matrix over the full catalog is hundreds of MB and
    was the bulk of the recommendation latency + container memory pressure.
    """
    cols, data = [], []
    for idx, weight in (entries or []):
        if 0 <= idx < dim:
            cols.append(idx)
            data.append(weight)
    return sparse.csr_matrix((data, ([0] * len(cols), cols)), shape=(1, dim))


def store_recipe_vector(recipe, tfidf, version):
    """Compute and persist the TF-IDF vector for a single recipe."""
    vec = tfidf.transform([_recipe_text(recipe)])
    entries = _sparse_entries(vec.toarray()[0])
    RecipeVector.objects.update_or_create(
        recipe=recipe,
        defaults={'vector': entries, 'vectorizer_version': version},
    )


def build_user_profile(user_id):
    """
    Create a weighted taste profile for a user from the recipes they've
    created/saved plus recipes they've positively interacted with
    (upvote/like/comment), using a single shared TF-IDF vector space so the
    result is directly comparable with precomputed RecipeVector rows.

    Each recipe counts once toward the profile, at the max weight across:
    created/saved = 1.0, upvoted = 2.0, liked = 1.5, commented = 1.25.

    Returns (tfidf, user_profile_vector) or None if there's no signal at all.
    Cached for 1h, keyed on the active vectorizer version so a refit busts it.
    """
    tfidf, version = get_active_vectorizer()
    if tfidf is None:
        return None

    cache_key = f"user_profile_{user_id}_v{version}"
    cached_profile = cache.get(cache_key)
    if cached_profile:
        return cached_profile

    recipe_weight = {}
    recipe_objs = {}

    user_recipes = Recipe.objects.filter(created_by=user_id)
    saved_versions = Recipe.objects.filter(created_by=user_id).exclude(parent=None)
    for r in list(user_recipes) + list(saved_versions):
        recipe_objs[r.id] = r
        recipe_weight[r.id] = max(recipe_weight.get(r.id, 0.0), CREATED_OR_SAVED_WEIGHT)

    interactions = UserRecipeInteraction.objects.filter(
        user_id=user_id,
        interaction_type__in=INTERACTION_PROFILE_WEIGHTS.keys(),
    ).select_related('recipe')
    for interaction in interactions:
        weight = INTERACTION_PROFILE_WEIGHTS[interaction.interaction_type]
        rid = interaction.recipe_id
        if interaction.recipe is None:
            continue
        recipe_objs.setdefault(rid, interaction.recipe)
        recipe_weight[rid] = max(recipe_weight.get(rid, 0.0), weight)

    if not recipe_weight:
        return None

    ids = list(recipe_weight.keys())
    texts = [_recipe_text(recipe_objs[rid]) for rid in ids]
    weights = np.array([recipe_weight[rid] for rid in ids], dtype=float)

    vectors = tfidf.transform(texts)
    weighted_sum = vectors.multiply(weights.reshape(-1, 1)).sum(axis=0)
    user_profile_vector = np.asarray(weighted_sum / weights.sum()).reshape(1, -1)

    result = (tfidf, user_profile_vector)
    cache.set(cache_key, result, timeout=USER_PROFILE_CACHE_TIMEOUT)
    return result


def _recency_weight(base_weight, ts, now):
    """Decay a signal's weight by its age (half-life SIGNAL_HALF_LIFE_DAYS) so a
    user's recent engagement outweighs old engagement."""
    if ts is None:
        return base_weight
    age_days = max((now - ts).total_seconds() / 86400.0, 0.0)
    return base_weight * (0.5 ** (age_days / SIGNAL_HALF_LIFE_DAYS))


def _gather_positive_signals(user_id, now):
    """Collect a user's positive taste signals as
    {recipe_id: effective_weight} plus {recipe_id: Recipe}, taking the MAX
    recency-weighted weight across all of a recipe's signals (so a recipe that
    was both clicked and upvoted counts once, as the upvote)."""
    weight_by_id = {}
    recipe_objs = {}

    def _bump(recipe, base_weight, ts):
        if recipe is None:
            return
        w = _recency_weight(base_weight, ts, now)
        rid = recipe.id
        recipe_objs.setdefault(rid, recipe)
        if w > weight_by_id.get(rid, 0.0):
            weight_by_id[rid] = w

    # Created recipes (parent is None) and saved copies (parent set).
    for r in Recipe.objects.filter(created_by=user_id):
        base = V2_SIGNAL_WEIGHTS["save"] if r.parent_id else V2_SIGNAL_WEIGHTS["created"]
        _bump(r, base, r.created_at)

    # Positive interactions.
    interactions = (
        UserRecipeInteraction.objects
        .filter(user_id=user_id, interaction_type__in=("upvote", "like", "comment"))
        .select_related("recipe")
    )
    for it in interactions:
        _bump(it.recipe, V2_SIGNAL_WEIGHTS[it.interaction_type], it.created_at)

    # Clicks (opens) — weak signal, capped for cost; most-recent click wins.
    clicks = (
        RecipeEvent.objects
        .filter(user_id=user_id, kind=RecipeEvent.KIND_CLICK)
        .select_related("recipe")
        .order_by("-created_at")[:CLICK_LOOKBACK_LIMIT]
    )
    for ev in clicks:
        _bump(ev.recipe, V2_SIGNAL_WEIGHTS["click"], ev.created_at)

    return weight_by_id, recipe_objs


def _taste_centroids(vectors, weights, multi_interest):
    """Return an (K, n_features) dense array of taste centroids.

    A single weighted-average centroid (v1 behaviour) unless multi-interest is
    enabled AND the user has enough engaged recipes to cluster — then K spherical
    k-means centroids, so a candidate matching ANY ONE of the user's interests
    can rank high instead of only matching the blurry average of all of them
    (the root cause of "always the same recommendations")."""
    n = vectors.shape[0]
    if not multi_interest or n < MIN_RECIPES_FOR_CLUSTERING:
        centroid = vectors.multiply(weights.reshape(-1, 1)).sum(axis=0) / weights.sum()
        return np.asarray(centroid).reshape(1, -1)

    k = min(max(2, round(math.sqrt(n / 2.0))), MAX_TASTE_CLUSTERS)
    # Spherical k-means: L2-normalize rows so euclidean clustering ≈ cosine.
    normed = sk_normalize(vectors)
    km = KMeans(n_clusters=k, n_init=3, random_state=42)
    km.fit(normed, sample_weight=weights)
    return np.asarray(km.cluster_centers_)


def _dislike_vector(user_id, now, tfidf):
    """A single 'dislike' centroid (recency-weighted mean of the user's
    downvoted recipes), or None. Used to demote candidates *similar* to what the
    user thumbed down — the exact downvoted recipes are also hard-excluded from
    candidates via _excluded_recipe_ids."""
    downvotes = (
        UserRecipeInteraction.objects
        .filter(user_id=user_id, interaction_type="downvote")
        .select_related("recipe")
    )
    texts, weights = [], []
    for it in downvotes:
        if it.recipe is None:
            continue
        texts.append(_recipe_text(it.recipe))
        weights.append(_recency_weight(1.0, it.created_at, now))
    if not texts:
        return None
    vectors = tfidf.transform(texts)
    w = np.array(weights, dtype=float).reshape(-1, 1)
    dislike = vectors.multiply(w).sum(axis=0) / w.sum()
    return np.asarray(dislike).reshape(1, -1)


def build_user_profile_v2(user_id):
    """Multi-interest taste profile (docs/plans/recommendation-algo-v2.md §2).

    Returns a dict {tfidf, version, centroids, dislike} or None when the user
    has no positive taste signal (→ caller falls back to cold-start trending; a
    dislike vector alone can't rank a feed). `centroids` is (K>=1, n_features);
    `dislike` is (1, n_features) or None. Cached 1h, keyed on vectorizer version.
    """
    tfidf, version = get_active_vectorizer()
    if tfidf is None:
        return None

    cache_key = f"user_profile_v2_{user_id}_v{version}"
    cached = cache.get(cache_key)
    if cached:
        return cached

    now = timezone.now()
    weight_by_id, recipe_objs = _gather_positive_signals(user_id, now)
    if not weight_by_id:
        return None

    ids = list(weight_by_id.keys())
    texts = [_recipe_text(recipe_objs[rid]) for rid in ids]
    weights = np.array([weight_by_id[rid] for rid in ids], dtype=float)
    vectors = tfidf.transform(texts)

    multi = getattr(settings, "RECOMMENDER_MULTI_INTEREST_ENABLED", True)
    result = {
        "tfidf": tfidf,
        "version": version,
        "centroids": _taste_centroids(vectors, weights, multi),
        "dislike": _dislike_vector(user_id, now, tfidf),
    }
    cache.set(cache_key, result, USER_PROFILE_CACHE_TIMEOUT)
    return result


def invalidate_user_recommendation_cache(user_id):
    """Drop a user's cached taste profile + ranked recommendations so a new
    up/downvote (or other signal change) is reflected immediately instead of
    waiting out the 1h/30m TTLs.

    Deletes both the v1 and v2 keys. The keys are suffixed with the active
    vectorizer version (which the HTTP view doesn't know), so we resolve it here
    via get_active_vectorizer — cheap: it reads the stored artifact, no refit.
    This also fixes the earlier no-op delete that used an unversioned key.
    """
    try:
        _, version = get_active_vectorizer()
    except Exception:
        logger.exception("Could not resolve vectorizer version to invalidate rec cache")
        return
    cache.delete_many([
        f"user_profile_{user_id}_v{version}",
        f"user_profile_v2_{user_id}_v{version}",
        f"similar_recipes_{user_id}_v{version}",
        f"similar_recipes_v2_{user_id}_v{version}",
    ])


def _excluded_recipe_ids(user_id):
    """Recipe ids that should never be recommended back to this user:
    their own recipes, their own saved copies, any recipe that's a copy
    (has a parent) regardless of owner, and anything they've downvoted."""
    excluded_ids = Recipe.objects.filter(created_by=user_id).values_list('id', flat=True)
    excluded_user_parents = Recipe.objects.filter(created_by=user_id).exclude(parent=None).values_list('parent', flat=True)
    excluded_all_copies = Recipe.objects.exclude(parent=None).values_list('id', flat=True)
    downvoted_ids = UserRecipeInteraction.objects.filter(
        user_id=user_id, interaction_type='downvote'
    ).values_list('recipe_id', flat=True)

    return set(excluded_ids).union(set(excluded_user_parents)).union(
        set(excluded_all_copies)).union(set(downvoted_ids))


def get_trending_recipes(user_id, exclude_ids=(), top_n=20):
    """
    Popularity + recency blend, standalone and importable so other callers
    (e.g. a home-feed "trending" rail, docs/plans/catalog-first-pivot.md
    §2 WS-P1/WS-P3) can use it directly without requiring the caller to have
    zero taste-profile signal first — unlike `_cold_start_fallback`, this is
    not gated on `user_id` having no personalization signal.

    Recipes are scored by a weighted count of upvotes/likes/saves across all
    users, then decayed by recipe age with a ~30 day half-life so recent
    popular recipes outrank old ones with a similar raw popularity score.
    AI-generated recipes (`Recipe.SOURCE_AI`) are never surfaced as trending
    catalog content.

    `user_id` is accepted for signature symmetry with other recommendation
    entry points and potential future personalized-trending variants; the
    current scoring is global (not user-specific).

    The expensive global ranking (aggregating every interaction + save and
    sorting all candidates in Python) is cached — it is invoked on every
    home-feed request via the trending rail and was the one recommendation
    entry point the similar_recipes cache didn't cover. Caller-specific
    `exclude_ids` and `top_n` are applied to the cached ranking below.
    """
    ranked = _ranked_trending_ids()
    excluded = set(exclude_ids or ())
    if excluded:
        ranked = [rid for rid in ranked if rid not in excluded]
    return ranked[:top_n]


def _ranked_trending_ids():
    """Global popularity+recency ranking over the whole catalog (AI-generated
    recipes excluded), best-first. Cached for TRENDING_CACHE_TIMEOUT; returns
    ALL ranked ids so callers can apply their own exclusions/limit cheaply.
    """
    cache_key = "trending_recipes_v1"
    ranked = cache.get(cache_key)
    if ranked is None:
        ranked = _compute_ranked_trending_ids()
        cache.set(cache_key, ranked, TRENDING_CACHE_TIMEOUT)
    return ranked


def _compute_ranked_trending_ids():
    """Uncached global trending ranking — see _ranked_trending_ids for caching."""
    excluded_ids = set(
        Recipe.objects.filter(source=Recipe.SOURCE_AI).values_list('id', flat=True)
    )

    score_by_recipe = defaultdict(float)

    interaction_counts = (
        UserRecipeInteraction.objects
        .exclude(recipe_id__in=excluded_ids)
        .filter(interaction_type__in=COLD_START_INTERACTION_WEIGHTS.keys())
        .values('recipe_id', 'interaction_type')
        .annotate(n=Count('id'))
    )
    for row in interaction_counts:
        weight = COLD_START_INTERACTION_WEIGHTS[row['interaction_type']]
        score_by_recipe[row['recipe_id']] += weight * row['n']

    save_counts = (
        SavedRecipe.objects
        .exclude(recipe_id__in=excluded_ids)
        .values('recipe_id')
        .annotate(n=Count('id'))
    )
    for row in save_counts:
        score_by_recipe[row['recipe_id']] += COLD_START_SAVE_WEIGHT * row['n']

    if not score_by_recipe:
        return []

    candidate_ids = list(score_by_recipe.keys())
    created_at_by_id = dict(
        Recipe.objects.filter(id__in=candidate_ids).values_list('id', 'created_at')
    )
    ids_with_images = _recipe_ids_with_images(candidate_ids)

    now = timezone.now()
    scored = []
    for rid, base_score in score_by_recipe.items():
        created_at = created_at_by_id.get(rid)
        if created_at:
            age_days = max((now - created_at).total_seconds() / 86400.0, 0.0)
        else:
            age_days = COLD_START_HALF_LIFE_DAYS
        decay = 0.5 ** (age_days / COLD_START_HALF_LIFE_DAYS)
        scored.append((rid, base_score * decay * _image_multiplier(rid, ids_with_images)))

    scored.sort(key=lambda x: x[1], reverse=True)
    return [rid for rid, _ in scored]


def _cold_start_fallback(excluded_ids, top_n):
    """
    Popularity + recency blend used when a user has no taste-profile signal
    at all (no created/saved/liked/upvoted/commented recipes). Delegates to
    `get_trending_recipes`, passing along whatever exclusions the caller
    already computed (the user's own recipes, copies, downvotes, etc.).
    """
    return get_trending_recipes(user_id=None, exclude_ids=excluded_ids, top_n=top_n)


def _candidate_vectors(candidates, tfidf, version):
    """
    Build the (n_candidates x n_features) matrix for cosine similarity,
    preferring precomputed RecipeVector rows (matching the active vectorizer
    version) and falling back to an on-the-fly transform for any recipe
    missing one (or whose stored vector is stale). Never raises.
    """
    dim = len(tfidf.vocabulary_)
    ids = [r.id for r in candidates]

    stored_by_id = {}
    try:
        stored_by_id = {
            rv.recipe_id: rv.vector
            for rv in RecipeVector.objects.filter(recipe_id__in=ids, vectorizer_version=version)
        }
    except Exception:
        logger.exception("Failed to load precomputed RecipeVectors; falling back to on-the-fly transform")

    rows = [None] * len(candidates)
    missing_recipes = []
    missing_positions = []

    for pos, r in enumerate(candidates):
        entries = stored_by_id.get(r.id)
        if entries is not None:
            rows[pos] = _entries_to_sparse_row(entries, dim)
        else:
            missing_recipes.append(r)
            missing_positions.append(pos)

    if missing_recipes:
        try:
            texts = [_recipe_text(r) for r in missing_recipes]
            computed = tfidf.transform(texts)  # already a sparse CSR matrix
            for i, pos in enumerate(missing_positions):
                rows[pos] = computed.getrow(i)
        except Exception:
            logger.exception("On-the-fly TF-IDF transform failed for %d candidates", len(missing_recipes))
            for pos in missing_positions:
                rows[pos] = sparse.csr_matrix((1, dim))

    return sparse.vstack(rows, format='csr'), ids


def get_similar_recipes(user_id, top_n=30, seed=None):
    """
    Recommend recipes similar to the user's own taste profile. Falls back to
    a popularity+recency blend when the user has no profile signal at all
    (cold start), instead of returning nothing.

    The expensive ranked POOL is cached per (user, vectorizer version); scoring
    the whole catalog by cosine similarity is what previously made explore/home
    take 20-30s. `seed` (optional) applies a cheap per-request variety transform
    (band-shuffle + exploration) on top of the cached pool so a refresh feels
    fresh without recomputing — pass a stable session seed to keep pagination
    consistent, a new seed to reshuffle. `seed=None` → deterministic pool order.

    When RECOMMENDER_V2_ENABLED (default on), uses the multi-interest profile +
    directional-downvote ranker (docs/plans/recommendation-algo-v2.md); set the
    flag false to revert to the single-centroid v1 path below (which ignores
    `seed`).
    """
    if getattr(settings, "RECOMMENDER_V2_ENABLED", True):
        return _get_similar_recipes_v2(user_id, top_n, seed)

    profile = build_user_profile(user_id)
    if not profile:
        return _cold_start_fallback(_excluded_recipe_ids(user_id), top_n)

    tfidf, user_profile_vector = profile
    if tfidf is None or user_profile_vector is None:
        return _cold_start_fallback(_excluded_recipe_ids(user_id), top_n)

    version = _vocab_version(tfidf)
    cache_key = f"similar_recipes_{user_id}_v{version}"
    ranked = cache.get(cache_key)
    if ranked is None:
        ranked = _rank_similar_recipes(user_id, tfidf, user_profile_vector, version)
        cache.set(cache_key, ranked, SIMILAR_RECIPES_CACHE_TIMEOUT)
    return ranked[:top_n]


def _get_similar_recipes_v2(user_id, top_n, seed=None):
    """v2 entry point: multi-interest profile + directional downvote, with the
    diversified pool cached and a cheap seeded variety transform layered on top.
    Cold-starts to trending (also variety-shuffled when seeded)."""
    profile = build_user_profile_v2(user_id)
    if not profile:
        excluded = _excluded_recipe_ids(user_id)
        if seed is None:
            return _cold_start_fallback(excluded, top_n)
        ranked = [r for r in _ranked_trending_ids() if r not in excluded]
        return _apply_variety(ranked, seed, top_n, user_id)

    version = profile["version"]
    cache_key = f"similar_recipes_v2_{user_id}_v{version}"
    pool = cache.get(cache_key)
    if pool is None:
        pool = _rank_similar_recipes_v2(user_id, profile, version)
        cache.set(cache_key, pool, SIMILAR_RECIPES_CACHE_TIMEOUT)

    if seed is None:
        return pool[:top_n]
    return _apply_variety(pool, seed, top_n, user_id)


def _minmax(x):
    """Scale an array to [0, 1]; all-equal input → all zeros."""
    x = np.asarray(x, dtype=float)
    lo, hi = float(x.min()), float(x.max())
    if hi - lo < 1e-12:
        return np.zeros_like(x)
    return (x - lo) / (hi - lo)


def _popularity_norms(ids):
    """Per-id popularity in [0, 1], derived from global trending rank (best = 1).
    Recipes with no popularity signal get 0."""
    ranked = _ranked_trending_ids()
    if not ranked:
        return np.zeros(len(ids))
    n = len(ranked)
    rank = {rid: i for i, rid in enumerate(ranked)}
    return np.array([(1.0 - rank[r] / n) if r in rank else 0.0 for r in ids])


def _recency_norms(candidates):
    """Per-candidate recency in (0, 1], decayed by age (RECENCY_HALF_LIFE_DAYS)."""
    now = timezone.now()
    out = []
    for r in candidates:
        if r.created_at:
            age_days = max((now - r.created_at).total_seconds() / 86400.0, 0.0)
            out.append(0.5 ** (age_days / RECENCY_HALF_LIFE_DAYS))
        else:
            out.append(0.0)
    return np.array(out)


def _diversify_mmr(order, blended, candidate_matrix, pool_size, lam):
    """MMR-reorder the top `pool_size` positions of `order` (positions into the
    candidate arrays, best-first by `blended`) to reduce near-duplicates; the
    remaining positions keep their blended order. Uses the already-in-memory
    candidate vectors, so no extra DB work."""
    head = list(order[:pool_size])
    tail = list(order[pool_size:])
    if len(head) <= 2:
        return head + tail

    sim = cosine_similarity(candidate_matrix[head])  # (h, h) dense
    rel = _minmax(np.array([blended[i] for i in head]))
    h = len(head)

    selected = [0]                 # head[0] is the top-relevance item
    chosen = {0}
    max_sim = sim[0].copy()        # running max similarity to any selected item
    while len(selected) < h:
        mmr = lam * rel - (1.0 - lam) * max_sim
        for c in chosen:
            mmr[c] = -np.inf
        nxt = int(np.argmax(mmr))
        selected.append(nxt)
        chosen.add(nxt)
        max_sim = np.maximum(max_sim, sim[nxt])

    return [head[i] for i in selected] + tail


def _rank_similar_recipes_v2(user_id, profile, version):
    """Build the ranked candidate POOL: taste match (best-matching interest) +
    directional-downvote penalty, blended with popularity + recency, then
    MMR-diversified. Returns ALL candidate ids best-first; callers cache this and
    layer the cheap per-request variety transform (_apply_variety) on top.

    docs/plans/recommendation-algo-v2.md §2-3.
    """
    excluded = _excluded_recipe_ids(user_id)
    candidates = list(Recipe.objects.exclude(id__in=excluded))
    if not candidates:
        return []

    tfidf = profile["tfidf"]
    candidate_matrix, ordered_ids = _candidate_vectors(candidates, tfidf, version)

    # Taste match: best cosine across the user's interest centroids.
    content = cosine_similarity(profile["centroids"], candidate_matrix).max(axis=0)
    dislike = profile.get("dislike")
    if dislike is not None:
        neg = cosine_similarity(dislike, candidate_matrix).flatten()
        content = content - DISLIKE_PENALTY * np.clip(neg, 0.0, None)

    # Blend with popularity + recency (all normalized → weights comparable).
    blended = (
        (1.0 - POPULARITY_WEIGHT - RECENCY_WEIGHT) * _minmax(content)
        + POPULARITY_WEIGHT * _popularity_norms(ordered_ids)
        + RECENCY_WEIGHT * _recency_norms(candidates)
    )

    # Imageless recipes always sink below image'd ones (a photoless card reads as
    # broken), so diversify/rank the two groups separately.
    img_positions, noimg_positions = [], []
    for i, r in enumerate(candidates):
        (img_positions if ((r.image and str(r.image)) or r.web_image_url) else noimg_positions).append(i)

    img_sorted = sorted(img_positions, key=lambda i: blended[i], reverse=True)
    noimg_sorted = sorted(noimg_positions, key=lambda i: blended[i], reverse=True)
    img_diversified = _diversify_mmr(img_sorted, blended, candidate_matrix, MMR_POOL_SIZE, MMR_LAMBDA)

    return [ordered_ids[i] for i in img_diversified + noimg_sorted]


def _band_shuffle(ids, rng):
    """Shuffle within contiguous relevance bands: strong matches stay near the
    top, but which ones (and their order) rotate per seed."""
    out = list(ids)
    for start in range(0, len(out), VARIETY_BAND_SIZE):
        band = out[start:start + VARIETY_BAND_SIZE]
        rng.shuffle(band)
        out[start:start + VARIETY_BAND_SIZE] = band
    return out


def _apply_variety(pool_ids, seed, want_n, user_id):
    """Cheap, seeded per-request transform over the cached pool: band-shuffle for
    freshness + weave popular-but-low-ranked recipes into the visible window for
    serendipity (the exploration slice). Deterministic for a given seed, so a
    paginated caller passing a stable session seed gets consistent paging while a
    new seed (pull-to-refresh) reshuffles the feed."""
    rng = random.Random(seed)
    ids = list(pool_ids)
    n = len(ids)
    window = want_n or n

    if n <= window:
        return _band_shuffle(ids, rng)[:want_n] if want_n else _band_shuffle(ids, rng)

    # Exploration: promote the most popular recipes currently ranked *below* the
    # visible window up into it (removing them from their low position so there
    # are no duplicates).
    trending_rank = {rid: i for i, rid in enumerate(_ranked_trending_ids())}
    below_window = ids[window:]
    explore_picks = sorted(
        (r for r in below_window if r in trending_rank),
        key=lambda r: trending_rank[r],
    )[:int(round(EXPLORATION_RATIO * window))]

    if explore_picks:
        pick_set = set(explore_picks)
        ids = _band_shuffle([r for r in ids if r not in pick_set], rng)
        for p in explore_picks:
            # Insert within the visible window so a promoted recipe is actually seen.
            ids.insert(rng.randint(0, max(0, min(window - 1, len(ids)))), p)
    else:
        ids = _band_shuffle(ids, rng)

    return ids[:want_n] if want_n else ids


def _rank_similar_recipes(user_id, tfidf, user_profile_vector, version):
    """Score every non-excluded catalog recipe by cosine similarity to the
    user's taste profile and return ALL candidate ids in ranked order.

    Expensive (loads all candidates + builds a dense TF-IDF matrix) — callers go
    through get_similar_recipes, which caches this result.
    """
    excluded = _excluded_recipe_ids(user_id)
    candidates = list(Recipe.objects.exclude(id__in=excluded))
    if not candidates:
        return []

    candidate_matrix, ordered_ids = _candidate_vectors(candidates, tfidf, version)

    similarities = cosine_similarity(user_profile_vector, candidate_matrix).flatten()
    ids_with_images = {
        r.id for r in candidates
        if (r.image and str(r.image)) or r.web_image_url
    }
    scored = sorted(
        zip(ordered_ids, similarities),
        key=lambda pair: pair[1] * _image_multiplier(pair[0], ids_with_images),
        reverse=True,
    )
    return [rid for rid, _ in scored]


# import pandas as pd
# from sklearn.feature_extraction.text import TfidfVectorizer
# from sklearn.metrics.pairwise import cosine_similarity
# from sklearn.decomposition import NMF
# from recipes.models import Recipe
# from recommendations.models import UserRecipeInteraction
# from django.db.models import Count

# def get_interaction_data():
#     """
#     Fetch user-recipe interactions from the database and return a DataFrame.
#     If no interactions exist, return an empty DataFrame with the required columns.
#     """
#     interactions = UserRecipeInteraction.objects.all().values('user_id', 'recipe_id', 'interaction_type')
#     if not interactions:
#         # Return an empty DataFrame with the required columns
#         return pd.DataFrame(columns=['user_id', 'recipe_id', 'interaction_type'])
#     return pd.DataFrame(list(interactions))

# def preprocess_interactions(interactions):
#     """
#     Preprocess interaction data:
#     - Assign weights to interaction types.
#     - Create a user-recipe interaction matrix.
#     If no interactions exist, return an empty DataFrame.
#     """
#     if interactions.empty:
#         return pd.DataFrame()

#     interaction_weights = {
#         'like': 3,
#         'comment': 1,
#         'upvote': 2,
#         'downvote': 0,
#     }
#     interactions['weight'] = interactions['interaction_type'].map(interaction_weights)
#     interaction_matrix = interactions.pivot_table(
#         index='user_id', columns='recipe_id', values='weight', fill_value=0
#     )

#     return interaction_matrix

# def train_collaborative_filtering(interaction_matrix):
#     """
#     Train a collaborative filtering model using Non-Negative Matrix Factorization (NMF).
#     If the interaction matrix is empty, return an empty DataFrame.
#     """
#     if interaction_matrix.empty:
#         return pd.DataFrame()

#     # Apply NMF
#     model = NMF(n_components=10, init='random', random_state=42, max_iter=100)  # Adjust n_components as needed
#     W = model.fit_transform(interaction_matrix)  # User features
#     H = model.components_  # Recipe features

#     # Reconstruct the interaction matrix
#     reconstructed_matrix = pd.DataFrame(W @ H, index=interaction_matrix.index, columns=interaction_matrix.columns)

#     return reconstructed_matrix

# def get_content_based_recommendations(user_id, top_n=30):
#     """
#     Generate content-based recommendations using recipe title, ingredients, description, and tags.
#     """
#     # Get all recipes with their relevant fields
#     recipes = Recipe.objects.all().values('id', 'title', 'ingredients', 'description', 'tags')
#     recipe_df = pd.DataFrame(list(recipes))

#     # Combine title, ingredients, description, and tags into a single text field
#     recipe_df['combined_features'] = (
#         recipe_df['title'].fillna('') + ' ' +
#         recipe_df['description'].fillna('') + ' ' +
#         recipe_df['tags'].apply(lambda x: ' '.join(x) if isinstance(x, list) else '') + ' ' +
#         recipe_df['ingredients'].apply(lambda ingredients: ' '.join([ingredient.name for ingredient in ingredients.all()]) if hasattr(ingredients, 'all') else '')
#     )

#     # Use TF-IDF vectorizer to convert text into feature vectors
#     tfidf = TfidfVectorizer(stop_words='english')
#     recipe_features = tfidf.fit_transform(recipe_df['combined_features'])

#     # Calculate cosine similarity between all recipes
#     recipe_similarity = cosine_similarity(recipe_features)

#     # Get the user’s previously interacted recipes
#     user_recipe_ids = recipes.filter(created_by__id=user_id).values_list('id', flat=True)
#     similar_recipes = set()

#     # Find similar recipes based on user interactions
#     for recipe_id in user_recipe_ids:
#         recipe_index = recipe_df.index[recipe_df['id'] == recipe_id].tolist()[0]
#         similar_indices = recipe_similarity[recipe_index].argsort()[-top_n-1:-1][::-1]
#         similar_recipes.update(recipe_df.iloc[similar_indices]['id'])

#     return list(similar_recipes)[:top_n]

# def get_hybrid_recommendations(user_id, top_n=30, collab_weight=0.6, content_weight=0.4):
#     """
#     Generate hybrid recommendations by combining collaborative and content-based filtering.
#     If no recommendations are found, recommend the most upvoted recipes.
#     """
#     # interactions = get_interaction_data()
#     # interaction_matrix = preprocess_interactions(interactions)
#     # reconstructed_matrix = train_collaborative_filtering(interaction_matrix)

#     # Get the list of recipes the user has created
#     user_created_recipes = set(
#         Recipe.objects
#         .filter(created_by=user_id)
#         .values_list('id', flat=True)
#     )

#     # Get the list of recipes where the user has created a recipe with parent = X
#     user_saved_versions = set(
#         Recipe.objects
#         .filter(created_by=user_id)
#         .values_list('parent', flat=True)
#     )

#     # Combine the lists of interacted, created, and saved versions
#     excluded_recipes = user_created_recipes.union(user_saved_versions)

#     # # Get collaborative filtering recommendations if user is in the interaction matrix
#     # collab_recs = []
#     # if user_id in reconstructed_matrix.index and not reconstructed_matrix.empty:
#     #     user_interactions = reconstructed_matrix.loc[user_id]
#     #     collab_recs = [recipe_id for recipe_id in user_interactions.sort_values(ascending=False).index.tolist() if recipe_id not in excluded_recipes][:top_n]

#     # Get content-based recommendations
#     content_recs = [recipe_id for recipe_id in get_content_based_recommendations(user_id, top_n) if recipe_id not in excluded_recipes]

#     # Combine recommendations without duplicates
#     combined_recs = {}
#     # for i, recipe_id in enumerate(collab_recs):
#     #     combined_recs[recipe_id] = combined_recs.get(recipe_id, 0) + (top_n - i) * collab_weight
#     for i, recipe_id in enumerate(content_recs):
#         combined_recs[recipe_id] = combined_recs.get(recipe_id, 0) + (top_n - i) * content_weight

#     # Sort by combined score
#     sorted_recs = sorted(combined_recs.items(), key=lambda x: x[1], reverse=True)

#     # Ensure no duplicates and return top N recommendations
#     unique_recs = []
#     for recipe_id, _ in sorted_recs:
#         if recipe_id not in excluded_recipes and recipe_id not in unique_recs:
#             unique_recs.append(recipe_id)
#         if len(unique_recs) >= top_n:
#             break

#     # If no recommendations were found, or fewer than top_n, fill with random recipes
#     if len(unique_recs) < top_n:
#         remaining_slots = top_n - len(unique_recs)
#         random_recipes = list(
#             Recipe.objects
#             .exclude(id__in=excluded_recipes)
#             .order_by('?')[:remaining_slots]
#             .values_list('id', flat=True)
#         )
#         unique_recs.extend(random_recipes)

#     return unique_recs[:top_n]

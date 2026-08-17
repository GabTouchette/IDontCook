import hashlib
import logging
import pickle
from collections import defaultdict

import numpy as np
from scipy import sparse
from django.core.cache import cache  # Django's caching system
from django.db.models import Count, Q
from django.utils import timezone
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

from recipes.models import Recipe, SavedRecipe
from recommendations.models import RecipeVector, UserRecipeInteraction, VectorizerArtifact

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


def get_similar_recipes(user_id, top_n=30):
    """
    Recommend recipes similar to the user's own taste profile. Falls back to
    a popularity+recency blend when the user has no profile signal at all
    (cold start), instead of returning nothing.

    The full ranked candidate list is cached per (user, vectorizer version) and
    sliced to `top_n` — scoring the whole catalog by cosine similarity is the
    expensive part (see _rank_similar_recipes) and previously reran on every
    explore/home request, which is what made those pages take 20-30s.
    """
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

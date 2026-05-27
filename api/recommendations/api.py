import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from recipes.models import Recipe
from recommendations.models import UserRecipeInteraction
from django.core.cache import cache  # Django's caching system
import numpy as np



def build_user_profile(user_id):
    """
    Create a user profile based on the recipes the user has created or saved.
    Cache the profile to avoid recalculating it each time.
    """
    cache_key = f"user_profile_{user_id}"
    cached_profile = cache.get(cache_key)
    if cached_profile:
        return cached_profile

    user_recipes = Recipe.objects.filter(created_by=user_id)
    saved_versions = Recipe.objects.filter(created_by=user_id).exclude(parent=None)

    combined_recipes = list(user_recipes) + list(saved_versions)

    if not combined_recipes:
        return None

    df = pd.DataFrame([{
        'id': r.id,
        'combined': f"{r.title or ''} {r.description or ''} " +
                    f"{' '.join(r.tags or [])} " +
                    f"{' '.join(i.name for i in r.ingredients.all())}"
    } for r in combined_recipes])

    tfidf = TfidfVectorizer(stop_words='english')
    vectors = tfidf.fit_transform(df['combined'])

    # Convert sparse matrix mean to ndarray to avoid np.matrix issues
    user_profile_vector = np.asarray(vectors.mean(axis=0)).reshape(1, -1)

    cache.set(cache_key, (tfidf, user_profile_vector), timeout=60 * 60)
    return tfidf, user_profile_vector



def get_similar_recipes(user_id, top_n=30):
    """
    Recommend recipes that are similar to the user's own.
    """
    tfidf, user_profile_vector = build_user_profile(user_id) or (None, None)

    if not tfidf or user_profile_vector is None:
        return []

    # Get other users' recipes (not created or saved by current user)
    # Exclude all recipes created or saved by the user (same as before)
    excluded_ids = Recipe.objects.filter(created_by=user_id).values_list('id', flat=True)
    excluded_user_parents = Recipe.objects.filter(created_by=user_id).exclude(parent=None).values_list('parent', flat=True)

    # NEW: Exclude all recipes that are copies (i.e. have a parent set), regardless of creator
    excluded_all_copies = Recipe.objects.exclude(parent=None).values_list('id', flat=True)

    # Exclude recipes the user has downvoted
    downvoted_ids = UserRecipeInteraction.objects.filter(
        user_id=user_id, interaction_type='downvote'
    ).values_list('recipe_id', flat=True)

    # Final exclusion set
    excluded = set(excluded_ids).union(set(excluded_user_parents)).union(
        set(excluded_all_copies)).union(set(downvoted_ids))

    candidates = Recipe.objects.exclude(id__in=excluded)
    
    df = pd.DataFrame([{
        'id': r.id,
        'combined': f"{r.title or ''} {r.description or ''} " +
                    f"{' '.join(r.tags or [])} " +
                    f"{' '.join(i.name for i in r.ingredients.all())}"
    } for r in candidates])

    if df.empty:
        return []

    # Transform candidate recipes using the same TF-IDF vectorizer
    candidate_vectors = tfidf.transform(df['combined'])

    # Compute cosine similarity between user profile and each candidate
    similarities = cosine_similarity(user_profile_vector, candidate_vectors).flatten()
    df['score'] = similarities

    # Return top N recommended recipe IDs
    top_recipes = df.sort_values(by='score', ascending=False).head(top_n)
    return top_recipes['id'].tolist()








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
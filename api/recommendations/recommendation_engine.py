import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.decomposition import NMF
from recipes.models import Recipe
from recommendations.models import UserRecipeInteraction
from django.db.models import Count

def get_interaction_data():
    """
    Fetch user-recipe interactions from the database and return a DataFrame.
    If no interactions exist, return an empty DataFrame with the required columns.
    """
    interactions = UserRecipeInteraction.objects.all().values('user_id', 'recipe_id', 'interaction_type')
    if not interactions:
        # Return an empty DataFrame with the required columns
        return pd.DataFrame(columns=['user_id', 'recipe_id', 'interaction_type'])
    return pd.DataFrame(list(interactions))

def preprocess_interactions(interactions):
    """
    Preprocess interaction data:
    - Assign weights to interaction types.
    - Create a user-recipe interaction matrix.
    If no interactions exist, return an empty DataFrame.
    """
    if interactions.empty:
        return pd.DataFrame()

    interaction_weights = {
        'like': 3,
        'comment': 1,
        'upvote': 2,
        'downvote': 0,
    }
    interactions['weight'] = interactions['interaction_type'].map(interaction_weights)
    interaction_matrix = interactions.pivot_table(
        index='user_id', columns='recipe_id', values='weight', fill_value=0
    )
    
    return interaction_matrix

def train_collaborative_filtering(interaction_matrix):
    """
    Train a collaborative filtering model using Non-Negative Matrix Factorization (NMF).
    If the interaction matrix is empty, return an empty DataFrame.
    """
    if interaction_matrix.empty:
        return pd.DataFrame()

    # Apply NMF
    model = NMF(n_components=10, init='random', random_state=42, max_iter=100)  # Adjust n_components as needed
    W = model.fit_transform(interaction_matrix)  # User features
    H = model.components_  # Recipe features

    # Reconstruct the interaction matrix
    reconstructed_matrix = pd.DataFrame(W @ H, index=interaction_matrix.index, columns=interaction_matrix.columns)

    return reconstructed_matrix

def get_content_based_recommendations(user_id, top_n=30):
    """
    Generate content-based recommendations using recipe title, ingredients, description, and tags.
    """
    # Get all recipes with their relevant fields
    recipes = Recipe.objects.all().values('id', 'title', 'ingredients', 'description', 'tags')
    recipe_df = pd.DataFrame(list(recipes))
    
    # Combine title, ingredients, description, and tags into a single text field
    recipe_df['combined_features'] = (
        recipe_df['title'].fillna('') + ' ' +
        recipe_df['description'].fillna('') + ' ' +
        recipe_df['tags'].apply(lambda x: ' '.join(x) if isinstance(x, list) else '') + ' ' +
        recipe_df['ingredients'].apply(lambda ingredients: ' '.join([ingredient.name for ingredient in ingredients.all()]) if hasattr(ingredients, 'all') else '')
    )
    
    # Use TF-IDF vectorizer to convert text into feature vectors
    tfidf = TfidfVectorizer(stop_words='english')
    recipe_features = tfidf.fit_transform(recipe_df['combined_features'])
    
    # Calculate cosine similarity between all recipes
    recipe_similarity = cosine_similarity(recipe_features)

    # Get the user’s previously interacted recipes
    user_recipe_ids = recipes.filter(created_by__id=user_id).values_list('id', flat=True)
    similar_recipes = set()
    
    # Find similar recipes based on user interactions
    for recipe_id in user_recipe_ids:
        recipe_index = recipe_df.index[recipe_df['id'] == recipe_id].tolist()[0]
        similar_indices = recipe_similarity[recipe_index].argsort()[-top_n-1:-1][::-1]
        similar_recipes.update(recipe_df.iloc[similar_indices]['id'])

    return list(similar_recipes)[:top_n]

def get_hybrid_recommendations(user_id, top_n=30, collab_weight=0.6, content_weight=0.4):
    """
    Generate hybrid recommendations by combining collaborative and content-based filtering.
    If no recommendations are found, recommend the most upvoted recipes.
    """
    interactions = get_interaction_data()
    interaction_matrix = preprocess_interactions(interactions)
    reconstructed_matrix = train_collaborative_filtering(interaction_matrix)

    # Get the list of recipes the user has created
    user_created_recipes = set(
        Recipe.objects
        .filter(created_by=user_id)
        .values_list('id', flat=True)
    )

    # Get the list of recipes where the user has created a recipe with parent = X
    user_saved_versions = set(
        Recipe.objects
        .filter(created_by=user_id)
        .values_list('parent', flat=True)
    )

    # Combine the lists of interacted, created, and saved versions
    excluded_recipes = user_created_recipes.union(user_saved_versions)

    # Get collaborative filtering recommendations if user is in the interaction matrix
    collab_recs = []
    if user_id in reconstructed_matrix.index and not reconstructed_matrix.empty:
        user_interactions = reconstructed_matrix.loc[user_id]
        collab_recs = [recipe_id for recipe_id in user_interactions.sort_values(ascending=False).index.tolist() if recipe_id not in excluded_recipes][:top_n]

    # Get content-based recommendations
    content_recs = [recipe_id for recipe_id in get_content_based_recommendations(user_id, top_n) if recipe_id not in excluded_recipes]

    # Combine recommendations without duplicates
    combined_recs = {}
    for i, recipe_id in enumerate(collab_recs):
        combined_recs[recipe_id] = combined_recs.get(recipe_id, 0) + (top_n - i) * collab_weight
    for i, recipe_id in enumerate(content_recs):
        combined_recs[recipe_id] = combined_recs.get(recipe_id, 0) + (top_n - i) * content_weight

    # Sort by combined score
    sorted_recs = sorted(combined_recs.items(), key=lambda x: x[1], reverse=True)

    # Ensure no duplicates and return top N recommendations
    unique_recs = []
    for recipe_id, _ in sorted_recs:
        if recipe_id not in excluded_recipes and recipe_id not in unique_recs:
            unique_recs.append(recipe_id)
        if len(unique_recs) >= top_n:
            break
    
    print(unique_recs)
    # If no recommendations were found, or fewer than top_n, fill with random recipes
    if len(unique_recs) < top_n:
        remaining_slots = top_n - len(unique_recs)
        random_recipes = list(
            Recipe.objects
            .exclude(id__in=excluded_recipes)
            .order_by('?')[:remaining_slots]
            .values_list('id', flat=True)
        )
        print(random_recipes)
        unique_recs.extend(random_recipes)

    return unique_recs[:top_n]
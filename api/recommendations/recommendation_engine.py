import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.decomposition import NMF  # Replace Surprise with NMF
from recipes.models import Recipe
from recommendations.models import UserRecipeInteraction

def get_interaction_data():
    """
    Fetch user-recipe interactions from the database and return a DataFrame.
    """
    interactions = UserRecipeInteraction.objects.all().values('user_id', 'recipe_id', 'interaction_type')
    return pd.DataFrame(list(interactions))

def preprocess_interactions(interactions):
    """
    Preprocess interaction data:
    - Assign weights to interaction types.
    - Create a user-recipe interaction matrix.
    """
    interaction_weights = {
        'like': 1,
        'save': 3,
        'comment': 1,
        'upvote': 2,
        'downvote': 0,
    }
    interactions['weight'] = interactions['interaction_type'].map(interaction_weights)
    interaction_matrix = interactions.pivot_table(
        index='user_id', columns='recipe_id', values='weight', fill_value=0
    )
    
    all_users = interactions['user_id'].unique()
    for user in all_users:
        if user not in interaction_matrix.index:
            interaction_matrix.loc[user] = 0

    return interaction_matrix

def train_collaborative_filtering(interaction_matrix):
    """
    Train a collaborative filtering model using Non-Negative Matrix Factorization (NMF).
    """
    # Fill missing values with 0 (no interaction)
    interaction_matrix = interaction_matrix.fillna(0)

    # Apply NMF
    model = NMF(n_components=10, init='random', random_state=42, max_iter=500)  # Adjust n_components as needed
    W = model.fit_transform(interaction_matrix)  # User features
    H = model.components_  # Recipe features

    # Reconstruct the interaction matrix
    reconstructed_matrix = pd.DataFrame(W @ H, index=interaction_matrix.index, columns=interaction_matrix.columns)

    return reconstructed_matrix

def get_content_based_recommendations(user_id, top_n=10):
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
    user_interactions = UserRecipeInteraction.objects.filter(user_id=user_id).values('recipe_id')
    user_recipe_ids = [interaction['recipe_id'] for interaction in user_interactions]
    similar_recipes = set()

    # Find similar recipes based on user interactions
    for recipe_id in user_recipe_ids:
        recipe_index = recipe_df.index[recipe_df['id'] == recipe_id].tolist()[0]
        similar_indices = recipe_similarity[recipe_index].argsort()[-top_n-1:-1][::-1]
        similar_recipes.update(recipe_df.iloc[similar_indices]['id'])

    return list(similar_recipes)[:top_n]

def get_hybrid_recommendations(user_id, top_n=10, collab_weight=0.6, content_weight=0.4):
    """
    Generate hybrid recommendations by combining collaborative and content-based filtering.
    If the user is new, recommend recipes with the highest upvotes, excluding recipes they have saved.
    """
    interactions = get_interaction_data()
    interaction_matrix = preprocess_interactions(interactions)
    reconstructed_matrix = train_collaborative_filtering(interaction_matrix)

    # Get the list of recipes the user has saved
    user_saved_recipes = set(
        UserRecipeInteraction.objects
        .filter(user_id=user_id, interaction_type='save')  # Only exclude saved recipes
        .values_list('recipe_id', flat=True)
    )

    if user_id not in reconstructed_matrix.index:
        # If user is new, recommend recipes sorted by highest upvotes
        top_upvoted_recipes = (
            UserRecipeInteraction.objects
            .filter(interaction_type='upvote')
            .exclude(recipe_id__in=user_saved_recipes)  # Exclude saved recipes
            .values('recipe_id')
            .annotate(upvote_count=pd.Count('recipe_id'))
            .order_by('-upvote_count')[:top_n]
        )
        return [recipe['recipe_id'] for recipe in top_upvoted_recipes]

    # Get collaborative filtering recommendations
    user_interactions = reconstructed_matrix.loc[user_id]
    collab_recs = [recipe_id for recipe_id in user_interactions.sort_values(ascending=False).index.tolist() if recipe_id not in user_saved_recipes][:top_n]

    # Get content-based recommendations
    content_recs = [recipe_id for recipe_id in get_content_based_recommendations(user_id, top_n) if recipe_id not in user_saved_recipes]

    # Combine recommendations
    combined_recs = {}
    for i, recipe_id in enumerate(collab_recs):
        combined_recs[recipe_id] = combined_recs.get(recipe_id, 0) + (top_n - i) * collab_weight
    for i, recipe_id in enumerate(content_recs):
        combined_recs[recipe_id] = combined_recs.get(recipe_id, 0) + (top_n - i) * content_weight

    # Sort by combined score and exclude saved recipes
    sorted_recs = sorted(combined_recs.items(), key=lambda x: x[1], reverse=True)
    
    return [recipe_id for recipe_id, score in sorted_recs if recipe_id not in user_saved_recipes][:top_n]

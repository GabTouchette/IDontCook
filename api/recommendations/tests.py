from django.contrib.auth import get_user_model
from django.test import TestCase
from django.utils import timezone
from datetime import timedelta

from recipes.models import Ingredient, Recipe, SavedRecipe
from recommendations.api import (
    _cold_start_fallback,
    _excluded_recipe_ids,
    build_user_profile,
    get_active_vectorizer,
    get_similar_recipes,
    get_trending_recipes,
    store_recipe_vector,
)
from recommendations.models import RecipeVector, UserRecipeInteraction

User = get_user_model()


def _make_recipe(created_by, title, tags=None, ingredient_names=None, description=""):
    recipe = Recipe.objects.create(
        title=title,
        description=description,
        tags=tags or ["Dinner"],
        created_by=created_by,
    )
    for name in (ingredient_names or []):
        ingredient = Ingredient.objects.create(name=name)
        recipe.ingredients.add(ingredient)
    return recipe


class WeightedProfileRankingTests(TestCase):
    """
    Building a user profile that also weights positive interactions
    (not just created/saved recipes) should change the resulting ranking:
    a recipe similar to something the user *upvoted* should be pulled in as
    a stronger match than when only created/saved recipes are considered.
    """

    def setUp(self):
        self.owner = User.objects.create_user(username="owner", password="pass1234")
        self.other = User.objects.create_user(username="other", password="pass1234")

        # The user's own recipe profile is about "pasta" dishes.
        self.created_recipe = _make_recipe(
            self.owner, "Pasta Night",
            tags=["Dinner"],
            ingredient_names=["pasta", "tomato", "basil"],
            description="Classic Italian pasta dish",
        )

        # A recipe by someone else about "curry" that the owner upvoted.
        self.upvoted_recipe = _make_recipe(
            self.other, "Chicken Curry",
            tags=["Dinner"],
            ingredient_names=["chicken", "curry", "coconut milk"],
            description="Spicy curry dish",
        )

        # Candidate similar to the curry recipe, should rank higher once
        # the upvote is weighted into the profile.
        self.curry_candidate = _make_recipe(
            self.other, "Vegetable Curry",
            tags=["Dinner"],
            ingredient_names=["curry", "coconut milk", "vegetable"],
            description="Spicy curry dish",
        )

        # Candidate similar to the created pasta recipe, should always rank
        # reasonably well since it's directly in the base profile.
        self.pasta_candidate = _make_recipe(
            self.other, "Tomato Basil Pasta",
            tags=["Dinner"],
            ingredient_names=["pasta", "tomato", "basil"],
            description="Classic Italian pasta dish",
        )

        UserRecipeInteraction.objects.create(
            user=self.owner, recipe=self.upvoted_recipe, interaction_type="upvote",
        )

    def test_upvote_pulls_similar_recipe_into_profile(self):
        recommendations = get_similar_recipes(self.owner.id, top_n=10)
        self.assertIn(self.curry_candidate.id, recommendations)

    def test_upvote_outranks_unweighted_profile(self):
        """
        Compare the weighted profile's similarity score for the curry
        candidate against what a pure created/saved-only (unweighted)
        profile would produce. The weighted profile must score it higher.
        """
        tfidf, weighted_vector = build_user_profile(self.owner.id)

        # Build the "unweighted" (created/saved only) profile by hand using
        # the same shared vectorizer, mirroring the old behavior.
        import numpy as np
        from recommendations.api import _recipe_text

        unweighted_vector = np.asarray(
            tfidf.transform([_recipe_text(self.created_recipe)]).mean(axis=0)
        ).reshape(1, -1)

        candidate_vector = tfidf.transform([_recipe_text(self.curry_candidate)])

        from sklearn.metrics.pairwise import cosine_similarity

        weighted_score = cosine_similarity(weighted_vector, candidate_vector)[0][0]
        unweighted_score = cosine_similarity(unweighted_vector, candidate_vector)[0][0]

        self.assertGreater(weighted_score, unweighted_score)

    def test_downvote_exclusion_still_works(self):
        downvoted = _make_recipe(
            self.other, "Downvoted Curry",
            tags=["Dinner"],
            ingredient_names=["curry", "coconut milk"],
        )
        UserRecipeInteraction.objects.create(
            user=self.owner, recipe=downvoted, interaction_type="downvote",
        )
        recommendations = get_similar_recipes(self.owner.id, top_n=50)
        self.assertNotIn(downvoted.id, recommendations)


class ColdStartFallbackTests(TestCase):
    """When a user has no signal at all, get_similar_recipes should fall
    back to a popularity+recency blend instead of returning nothing."""

    def setUp(self):
        self.new_user = User.objects.create_user(username="newbie", password="pass1234")
        self.author = User.objects.create_user(username="author", password="pass1234")

        self.popular_recent = _make_recipe(self.author, "Popular Recent", ingredient_names=["egg"])
        self.popular_old = _make_recipe(self.author, "Popular Old", ingredient_names=["egg"])
        self.unpopular = _make_recipe(self.author, "Unpopular", ingredient_names=["egg"])

        # Make "popular_old" much older than "popular_recent" so recency
        # decay meaningfully separates them despite equal raw popularity.
        old_date = timezone.now() - timedelta(days=120)
        Recipe.objects.filter(id=self.popular_old.id).update(created_at=old_date)

        interested_users = [
            User.objects.create_user(username=f"voter{i}", password="pass1234")
            for i in range(5)
        ]
        for u in interested_users:
            UserRecipeInteraction.objects.create(user=u, recipe=self.popular_recent, interaction_type="upvote")
            UserRecipeInteraction.objects.create(user=u, recipe=self.popular_old, interaction_type="upvote")

    def test_build_user_profile_returns_none_for_no_signal(self):
        self.assertIsNone(build_user_profile(self.new_user.id))

    def test_cold_start_returns_same_shape_as_personalized(self):
        recommendations = get_similar_recipes(self.new_user.id, top_n=10)
        self.assertIsInstance(recommendations, list)
        self.assertTrue(all(isinstance(rid, int) for rid in recommendations))

    def test_cold_start_prefers_popular_recipes(self):
        recommendations = get_similar_recipes(self.new_user.id, top_n=10)
        self.assertIn(self.popular_recent.id, recommendations)
        self.assertIn(self.popular_old.id, recommendations)
        # Unpopular (no interactions) recipe should not outrank the popular ones,
        # and with only 3 candidates total it should rank last (or be absent
        # if the fallback only returns recipes with signal).
        if self.unpopular.id in recommendations:
            self.assertLess(
                recommendations.index(self.popular_recent.id),
                recommendations.index(self.unpopular.id),
            )

    def test_cold_start_recency_decay_ranks_recent_over_old(self):
        excluded = _excluded_recipe_ids(self.new_user.id)
        ranked = _cold_start_fallback(excluded, top_n=10)
        self.assertLess(ranked.index(self.popular_recent.id), ranked.index(self.popular_old.id))


class GetTrendingRecipesTests(TestCase):
    """get_trending_recipes() is the standalone extraction of the
    popularity+recency scorer that used to live only inside
    _cold_start_fallback (docs/plans/catalog-first-pivot.md WS-P1 §4);
    it should reproduce the same recency-decay and popularity-weighting
    behavior, be usable for any user (not just cold-start ones), and
    never surface AI-generated recipes."""

    def setUp(self):
        self.user = User.objects.create_user(username="trend_user", password="pass1234")
        self.author = User.objects.create_user(username="trend_author", password="pass1234")

        self.popular_recent = _make_recipe(self.author, "Trending Recent", ingredient_names=["egg"])
        self.popular_old = _make_recipe(self.author, "Trending Old", ingredient_names=["egg"])
        self.ai_popular = _make_recipe(self.author, "AI Trending", ingredient_names=["egg"])
        self.ai_popular.source = Recipe.SOURCE_AI
        self.ai_popular.save(update_fields=["source"])

        old_date = timezone.now() - timedelta(days=120)
        Recipe.objects.filter(id=self.popular_old.id).update(created_at=old_date)

        interested_users = [
            User.objects.create_user(username=f"trend_voter{i}", password="pass1234")
            for i in range(5)
        ]
        for u in interested_users:
            UserRecipeInteraction.objects.create(user=u, recipe=self.popular_recent, interaction_type="upvote")
            UserRecipeInteraction.objects.create(user=u, recipe=self.popular_old, interaction_type="upvote")
            UserRecipeInteraction.objects.create(user=u, recipe=self.ai_popular, interaction_type="upvote")

    def test_recency_decay_ranks_recent_over_old(self):
        ranked = get_trending_recipes(self.user.id, top_n=10)
        self.assertLess(ranked.index(self.popular_recent.id), ranked.index(self.popular_old.id))

    def test_ai_generated_recipes_excluded(self):
        ranked = get_trending_recipes(self.user.id, top_n=10)
        self.assertNotIn(self.ai_popular.id, ranked)

    def test_respects_exclude_ids(self):
        ranked = get_trending_recipes(self.user.id, exclude_ids=[self.popular_recent.id], top_n=10)
        self.assertNotIn(self.popular_recent.id, ranked)

    def test_cold_start_fallback_delegates_to_trending(self):
        excluded = _excluded_recipe_ids(self.user.id)
        via_cold_start = _cold_start_fallback(excluded, top_n=10)
        via_trending = get_trending_recipes(user_id=None, exclude_ids=excluded, top_n=10)
        self.assertEqual(via_cold_start, via_trending)


class ImageBiasRankingTests(TestCase):
    """Explore/recommendation surfaces heavily bias toward recipes that have
    an image (uploaded file or `web_image_url`); imageless recipes are demoted
    via IMAGELESS_SCORE_PENALTY so they sink to the bottom of the ranking."""

    def setUp(self):
        self.user = User.objects.create_user(username="img_user", password="pass1234")
        self.author = User.objects.create_user(username="img_author", password="pass1234")

        # Two equally-popular, equally-recent recipes; only the difference in
        # image presence should decide their relative order.
        self.with_image = _make_recipe(self.author, "Has Photo", ingredient_names=["egg"])
        self.with_image.web_image_url = "https://example.com/photo.jpg"
        self.with_image.save(update_fields=["web_image_url"])
        self.no_image = _make_recipe(self.author, "No Photo", ingredient_names=["egg"])

        voters = [
            User.objects.create_user(username=f"img_voter{i}", password="pass1234")
            for i in range(5)
        ]
        for u in voters:
            UserRecipeInteraction.objects.create(user=u, recipe=self.with_image, interaction_type="upvote")
            UserRecipeInteraction.objects.create(user=u, recipe=self.no_image, interaction_type="upvote")

    def test_trending_ranks_image_recipe_above_imageless(self):
        ranked = get_trending_recipes(self.user.id, top_n=10)
        self.assertIn(self.with_image.id, ranked)
        self.assertIn(self.no_image.id, ranked)
        self.assertLess(ranked.index(self.with_image.id), ranked.index(self.no_image.id))


class RecipeVectorPrecomputeTests(TestCase):
    """Precomputed RecipeVector rows should produce identical similarity
    results to an on-the-fly transform, and any recipe missing a stored
    vector should fall back gracefully rather than crash or degrade below
    today's behavior."""

    def setUp(self):
        self.owner = User.objects.create_user(username="owner2", password="pass1234")
        self.other = User.objects.create_user(username="other2", password="pass1234")

        self.profile_recipe = _make_recipe(
            self.owner, "Owner Base",
            ingredient_names=["salmon", "lemon", "dill"],
            description="Baked salmon",
        )
        self.candidate_a = _make_recipe(
            self.other, "Candidate A",
            ingredient_names=["salmon", "lemon", "dill"],
            description="Baked salmon fillet",
        )
        self.candidate_b = _make_recipe(
            self.other, "Candidate B",
            ingredient_names=["beef", "potato"],
            description="Beef stew",
        )

    def test_stored_vector_path_matches_on_the_fly(self):
        # Without any stored vectors, everything is computed on-the-fly.
        RecipeVector.objects.all().delete()
        baseline = get_similar_recipes(self.owner.id, top_n=10)

        # Now precompute vectors for all recipes using the active vectorizer
        # and confirm results are identical.
        tfidf, version = get_active_vectorizer()
        for recipe in Recipe.objects.all():
            store_recipe_vector(recipe, tfidf, version)

        with_stored_vectors = get_similar_recipes(self.owner.id, top_n=10)
        self.assertEqual(baseline, with_stored_vectors)

    def test_missing_vector_falls_back_without_crashing(self):
        tfidf, version = get_active_vectorizer()
        # Only store a vector for candidate_b; candidate_a and the profile
        # recipe are intentionally left without stored vectors.
        store_recipe_vector(self.candidate_b, tfidf, version)

        recommendations = get_similar_recipes(self.owner.id, top_n=10)
        self.assertIn(self.candidate_a.id, recommendations)
        # candidate_a (textually identical to the profile) should still
        # outrank candidate_b (unrelated) despite candidate_a missing a
        # stored vector.
        self.assertLess(
            recommendations.index(self.candidate_a.id),
            recommendations.index(self.candidate_b.id),
        )

    def test_stale_version_vector_is_ignored_not_used_as_is(self):
        store_recipe_vector(self.candidate_a, *get_active_vectorizer())
        # Corrupt the stored version tag to simulate a vocabulary refit.
        RecipeVector.objects.filter(recipe=self.candidate_a).update(vectorizer_version="stale-version")

        # Should not crash, and should still return sensible recommendations
        # (falls back to on-the-fly transform for the stale recipe).
        recommendations = get_similar_recipes(self.owner.id, top_n=10)
        self.assertIn(self.candidate_a.id, recommendations)


class RecipeVectorSignalTests(TestCase):
    """Saving a Recipe should (synchronously, since no Celery broker is
    available in tests) populate a RecipeVector for it."""

    def setUp(self):
        self.owner = User.objects.create_user(username="owner3", password="pass1234")

    def test_recipe_save_populates_recipe_vector(self):
        recipe = _make_recipe(self.owner, "Signal Test Recipe", ingredient_names=["egg", "flour"])
        self.assertTrue(RecipeVector.objects.filter(recipe=recipe).exists())

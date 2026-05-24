import unicodedata
from typing import List, Tuple
from recipes.models import Recipe


def _normalize(text: str) -> str:
    """Lowercase and strip accents/diacritics."""
    text = text.lower().strip()
    return ''.join(
        c for c in unicodedata.normalize('NFD', text)
        if unicodedata.category(c) != 'Mn'
    )


def _trigrams(s: str) -> set:
    padded = ' ' + s + ' '
    return {padded[i:i + 3] for i in range(len(padded) - 2)}


def _trigram_similarity(s1: str, s2: str) -> float:
    """Dice-coefficient over trigrams. Returns 0..1."""
    t1, t2 = _trigrams(s1), _trigrams(s2)
    if not t1 or not t2:
        return 0.0
    return 2 * len(t1 & t2) / (len(t1) + len(t2))


def _word_match_score(query_word: str, target_word: str) -> float:
    """
    Returns a similarity score 0..1 between a single query word and a target word.
    - 1.0  exact match
    - 0.85 prefix match (query is a prefix of the target, ≥3 chars)
    - 0.5+ trigram similarity if > 0.5 threshold
    """
    if query_word == target_word:
        return 1.0
    if len(query_word) >= 3 and target_word.startswith(query_word):
        return 0.85
    sim = _trigram_similarity(query_word, target_word)
    return sim if sim >= 0.45 else 0.0


class RecipeSearchEngine:
    def search(self, query: str, recipes: List[Recipe], limit: int = 50) -> List[Tuple[Recipe, float]]:
        query_norm = _normalize(query)
        if not query_norm:
            return []

        query_words = query_norm.split()
        scored_recipes = []

        for recipe in recipes:
            score = 0.0
            title_norm = _normalize(recipe.title or '')
            title_words = title_norm.split()

            # 1. Exact phrase in title — highest priority
            if query_norm in title_norm:
                score += 100

            # 2. All query words matched (exact or fuzzy) — weighted by quality
            if title_words:
                per_word_best = [
                    max((_word_match_score(qw, tw) for tw in title_words), default=0.0)
                    for qw in query_words
                ]
                if per_word_best and min(per_word_best) > 0:
                    avg = sum(per_word_best) / len(per_word_best)
                    score += 60 * avg

                # 3. Per-word partial hits
                for qw in query_words:
                    for tw in title_words:
                        s = _word_match_score(qw, tw)
                        if s > 0:
                            score += s * 8

            # 4. Full-phrase trigram similarity (handles short queries / overall typos)
            phrase_sim = _trigram_similarity(query_norm, title_norm)
            score += phrase_sim * 25

            # 5. Ingredients — exact phrase, then per-word fuzzy
            ingredients_text = _normalize(
                ' '.join(i.name for i in recipe.ingredients.all() if i.name)
            )
            if ingredients_text:
                if query_norm in ingredients_text:
                    score += 6
                else:
                    ingredient_words = ingredients_text.split()
                    for qw in query_words:
                        best = max((_word_match_score(qw, iw) for iw in ingredient_words), default=0.0)
                        if best >= 0.85:
                            score += best * 2

            if score > 0:
                scored_recipes.append((recipe, score))

        # Deterministic sort: score desc, then title asc for ties
        scored_recipes.sort(key=lambda x: (-x[1], x[0].title))
        return scored_recipes[:limit]

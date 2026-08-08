"""Plain-dict builders for the home feed contracts (plan §1.1 / §1.2).

RecipeSummary = {
    "id": int, "title": str, "image_url": str|null,
    "total_time": int|null, "calories": int|null, "tags": [str]
}
"""


def recipe_total_time(recipe):
    """Total time in minutes (preparation + cooking), or None when unknown."""
    prep = recipe.preparation_time
    cook = recipe.cooking_time
    if prep is None and cook is None:
        return None
    return (prep or 0) + (cook or 0)


def recipe_image_url(recipe):
    """Mirrors RecipeSerializer.get_image_url: uploaded image first, then web URL."""
    if recipe.image and hasattr(recipe.image, 'url'):
        return recipe.image.url
    return recipe.web_image_url or None


def recipe_summary(recipe):
    """Build the §1.1 RecipeSummary dict for a Recipe instance."""
    calories = recipe.calories
    return {
        'id': recipe.id,
        'title': recipe.title or '',
        'image_url': recipe_image_url(recipe),
        'total_time': recipe_total_time(recipe),
        'calories': int(round(calories)) if calories is not None else None,
        'tags': list(recipe.tags or []),
    }


def build_module(module_id, module_type, reason, payload):
    """Build the §1.2 Module dict."""
    return {
        'id': module_id,
        'module_type': module_type,
        'reason': reason,
        'payload': payload,
    }

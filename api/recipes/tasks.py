import logging
import threading

from celery import shared_task

from recipes.models import Recipe
from ai_chatbot.api import AnthropicService

logger = logging.getLogger(__name__)


@shared_task
def calculate_recipe_nutrition(recipe_id):
    """Calculate and cache nutrition for a recipe. Idempotent — safe to run
    multiple times. Replaces the raw daemon threads that previously ran this
    inline in the serializer/view (not durable, no retry, no visibility)."""
    logger.info(f"🥦 CELERY TASK STARTED: calculate_recipe_nutrition for recipe_id={recipe_id}")
    try:
        recipe = Recipe.objects.get(id=recipe_id)
    except Recipe.DoesNotExist:
        logger.warning(f"calculate_recipe_nutrition: recipe {recipe_id} not found")
        return f"Recipe {recipe_id} not found"

    recipe.calculate_nutrition()
    logger.info(f"✅ CELERY TASK COMPLETED: nutrition for recipe '{recipe.title}'")
    return f"Calculated nutrition for recipe '{recipe.title}'"


def dispatch_nutrition_calculation(recipe_id):
    """Queue nutrition calculation on Celery, falling back to a daemon thread if
    the broker is unavailable (e.g. local dev without Redis). Mirrors the
    dispatch-or-fallback pattern already used for format_recipe_ingredients."""
    try:
        calculate_recipe_nutrition.delay(recipe_id)
    except Exception as exc:
        logger.warning(
            f"⚠️ Celery dispatch failed for nutrition calc ({exc}); "
            f"running in background thread"
        )
        threading.Thread(
            target=calculate_recipe_nutrition,
            args=(recipe_id,),
            daemon=True,
        ).start()

@shared_task
def format_recipe_ingredients(recipe_id):
    """
    Format recipe ingredients using LLM.
    Also formats parent recipe if it exists and is not already formatted.
    """
    logger.info(f"🚀 CELERY TASK STARTED: format_recipe_ingredients for recipe_id={recipe_id}")
    print(f"🚀 CELERY TASK STARTED: format_recipe_ingredients for recipe_id={recipe_id}")
    
    try:
        recipe = Recipe.objects.get(id=recipe_id)
        logger.info(f"📖 Found recipe: '{recipe.title}' (is_formatted: {recipe.is_formatted})")
        print(f"📖 Found recipe: '{recipe.title}' (is_formatted: {recipe.is_formatted})")
        
        formatted_recipes = []
        
        # Format the main recipe
        if not recipe.is_formatted:
            logger.info(f"🔄 Starting LLM formatting for recipe '{recipe.title}'")
            print(f"🔄 Starting LLM formatting for recipe '{recipe.title}'")
            
            recipe = AnthropicService().llm_format_ingredients(recipe)
            recipe.is_formatted = True
            recipe.save()
            formatted_recipes.append(recipe.title)
            
            logger.info(f"✅ Successfully formatted ingredients for recipe '{recipe.title}'")
            print(f"✅ Successfully formatted ingredients for recipe '{recipe.title}'")
        else:
            logger.info(f"ℹ️ Recipe '{recipe.title}' already formatted - skipping")
            print(f"ℹ️ Recipe '{recipe.title}' already formatted - skipping")
        
        # Format parent recipe if it exists and is not formatted
        if recipe.parent:
            logger.info(f"👥 Found parent recipe: '{recipe.parent.title}' (is_formatted: {recipe.parent.is_formatted})")
            print(f"👥 Found parent recipe: '{recipe.parent.title}' (is_formatted: {recipe.parent.is_formatted})")
            
            if not recipe.parent.is_formatted:
                logger.info(f"🔄 Starting LLM formatting for parent recipe '{recipe.parent.title}'")
                print(f"🔄 Starting LLM formatting for parent recipe '{recipe.parent.title}'")
                
                parent = recipe.parent
                parent = AnthropicService().llm_format_ingredients(parent)
                parent.is_formatted = True
                parent.save()
                formatted_recipes.append(parent.title)
                
                logger.info(f"✅ Successfully formatted ingredients for parent recipe '{parent.title}'")
                print(f"✅ Successfully formatted ingredients for parent recipe '{parent.title}'")
            else:
                logger.info(f"ℹ️ Parent recipe '{recipe.parent.title}' already formatted - skipping")
                print(f"ℹ️ Parent recipe '{recipe.parent.title}' already formatted - skipping")
        else:
            logger.info("👥 No parent recipe found")
            print("👥 No parent recipe found")
        
        result_message = f"Processed ingredients for recipe '{recipe.title}'"
        if formatted_recipes:
            result_message += f". Formatted: {', '.join(formatted_recipes)}"
        
        logger.info(f"🎉 CELERY TASK COMPLETED: {result_message}")
        print(f"🎉 CELERY TASK COMPLETED: {result_message}")
        
        return result_message
        
    except Exception as e:
        error_msg = f"❌ CELERY TASK FAILED for recipe_id={recipe_id}: {str(e)}"
        logger.error(error_msg)
        print(error_msg)
        raise


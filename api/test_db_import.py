#!/usr/bin/env python3
"""
Test scraping 5 recipes and importing them directly to the database
"""

import os
import sys
import django
from allrecipes_scraper import AllrecipesScraper
from import_allrecipes import AllrecipesImporter
import csv
import tempfile
import json

# Setup Django environment
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'api.settings')
django.setup()

from recipes.models import Recipe, Ingredient

def test_db_import_5_recipes():
    """Test scraping 5 recipes and importing them to database"""
    print("🧪 Testing Database Import with 5 Allrecipes")
    print("=" * 60)
    
    scraper = AllrecipesScraper(delay=1)  # Faster for testing
    
    # Get recipe URLs from first category
    print("Step 1: Getting recipe URLs...")
    test_category = scraper.category_urls[0]  
    recipe_urls = scraper.extract_recipe_urls_from_category_page(test_category, max_pages=1)
    
    if not recipe_urls:
        print("❌ No recipe URLs found!")
        return
    
    # Get first 5 recipes
    test_urls = list(recipe_urls)[:5]
    print(f"Found {len(recipe_urls)} total URLs, testing with first 5")
    
    # Step 2: Scrape recipe data
    print("\nStep 2: Scraping recipe data...")
    scraped_recipes = []
    
    for i, url in enumerate(test_urls, 1):
        print(f"  Scraping recipe {i}/5: {url}")
        try:
            recipe_data = scraper.extract_recipe_data(url)
            if recipe_data:
                scraped_recipes.append(recipe_data)
                print(f"    ✅ {recipe_data['title']}")
            else:
                print(f"    ❌ Failed to scrape")
        except Exception as e:
            print(f"    ❌ Error: {e}")
    
    if not scraped_recipes:
        print("❌ No recipes scraped successfully!")
        return
    
    print(f"\n✅ Successfully scraped {len(scraped_recipes)} recipes")
    
    # Step 3: Save to temporary CSV
    print("\nStep 3: Creating temporary CSV...")
    fieldnames = [
        'title', 'description', 'prep_time', 'cook_time', 'total_time', 'servings',
        'ingredients_json', 'instructions_json', 'tags_json', 'image_url',
        'nutrition_calories', 'nutrition_protein', 'nutrition_fat', 'nutrition_carbs',
        'source_url', 'difficulty_level', 'cuisine_type'
    ]
    
    with tempfile.NamedTemporaryFile(mode='w', suffix='.csv', delete=False, encoding='utf-8') as temp_file:
        writer = csv.DictWriter(temp_file, fieldnames=fieldnames, quoting=csv.QUOTE_ALL)
        writer.writeheader()
        for recipe in scraped_recipes:
            writer.writerow(recipe)
        temp_csv_path = temp_file.name
    
    print(f"✅ Created temporary CSV: {temp_csv_path}")
    
    # Step 4: Import to database
    print("\nStep 4: Importing to database...")
    
    # Count recipes before import
    recipes_before = Recipe.objects.count()
    ingredients_before = Ingredient.objects.count()
    
    print(f"Database before: {recipes_before} recipes, {ingredients_before} ingredients")
    
    # Import recipes
    importer = AllrecipesImporter()
    imported_count = importer.import_from_csv(temp_csv_path)
    
    # Count recipes after import
    recipes_after = Recipe.objects.count()
    ingredients_after = Ingredient.objects.count()
    
    print(f"Database after: {recipes_after} recipes, {ingredients_after} ingredients")
    print(f"✅ Imported {imported_count} recipes")
    print(f"📈 Added {recipes_after - recipes_before} recipes, {ingredients_after - ingredients_before} ingredients")
    
    # Step 5: Verify the imported recipes
    print("\nStep 5: Verifying imported recipes...")
    
    for recipe_data in scraped_recipes:
        title = recipe_data['title']
        try:
            db_recipe = Recipe.objects.filter(title=title).first()
            if db_recipe:
                print(f"✅ Found in DB: {title}")
                print(f"   Ingredients: {db_recipe.ingredients.count()}")
                print(f"   Instructions: {len(db_recipe.instructions) if db_recipe.instructions else 0}")
                print(f"   Tags: {len(db_recipe.tags) if db_recipe.tags else 0}")
                print(f"   Calories: {db_recipe.calories}")
                print(f"   Difficulty: {db_recipe.difficulty_level if hasattr(db_recipe, 'difficulty_level') else 'N/A'}")
                
                # Show first ingredient
                first_ingredient = db_recipe.ingredients.first()
                if first_ingredient:
                    print(f"   First ingredient: {first_ingredient.quantity_unit} {first_ingredient.name}")
                    if first_ingredient.preparation:
                        print(f"                    {first_ingredient.preparation}")
                
            else:
                print(f"❌ NOT found in DB: {title}")
        except Exception as e:
            print(f"❌ Error checking {title}: {e}")
    
    # Clean up
    os.unlink(temp_csv_path)
    print(f"\n🧹 Cleaned up temporary file")
    
    print(f"\n🎉 Test Complete!")
    print(f"Successfully imported {imported_count} recipes to your database")
    
    return imported_count > 0

if __name__ == "__main__":
    test_db_import_5_recipes()
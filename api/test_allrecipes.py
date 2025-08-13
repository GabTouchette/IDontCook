#!/usr/bin/env python3
"""
Quick test of Allrecipes scraper with just 5 recipes
"""

from allrecipes_scraper import AllrecipesScraper
import json

def test_5_recipes():
    """Test scraping just 5 recipes to see what we get"""
    print("🍽️  Testing Allrecipes Scraper with 5 recipes")
    print("=" * 50)
    
    scraper = AllrecipesScraper(delay=1)  # Faster for testing
    
    # Test with first category only and limit to 5 recipes
    test_category = scraper.category_urls[0]  # First category
    print(f"Testing category: {test_category}")
    
    # Get recipe URLs from first category
    print("\n=== PART 1: Getting Recipe URLs ===")
    recipe_urls = scraper.extract_recipe_urls_from_category_page(test_category, max_pages=1)
    
    if not recipe_urls:
        print("❌ No recipe URLs found!")
        return
    
    # Limit to first 5 recipes
    test_urls = list(recipe_urls)[:5]
    print(f"Found {len(recipe_urls)} total URLs, testing first {len(test_urls)}")
    
    print("\n=== PART 2: Extracting Recipe Data ===")
    
    for i, url in enumerate(test_urls, 1):
        print(f"\n--- Recipe {i}/5 ---")
        print(f"URL: {url}")
        
        try:
            recipe_data = scraper.extract_recipe_data(url)
            
            if recipe_data:
                print(f"✅ SUCCESS! Here are ALL FIELDS:")
                print("=" * 60)
                
                # Basic Info
                print(f"📝 BASIC INFO:")
                print(f"   Title: {recipe_data['title']}")
                print(f"   Description: {recipe_data['description'][:150]}..." if recipe_data['description'] else "   Description: None")
                print(f"   Source URL: {recipe_data['source_url']}")
                
                # Timing & Servings
                print(f"\n⏱️  TIMING & SERVINGS:")
                print(f"   Prep Time: {recipe_data['prep_time']} minutes")
                print(f"   Cook Time: {recipe_data['cook_time']} minutes") 
                print(f"   Total Time: {recipe_data['total_time']} minutes")
                print(f"   Servings: {recipe_data['servings']}")
                
                # Ingredients (detailed breakdown)
                ingredients = json.loads(recipe_data['ingredients_json'])
                print(f"\n🥘 INGREDIENTS ({len(ingredients)} items):")
                for i, ing in enumerate(ingredients[:3], 1):  # Show first 3
                    print(f"   {i}. Quantity/Unit: '{ing['quantity_unit']}'")
                    print(f"      Name: '{ing['name']}'")
                    print(f"      Preparation: '{ing['preparation']}'")
                    print(f"      Original: '{ing['original_text']}'")
                if len(ingredients) > 3:
                    print(f"   ... and {len(ingredients) - 3} more ingredients")
                
                # Instructions 
                instructions = json.loads(recipe_data['instructions_json'])
                print(f"\n📋 INSTRUCTIONS ({len(instructions)} steps):")
                for i, step in enumerate(instructions[:2], 1):  # Show first 2 steps
                    print(f"   {i}. {step[:100]}..." if len(step) > 100 else f"   {i}. {step}")
                if len(instructions) > 2:
                    print(f"   ... and {len(instructions) - 2} more steps")
                
                # Nutrition
                print(f"\n🍎 NUTRITION:")
                print(f"   Calories: {recipe_data['nutrition_calories']}")
                print(f"   Protein: {recipe_data['nutrition_protein']}g")
                print(f"   Fat: {recipe_data['nutrition_fat']}g")
                print(f"   Carbs: {recipe_data['nutrition_carbs']}g")
                
                # Tags & Categories (including breadcrumbs)
                tags = json.loads(recipe_data['tags_json'])
                print(f"\n🏷️  TAGS & CATEGORIES ({len(tags)} total):")
                if tags:
                    print(f"   Tags: {', '.join(tags)}")
                else:
                    print("   No tags found")
                
                # Difficulty & Image
                print(f"\n⭐ OTHER:")
                print(f"   Difficulty: {recipe_data['difficulty_level']}")
                print(f"   Cuisine Type: {recipe_data['cuisine_type']}")
                print(f"   Image URL: {recipe_data['image_url'][:60]}..." if recipe_data['image_url'] else "   Image URL: None")
                
                print("=" * 60)
                
            else:
                print("❌ Failed to extract recipe data")
                
        except Exception as e:
            print(f"❌ Error: {e}")
    
    print(f"\n=== Test Complete ===")
    print("If this looks good, run the full scraper with:")
    print("python allrecipes_scraper.py")

if __name__ == "__main__":
    test_5_recipes()
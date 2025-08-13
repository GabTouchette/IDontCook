import os
import sys
import csv
import json
import django
from django.db import transaction
from django.utils import timezone
import requests

# Setup Django environment
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'api.settings')
django.setup()

from recipes.models import Recipe, Ingredient, NutritionData
from accounts.models import CustomUser
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class AllrecipesImporter:
    def __init__(self, validate_images=False):
        """Initialize the Allrecipes recipe importer"""
        self.validate_images = validate_images
        
        # Fraction to float conversion mapping
        self.fraction_to_float = {
            '½': 0.5,
            '⅓': 1/3,
            '⅔': 2/3,
            '¼': 0.25,
            '¾': 0.75,
            '⅕': 0.2,
            '⅖': 0.4,
            '⅗': 0.6,
            '⅘': 0.8,
            '⅙': 1/6,
            '⅚': 5/6,
            '⅐': 1/7,
            '⅛': 0.125,
            '⅜': 0.375,
            '⅝': 0.625,
            '⅞': 0.875,
            '⅑': 1/9,
            '⅒': 0.1,
        }
        
        # Get or create a system user for imported recipes
        self.system_user, created = CustomUser.objects.get_or_create(
            username='allrecipes_importer',
            defaults={
                'email': 'allrecipes@system.com',
                'is_active': False  # System user, not for login
            }
        )
        if created:
            logger.info("Created system user for Allrecipes imports")

    def validate_image_url(self, image_url):
        """Validate that image URL is accessible"""
        if not image_url:
            return None
            
        try:
            # Just do a HEAD request to check if the image is accessible
            response = requests.head(image_url, timeout=10)
            if response.status_code == 200:
                return image_url
            else:
                logger.warning(f"Image URL not accessible (status {response.status_code}): {image_url}")
                return None
                
        except Exception as e:
            logger.warning(f"Failed to validate image URL {image_url}: {e}")
            return None

    def convert_quantity_to_float(self, quantity_str):
        """Convert quantity string with fractions to float"""
        if not quantity_str:
            return None
        
        # Handle mixed numbers like "1½" -> "1.5" BEFORE replacing individual fractions
        import re
        
        # Pattern to match whole number followed by fraction
        mixed_pattern = r'(\d+)([⅛⅜⅝⅞¼¾½⅓⅔⅕⅖⅗⅘⅙⅚⅐⅑⅒])'
        matches = re.findall(mixed_pattern, quantity_str)
        
        converted_str = quantity_str
        if matches:
            for whole_num, fraction_char in matches:
                if fraction_char in self.fraction_to_float:
                    mixed_value = int(whole_num) + self.fraction_to_float[fraction_char]
                    # Replace the mixed number in the string
                    original_mixed = whole_num + fraction_char
                    converted_str = converted_str.replace(original_mixed, str(mixed_value))
        else:
            # Only replace individual fraction characters if no mixed numbers found
            for fraction_char, decimal_value in self.fraction_to_float.items():
                converted_str = converted_str.replace(fraction_char, str(decimal_value))
        
        # Now try to convert to float
        try:
            # Handle cases like "1-2" or "1 to 2" by taking the first number
            if '-' in converted_str or 'to' in converted_str.lower():
                parts = re.split(r'[-\s]|to', converted_str, flags=re.IGNORECASE)
                if parts:
                    return float(parts[0].strip())
            
            return float(converted_str)
        except ValueError:
            # If conversion fails, try to extract first number
            numbers = re.findall(r'\d+\.?\d*', converted_str)
            if numbers:
                return float(numbers[0])
            return None

    def create_or_get_ingredient(self, ingredient_data):
        """Create or get an ingredient from parsed data"""
        name = ingredient_data.get('name', '').strip()
        preparation = ingredient_data.get('preparation', '').strip()
        original_text = ingredient_data.get('original_text', '').strip()
        
        # Handle both separate quantity/unit fields and combined quantity_unit field
        quantity = ingredient_data.get('quantity', '').strip() if ingredient_data.get('quantity') else None
        unit = ingredient_data.get('unit', '').strip() if ingredient_data.get('unit') else None
        quantity_unit = ingredient_data.get('quantity_unit', '').strip()
        
        # If we don't have quantity_unit but have separate fields, combine them
        if not quantity_unit and quantity:
            quantity_unit = f"{quantity} {unit}".strip() if unit else quantity
        
        if not name:
            return None
        
        # Try to find existing ingredient with same name and quantity_unit
        existing_ingredient = Ingredient.objects.filter(
            name=name,
            quantity_unit=quantity_unit,
            preparation=preparation
        ).first()
        
        if existing_ingredient:
            return existing_ingredient
        
        # Create new ingredient with separate fields if available
        ingredient_data_to_create = {
            'name': name,
            'quantity_unit': quantity_unit,
            'preparation': preparation,
            'original_text': original_text
        }
        
        # Add separate fields if available
        if quantity:
            try:
                # Convert fraction characters to decimal values
                quantity_to_convert = quantity.split()[0]  # Take first part
                ingredient_data_to_create['quantity'] = self.convert_quantity_to_float(quantity_to_convert)
            except (ValueError, IndexError):
                pass  # Keep quantity as None if conversion fails
                
        if unit:
            ingredient_data_to_create['unit'] = unit
        
        ingredient = Ingredient.objects.create(**ingredient_data_to_create)
        
        logger.debug(f"Created ingredient: {ingredient}")
        return ingredient

    def format_tag(self, tag):
        """Format a tag from kebab-case to Title Case and remove redundant words"""
        if not tag:
            return tag
        
        # Replace hyphens with spaces
        formatted = tag.replace('-', ' ')
        
        # Remove redundant words like 'recipes', 'recipe'
        words_to_remove = ['recipes', 'recipe']
        words = formatted.split()
        filtered_words = [word for word in words if word.lower() not in words_to_remove]
        
        # Join back and capitalize each word
        result = ' '.join(filtered_words).title()
        
        # Handle edge case where removing words results in empty string
        return result if result.strip() else tag.replace('-', ' ').title()

    def parse_tags(self, tags_json):
        """Parse and format tags from JSON"""
        try:
            tags = json.loads(tags_json) if tags_json else []
        except json.JSONDecodeError:
            logger.warning(f"Invalid JSON in tags: {tags_json}")
            return []
        
        # Format tags and remove duplicates
        formatted_tags = []
        for tag in tags:
            if isinstance(tag, str):
                # Format the tag properly
                formatted_tag = self.format_tag(tag.strip())
                if formatted_tag and formatted_tag not in formatted_tags:
                    formatted_tags.append(formatted_tag)
        
        return formatted_tags

    def import_recipe_from_row(self, row):
        """Import a single recipe from CSV row"""
        try:
            title = row.get('title', '').strip()
            if not title:
                logger.warning("Skipping recipe without title")
                return None
            
            # Check if recipe already exists (check by source URL for Allrecipes)
            source_url = row.get('source_url', '').strip()
            existing_recipe = None
            
            if source_url:
                existing_recipe = Recipe.objects.filter(description__contains=source_url).first()
            
            if not existing_recipe:
                existing_recipe = Recipe.objects.filter(title=title).first()
                
            if existing_recipe:
                logger.info(f"Recipe '{title}' already exists, skipping")
                return None  # Return None for existing recipes so we can count them as skipped
            
            # Parse ingredients
            ingredients_data = []
            try:
                ingredients_json = row.get('ingredients_json', '[]')
                ingredients_data = json.loads(ingredients_json) if ingredients_json else []
            except json.JSONDecodeError:
                logger.warning(f"Invalid ingredients JSON for recipe '{title}'")
                ingredients_data = []
            
            # Parse instructions
            instructions = []
            try:
                instructions_json = row.get('instructions_json', '[]')
                instructions = json.loads(instructions_json) if instructions_json else []
            except json.JSONDecodeError:
                logger.warning(f"Invalid instructions JSON for recipe '{title}'")
                instructions = []
            
            # Parse numeric fields
            prep_time = self.safe_int(row.get('prep_time'))
            cook_time = self.safe_int(row.get('cook_time'))
            total_time = self.safe_int(row.get('total_time'))
            servings = self.safe_int(row.get('servings'))
            calories = self.safe_float(row.get('nutrition_calories'))
            protein = self.safe_float(row.get('nutrition_protein'))
            fat = self.safe_float(row.get('nutrition_fat'))
            carbs = self.safe_float(row.get('nutrition_carbs'))
            
            # Parse tags
            tags = self.parse_tags(row.get('tags_json', '[]'))
            
            # Prepare description with source attribution
            description = row.get('description', '').strip()
            if source_url:
                if description:
                    description += f"\n\nSource: {source_url}"
                else:
                    description = f"Source: {source_url}"
            
            # Create recipe
            with transaction.atomic():
                recipe = Recipe.objects.create(
                    title=title,
                    description=description,
                    preparation_time=prep_time,
                    cooking_time=cook_time,
                    servings=servings,
                    instructions=instructions,
                    tags=tags,
                    web_image_url=row.get('image_url', '').strip(),
                    calories=calories,
                    protein=protein,
                    fat=fat,
                    carbs=carbs,
                    created_by=self.system_user,
                    is_formatted=True,
                    is_nutrition_calculated=bool(calories)
                    # Note: difficulty_level not stored in model, just used for CSV
                )
                
                # Create and link ingredients
                for ingredient_data in ingredients_data:
                    ingredient = self.create_or_get_ingredient(ingredient_data)
                    if ingredient:
                        recipe.ingredients.add(ingredient)
                
                # Set image URL (don't download, just use public URL)
                image_url = row.get('image_url', '').strip()
                if image_url:
                    if self.validate_images:
                        validated_url = self.validate_image_url(image_url)
                        if validated_url:
                            recipe.web_image_url = validated_url
                            recipe.save()
                    else:
                        # Just use the URL without validation for faster imports
                        recipe.web_image_url = image_url
                        recipe.save()
                
                logger.info(f"Successfully imported Allrecipes recipe: {title}")
                return recipe
                
        except Exception as e:
            logger.error(f"Error importing recipe '{row.get('title', 'Unknown')}': {e}")
            return None

    def safe_int(self, value):
        """Safely convert value to int, return None if invalid"""
        if not value:
            return None
        try:
            return int(float(value))
        except (ValueError, TypeError):
            return None

    def safe_float(self, value):
        """Safely convert value to float, return None if invalid"""
        if not value:
            return None
        try:
            return float(value)
        except (ValueError, TypeError):
            return None

    def import_from_csv(self, csv_file_path):
        """Import all recipes from CSV file"""
        if not os.path.exists(csv_file_path):
            logger.error(f"CSV file not found: {csv_file_path}")
            return
        
        imported_count = 0
        skipped_count = 0
        error_count = 0
        
        logger.info(f"Starting import from {csv_file_path}")
        
        with open(csv_file_path, 'r', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)
            
            for row_num, row in enumerate(reader, 1):
                try:
                    recipe = self.import_recipe_from_row(row)
                    if recipe:
                        imported_count += 1
                    else:
                        # None means either error or skipped (existing recipe)
                        # Check if it was a skip (title exists) or error (no title/other issue)
                        title = row.get('title', '').strip()
                        source_url = row.get('source_url', '').strip()
                        
                        if title and (Recipe.objects.filter(title=title).exists() or 
                                    (source_url and Recipe.objects.filter(description__contains=source_url).exists())):
                            skipped_count += 1
                        else:
                            error_count += 1
                        
                except Exception as e:
                    logger.error(f"Error processing row {row_num}: {e}")
                    error_count += 1
                
                # Progress update every 25 recipes
                if row_num % 25 == 0:
                    logger.info(f"Processed {row_num} rows: {imported_count} imported, {skipped_count} skipped, {error_count} errors")
        
        logger.info(f"Import completed: {imported_count} imported, {skipped_count} skipped, {error_count} errors")
        return imported_count

def main():
    """Main function to run the import"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Import Allrecipes from CSV')
    parser.add_argument('csv_file', help='Path to the CSV file containing recipes')
    parser.add_argument('--validate-images', action='store_true', 
                       help='Validate that image URLs are accessible')
    
    args = parser.parse_args()
    
    importer = AllrecipesImporter(validate_images=args.validate_images)
    imported_count = importer.import_from_csv(args.csv_file)
    
    print(f"\nImport completed successfully!")
    print(f"Total Allrecipes imported: {imported_count}")

if __name__ == "__main__":
    main()
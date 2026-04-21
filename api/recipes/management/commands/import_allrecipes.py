"""
Django Management Command: import_allrecipes

PURPOSE:
This command imports recipe data from Allrecipes CSV files into the Django database.
It converts the original standalone import script into a proper Django management command.

WHAT IT DOES:
- Imports recipes from CSV files with full recipe data (title, description, ingredients, instructions, etc.)
- Creates Recipe objects with nutrition information and cooking details
- Parses ingredient lists and creates Ingredient objects with quantities and units
- Handles duplicate detection by checking existing recipe names
- Supports dry-run mode for previewing imports without database changes
- Provides progress tracking and comprehensive logging
- Validates image URLs and handles long URLs (up to 500 characters)

HOW IT WORKS:
1. Reads CSV file with Allrecipes data (title, description, ingredients, instructions, nutrition, etc.)
2. For each row, checks if recipe already exists by name to avoid duplicates
3. Parses ingredients string into individual Ingredient objects with quantities/units
4. Creates Recipe object with all metadata (cook time, servings, difficulty, etc.)
5. Associates parsed ingredients with the recipe
6. Handles nutrition data and dietary information
7. Logs progress every 25 recipes and provides final summary

CSV FORMAT EXPECTED:
- title: Recipe name
- description: Recipe description/summary  
- ingredients: Comma-separated ingredient list with quantities
- instructions: Step-by-step cooking instructions
- prep_time, cook_time: Time values in minutes
- servings: Number of servings
- difficulty: easy/medium/hard
- web_image_url: URL to recipe image
- calories, protein, fat, carbs: Nutrition values

USAGE:
    # Import recipes from CSV file
    python manage.py import_allrecipes misc/allrecipes_data.csv
    
    # Preview import without saving to database
    python manage.py import_allrecipes misc/allrecipes_data.csv --dry-run
    
    # Import with image URL validation
    python manage.py import_allrecipes misc/allrecipes_data.csv --validate-images

NOTES:
- Tag extraction logic has been commented out and will be handled separately
- Recipe tags should be added using the auto_tag_recipes command after import
- Duplicate recipes are skipped based on exact title matching
- Failed imports are logged but don't stop the process
"""

from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone
import csv
import json
import os
import requests
import logging

from recipes.models import Recipe, Ingredient, NutritionData
from accounts.models import CustomUser

class Command(BaseCommand):
    help = 'Import Allrecipes from CSV file'

    def add_arguments(self, parser):
        parser.add_argument(
            'csv_file',
            type=str,
            help='Path to the CSV file containing recipes'
        )
        parser.add_argument(
            '--validate-images',
            action='store_true',
            help='Validate that image URLs are accessible (slower)',
        )
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Show what would be imported without actually creating recipes',
        )

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        
        # Configure logging
        logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
        self.logger = logging.getLogger(__name__)
        
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

    def handle(self, *args, **options):
        csv_file_path = options['csv_file']
        validate_images = options['validate_images']
        dry_run = options['dry_run']
        
        if dry_run:
            self.stdout.write(self.style.WARNING('DRY RUN MODE - No recipes will be created'))
        
        if not os.path.exists(csv_file_path):
            self.stdout.write(self.style.ERROR(f'CSV file not found: {csv_file_path}'))
            return
        
        # Get or create system user for imported recipes
        system_user, created = CustomUser.objects.get_or_create(
            username='allrecipes_importer',
            defaults={
                'email': 'allrecipes@system.com',
                'is_active': False  # System user, not for login
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS("Created system user for Allrecipes imports"))
        
        imported_count = 0
        skipped_count = 0
        error_count = 0
        
        self.stdout.write(f"Starting import from {csv_file_path}")
        
        with open(csv_file_path, 'r', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)
            
            for row_num, row in enumerate(reader, 1):
                try:
                    result = self.import_recipe_from_row(row, system_user, validate_images, dry_run)
                    if result == 'imported':
                        imported_count += 1
                    elif result == 'skipped':
                        skipped_count += 1
                    else:  # error or None
                        error_count += 1
                        
                except Exception as e:
                    self.logger.error(f"Error processing row {row_num}: {e}")
                    error_count += 1
                
                # Progress update every 25 recipes
                if row_num % 25 == 0:
                    self.stdout.write(f"Processed {row_num} rows: {imported_count} imported, {skipped_count} skipped, {error_count} errors")
        
        # Final summary
        if dry_run:
            self.stdout.write(self.style.SUCCESS(f"DRY RUN completed: Would import {imported_count}, skip {skipped_count}, {error_count} errors"))
        else:
            self.stdout.write(self.style.SUCCESS(f"Import completed: {imported_count} imported, {skipped_count} skipped, {error_count} errors"))

    def import_recipe_from_row(self, row, system_user, validate_images, dry_run):
        """Import a single recipe from CSV row"""
        try:
            title = row.get('title', '').strip()
            if not title:
                self.logger.warning("Skipping recipe without title")
                return 'error'
            
            # Check if recipe already exists (check by source URL for Allrecipes)
            source_url = row.get('source_url', '').strip()
            existing_recipe = None
            
            if source_url:
                existing_recipe = Recipe.objects.filter(description__contains=source_url).first()
            
            if not existing_recipe:
                existing_recipe = Recipe.objects.filter(title=title).first()
                
            if existing_recipe:
                self.logger.info(f"Recipe '{title}' already exists, skipping")
                return 'skipped'
            
            if dry_run:
                self.stdout.write(f"Would import: {title}")
                return 'imported'
            
            # Parse ingredients
            ingredients_data = []
            try:
                ingredients_json = row.get('ingredients_json', '[]')
                ingredients_data = json.loads(ingredients_json) if ingredients_json else []
            except json.JSONDecodeError:
                self.logger.warning(f"Invalid ingredients JSON for recipe '{title}'")
                ingredients_data = []
            
            # Parse instructions
            instructions = []
            try:
                instructions_json = row.get('instructions_json', '[]')
                instructions = json.loads(instructions_json) if instructions_json else []
            except json.JSONDecodeError:
                self.logger.warning(f"Invalid instructions JSON for recipe '{title}'")
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
            
            # Parse tags - COMMENTED OUT FOR NOW
            # tags = self.parse_tags(row.get('tags_json', '[]'))
            tags = []  # Empty tags list for now
            
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
                    created_by=system_user,
                    is_formatted=True,
                    is_nutrition_calculated=bool(calories)
                )
                
                # Create and link ingredients
                for ingredient_data in ingredients_data:
                    ingredient = self.create_or_get_ingredient(ingredient_data)
                    if ingredient:
                        recipe.ingredients.add(ingredient)
                
                # Set image URL (don't download, just use public URL)
                image_url = row.get('image_url', '').strip()
                if image_url:
                    if validate_images:
                        validated_url = self.validate_image_url(image_url)
                        if validated_url:
                            recipe.web_image_url = validated_url
                            recipe.save()
                    else:
                        # Just use the URL without validation for faster imports
                        recipe.web_image_url = image_url
                        recipe.save()
                
                self.logger.info(f"Successfully imported Allrecipes recipe: {title}")
                return 'imported'
                
        except Exception as e:
            self.logger.error(f"Error importing recipe '{row.get('title', 'Unknown')}': {e}")
            return 'error'

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
                self.logger.warning(f"Image URL not accessible (status {response.status_code}): {image_url}")
                return None
                
        except Exception as e:
            self.logger.warning(f"Failed to validate image URL {image_url}: {e}")
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
        
        self.logger.debug(f"Created ingredient: {ingredient}")
        return ingredient

    # COMMENTED OUT TAG PARSING FOR NOW
    # def format_tag(self, tag):
    #     """Format a tag from kebab-case to Title Case and remove redundant words"""
    #     if not tag:
    #         return tag
    #     
    #     # Replace hyphens with spaces
    #     formatted = tag.replace('-', ' ')
    #     
    #     # Remove redundant words like 'recipes', 'recipe'
    #     words_to_remove = ['recipes', 'recipe']
    #     words = formatted.split()
    #     filtered_words = [word for word in words if word.lower() not in words_to_remove]
    #     
    #     # Join back and capitalize each word
    #     result = ' '.join(filtered_words).title()
    #     
    #     # Handle edge case where removing words results in empty string
    #     return result if result.strip() else tag.replace('-', ' ').title()

    # def parse_tags(self, tags_json):
    #     """Parse and format tags from JSON"""
    #     try:
    #         tags = json.loads(tags_json) if tags_json else []
    #     except json.JSONDecodeError:
    #         self.logger.warning(f"Invalid JSON in tags: {tags_json}")
    #         return []
    #     
    #     # Format tags and remove duplicates
    #     formatted_tags = []
    #     for tag in tags:
    #         if isinstance(tag, str):
    #             # Format the tag properly
    #             formatted_tag = self.format_tag(tag.strip())
    #             if formatted_tag and formatted_tag not in formatted_tags:
    #                 formatted_tags.append(formatted_tag)
    #     
    #     return formatted_tags

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

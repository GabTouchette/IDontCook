#!/usr/bin/env python3
"""
Generic importer for scraper CSVs (Serious Eats, Simply Recipes, ...).

Same CSV schema and import logic as ``import_allrecipes.py`` — fraction
conversion, ingredient normalisation, source-URL dedup, tag formatting — but the
attribution user is parametrised via ``--source`` so each site gets its own
system user (e.g. ``seriouseats_importer``).

Usage:
    venv/bin/python misc/import_scraped_recipes.py seriouseats_data.csv --source seriouseats
    venv/bin/python misc/import_scraped_recipes.py simplyrecipes_data.csv --source simplyrecipes
"""

import os
import sys
import csv
import json
import logging

import django
from django.db import transaction, connection
import requests

# Setup Django: ensure the project root (outer 'api' folder) is on sys.path.
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "api.settings")
django.setup()

from recipes.models import Recipe, Ingredient  # noqa: E402
from recipes.ingredient_normalizer import normalize_name_and_prep  # noqa: E402
from accounts.models import CustomUser  # noqa: E402

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

FRACTION_TO_FLOAT = {
    "½": 0.5, "⅓": 1 / 3, "⅔": 2 / 3, "¼": 0.25, "¾": 0.75, "⅕": 0.2, "⅖": 0.4,
    "⅗": 0.6, "⅘": 0.8, "⅙": 1 / 6, "⅚": 5 / 6, "⅐": 1 / 7, "⅛": 0.125,
    "⅜": 0.375, "⅝": 0.625, "⅞": 0.875, "⅑": 1 / 9, "⅒": 0.1,
}


class ScrapedRecipeImporter:
    def __init__(self, source: str, validate_images: bool = False):
        self.source = source
        self.validate_images = validate_images
        username = f"{source}_importer"
        self.system_user, created = CustomUser.objects.get_or_create(
            username=username,
            defaults={"email": f"{source}@system.com", "is_active": False},
        )
        if created:
            logger.info("Created system user '%s' for %s imports", username, source)

    # ---- helpers -----------------------------------------------------------
    def validate_image_url(self, image_url):
        if not image_url:
            return None
        try:
            resp = requests.head(image_url, timeout=10)
            return image_url if resp.status_code == 200 else None
        except Exception as e:
            logger.warning("Failed to validate image URL %s: %s", image_url, e)
            return None

    def convert_quantity_to_float(self, quantity_str):
        if not quantity_str:
            return None
        import re

        converted = quantity_str
        mixed = re.findall(r"(\d+)([⅛⅜⅝⅞¼¾½⅓⅔⅕⅖⅗⅘⅙⅚⅐⅑⅒])", quantity_str)
        if mixed:
            for whole, frac in mixed:
                if frac in FRACTION_TO_FLOAT:
                    converted = converted.replace(whole + frac, str(int(whole) + FRACTION_TO_FLOAT[frac]))
        else:
            for frac, val in FRACTION_TO_FLOAT.items():
                converted = converted.replace(frac, str(val))
        try:
            if "-" in converted or "to" in converted.lower():
                parts = re.split(r"[-\s]|to", converted, flags=re.IGNORECASE)
                if parts:
                    return float(parts[0].strip())
            return float(converted)
        except ValueError:
            nums = re.findall(r"\d+\.?\d*", converted)
            return float(nums[0]) if nums else None

    def create_or_get_ingredient(self, ingredient_data):
        name = (ingredient_data.get("name") or "").strip()
        preparation = (ingredient_data.get("preparation") or "").strip()
        original_text = (ingredient_data.get("original_text") or "").strip()
        quantity = (ingredient_data.get("quantity") or "").strip() if ingredient_data.get("quantity") else None
        unit = (ingredient_data.get("unit") or "").strip() if ingredient_data.get("unit") else None
        quantity_unit = (ingredient_data.get("quantity_unit") or "").strip()

        if not quantity_unit and quantity:
            quantity_unit = f"{quantity} {unit}".strip() if unit else quantity
        if not name:
            return None

        canonical_name, prep_from_name = normalize_name_and_prep(name)
        if canonical_name:
            name = canonical_name
        if not preparation and prep_from_name:
            preparation = prep_from_name

        existing = Ingredient.objects.filter(
            name=name, quantity_unit=quantity_unit, preparation=preparation
        ).first()
        if existing:
            return existing

        data = {"name": name, "quantity_unit": quantity_unit,
                "preparation": preparation, "original_text": original_text}
        if quantity:
            try:
                data["quantity"] = self.convert_quantity_to_float(quantity.split()[0])
            except (ValueError, IndexError):
                pass
        if unit:
            data["unit"] = unit
        return Ingredient.objects.create(**data)

    def format_tag(self, tag):
        if not tag:
            return tag
        formatted = tag.replace("-", " ")
        words = [w for w in formatted.split() if w.lower() not in ("recipes", "recipe")]
        result = " ".join(words).title()
        return result if result.strip() else tag.replace("-", " ").title()

    def parse_tags(self, tags_json):
        try:
            tags = json.loads(tags_json) if tags_json else []
        except json.JSONDecodeError:
            logger.warning("Invalid JSON in tags: %s", tags_json)
            return []
        out = []
        for tag in tags:
            if isinstance(tag, str):
                ft = self.format_tag(tag.strip())
                if ft and ft not in out:
                    out.append(ft)
        return out

    def safe_int(self, value):
        if not value:
            return None
        try:
            return int(float(value))
        except (ValueError, TypeError):
            return None

    def safe_float(self, value):
        if not value:
            return None
        try:
            return float(value)
        except (ValueError, TypeError):
            return None

    # ---- import ------------------------------------------------------------
    def import_recipe_from_row(self, row):
        try:
            title = (row.get("title") or "").strip()
            if not title:
                logger.warning("Skipping recipe without title")
                return None

            source_url = (row.get("source_url") or "").strip()
            existing = None
            if source_url:
                existing = Recipe.objects.filter(description__contains=source_url).first()
            if not existing:
                existing = Recipe.objects.filter(title=title).first()
            if existing:
                logger.info("Recipe '%s' already exists, skipping", title)
                return None

            try:
                ingredients_data = json.loads(row.get("ingredients_json") or "[]")
            except json.JSONDecodeError:
                logger.warning("Invalid ingredients JSON for '%s'", title)
                ingredients_data = []
            try:
                instructions = json.loads(row.get("instructions_json") or "[]")
            except json.JSONDecodeError:
                logger.warning("Invalid instructions JSON for '%s'", title)
                instructions = []

            prep_time = self.safe_int(row.get("prep_time"))
            cook_time = self.safe_int(row.get("cook_time"))
            servings = self.safe_int(row.get("servings"))
            calories = self.safe_float(row.get("nutrition_calories"))
            protein = self.safe_float(row.get("nutrition_protein"))
            fat = self.safe_float(row.get("nutrition_fat"))
            carbs = self.safe_float(row.get("nutrition_carbs"))
            tags = self.parse_tags(row.get("tags_json", "[]"))

            description = (row.get("description") or "").strip()
            if source_url:
                description = f"{description}\n\nSource: {source_url}" if description else f"Source: {source_url}"

            with transaction.atomic():
                recipe = Recipe.objects.create(
                    title=title,
                    description=description,
                    preparation_time=prep_time,
                    cooking_time=cook_time,
                    servings=servings,
                    instructions=instructions,
                    tags=tags,
                    web_image_url=(row.get("image_url") or "").strip(),
                    calories=calories,
                    protein=protein,
                    fat=fat,
                    carbs=carbs,
                    created_by=self.system_user,
                    is_formatted=True,
                    is_nutrition_calculated=bool(calories),
                )
                for ing in ingredients_data:
                    ingredient = self.create_or_get_ingredient(ing)
                    if ingredient:
                        recipe.ingredients.add(ingredient)

                image_url = (row.get("image_url") or "").strip()
                if image_url:
                    if self.validate_images:
                        validated = self.validate_image_url(image_url)
                        if validated:
                            recipe.web_image_url = validated
                            recipe.save()
                    else:
                        recipe.web_image_url = image_url
                        recipe.save()

                logger.info("Imported %s recipe: %s", self.source, title)
                return recipe
        except Exception as e:
            logger.error("Error importing '%s': %s", row.get("title", "Unknown"), e)
            # A dropped DB connection (common over a remote/proxied DB connection on
            # long runs) leaves the connection unusable — every later row would fail
            # with "connection already closed". Close it so Django reconnects next row.
            try:
                connection.close()
            except Exception:
                pass
            return None

    def import_from_csv(self, csv_file_path):
        if not os.path.exists(csv_file_path):
            logger.error("CSV file not found: %s", csv_file_path)
            return 0

        imported = skipped = errors = 0
        logger.info("Starting import from %s (source=%s)", csv_file_path, self.source)
        with open(csv_file_path, "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for row_num, row in enumerate(reader, 1):
                try:
                    if self.import_recipe_from_row(row):
                        imported += 1
                    else:
                        title = (row.get("title") or "").strip()
                        source_url = (row.get("source_url") or "").strip()
                        if title and (Recipe.objects.filter(title=title).exists() or
                                      (source_url and Recipe.objects.filter(description__contains=source_url).exists())):
                            skipped += 1
                        else:
                            errors += 1
                except Exception as e:
                    logger.error("Error processing row %d: %s", row_num, e)
                    errors += 1
                if row_num % 25 == 0:
                    logger.info("Processed %d rows: %d imported, %d skipped, %d errors",
                                row_num, imported, skipped, errors)
        logger.info("Import completed: %d imported, %d skipped, %d errors", imported, skipped, errors)
        return imported


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Import scraped recipes from CSV")
    parser.add_argument("csv_file", help="Path to the CSV file")
    parser.add_argument("--source", required=True,
                        help="Source label for attribution (e.g. seriouseats, simplyrecipes)")
    parser.add_argument("--validate-images", action="store_true",
                        help="HEAD-check image URLs before saving (slower)")
    args = parser.parse_args()

    importer = ScrapedRecipeImporter(source=args.source, validate_images=args.validate_images)
    imported = importer.import_from_csv(args.csv_file)
    print(f"\nImport completed! Total {args.source} imported: {imported}")


if __name__ == "__main__":
    main()

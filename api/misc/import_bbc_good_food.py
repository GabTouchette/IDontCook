"""
BBC Good Food CSV → Django database importer.

CSV columns (produced by bbc_good_food_scraper.py):
  title, image, prepTime, cookTime, recipeIngredients, recipeInstructions,
  recipeYield, description, tags

Usage:
  # Local dev database
  python misc/import_bbc_good_food.py bbc_1000.csv

  # Production database (Railway)
  DATABASE_URL=<prod_url> python misc/import_bbc_good_food.py bbc_1000.csv

  # Dry run (no DB writes)
  python misc/import_bbc_good_food.py bbc_1000.csv --dry-run

  # Skip image-URL validation (faster; default)
  python misc/import_bbc_good_food.py bbc_1000.csv --validate-images
"""

import os
import sys
import csv
import re
import argparse
import logging
from datetime import timedelta

# ── Django setup ──────────────────────────────────────────────────────────────
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "api.settings")

import django
django.setup()

from django.db import transaction
import requests as http_requests

from recipes.models import Recipe, Ingredient
from recipes.ingredient_normalizer import normalize_name_and_prep
from accounts.models import CustomUser

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

# ── Meal-type inference ───────────────────────────────────────────────────────
# BBC Good Food tags that map to the required meal-type labels.
# Order matters: first match wins.
_MEAL_TYPE_MAP = [
    ("Breakfast",  ["breakfast", "brunch"]),
    ("Dessert",    ["dessert", "desserts", "pudding", "puddings", "cake", "cakes",
                    "biscuit", "biscuits", "cookie", "cookies", "sweet treat",
                    "sweet treats", "chocolate", "ice cream", "pastry", "tart",
                    "cheesecake", "brownie", "cupcake"]),
    ("Snack",      ["snack", "snacks", "starter", "starters", "appetiser",
                    "appetizer", "canape", "canapé", "dip", "dips", "side dish",
                    "sides", "bread", "rolls", "bun", "buns"]),
    ("Lunch",      ["lunch", "salad", "salads", "sandwich", "sandwiches", "wrap",
                    "soup", "soups", "light meal", "light meals"]),
    ("Dinner",     ["dinner", "mains", "main", "supper", "midweek meal",
                    "midweek meals", "one-pot", "one pot", "slow cooker",
                    "casserole", "stew", "curry", "pasta", "pizza", "roast",
                    "traybake", "bbq", "barbecue"]),
]
_DRINK_KEYWORDS = ["cocktail", "drink", "drinks", "smoothie", "juice", "lemonade",
                   "mocktail", "punch", "shake", "milkshake", "hot chocolate"]


def infer_meal_type(tags: list[str], title: str) -> str | None:
    """
    Return the single meal-type tag required by the Recipe.clean() validator.
    Returns None for drinks/cocktails (which may omit a meal-type tag).
    """
    combined = " ".join(t.lower() for t in tags) + " " + title.lower()

    for kw in _DRINK_KEYWORDS:
        if kw in combined:
            return None  # drinks don't need a meal-type

    for meal_type, keywords in _MEAL_TYPE_MAP:
        for kw in keywords:
            if kw in combined:
                return meal_type

    return "Dinner"  # sensible fallback for unclassified savoury recipes


# ── Duration parsing (ISO 8601: PT5M, PT1H30M, PT1H) ─────────────────────────
_ISO_DURATION = re.compile(
    r"^PT(?:(?P<hours>\d+)H)?(?:(?P<minutes>\d+)M)?(?:(?P<seconds>\d+)S)?$",
    re.IGNORECASE,
)


def parse_iso_duration_to_minutes(value: str) -> int | None:
    """Convert an ISO 8601 duration string to total minutes (rounded)."""
    if not value:
        return None
    m = _ISO_DURATION.match(value.strip())
    if not m:
        return None
    hours   = int(m.group("hours")   or 0)
    minutes = int(m.group("minutes") or 0)
    seconds = int(m.group("seconds") or 0)
    total = hours * 60 + minutes + round(seconds / 60)
    return total or None  # return None for PT0S / zero durations


# ── Serving count extraction ──────────────────────────────────────────────────
_SERVING_NUM = re.compile(r"(\d+)")


def parse_servings(recipe_yield: str) -> int | None:
    """Extract the first integer from a yield string like 'Serves 4' or '12'."""
    if not recipe_yield:
        return None
    m = _SERVING_NUM.search(recipe_yield)
    return int(m.group(1)) if m else None


# ── Ingredient helpers ────────────────────────────────────────────────────────

def get_or_create_ingredient(raw_text: str) -> Ingredient | None:
    """
    Parse a raw ingredient line (e.g. "2 tbsp toasted sesame oil") into an
    Ingredient record, reusing existing records when possible.
    """
    raw_text = raw_text.strip()
    if not raw_text:
        return None

    # Try the normaliser; fall back gracefully
    try:
        canonical_name, preparation = normalize_name_and_prep(raw_text)
        name = canonical_name or raw_text
    except Exception:
        name = raw_text
        preparation = ""

    # Check for an existing match to avoid duplicates
    existing = Ingredient.objects.filter(
        original_text=raw_text,
    ).first()
    if existing:
        return existing

    return Ingredient.objects.create(
        name=name,
        preparation=preparation or "",
        original_text=raw_text,
        language="en",
    )


# ── Main importer class ───────────────────────────────────────────────────────

class BBCGoodFoodImporter:

    SYSTEM_USERNAME = "bbc_good_food_importer"

    def __init__(self, dry_run: bool = False, validate_images: bool = False):
        self.dry_run = dry_run
        self.validate_images = validate_images
        self.system_user = self._get_system_user()

    def _get_system_user(self) -> CustomUser:
        if self.dry_run:
            # Return a dummy-ish user object without hitting the DB
            return CustomUser(username=self.SYSTEM_USERNAME, is_active=False)
        user, created = CustomUser.objects.get_or_create(
            username=self.SYSTEM_USERNAME,
            defaults={
                "email": "bbcgoodfood@system.com",
                "is_active": False,
            },
        )
        if created:
            logger.info(f"Created system user '{self.SYSTEM_USERNAME}'")
        return user

    # ── Image URL validation ──────────────────────────────────────────────────

    def _validate_image_url(self, url: str) -> str | None:
        if not url:
            return None
        try:
            r = http_requests.head(url, timeout=8)
            return url if r.status_code == 200 else None
        except Exception as e:
            logger.warning(f"Image URL unreachable: {url} — {e}")
            return None

    # ── Single-row import ─────────────────────────────────────────────────────

    def import_row(self, row: dict) -> bool:
        """
        Import one CSV row.  Returns True on success, False on skip/error.
        """
        title = row.get("title", "").strip()
        if not title:
            logger.warning("Skipping row: no title")
            return False

        # Dedup: skip if title already in DB
        if not self.dry_run and Recipe.objects.filter(title=title).exists():
            logger.debug(f"Already exists, skipping: {title}")
            return False

        # ── Parse fields ──────────────────────────────────────────────────────
        prep_time   = parse_iso_duration_to_minutes(row.get("prepTime", ""))
        cook_time   = parse_iso_duration_to_minutes(row.get("cookTime", ""))
        recipe_yield = row.get("recipeYield", "").strip()
        servings    = parse_servings(recipe_yield)
        description = row.get("description", "").strip()
        image_url   = row.get("image", "").strip()

        raw_ingredients  = [s.strip() for s in row.get("recipeIngredients", "").split(";") if s.strip()]
        raw_instructions = [s.strip() for s in row.get("recipeInstructions", "").split(";") if s.strip()]
        raw_tags         = [s.strip() for s in row.get("tags", "").split(";") if s.strip()]

        # ── Meal-type tag ──────────────────────────────────────────────────────
        meal_type = infer_meal_type(raw_tags, title)
        tags = list(raw_tags)  # copy
        if meal_type and meal_type not in tags:
            tags.append(meal_type)

        # ── Image validation ──────────────────────────────────────────────────
        if self.validate_images:
            image_url = self._validate_image_url(image_url) or image_url

        if self.dry_run:
            logger.info(
                f"[DRY RUN] Would import: '{title}' | "
                f"prep={prep_time}m cook={cook_time}m servings={servings} | "
                f"ingredients={len(raw_ingredients)} steps={len(raw_instructions)} tags={tags}"
            )
            return True

        # ── Write to DB ───────────────────────────────────────────────────────
        try:
            with transaction.atomic():
                recipe = Recipe.objects.create(
                    title=title,
                    description=description,
                    preparation_time=prep_time,
                    cooking_time=cook_time,
                    servings=servings,
                    recipe_yield=recipe_yield,
                    instructions=raw_instructions,
                    tags=tags,
                    web_image_url=image_url,
                    created_by=self.system_user,
                    is_formatted=True,
                    is_nutrition_calculated=False,
                )

                for raw_ing in raw_ingredients:
                    ingredient = get_or_create_ingredient(raw_ing)
                    if ingredient:
                        recipe.ingredients.add(ingredient)

            logger.info(f"Imported: {title}")
            return True

        except Exception as e:
            logger.error(f"Error importing '{title}': {e}")
            return False

    # ── Bulk CSV import ───────────────────────────────────────────────────────

    def import_from_csv(self, csv_path: str) -> dict:
        if not os.path.exists(csv_path):
            logger.error(f"File not found: {csv_path}")
            sys.exit(1)

        imported = skipped = errors = 0

        with open(csv_path, newline="", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            rows = list(reader)

        total = len(rows)
        logger.info(f"Starting import of {total} rows from {csv_path}"
                    + (" [DRY RUN]" if self.dry_run else ""))

        for i, row in enumerate(rows, 1):
            try:
                result = self.import_row(row)
                if result:
                    imported += 1
                else:
                    skipped += 1
            except Exception as e:
                logger.error(f"Unexpected error on row {i}: {e}")
                errors += 1

            if i % 50 == 0:
                logger.info(
                    f"Progress {i}/{total}: "
                    f"{imported} imported / {skipped} skipped / {errors} errors"
                )

        return {"imported": imported, "skipped": skipped, "errors": errors, "total": total}


# ── CLI ───────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Import BBC Good Food recipes from a scraped CSV into Django.",
        epilog="""
Examples:
  # Import into local dev database
  python misc/import_bbc_good_food.py bbc_1000.csv

  # Dry run (prints what would be imported, no DB writes)
  python misc/import_bbc_good_food.py bbc_1000.csv --dry-run

  # Import into production database
  DATABASE_URL=<prod_url> python misc/import_bbc_good_food.py bbc_1000.csv
""",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("csv_file", help="Path to the BBC Good Food CSV file.")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Parse and validate every row but do NOT write to the database.",
    )
    parser.add_argument(
        "--validate-images",
        action="store_true",
        help="Send a HEAD request for each image URL to verify it is reachable (slower).",
    )
    args = parser.parse_args()

    importer = BBCGoodFoodImporter(
        dry_run=args.dry_run,
        validate_images=args.validate_images,
    )
    stats = importer.import_from_csv(args.csv_file)

    print(f"\n{'[DRY RUN] ' if args.dry_run else ''}Import complete.")
    print(f"  Imported : {stats['imported']}")
    print(f"  Skipped  : {stats['skipped']}  (already exist or no title)")
    print(f"  Errors   : {stats['errors']}")
    print(f"  Total    : {stats['total']}")


if __name__ == "__main__":
    main()

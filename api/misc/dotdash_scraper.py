#!/usr/bin/env python3
"""
Dotdash Meredith recipe scraper (Serious Eats + Simply Recipes).

Both sites run the same Dotdash Meredith CMS as Allrecipes, so a single
parametrised scraper covers them. Approach:

1. Breadth-first crawl of category/listing pages starting from a few seed hubs.
   Dotdash list pages do NOT paginate (``?page=N`` returns the same links), so
   coverage comes from walking the category tree, not pagination.
2. Every fetched URL is handed to ``recipe_scrapers`` — if it yields a recipe
   schema it's a recipe (extract + write), otherwise it's treated as a listing
   page and its child links are enqueued. This unifies discovery and extraction
   and naturally skips collections / how-tos / guides.
3. Rows are written to CSV in the exact schema the importer expects
   (``import_scraped_recipes.py``).

Usage:
    python dotdash_scraper.py --site seriouseats --max-recipes 1000
    python dotdash_scraper.py --site simplyrecipes --max-recipes 1000

Run with the venv that has recipe_scrapers installed:
    venv/bin/python misc/dotdash_scraper.py --site seriouseats
"""

import argparse
import csv
import json
import logging
import re
import time
from collections import deque
from typing import List, Optional

import requests
from bs4 import BeautifulSoup
from recipe_scrapers import scrape_html
from recipe_scrapers._exceptions import (
    RecipeSchemaNotFound,
    NoSchemaFoundInWildMode,
    SchemaOrgException,
    ElementNotFoundInHtml,
)
from tqdm import tqdm

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

# Errors that mean "this page isn't a recipe" (so treat it as a listing page).
_NOT_A_RECIPE = (
    RecipeSchemaNotFound,
    NoSchemaFoundInWildMode,
    SchemaOrgException,
    ElementNotFoundInHtml,
    NotImplementedError,
    AttributeError,
)

# Per-site configuration. Seeds are a few verified category hubs; the crawler
# expands from there by harvesting sub-category links off each listing page.
SITE_CONFIG = {
    "seriouseats": {
        "host": "seriouseats.com",
        "base_url": "https://www.seriouseats.com",
        "seeds": [
            "https://www.seriouseats.com/recipes-5117840",
            "https://www.seriouseats.com/all-recipes-5117985",
            "https://www.seriouseats.com/recipes-by-course-5117906",
            "https://www.seriouseats.com/recipes-by-world-cuisine-5117277",
            "https://www.seriouseats.com/recipes-by-method-5117399",
            "https://www.seriouseats.com/recipes-by-ingredient-recipes-5117749",
            "https://www.seriouseats.com/recipes-by-diet-5117779",
        ],
    },
    "simplyrecipes": {
        "host": "simplyrecipes.com",
        "base_url": "https://www.simplyrecipes.com",
        "seeds": [
            "https://www.simplyrecipes.com/dinner-recipes-5091433",
            "https://www.simplyrecipes.com/breakfast-recipes-5091541",
            "https://www.simplyrecipes.com/dessert-recipes-5091513",
            "https://www.simplyrecipes.com/comfort-food-recipes-5091432",
            "https://www.simplyrecipes.com/dinner-recipes-by-ingredients-5091423",
            "https://www.simplyrecipes.com/dinner-recipes-by-diet-5091431",
            "https://www.simplyrecipes.com/side-dish-recipes-5091521",
            "https://www.simplyrecipes.com/recipes-by-ingredient-5091496",
            "https://www.simplyrecipes.com/world-cuisine-recipes-5090804",
        ],
    },
}

# A same-host link ending in a 6+ digit id is either a recipe or a listing page.
_ID_SLUG = re.compile(r"/[a-z0-9][a-z0-9-]*-\d{6,}/?$")

# Food/category words that mark a listing page worth crawling for more recipes.
_CATEGORY_ALLOW = re.compile(
    r"(recipes?|dishes|dessert|breakfast|brunch|lunch|dinner|drink|cocktail|"
    r"appetizer|side|snack|soup|salad|bread|sauce|pasta|chicken|beef|pork|"
    r"seafood|vegetarian|vegan|cuisine|course|method|ingredient|diet|holiday|"
    r"grilling|baking|slow-cooker|instant-pot)",
    re.IGNORECASE,
)

# Slugs that are clearly not recipes/categories — never enqueue or extract these.
_SLUG_DENY = re.compile(
    r"(about-us|our-team|editorial|privacy|terms|contact|cleaning|organizing|"
    r"celebrity|news|gift|review|equipment|product|how-tos?|cooking-tips|"
    r"techniques|guides?|what-is|substitute|newsletter|subscribe)",
    re.IGNORECASE,
)

_HEADERS = {
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9",
    "Accept-Encoding": "gzip, deflate, br",
    "Connection": "keep-alive",
    "Upgrade-Insecure-Requests": "1",
}

CSV_FIELDS = [
    "title", "description", "prep_time", "cook_time", "total_time", "servings",
    "ingredients_json", "instructions_json", "tags_json", "image_url",
    "nutrition_calories", "nutrition_protein", "nutrition_fat", "nutrition_carbs",
    "source_url", "difficulty_level", "cuisine_type",
]


def parse_ingredient(ingredient_text: str) -> Optional[dict]:
    """Split a flat ingredient string into quantity_unit / name / preparation.

    Same regex approach as the Allrecipes scraper so the importer sees a
    consistent shape across all sources.
    """
    if not ingredient_text:
        return None
    original_text = str(ingredient_text).strip()
    if not original_text:
        return None

    quantity_pattern = (
        r"^(\d+(?:\s*\d+/\d+|\.\d+)?(?:/\d+)?(?:\s*\([^)]+\))?"
        r"(?:\s*(?:to|\-)\s*\d+(?:\s*\d+/\d+|\.\d+)?)?"
        r"(?:\s*(?:cups?|cup|tablespoons?|tablespoon|tbsp|teaspoons?|teaspoon|tsp|"
        r"pounds?|pound|lbs?|lb|oz|ounces?|ounce|grams?|gram|g|ml|milliliters?|"
        r"milliliter|liters?|liter|l|cloves?|clove|slices?|slice|pieces?|piece|"
        r"large|medium|small|whole|pinch|dash|handful|can|cans|package|packages|"
        r"pkg|bunch|bunches))+)\s*"
    )
    quantity_unit = ""
    remaining_text = original_text
    m = re.match(quantity_pattern, original_text, re.IGNORECASE)
    if m:
        quantity_unit = (m.group(1) or "").strip()
        remaining_text = original_text[m.end():].strip()
    else:
        simple = re.match(r"^(\d+(?:\s*\d+/\d+|\.\d+)?(?:/\d+)?(?:\s*\([^)]+\))?)\s*", original_text)
        if simple:
            quantity_unit = simple.group(1).strip()
            remaining_text = original_text[simple.end():].strip()

    parts = remaining_text.split(",", 1)
    name = parts[0].strip() if parts and parts[0] else ""
    preparation = parts[1].strip() if len(parts) > 1 and parts[1] else ""
    return {
        "quantity_unit": quantity_unit,
        "name": name,
        "preparation": preparation,
        "original_text": original_text,
    }


def extract_numeric_value(value) -> Optional[float]:
    """Pull the first number out of a nutrition string like '240 kcal'."""
    if not value:
        return None
    if isinstance(value, (int, float)):
        return float(value)
    if isinstance(value, str):
        nums = re.findall(r"\d+(?:\.\d+)?", value)
        if nums:
            return float(nums[0])
    return None


def instructions_from_schema(scraper) -> List[str]:
    """Pull instruction steps straight from schema.org JSON-LD.

    recipe_scrapers' ``instructions()`` crashes on current Simply Recipes pages
    ('NoneType' has no attribute 'ol'), so we read ``recipeInstructions`` from the
    raw schema instead. Handles HowToStep, nested HowToSection, and plain strings.
    """
    try:
        raw = scraper.schema.data.get("recipeInstructions")
    except Exception:
        return []
    steps: List[str] = []

    def _walk(node):
        if node is None:
            return
        if isinstance(node, str):
            text = node.strip()
            if text:
                steps.append(text)
        elif isinstance(node, list):
            for item in node:
                _walk(item)
        elif isinstance(node, dict):
            node_type = node.get("@type", "")
            if node_type == "HowToSection" or "itemListElement" in node:
                _walk(node.get("itemListElement"))
            else:
                text = (node.get("text") or "").strip()
                if text:
                    steps.append(text)

    _walk(raw)
    return steps


def assess_difficulty(ingredients: List[dict], instructions: List[str]) -> str:
    ic, sc = len(ingredients), len(instructions)
    if ic <= 7 and sc <= 7:
        return "easy"
    if ic <= 12 and sc <= 12:
        return "medium"
    return "hard"


class DotdashScraper:
    def __init__(self, site: str, delay: float = 0.2):
        if site not in SITE_CONFIG:
            raise ValueError(f"Unknown site '{site}'. Choose from {list(SITE_CONFIG)}")
        self.site = site
        self.cfg = SITE_CONFIG[site]
        self.host = self.cfg["host"]
        self.delay = delay
        self.session = requests.Session()
        self.session.headers.update(_HEADERS)

    def _fetch(self, url: str) -> Optional[str]:
        try:
            resp = self.session.get(url, timeout=20)
            if resp.status_code == 200 and resp.text:
                return resp.text
            logger.warning("Non-200 (%s) for %s", resp.status_code, url)
        except Exception as e:
            logger.warning("Fetch failed for %s: %s", url, e)
        return None

    def _links(self, html: str) -> List[str]:
        """Same-host links ending in a 6+ digit id (recipes or listings)."""
        soup = BeautifulSoup(html, "html.parser")
        out = []
        for a in soup.select("a[href]"):
            href = a.get("href", "").split("?")[0].split("#")[0]
            if self.host in href and href.startswith("http") and _ID_SLUG.search(href):
                if _SLUG_DENY.search(href):
                    continue
                out.append(href.rstrip("/"))
        return out

    def _list_time(self, scraper, attr: str) -> Optional[int]:
        try:
            val = getattr(scraper, attr)()
            return int(val) if val else None
        except Exception:
            return None

    def extract_recipe(self, url: str, html: str) -> Optional[dict]:
        """Extract a recipe via recipe_scrapers. Returns None if not a recipe."""
        scraper = scrape_html(html, org_url=url)
        title = scraper.title()  # raises for non-recipe pages -> caught by caller
        if not title:
            return None

        # Ingredients (flat strings -> parsed dicts)
        try:
            raw_ingredients = scraper.ingredients() or []
        except Exception:
            raw_ingredients = []
        parsed_ingredients = [p for p in (parse_ingredient(i) for i in raw_ingredients) if p and p["name"]]

        # Instructions as a list. The library's instructions_list()/instructions()
        # crash on current Simply Recipes markup, so fall back to the JSON-LD
        # recipeInstructions, which both Dotdash sites populate reliably.
        instructions: List[str] = []
        try:
            instructions = [s for s in (scraper.instructions_list() or []) if s and s.strip()]
        except Exception:
            instructions = []
        if not instructions:
            instructions = instructions_from_schema(scraper)

        if not parsed_ingredients or not instructions:
            logger.info("Incomplete recipe, skipping: %s", url)
            return None

        prep_time = self._list_time(scraper, "prep_time")
        cook_time = self._list_time(scraper, "cook_time")
        total_time = self._list_time(scraper, "total_time")

        servings = None
        try:
            y = scraper.yields()
            if y:
                mm = re.search(r"(\d+)", str(y))
                if mm:
                    servings = int(mm.group(1))
        except Exception:
            pass

        nutrition = {}
        try:
            nutrition = scraper.nutrients() or {}
        except Exception:
            nutrition = {}

        image_url = ""
        try:
            image_url = scraper.image() or ""
        except Exception:
            pass

        description = ""
        try:
            description = scraper.description() or ""
        except Exception:
            pass

        tags: List[str] = []
        for attr in ("category", "cuisine", "keywords"):
            try:
                val = getattr(scraper, attr)()
            except Exception:
                continue
            if isinstance(val, list):
                tags.extend(str(v) for v in val if v)
            elif isinstance(val, str) and val:
                tags.extend(t.strip() for t in val.split(",") if t.strip())

        cuisine_type = ""
        try:
            cuisine_type = (scraper.cuisine() or "")
            if isinstance(cuisine_type, list):
                cuisine_type = cuisine_type[0] if cuisine_type else ""
        except Exception:
            cuisine_type = tags[0] if tags else ""

        return {
            "title": title,
            "description": description,
            "prep_time": prep_time,
            "cook_time": cook_time,
            "total_time": total_time,
            "servings": servings,
            "ingredients_json": json.dumps(parsed_ingredients),
            "instructions_json": json.dumps(instructions),
            "tags_json": json.dumps(sorted(set(tags))),
            "image_url": image_url,
            "nutrition_calories": extract_numeric_value(nutrition.get("calories")),
            "nutrition_protein": extract_numeric_value(nutrition.get("proteinContent")),
            "nutrition_fat": extract_numeric_value(nutrition.get("fatContent")),
            "nutrition_carbs": extract_numeric_value(nutrition.get("carbohydrateContent")),
            "source_url": url,
            "difficulty_level": assess_difficulty(parsed_ingredients, instructions),
            "cuisine_type": str(cuisine_type),
        }

    def scrape(self, output_file: str, max_recipes: int = 1000, max_fetches: int = 6000) -> int:
        """Crawl category pages, extract recipes, write CSV. Returns count written."""
        queue = deque(self.cfg["seeds"])
        seen = set()
        written = 0
        fetches = 0

        logger.info("Starting %s crawl (target %d recipes)", self.site, max_recipes)
        with open(output_file, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=CSV_FIELDS, quoting=csv.QUOTE_ALL)
            writer.writeheader()

            pbar = tqdm(total=max_recipes, desc=f"{self.site} recipes")
            while queue and written < max_recipes and fetches < max_fetches:
                url = queue.popleft()
                if url in seen:
                    continue
                seen.add(url)

                html = self._fetch(url)
                fetches += 1
                time.sleep(self.delay)
                if not html:
                    continue

                # Is it a recipe? Try to extract; failure => treat as listing page.
                try:
                    row = self.extract_recipe(url, html)
                except _NOT_A_RECIPE:
                    row = None
                except Exception as e:  # unexpected — log and move on
                    logger.warning("Extract error for %s: %s", url, e)
                    row = None

                if row:
                    writer.writerow(row)
                    written += 1
                    pbar.update(1)
                    if written % 50 == 0:
                        logger.info("Progress: %d recipes written", written)
                    continue

                # Listing page: harvest child links (recipes + sub-categories).
                for link in self._links(html):
                    if link in seen:
                        continue
                    # Enqueue recipes always; enqueue categories only if food-related.
                    queue.append(link)
            pbar.close()

        logger.info("Done: %d recipes written to %s (%d pages fetched)", written, output_file, fetches)
        return written


def main():
    parser = argparse.ArgumentParser(description="Scrape Serious Eats / Simply Recipes")
    parser.add_argument("--site", required=True, choices=list(SITE_CONFIG),
                        help="Which Dotdash site to scrape")
    parser.add_argument("--max-recipes", type=int, default=1000,
                        help="Stop after this many recipes (default 1000)")
    parser.add_argument("--max-fetches", type=int, default=6000,
                        help="Hard cap on total page fetches (crawl safety limit)")
    parser.add_argument("--output", default=None,
                        help="Output CSV path (default: <site>_data.csv)")
    parser.add_argument("--delay", type=float, default=0.2,
                        help="Seconds between requests (be polite; default 0.2)")
    args = parser.parse_args()

    output = args.output or f"{args.site}_data.csv"
    scraper = DotdashScraper(args.site, delay=args.delay)
    count = scraper.scrape(output, max_recipes=args.max_recipes, max_fetches=args.max_fetches)

    print(f"\n✅ Scraped {count} {args.site} recipes -> {output}")
    print("To import:")
    print(f"  venv/bin/python misc/import_scraped_recipes.py {output} --source {args.site}")


if __name__ == "__main__":
    main()

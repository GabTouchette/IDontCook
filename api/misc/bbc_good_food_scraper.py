import os
import requests
import json
import csv
import time
import re
import argparse
from bs4 import BeautifulSoup
from tqdm import tqdm
from urllib.parse import urljoin, urlparse
import logging

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

# Fields that MUST be present and non-empty for a recipe to be kept
REQUIRED_FIELDS = [
    "title",
    "image",
    "prepTime",
    "cookTime",
    "ingredients",
    "instructions",
    "recipeYield",
    "description",
    "tags",
]

BASE_URL = "https://www.bbcgoodfood.com"

# A broad set of collection pages covering many cuisines and meal types
COLLECTION_URLS = [
    # Quick & easy
    "https://www.bbcgoodfood.com/recipes/collection/quick-and-easy-recipes",
    # Dinner
    "https://www.bbcgoodfood.com/recipes/collection/dinner-recipes",
    "https://www.bbcgoodfood.com/recipes/collection/midweek-meal-recipes",
    "https://www.bbcgoodfood.com/recipes/collection/chicken-recipes",
    "https://www.bbcgoodfood.com/recipes/collection/beef-recipes",
    "https://www.bbcgoodfood.com/recipes/collection/pasta-recipes",
    "https://www.bbcgoodfood.com/recipes/collection/soup-recipes",
    "https://www.bbcgoodfood.com/recipes/collection/salad-recipes",
    "https://www.bbcgoodfood.com/recipes/collection/steak-recipes",
    "https://www.bbcgoodfood.com/recipes/collection/pork-recipes",
    "https://www.bbcgoodfood.com/recipes/collection/lamb-recipes",
    # Healthy
    "https://www.bbcgoodfood.com/recipes/collection/healthy-dinner-recipes",
    "https://www.bbcgoodfood.com/recipes/collection/healthy-family-recipes",
    "https://www.bbcgoodfood.com/recipes/collection/low-calorie-recipes",
    "https://www.bbcgoodfood.com/recipes/collection/high-protein-recipes",
    # Vegetarian / Vegan
    "https://www.bbcgoodfood.com/recipes/collection/vegetarian-dinner-recipes",
    "https://www.bbcgoodfood.com/recipes/collection/vegan-recipes",
    "https://www.bbcgoodfood.com/recipes/collection/vegetarian-recipes",
    # Baking / Desserts
    "https://www.bbcgoodfood.com/recipes/collection/cake-recipes",
    "https://www.bbcgoodfood.com/recipes/collection/biscuit-recipes",
    "https://www.bbcgoodfood.com/recipes/collection/bread-recipes",
    "https://www.bbcgoodfood.com/recipes/collection/chocolate-recipes",
    "https://www.bbcgoodfood.com/recipes/collection/dessert-recipes",
    # Breakfast
    "https://www.bbcgoodfood.com/recipes/collection/breakfast-recipes",
    "https://www.bbcgoodfood.com/recipes/collection/brunch-recipes",
    # World cuisine
    "https://www.bbcgoodfood.com/recipes/collection/indian-recipes",
    "https://www.bbcgoodfood.com/recipes/collection/italian-recipes",
    "https://www.bbcgoodfood.com/recipes/collection/chinese-recipes",
    "https://www.bbcgoodfood.com/recipes/collection/mexican-recipes",
    "https://www.bbcgoodfood.com/recipes/collection/thai-recipes",
    "https://www.bbcgoodfood.com/recipes/collection/japanese-recipes",
    "https://www.bbcgoodfood.com/recipes/collection/greek-recipes",
    "https://www.bbcgoodfood.com/recipes/collection/american-recipes",
    "https://www.bbcgoodfood.com/recipes/collection/spanish-recipes",
    "https://www.bbcgoodfood.com/recipes/collection/french-recipes",
    # Budget / Family
    "https://www.bbcgoodfood.com/recipes/collection/budget-family-meal-recipes",
    "https://www.bbcgoodfood.com/recipes/collection/slow-cooker-recipes",
    "https://www.bbcgoodfood.com/recipes/collection/one-pan-recipes",
    "https://www.bbcgoodfood.com/recipes/collection/air-fryer-recipes",
    # Fish
    "https://www.bbcgoodfood.com/recipes/collection/fish-recipes",
    "https://www.bbcgoodfood.com/recipes/collection/salmon-recipes",
    "https://www.bbcgoodfood.com/recipes/collection/prawn-recipes",
]


def make_session() -> requests.Session:
    """Create a session with browser-like headers to avoid being blocked."""
    session = requests.Session()
    session.headers.update(
        {
            "User-Agent": (
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                "AppleWebKit/537.36 (KHTML, like Gecko) "
                "Chrome/124.0.0.0 Safari/537.36"
            ),
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
            "Accept-Language": "en-GB,en;q=0.9",
            "Accept-Encoding": "gzip, deflate, br",
            "Connection": "keep-alive",
        }
    )
    return session


def discover_recipe_urls(session: requests.Session, delay: float = 1.5) -> set:
    """
    Crawl collection pages and harvest all free recipe URLs.
    Follows pagination (?page=N) until a page returns no new recipe links.
    Skips /premium/ URLs.
    """
    recipe_urls: set = set()
    # Matches /recipes/<slug> but excludes known non-recipe paths like
    # /recipes/collection, /recipes/category, /recipes/search, etc.
    _non_recipe = {"collection", "category", "search", "letter", "az", "feature"}
    recipe_pattern = re.compile(r"^/recipes/[a-z0-9][a-z0-9-]+$")

    for collection_url in tqdm(COLLECTION_URLS, desc="Discovering collections", unit="collection"):
        page = 1
        while True:
            url = f"{collection_url}?page={page}" if page > 1 else collection_url
            try:
                resp = session.get(url, timeout=15)
                if resp.status_code != 200:
                    break
            except requests.RequestException as e:
                logger.warning(f"Request failed for {url}: {e}")
                break

            soup = BeautifulSoup(resp.content, "html.parser")
            found_on_page = set()

            for a_tag in soup.find_all("a", href=True):
                href = a_tag["href"]
                # Normalise to path-only
                parsed = urlparse(href)
                path = parsed.path.rstrip("/")
                if recipe_pattern.match(path):
                    slug = path.split("/")[-1]
                    if slug in _non_recipe:
                        continue
                    full_url = urljoin(BASE_URL, path)
                    if full_url not in recipe_urls:
                        found_on_page.add(full_url)

            if not found_on_page:
                break  # No new results on this page → stop paginating

            recipe_urls.update(found_on_page)
            page += 1
            time.sleep(delay)

    logger.info(f"Discovered {len(recipe_urls)} unique recipe URLs")
    return recipe_urls


def find_recipe_json_ld(soup: BeautifulSoup) -> dict | None:
    """
    BBC Good Food pages can contain multiple JSON-LD blocks.
    Find the one with @type == "Recipe".
    """
    for script in soup.find_all("script", type="application/ld+json"):
        try:
            data = json.loads(script.string or "")
        except (json.JSONDecodeError, TypeError):
            continue

        # Handle both a single object and a @graph array
        candidates = []
        if isinstance(data, list):
            candidates = data
        elif isinstance(data, dict):
            if data.get("@graph"):
                candidates = data["@graph"]
            else:
                candidates = [data]

        for item in candidates:
            if isinstance(item, dict) and item.get("@type") == "Recipe":
                return item

    return None


def extract_image_url(image_field) -> str:
    """
    BBC Good Food uses an ImageObject dict; AllRecipes uses a plain string.
    Handle both for robustness.
    """
    if isinstance(image_field, str):
        return image_field
    if isinstance(image_field, dict):
        return image_field.get("url", "")
    if isinstance(image_field, list) and image_field:
        return extract_image_url(image_field[0])
    return ""


def extract_instructions(instructions_field) -> list[str]:
    """
    BBC Good Food: flat list of HowToStep objects, each with a 'text' key.
    Ricardo: nested sections with itemListElement.
    Handle both shapes.
    """
    if not instructions_field:
        return []

    steps = []
    for item in instructions_field:
        if not isinstance(item, dict):
            continue
        item_type = item.get("@type", "")
        if item_type == "HowToStep":
            text = item.get("text", "").strip()
            if text:
                steps.append(text)
        elif item_type in ("HowToSection", "ItemList"):
            # Nested structure (Ricardo-style), recurse
            for sub in item.get("itemListElement", []):
                if isinstance(sub, dict):
                    text = sub.get("text", "").strip()
                    if text:
                        steps.append(text)
    return steps


def validate_recipe(data: dict, url: str) -> bool:
    """
    Check every required field individually and log the first failure.
    Returns True only when all fields pass.
    """
    checks = {
        "title":        data.get("title"),
        "image":        data.get("image"),
        "prepTime":     data.get("prepTime"),
        "cookTime":     data.get("cookTime"),
        "ingredients":  data.get("ingredients"),
        "instructions": data.get("instructions"),
        "recipeYield":  data.get("recipeYield"),
        "description":  data.get("description"),
        "tags":         data.get("tags"),
    }
    for field, value in checks.items():
        if not value:
            logger.warning(f"SKIP [{field} missing/empty] {url}")
            return False
    return True


def extract_recipe_data(session: requests.Session, recipe_url: str) -> dict | None:
    """
    Fetch a BBC Good Food recipe page and extract structured data from JSON-LD.
    Every required field is validated individually; the recipe is dropped on
    the first missing field.
    """
    try:
        resp = session.get(recipe_url, timeout=15)
    except requests.RequestException as e:
        logger.warning(f"SKIP [request error: {e}] {recipe_url}")
        return None

    if resp.status_code != 200:
        logger.warning(f"SKIP [HTTP {resp.status_code}] {recipe_url}")
        return None

    soup = BeautifulSoup(resp.content, "html.parser")

    recipe_info = find_recipe_json_ld(soup)
    if recipe_info is None:
        logger.warning(f"SKIP [no Recipe JSON-LD block] {recipe_url}")
        return None

    # ── Extract each field individually ──────────────────────────────────────

    title = recipe_info.get("name", "").strip()

    image = extract_image_url(recipe_info.get("image", ""))

    prep_time = (recipe_info.get("prepTime") or "").strip()
    cook_time = (recipe_info.get("cookTime") or "").strip()

    ingredients = recipe_info.get("recipeIngredient", [])
    if not isinstance(ingredients, list):
        ingredients = []

    instructions = extract_instructions(recipe_info.get("recipeInstructions", []))

    recipe_yield = recipe_info.get("recipeYield", "")
    if isinstance(recipe_yield, list):
        recipe_yield = recipe_yield[0] if recipe_yield else ""
    recipe_yield = str(recipe_yield).strip()

    description = recipe_info.get("description", "").strip()

    # BBC Good Food uses 'keywords' (comma-separated string) rather than 'tags'
    keywords_raw = recipe_info.get("keywords", "")
    if isinstance(keywords_raw, list):
        tags = [t.strip() for t in keywords_raw if t.strip()]
    else:
        tags = [t.strip() for t in keywords_raw.split(",") if t.strip()]

    # ── Strict validation: skip if ANY field is empty ────────────────────────
    candidate = {
        "title":        title,
        "image":        image,
        "prepTime":     prep_time,
        "cookTime":     cook_time,
        "ingredients":  ingredients,   # list – truthy when non-empty
        "instructions": instructions,  # list – truthy when non-empty
        "recipeYield":  recipe_yield,
        "description":  description,
        "tags":         tags,          # list – truthy when non-empty
    }
    if not validate_recipe(candidate, recipe_url):
        return None

    return {
        "title":              title,
        "image":              image,
        "prepTime":           prep_time,
        "cookTime":           cook_time,
        "recipeIngredients":  "; ".join(ingredients),
        "recipeInstructions": "; ".join(instructions),
        "recipeYield":        recipe_yield,
        "description":        description,
        "tags":               "; ".join(tags),
    }


# ── CSV fieldnames shared across all write paths ──────────────────────────────
CSV_FIELDNAMES = [
    "title", "image", "prepTime", "cookTime",
    "recipeIngredients", "recipeInstructions",
    "recipeYield", "description", "tags",
]


def dry_run(n: int = 5, delay: float = 1.0):
    """
    Fetch the first page of the first collection, pick up to `n` recipe URLs,
    scrape them and pretty-print results to stdout.  Nothing is written to disk.
    """
    session = make_session()
    collection_url = COLLECTION_URLS[0]
    recipe_pattern = re.compile(r"^/recipes/[a-z0-9][a-z0-9-]+$")
    _non_recipe = {"collection", "category", "search", "letter", "az", "feature"}

    print(f"\n{'='*60}")
    print(f"DRY RUN — testing first {n} recipes from:")
    print(f"  {collection_url}")
    print(f"{'='*60}\n")

    resp = session.get(collection_url, timeout=15)
    resp.raise_for_status()
    soup = BeautifulSoup(resp.content, "html.parser")

    sample_urls = []
    for a_tag in soup.find_all("a", href=True):
        parsed = urlparse(a_tag["href"])
        path = parsed.path.rstrip("/")
        if recipe_pattern.match(path):
            slug = path.split("/")[-1]
            if slug in _non_recipe:
                continue
            full_url = urljoin(BASE_URL, path)
            if full_url not in sample_urls:
                sample_urls.append(full_url)
        if len(sample_urls) >= n:
            break

    if not sample_urls:
        print("ERROR: could not find any recipe links on the collection page.")
        print("The site may be blocking requests or the page structure has changed.")
        return

    passed = 0
    skipped = 0
    for url in sample_urls:
        print(f"→ {url}")
        data = extract_recipe_data(session, url)
        if data:
            passed += 1
            print(f"  ✓ title:       {data['title']}")
            print(f"    image:       {data['image'][:60]}...")
            print(f"    prepTime:    {data['prepTime']}")
            print(f"    cookTime:    {data['cookTime']}")
            print(f"    yield:       {data['recipeYield']}")
            print(f"    ingredients: {len(data['recipeIngredients'].split(';'))} items")
            print(f"    steps:       {len(data['recipeInstructions'].split(';'))} steps")
            print(f"    tags:        {data['tags'][:80]}")
            print(f"    description: {data['description'][:80]}...")
        else:
            skipped += 1
            print("  ✗ SKIPPED (see WARNING above)")
        print()
        time.sleep(delay)

    print(f"{'='*60}")
    print(f"DRY RUN COMPLETE  —  {passed} passed / {skipped} skipped out of {len(sample_urls)}")
    print(f"{'='*60}\n")


def _progress_file(output_csv: str) -> str:
    """Returns the companion progress-tracking filename for a given CSV path."""
    return output_csv + ".progress"


def _load_progress(output_csv: str) -> set:
    """
    Load the set of URLs already attempted from the .progress file.
    Returns an empty set if the file doesn't exist.
    """
    pfile = _progress_file(output_csv)
    if not os.path.exists(pfile):
        return set()
    with open(pfile, "r", encoding="utf-8") as f:
        return {line.strip() for line in f if line.strip()}


def _load_existing_titles(output_csv: str) -> set:
    """Read titles already saved in an existing output CSV (for resume without a progress file)."""
    if not os.path.exists(output_csv):
        return set()
    titles = set()
    with open(output_csv, newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            t = row.get("title", "").strip()
            if t:
                titles.add(t)
    return titles


def scrape_from_url_list(
    url_list_file: str,
    output_csv: str,
    delay: float = 1.2,
    limit: int | None = None,
    resume: bool = False,
):
    """
    Scrape recipes from a pre-existing text file of URLs (one per line).
    Matches the Ricardo scraper's input/output convention.

    resume=True: append to an existing CSV, skip URLs already in the .progress
    file, and fall back to title-dedup when no progress file exists.
    """
    session = make_session()

    with open(url_list_file, "r") as f:
        recipe_urls = [line.strip() for line in f if line.strip()]

    # ── Resume: figure out what to skip ──────────────────────────────────────
    attempted_urls: set = set()
    existing_titles: set = set()
    file_mode = "w"

    if resume:
        attempted_urls = _load_progress(output_csv)
        if attempted_urls:
            logger.info(f"Resuming: {len(attempted_urls)} URLs already in progress file — will skip them")
        else:
            existing_titles = _load_existing_titles(output_csv)
            if existing_titles:
                logger.info(
                    f"No progress file found. Resuming via title-dedup: "
                    f"{len(existing_titles)} titles already in CSV — duplicates will be skipped"
                )
        file_mode = "a"  # append to existing CSV

    # Cap the list only for non-resume runs; for resume we keep scraping until
    # `limit` NEW recipes are saved.
    if limit and not resume:
        recipe_urls = recipe_urls[:limit]
        logger.info(f"--limit {limit}: will attempt first {limit} URLs in the list")
    elif limit and resume:
        logger.info(f"--limit {limit}: will stop after saving {limit} new recipes")

    total = len(recipe_urls)
    scraped = skipped = already_done = 0

    progress_path = _progress_file(output_csv)
    progress_fh = open(progress_path, "a", encoding="utf-8")  # always append

    try:
        with open(output_csv, file_mode, newline="", encoding="utf-8") as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=CSV_FIELDNAMES, quoting=csv.QUOTE_ALL)
            if file_mode == "w":
                writer.writeheader()

            for recipe_url in tqdm(recipe_urls, desc="Scraping recipes", unit="recipe"):
                if limit and scraped >= limit:
                    logger.info(f"Reached --limit {limit}. Stopping.")
                    break

                # Skip if already attempted (progress-file resume)
                if recipe_url in attempted_urls:
                    already_done += 1
                    continue

                data = extract_recipe_data(session, recipe_url)

                # Mark URL as attempted
                progress_fh.write(recipe_url + "\n")
                progress_fh.flush()

                if data:
                    # Skip if title already saved (fallback title-dedup resume)
                    if data["title"] in existing_titles:
                        already_done += 1
                        continue
                    writer.writerow(data)
                    existing_titles.add(data["title"])
                    scraped += 1
                else:
                    skipped += 1
                time.sleep(delay)
    finally:
        progress_fh.close()

    msg_parts = [f"{scraped} saved", f"{skipped} skipped"]
    if already_done:
        msg_parts.append(f"{already_done} already done")
    print(f"\nDone. {' / '.join(msg_parts)} out of {total} → {output_csv}")
    print(f"Progress tracked in {progress_path}")


def scrape_all_collections(
    output_csv: str = "bbc_good_food_recipes.csv",
    url_output_file: str = "bbc_recipe_urls.txt",
    delay: float = 1.2,
    limit: int | None = None,
):
    """
    Full pipeline:
      1. Discover recipe URLs from all collection pages
      2. Scrape each recipe (skip on any missing field), up to `limit` saved rows
      3. Save to CSV
    Saves all discovered URLs to a text file so you can resume with --url-list if interrupted.
    """
    session = make_session()

    # Step 1: discover URLs
    recipe_urls = list(discover_recipe_urls(session, delay=delay))
    total_discovered = len(recipe_urls)

    with open(url_output_file, "w", encoding="utf-8") as f:
        for url in sorted(recipe_urls):
            f.write(url + "\n")
    logger.info(f"URL list saved to {url_output_file} ({total_discovered} URLs)")

    if limit:
        logger.info(f"--limit {limit}: will stop after saving {limit} valid recipes")

    # Step 2 & 3: scrape and write CSV (with progress tracking)
    scraped = skipped = 0
    progress_path = _progress_file(output_csv)
    progress_fh = open(progress_path, "w", encoding="utf-8")

    try:
        with open(output_csv, "w", newline="", encoding="utf-8") as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=CSV_FIELDNAMES, quoting=csv.QUOTE_ALL)
            writer.writeheader()

            for recipe_url in tqdm(recipe_urls, desc="Scraping recipes", unit="recipe"):
                if limit and scraped >= limit:
                    logger.info(f"Reached --limit {limit}. Stopping early.")
                    break
                data = extract_recipe_data(session, recipe_url)
                progress_fh.write(recipe_url + "\n")
                progress_fh.flush()
                if data:
                    writer.writerow(data)
                    scraped += 1
                else:
                    skipped += 1
                time.sleep(delay)
    finally:
        progress_fh.close()

    print(f"\nScraping complete. {scraped} saved / {skipped} skipped out of {total_discovered} discovered → {output_csv}")


def verify_csv(csv_file: str, sample: int = 3):
    """
    Read a scraped CSV and print a quality report:
    - Row count
    - Per-field empty/missing rate
    - Distribution stats (avg ingredients, avg steps, top tags)
    - A random sample of N recipes printed in full
    """
    import collections
    import random
    import statistics

    rows = []
    with open(csv_file, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append(row)

    if not rows:
        print(f"ERROR: {csv_file} is empty or unreadable.")
        return

    total = len(rows)
    W = 60
    print(f"\n{'='*W}")
    print(f"VERIFICATION REPORT — {csv_file}")
    print(f"{'='*W}")
    print(f"  Total recipes : {total}")

    # ── Per-field completeness ────────────────────────────────────────────────
    print(f"\n  Field completeness (% rows with a non-empty value):")
    for field in CSV_FIELDNAMES:
        filled = sum(1 for r in rows if r.get(field, "").strip())
        pct = filled / total * 100
        bar = "#" * int(pct / 5)  # 20-char max bar
        print(f"    {field:<22} {pct:5.1f}%  [{bar:<20}]  ({filled}/{total})")

    # ── Numeric distributions ─────────────────────────────────────────────────
    ingredient_counts = []
    step_counts = []
    tag_counts = []
    for r in rows:
        ing = r.get("recipeIngredients", "")
        ingredient_counts.append(len([x for x in ing.split(";") if x.strip()]))
        steps = r.get("recipeInstructions", "")
        step_counts.append(len([x for x in steps.split(";") if x.strip()]))
        tags = r.get("tags", "")
        tag_counts.append(len([x for x in tags.split(";") if x.strip()]))

    def stats(label: str, values: list):
        if not values:
            return
        print(f"    {label:<22} avg={statistics.mean(values):.1f}  "
              f"min={min(values)}  max={max(values)}  "
              f"median={statistics.median(values):.0f}")

    print(f"\n  Distribution stats:")
    stats("ingredients/recipe", ingredient_counts)
    stats("steps/recipe", step_counts)
    stats("tags/recipe", tag_counts)

    # ── Top tags ──────────────────────────────────────────────────────────────
    tag_counter: collections.Counter = collections.Counter()
    for r in rows:
        for tag in r.get("tags", "").split(";"):
            t = tag.strip()
            if t:
                tag_counter[t] += 1
    print(f"\n  Top 15 tags:")
    for tag, count in tag_counter.most_common(15):
        print(f"    {count:5d}x  {tag}")

    # ── prepTime / cookTime format sample ─────────────────────────────────────
    time_formats = collections.Counter(r.get("prepTime", "")[:3] for r in rows)
    print(f"\n  prepTime format (first 3 chars): {dict(time_formats.most_common(5))}")

    # ── Random sample of full recipes ─────────────────────────────────────────
    print(f"\n  Random sample of {sample} recipe(s):")
    for r in random.sample(rows, min(sample, total)):
        print(f"  {'─'*56}")
        print(f"  title      : {r['title']}")
        print(f"  image      : {r['image'][:70]}...")
        print(f"  prepTime   : {r['prepTime']}   cookTime: {r['cookTime']}")
        print(f"  yield      : {r['recipeYield']}")
        ing_list = [x.strip() for x in r['recipeIngredients'].split(';') if x.strip()]
        print(f"  ingredients: {len(ing_list)} — {'; '.join(ing_list[:3])}{'...' if len(ing_list) > 3 else ''}")
        step_list = [x.strip() for x in r['recipeInstructions'].split(';') if x.strip()]
        print(f"  steps      : {len(step_list)} — {step_list[0][:80]}...")
        print(f"  tags       : {r['tags'][:90]}")
        print(f"  description: {r['description'][:100]}...")
    print(f"\n{'='*W}\n")


# ── CLI ───────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="BBC Good Food recipe scraper",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Dry run: fetch & validate 5 sample recipes, print to stdout
  python bbc_good_food_scraper.py --dry-run

  # Dry run with more samples
  python bbc_good_food_scraper.py --dry-run --dry-run-count 10

  # Scrape exactly 1000 recipes then stop
  python bbc_good_food_scraper.py --limit 1000 --output bbc_1000.csv

  # Resume from a saved URL list, cap at 1000
  python bbc_good_food_scraper.py --url-list bbc_recipe_urls.txt --limit 1000

  # Resume an interrupted run (keeps existing CSV, skips already-done URLs)
  python bbc_good_food_scraper.py --url-list bbc_recipe_urls.txt --limit 1000 --resume

  # Verify a CSV file after scraping
  python bbc_good_food_scraper.py --verify bbc_1000.csv
  python bbc_good_food_scraper.py --verify bbc_1000.csv --sample 5

  # Full pipeline: discover URLs then scrape everything
  python bbc_good_food_scraper.py
""",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Fetch a small sample and print results; do NOT write any files.",
    )
    parser.add_argument(
        "--dry-run-count",
        type=int,
        default=5,
        metavar="N",
        help="Number of recipes to test in dry-run mode (default: 5).",
    )
    parser.add_argument(
        "--url-list",
        metavar="FILE",
        help="Path to a text file of recipe URLs (one per line). "
             "Skips discovery and scrapes only the listed URLs.",
    )
    parser.add_argument(
        "--output",
        default="bbc_good_food_recipes.csv",
        metavar="FILE",
        help="Output CSV file path (default: bbc_good_food_recipes.csv).",
    )
    parser.add_argument(
        "--delay",
        type=float,
        default=1.2,
        metavar="SECONDS",
        help="Seconds to wait between requests (default: 1.2).",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=None,
        metavar="N",
        help="Stop after saving N valid recipes to the CSV (default: no limit).",
    )
    parser.add_argument(
        "--verify",
        metavar="FILE",
        help="Path to a previously scraped CSV. Prints a quality/stats report and exits.",
    )
    parser.add_argument(
        "--sample",
        type=int,
        default=3,
        metavar="N",
        help="Number of random recipes to print in --verify mode (default: 3).",
    )
    parser.add_argument(
        "--resume",
        action="store_true",
        help="Resume an interrupted --url-list run: append to the existing CSV, "
             "skip already-attempted URLs (uses .progress file, falls back to title-dedup).",
    )

    args = parser.parse_args()

    if args.verify:
        verify_csv(args.verify, sample=args.sample)
    elif args.dry_run:
        dry_run(n=args.dry_run_count, delay=args.delay)
    elif args.url_list:
        scrape_from_url_list(
            url_list_file=args.url_list,
            output_csv=args.output,
            delay=args.delay,
            limit=args.limit,
            resume=args.resume,
        )
    else:
        scrape_all_collections(
            output_csv=args.output,
            delay=args.delay,
            limit=args.limit,
        )

#!/usr/bin/env python3
"""
Allrecipes Comprehensive Scraper
3-part approach:
1. Discover category URLs and extract recipe URLs from category pages
2. Scrape individual recipe data using recipe-scrapers
3. Save to CSV for database import
"""

import requests
import json
import csv
import re
import time
from bs4 import BeautifulSoup
from tqdm import tqdm
from urllib.parse import urljoin, urlparse
import logging
from recipe_scrapers import scrape_me
from dataclasses import dataclass
from typing import List, Set, Optional

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

@dataclass
class AllrecipesCategory:
    name: str
    url: str
    parent_category: str = ""

class AllrecipesScraper:
    def __init__(self, delay=0.1):
        """Initialize Allrecipes scraper with respectful delays"""
        self.delay = delay
        self.base_url = "https://www.allrecipes.com"
        self.session = requests.Session()
        
        # Set realistic headers to avoid blocking
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
            'Accept-Encoding': 'gzip, deflate, br',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1',
        })
        
        # Your comprehensive Allrecipes category URLs
        self.category_urls = [
            "https://www.allrecipes.com/recipes/15054/everyday-cooking/cooking-for-one/quick-and-easy/",
            "https://www.allrecipes.com/recipes/476/everyday-cooking/cooking-for-two/",
            "https://www.allrecipes.com/recipes/22992/everyday-cooking/sheet-pan-dinners/",
            "https://www.allrecipes.com/recipes/17253/everyday-cooking/slow-cooker/main-dishes/",
            "https://www.allrecipes.com/recipes/265/everyday-cooking/vegetarian/main-dishes/",
            "https://www.allrecipes.com/recipes/1320/healthy-recipes/main-dishes/",
            "https://www.allrecipes.com/recipes/80/main-dish/",
            "https://www.allrecipes.com/recipes/256/main-dish/meatloaf/",
            "https://www.allrecipes.com/recipes/17245/main-dish/pasta/",
            "https://www.allrecipes.com/recipes/674/main-dish/pork/pork-chops/",
            "https://www.allrecipes.com/recipes/260/main-dish/salads/",
            "https://www.allrecipes.com/recipes/475/meat-and-poultry/beef/steaks/",
            "https://www.allrecipes.com/recipes/664/meat-and-poultry/chicken/baked-and-roasted/",
            "https://www.allrecipes.com/recipes/81/side-dish/",
            "https://www.allrecipes.com/recipes/16492/everyday-cooking/special-collections/allrecipes-allstars/",
            "https://www.allrecipes.com/recipes/385/desserts/cakes/angel-food-cake/",
            "https://www.allrecipes.com/recipes/102/appetizers-and-snacks/antipasto/",
            "https://www.allrecipes.com/recipes/76/appetizers-and-snacks/",
            "https://www.allrecipes.com/recipes/788/desserts/pies/apple-pie/",
            "https://www.allrecipes.com/recipes/1333/side-dish/applesauce/",
            "https://www.allrecipes.com/recipes/14913/appetizers-and-snacks/dips-and-spreads/artichoke-dip/",
            "https://www.allrecipes.com/recipes/1537/bread/yeast-bread/bagels/",
            "https://www.allrecipes.com/recipes/1673/side-dish/beans-and-peas/baked-beans/",
            "https://www.allrecipes.com/recipes/343/bread/quick-bread/fruit-bread/banana-bread/",
            "https://www.allrecipes.com/recipes/836/desserts/cookies/bar-cookies/",
            "https://www.allrecipes.com/recipes/200/meat-and-poultry/beef/",
            "https://www.allrecipes.com/recipes/14730/soups-stews-and-chili/stews/beef/",
            "https://www.allrecipes.com/recipes/17123/main-dish/beef/beef-stroganoff/",
            "https://www.allrecipes.com/recipes/469/meat-and-poultry/beef/tenderloin/",
            "https://www.allrecipes.com/recipes/837/desserts/cookies/biscotti/",
            "https://www.allrecipes.com/recipes/1998/bread/quick-bread/biscuits/",
            "https://www.allrecipes.com/recipes/17853/breakfast-and-brunch/crepes/blintz/",
            "https://www.allrecipes.com/recipes/2754/desserts/cookies/brownies/blondies/",
            "https://www.allrecipes.com/recipes/15044/drinks/cocktails/bloody-marys/",
            "https://www.allrecipes.com/recipes/12946/desserts/pies/fruit-pies/blueberry-pie/",
            "https://www.allrecipes.com/recipes/14768/soups-stews-and-chili/soup/vegetable-soup/borscht/",
            "https://www.allrecipes.com/recipes/156/bread/",
            "https://www.allrecipes.com/recipes/78/breakfast-and-brunch/",
            "https://www.allrecipes.com/recipes/1310/breakfast-and-brunch/eggs/breakfast-burritos/",
            "https://www.allrecipes.com/recipes/144/breakfast-and-brunch/breakfast-casseroles/",
            "https://www.allrecipes.com/recipes/152/breakfast-and-brunch/potatoes/",
            "https://www.allrecipes.com/recipes/1307/breakfast-and-brunch/eggs/breakfast-strata/",
            "https://www.allrecipes.com/recipes/8161994/side-dish/sauces-and-condiments/brines/",
            "https://www.allrecipes.com/recipes/15103/salad/vegetable-salads/broccoli-salad/",
            "https://www.allrecipes.com/recipes/838/desserts/cookies/brownies/",
            "https://www.allrecipes.com/recipes/16833/appetizers-and-snacks/bruschetta/",
            "https://www.allrecipes.com/recipes/17660/appetizers-and-snacks/dips-and-spreads/buffalo-chicken-dip/",
            "https://www.allrecipes.com/recipes/15837/meat-and-poultry/chicken/chicken-wings/buffalo-chicken-wings/",
            "https://www.allrecipes.com/recipes/17835/world-cuisine/asian/korean/main-dishes/bulgogi/",
            "https://www.allrecipes.com/recipes/248/main-dish/burgers/",
            "https://www.allrecipes.com/recipes/1216/world-cuisine/latin-american/mexican/main-dishes/burritos/",
            "https://www.allrecipes.com/recipes/16370/soups-stews-and-chili/soup/vegetable-soup/squash-soup/butternut-squash-soup/",
            "https://www.allrecipes.com/recipes/16539/main-dish/stuffed-main-dishes/stuffed-cabbage/",
            "https://www.allrecipes.com/recipes/276/desserts/cakes/",
            "https://www.allrecipes.com/recipes/1045/main-dish/calzones/",
            "https://www.allrecipes.com/recipes/1529/everyday-cooking/on-the-go/camping/",
            "https://www.allrecipes.com/recipes/15930/side-dish/sauces-and-condiments/canning-and-preserving/",
            "https://www.allrecipes.com/recipes/860/desserts/cakes/carrot-cake/",
            "https://www.allrecipes.com/recipes/249/main-dish/casseroles/",
            "https://www.allrecipes.com/recipes/15133/appetizers-and-snacks/seafood/ceviche/",
            "https://www.allrecipes.com/recipes/404/appetizers-and-snacks/dips-and-spreads/cheese-dips-and-spreads/cheese-balls/",
            "https://www.allrecipes.com/recipes/433/appetizers-and-snacks/cheese/cheese-fondue/",
            "https://www.allrecipes.com/recipes/387/desserts/cakes/cheesecake/",
            "https://www.allrecipes.com/recipes/16791/everyday-cooking/special-collections/food-wishes/",
            "https://www.allrecipes.com/recipes/12947/desserts/pies/fruit-pies/cherry-pie/",
            "https://www.allrecipes.com/recipes/12957/desserts/pies/vintage-pies/chess-pie/",
            "https://www.allrecipes.com/recipes/16519/main-dish/chicken/chicken-adobo/",
            "https://www.allrecipes.com/recipes/14723/soups-stews-and-chili/soup/chicken-soup/chicken-and-dumplings/",
            "https://www.allrecipes.com/recipes/17553/main-dish/chicken/chicken-cacciatore/",
            "https://www.allrecipes.com/recipes/17371/main-dish/chicken/chicken-cordon-bleu/",
            "https://www.allrecipes.com/recipes/17139/main-dish/chicken/chicken-marsala/",
            "https://www.allrecipes.com/recipes/14722/soups-stews-and-chili/soup/chicken-soup/chicken-noodle-soup/",
            "https://www.allrecipes.com/recipes/16383/main-dish/chicken/chicken-parmesan/",
            "https://www.allrecipes.com/recipes/17187/main-dish/chicken/chicken-piccata/",
            "https://www.allrecipes.com/recipes/649/meat-and-poultry/chicken/chicken-salad/",
            "https://www.allrecipes.com/recipes/15938/main-dish/chicken/chicken-teriyaki/",
            "https://www.allrecipes.com/recipes/23045/world-cuisine/latin-american/mexican/main-dishes/chilaquiles/",
            "https://www.allrecipes.com/recipes/16085/world-cuisine/latin-american/mexican/main-dishes/chile-rellenos/",
            "https://www.allrecipes.com/recipes/173/soups-stews-and-chili/chili/",
            "https://www.allrecipes.com/recipes/695/world-cuisine/asian/chinese/",
            "https://www.allrecipes.com/recipes/835/desserts/cakes/chocolate-cake/",
            "https://www.allrecipes.com/recipes/839/desserts/cookies/chocolate-chip-cookies/",
            "https://www.allrecipes.com/recipes/17151/desserts/candy/fudge/chocolate/",
            "https://www.allrecipes.com/recipes/174/soups-stews-and-chili/chowders/",
            "https://www.allrecipes.com/recipes/187/holidays-and-events/christmas/",
            "https://www.allrecipes.com/recipes/841/holidays-and-events/christmas/desserts/christmas-cookies/",
            "https://www.allrecipes.com/recipes/1306/bread/pastries/cinnamon-rolls/"
        ]

    def get_all_categories(self) -> List[AllrecipesCategory]:
        """Get comprehensive list of Allrecipes categories from your provided URLs"""
        categories = []
        
        for i, url in enumerate(self.category_urls):
            # Extract category name from URL path
            path_parts = url.split('/')
            category_name = path_parts[-2] if path_parts[-1] == '' else path_parts[-1]
            category_name = category_name.replace('-', ' ').title()
            
            categories.append(AllrecipesCategory(
                name=f"{category_name} ({i+1})",
                url=url,
                parent_category="Allrecipes"
            ))
        
        logger.info(f"Generated {len(categories)} categories to explore")
        return categories

    def extract_recipe_urls_from_category_page(self, category_url: str, max_pages: int = 5) -> Set[str]:
        """
        PART 1: Extract recipe URLs from category pages using your specified CSS selectors
        """
        recipe_urls = set()
        page = 1
        
        logger.info(f"Extracting recipes from category: {category_url}")
        
        while page <= max_pages:
            try:
                # Allrecipes pagination pattern
                paginated_url = f"{category_url}?page={page}" if page > 1 else category_url
                
                response = self.session.get(paginated_url)
                response.raise_for_status()
                
                soup = BeautifulSoup(response.content, 'html.parser')
                page_recipes = set()
                
                # PART 1: Use your specified CSS selectors
                # Look for the taxonomy article list group
                taxonomy_groups = soup.select('.mntl-taxonomysc-article-list-group')
                
                for group in taxonomy_groups:
                    # Find recipe cards within each group using your exact selector
                    recipe_cards = group.select('.comp.mntl-card-list-items.mntl-universal-card.mntl-document-card.mntl-card.card.card--no-image')
                    
                    for card in recipe_cards:
                        # Extract href from the card
                        link = card.find('a', href=True)
                        if link:
                            href = link['href']
                            # Ensure it's a recipe URL pattern you specified
                            if '/recipe/' in href or href.endswith('-recipe-'):
                                full_url = urljoin(self.base_url, href)
                                page_recipes.add(full_url)
                
                # Also look for alternative selectors in case the structure varies
                alternative_selectors = [
                    'a[href*="/recipe/"]',
                    '.mntl-card-list-items a[href*="recipe"]',
                    '.card a[href*="recipe"]',
                    '.recipe-card a',
                    'article a[href*="recipe"]',
                    '[data-tracking-zone="recipe-card"] a'
                ]
                
                for selector in alternative_selectors:
                    links = soup.select(selector)
                    for link in links:
                        href = link.get('href')
                        if href and ('/recipe/' in href or 'recipe-' in href):
                            full_url = urljoin(self.base_url, href)
                            # Filter to ensure it's actually a recipe page using your pattern
                            if re.search(r'/(recipe/|[\w-]+-recipe-\d+)', full_url):
                                page_recipes.add(full_url)
                
                if not page_recipes:
                    logger.info(f"No more recipes found on page {page}")
                    break
                    
                recipe_urls.update(page_recipes)
                logger.info(f"Page {page}: Found {len(page_recipes)} recipes (total: {len(recipe_urls)})")
                
                # Check if there's a next page
                next_page = soup.select_one('a[aria-label="Next page"]') or soup.select_one('.pagination .next')
                if not next_page and len(page_recipes) == 0:
                    logger.info("No next page found, stopping pagination")
                    break
                    
                page += 1
                time.sleep(self.delay)
                
            except Exception as e:
                logger.error(f"Error extracting from page {page} of {category_url}: {e}")
                break
        
        logger.info(f"Total recipes found from {category_url}: {len(recipe_urls)}")
        return recipe_urls

    def discover_all_recipe_urls(self, max_recipes_per_category: int = 100) -> List[str]:
        """
        PART 1: Discover all recipe URLs across all Allrecipes categories
        """
        logger.info("Starting comprehensive Allrecipes recipe URL discovery...")
        
        all_categories = self.get_all_categories()
        all_recipe_urls = set()
        
        for category in tqdm(all_categories, desc="Processing categories"):
            logger.info(f"Processing category: {category.name}")
            
            try:
                category_urls = self.extract_recipe_urls_from_category_page(
                    category.url, 
                    max_pages=max_recipes_per_category // 24  # Assume ~24 recipes per page
                )
                
                new_urls = category_urls - all_recipe_urls
                all_recipe_urls.update(category_urls)
                
                logger.info(f"Category '{category.name}': {len(category_urls)} recipes ({len(new_urls)} new)")
                
                # Respect rate limiting between categories
                time.sleep(self.delay * 2)
                
            except Exception as e:
                logger.error(f"Error processing category {category.name}: {e}")
        
        logger.info(f"URL discovery complete! Found {len(all_recipe_urls)} unique recipes")
        return list(all_recipe_urls)

    def extract_ingredients_from_html(self, recipe_url: str) -> List[dict]:
        """Extract ingredients from HTML using structured data attributes"""
        try:
            response = self.session.get(recipe_url)
            soup = BeautifulSoup(response.content, 'html.parser')
            
            ingredients = []
            
            # Look for ingredient containers with structured data
            # Your pattern: <p><span data-ingredient-quantity="true">1</span> <span data-ingredient-unit="true">pound</span> <span data-ingredient-name="true">ingredient name</span></p>
            
            # Find parent containers that have quantity spans as children
            quantity_spans = soup.select('[data-ingredient-quantity="true"]')
            
            for quantity_span in quantity_spans:
                # Get the parent container (usually a <p> or <li>)
                parent = quantity_span.parent
                if not parent:
                    continue
                
                # Look for sibling spans with unit and name data
                quantity = quantity_span.get_text(strip=True)
                
                # Find unit span (should be a sibling)
                unit_span = parent.select_one('[data-ingredient-unit="true"]')
                unit = unit_span.get_text(strip=True) if unit_span else ""
                
                # Find name span (should be a sibling)
                name_span = parent.select_one('[data-ingredient-name="true"]')
                name = name_span.get_text(strip=True) if name_span else ""
                
                # Get the full text as original from the parent container
                original_text = parent.get_text(strip=True)
                
                if quantity and name:  # Quantity and name are required
                    ingredients.append({
                        'quantity': quantity,
                        'unit': unit,
                        'name': name,
                        'original_text': original_text
                    })
            
            if ingredients:
                logger.info(f"Extracted {len(ingredients)} ingredients from HTML structured data")
            else:
                logger.info("No HTML structured ingredient data found")
                
            return ingredients
            
        except Exception as e:
            logger.warning(f"Error extracting ingredients from HTML: {e}")
            return []

    def extract_recipe_data(self, recipe_url: str) -> Optional[dict]:
        """
        PART 2: Extract recipe data using recipe-scrapers library
        """
        try:
            scraper = scrape_me(recipe_url)
            
            # Extract basic recipe data safely
            title = scraper.title()
            ingredients = scraper.ingredients()
            
            # Ensure we have valid data types
            title = str(title) if title is not None else ""
            ingredients = ingredients if ingredients is not None else []
            
            # Extract instructions directly from HTML using CSS selector
            instructions = []
            try:
                response = self.session.get(recipe_url)
                soup = BeautifulSoup(response.content, 'html.parser')
                
                # Use your specified CSS selector for instructions
                instruction_elements = soup.select('.comp.mntl-sc-block.mntl-sc-block-html')
                
                for element in instruction_elements:
                    text = element.get_text(strip=True)
                    # Filter out empty text and non-instruction content
                    if text and len(text) > 10 and not text.startswith('Advertisement'):
                        instructions.append(text)
                
                # If we didn't get instructions from CSS selector, try recipe-scrapers as fallback
                if not instructions:
                    scraped_instructions = scraper.instructions()
                    if scraped_instructions and isinstance(scraped_instructions, list):
                        instructions = scraped_instructions
                        
            except Exception as e:
                logger.warning(f"Failed to extract instructions from HTML, using recipe-scrapers fallback: {e}")
                try:
                    scraped_instructions = scraper.instructions()
                    if scraped_instructions and isinstance(scraped_instructions, list):
                        instructions = scraped_instructions
                except:
                    instructions = []
            
            # Skip recipes without essential data
            if not title or not ingredients or not instructions:
                logger.warning(f"Incomplete recipe data for {recipe_url}")
                return None
            
            # Parse ingredients using both HTML structured data and recipe-scrapers
            parsed_ingredients = []
            
            # First, try to extract ingredients from HTML structured data
            html_ingredients = self.extract_ingredients_from_html(recipe_url)
            
            if html_ingredients:
                # Use HTML structured data as primary source
                logger.info(f"Using HTML structured ingredient data ({len(html_ingredients)} ingredients)")
                
                # But also get recipe-scrapers ingredients for preparation info
                scraped_ingredients_map = {}
                for ingredient_text in ingredients:
                    if ingredient_text is not None:
                        parsed = self.parse_ingredient(ingredient_text)
                        if parsed and parsed['name']:
                            # Create a key for matching (normalize name)
                            key = parsed['name'].lower().strip()
                            scraped_ingredients_map[key] = parsed['preparation']
                
                # Combine HTML data with preparation from recipe-scrapers
                for html_ing in html_ingredients:
                    # Try to find preparation from scraped ingredients
                    name_key = html_ing['name'].lower().strip()
                    preparation = ""
                    
                    # Look for exact match first
                    if name_key in scraped_ingredients_map:
                        preparation = scraped_ingredients_map[name_key]
                    else:
                        # Try partial matches for ingredients with extra details
                        for scraped_key, scraped_prep in scraped_ingredients_map.items():
                            if name_key in scraped_key or scraped_key in name_key:
                                preparation = scraped_prep
                                break
                    
                    parsed_ingredients.append({
                        "quantity": html_ing['quantity'],
                        "unit": html_ing['unit'],
                        "name": html_ing['name'],
                        "preparation": preparation,
                        "original_text": html_ing['original_text']
                    })
            else:
                # Fallback to recipe-scrapers method
                logger.info("HTML structured data not found, using recipe-scrapers fallback")
                for ingredient_text in ingredients:
                    if ingredient_text is not None:
                        parsed_ingredient = self.parse_ingredient(ingredient_text)
                        if parsed_ingredient:
                            parsed_ingredients.append(parsed_ingredient)
            
            # Get timing information safely
            prep_time = cook_time = total_time = None
            
            try:
                prep_time = scraper.prep_time()
            except:
                pass
                
            try:
                cook_time = scraper.cook_time()
            except:
                pass
                
            try:
                total_time = scraper.total_time()
            except:
                pass
            
            # Get servings/yield
            servings = None
            try:
                servings_text = scraper.yields()
                if servings_text:
                    # Extract number from yield text
                    servings_match = re.search(r'(\d+)', str(servings_text))
                    if servings_match:
                        servings = int(servings_match.group(1))
            except:
                pass
            
            # Get nutrition information
            nutrition_data = {}
            try:
                nutrition = scraper.nutrients()
                if nutrition:
                    nutrition_data = {
                        'calories': self.extract_numeric_value(nutrition.get('calories')),
                        'protein': self.extract_numeric_value(nutrition.get('proteinContent')),
                        'fat': self.extract_numeric_value(nutrition.get('fatContent')),
                        'carbs': self.extract_numeric_value(nutrition.get('carbohydrateContent'))
                    }
            except:
                nutrition_data = {'calories': None, 'protein': None, 'fat': None, 'carbs': None}
            
            # Get image
            image_url = ""
            try:
                image_url = scraper.image() or ""
            except:
                pass
            
            # Extract tags/categories
            tags = []
            try:
                # Allrecipes often includes tags in the schema
                if hasattr(scraper, 'schema') and scraper.schema:
                    categories = scraper.schema.get('recipeCategory', [])
                    cuisines = scraper.schema.get('recipeCuisine', [])
                    keywords = scraper.schema.get('keywords', [])
                    
                    for item in [categories, cuisines, keywords]:
                        if isinstance(item, list):
                            tags.extend(item)
                        elif item:
                            tags.append(item)
            except:
                pass
            
            # Extract breadcrumb categories (e.g., "Recipes > Seafood > Shellfish > Scallops")
            try:
                # Get the page content to extract breadcrumbs
                response = self.session.get(recipe_url)
                soup = BeautifulSoup(response.content, 'html.parser')
                
                # Look for breadcrumb navigation
                breadcrumb_selectors = [
                    '.mntl-breadcrumbs a',
                    '.breadcrumbs a', 
                    'nav[aria-label="Breadcrumb"] a',
                    '.o-Breadcrumbs__a',
                    '[data-module="Breadcrumbs"] a'
                ]
                
                for selector in breadcrumb_selectors:
                    breadcrumb_links = soup.select(selector)
                    if breadcrumb_links:
                        breadcrumb_tags = []
                        for link in breadcrumb_links:
                            text = link.get_text(strip=True)
                            if text and text.lower() not in ['home', 'recipes', 'allrecipes']:
                                breadcrumb_tags.append(text.lower().replace(' ', '-'))
                        if breadcrumb_tags:
                            tags.extend(breadcrumb_tags)
                            break
            except:
                pass
            
            # Get description safely
            description = ""
            try:
                if hasattr(scraper, 'description'):
                    if callable(scraper.description):
                        desc = scraper.description()
                        description = str(desc) if desc is not None else ""
                    else:
                        desc = scraper.description
                        description = str(desc) if desc is not None else ""
            except:
                description = ""
            
            return {
                'title': title,
                'description': description,
                'prep_time': prep_time,
                'cook_time': cook_time,
                'total_time': total_time,
                'servings': servings,
                'ingredients_json': json.dumps(parsed_ingredients),
                'instructions_json': json.dumps(instructions),
                'tags_json': json.dumps(tags),
                'image_url': image_url,
                'nutrition_calories': nutrition_data.get('calories'),
                'nutrition_protein': nutrition_data.get('protein'),
                'nutrition_fat': nutrition_data.get('fat'),
                'nutrition_carbs': nutrition_data.get('carbs'),
                'source_url': recipe_url,
                'difficulty_level': self.assess_difficulty(parsed_ingredients, instructions),
                'cuisine_type': tags[0] if tags else ''
            }
            
        except Exception as e:
            logger.error(f"Error extracting recipe data from {recipe_url}: {e}")
            return None

    def parse_ingredient(self, ingredient_text: str) -> Optional[dict]:
        """Parse ingredient text to extract components"""
        if not ingredient_text or ingredient_text is None:
            return None
            
        # Ensure we have a string
        ingredient_text = str(ingredient_text)
        original_text = ingredient_text.strip()
        
        if not original_text:
            return None
        
        # More comprehensive pattern to match quantity and unit
        # Examples: "1 tablespoon", "2 cups", "1 (6 ounce)", "1/2 teaspoon"
        quantity_pattern = r'^(\d+(?:\s*\d+/\d+|\.\d+)?(?:/\d+)?(?:\s*\([^)]+\))?(?:\s*(?:to|\-)\s*\d+(?:\s*\d+/\d+|\.\d+)?)?(?:\s*(?:cups?|cup|tablespoons?|tablespoon|tbsp|teaspoons?|teaspoon|tsp|pounds?|pound|lbs?|lb|oz|ounces?|ounce|grams?|gram|g|ml|milliliters?|milliliter|liters?|liter|l|cloves?|clove|slices?|slice|pieces?|piece|large|medium|small|whole|pinch|dash|handful|can|cans|package|packages|pkg|bunch|bunches))+)\s*'
        
        quantity_match = re.match(quantity_pattern, original_text, re.IGNORECASE)
        quantity_unit = ""
        remaining_text = original_text
        
        if quantity_match:
            quantity_unit = quantity_match.group(1).strip() if quantity_match.group(1) else ""
            remaining_text = original_text[quantity_match.end():].strip()
        else:
            # Try simpler pattern for just numbers at the start
            simple_pattern = r'^(\d+(?:\s*\d+/\d+|\.\d+)?(?:/\d+)?(?:\s*\([^)]+\))?)\s*'
            simple_match = re.match(simple_pattern, original_text)
            if simple_match:
                quantity_unit = simple_match.group(1).strip()
                remaining_text = original_text[simple_match.end():].strip()
        
        # Split on comma for preparation
        parts = remaining_text.split(',', 1)
        name = parts[0].strip() if parts[0] else ""
        preparation = parts[1].strip() if len(parts) > 1 and parts[1] else ""
        
        return {
            "quantity_unit": quantity_unit,
            "name": name,
            "preparation": preparation,
            "original_text": original_text
        }

    def extract_numeric_value(self, value) -> Optional[float]:
        """Extract numeric value from nutrition strings"""
        if not value:
            return None
        
        if isinstance(value, str):
            numbers = re.findall(r'\d+(?:\.\d+)?', value)
            if numbers:
                return float(numbers[0])
        elif isinstance(value, (int, float)):
            return float(value)
        
        return None

    def assess_difficulty(self, ingredients: List[dict], instructions: List[str]) -> str:
        """Assess recipe difficulty based on complexity"""
        ingredient_count = len(ingredients)
        instruction_count = len(instructions)
        
        if ingredient_count <= 7 and instruction_count <= 7:
            return 'easy'
        elif ingredient_count <= 12 and instruction_count <= 12:
            return 'medium'
        else:
            return 'hard'

    def scrape_all_recipes(self, output_file: str = 'allrecipes_data.csv', max_recipes: Optional[int] = None) -> int:
        """
        PART 3: Complete scraping workflow - discover URLs, scrape data, save to CSV
        """
        logger.info("Starting Allrecipes comprehensive scrape...")
        
        # PART 1: Discover all recipe URLs
        logger.info("=== PART 1: Discovering Recipe URLs ===")
        all_recipe_urls = self.discover_all_recipe_urls()
        
        if not all_recipe_urls:
            logger.error("No recipe URLs discovered!")
            return 0
        
        # Apply limit if specified
        if max_recipes and len(all_recipe_urls) > max_recipes:
            all_recipe_urls = all_recipe_urls[:max_recipes]
            logger.info(f"Limited to first {max_recipes} recipes")
        
        # PART 2 & 3: Scrape recipe data and save to CSV
        logger.info("=== PART 2 & 3: Scraping Recipe Data and Saving ===")
        
        # Setup CSV
        fieldnames = [
            'title', 'description', 'prep_time', 'cook_time', 'total_time', 'servings',
            'ingredients_json', 'instructions_json', 'tags_json', 'image_url',
            'nutrition_calories', 'nutrition_protein', 'nutrition_fat', 'nutrition_carbs',
            'source_url', 'difficulty_level', 'cuisine_type'
        ]
        
        scraped_count = 0
        failed_count = 0
        
        logger.info(f"Starting recipe data extraction for {len(all_recipe_urls)} recipes...")
        
        with open(output_file, 'w', newline='', encoding='utf-8') as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames, quoting=csv.QUOTE_ALL)
            writer.writeheader()
            
            for i, recipe_url in enumerate(tqdm(all_recipe_urls, desc="Scraping recipes")):
                try:
                    recipe_data = self.extract_recipe_data(recipe_url)
                    
                    if recipe_data:
                        writer.writerow(recipe_data)
                        scraped_count += 1
                        
                        # Periodic logging
                        if scraped_count % 50 == 0:
                            logger.info(f"Progress: {scraped_count} recipes scraped successfully")
                    else:
                        failed_count += 1
                    
                    # Respectful delay
                    time.sleep(self.delay)
                    
                except Exception as e:
                    logger.error(f"Error processing recipe {recipe_url}: {e}")
                    failed_count += 1
        
        logger.info(f"Scraping completed!")
        logger.info(f"Successfully scraped: {scraped_count} recipes")
        logger.info(f"Failed to scrape: {failed_count} recipes") 
        logger.info(f"Saved to: {output_file}")
        
        return scraped_count

def main():
    """Main function"""
    print("🍽️  Allrecipes Comprehensive Scraper")
    print("=" * 50)
    print("3-Part Process:")
    print("1. Discover recipe URLs from category pages")
    print("2. Scrape individual recipe data")
    print("3. Save to CSV for database import")
    print("=" * 50)
    
    scraper = AllrecipesScraper(delay=0.1)  # Fast 0.1-second delay
    
    # Production run with 1000 recipe limit
    scraped_count = scraper.scrape_all_recipes(
        output_file='allrecipes_data.csv',
        max_recipes=1000  # Production limit of 1000 recipes
    )
    
    if scraped_count > 0:
        print(f"\n✅ Successfully scraped {scraped_count} Allrecipes recipes!")
        print("📁 Data saved to: allrecipes_data.csv")
        print("\nTo import to database, run:")
        print("python import_allrecipes.py allrecipes_data.csv")
    else:
        print("❌ No recipes were scraped. Check connectivity and Allrecipes access.")

if __name__ == "__main__":
    main()
import requests
import json
import csv
from bs4 import BeautifulSoup
from tqdm import tqdm  # Import tqdm for the progress bar

# Function to extract recipe data from a recipe page
def extract_recipe_data(recipe_url):
    response = requests.get(recipe_url)
    if response.status_code != 200:
        print(f"Failed to retrieve page: {recipe_url}")
        return None

    soup = BeautifulSoup(response.content, "html.parser")

    # Check if the recipe is magazine exclusive
    magazine_badge = soup.find("div", class_="c-badge c-badge--magazine")
    if magazine_badge:
        print(f"Magazine exclusive recipe found: {recipe_url}")
        return None

    # Extract JSON data from <script type='application/ld+json'>
    json_data = soup.find("script", type="application/ld+json")
    
    if json_data is None:
        print(f"No recipe data found in the page: {recipe_url}")
        return None
    
    # Parse the JSON data
    try:
        recipe_info = json.loads(json_data.string)
    except json.JSONDecodeError:
        print(f"Error decoding JSON for: {recipe_url}")
        return None

    # Extract required fields
    title = recipe_info.get("name", "")
    image = recipe_info.get("image", [None])[0]  # First image if available
    prep_time = recipe_info.get("prepTime", "")
    cook_time = recipe_info.get("cookTime", "")
    ingredients = recipe_info.get("recipeIngredient", [])
    instructions = [step["text"] for section in recipe_info.get("recipeInstructions", []) for step in section.get("itemListElement", [])]
    recipe_yield = recipe_info.get("recipeYield", "")
    description = recipe_info.get("description", "")
    tags = recipe_info.get("tags", [])

    # Skip recipe if any of the required fields are missing
    if not all([title, image, prep_time, cook_time, ingredients, instructions, recipe_yield, description]):
        print(f"Missing required field in recipe: {recipe_url}")
        return None

    return {
        "title": title,
        "image": image,
        "prepTime": prep_time,
        "cookTime": cook_time,
        "recipeIngredients": "; ".join(ingredients),  # Changed to separate with ";"
        "recipeInstructions": "; ".join(instructions),
        "recipeYield": recipe_yield,
        "description": description,
        "tags": "; ".join(tags),  # Changed to separate with ";"
    }

# Main entry point
if __name__ == "__main__":
    # Open the file containing the recipe URLs
    with open("recipe_urls.txt", "r") as file:
        recipe_urls = file.readlines()

    # Prepare CSV file
    with open("recipes.csv", "w", newline="", encoding="utf-8") as csvfile:
        fieldnames = ["title", "image", "prepTime", "cookTime", "recipeIngredients", "recipeInstructions", "recipeYield", "description", "tags"]
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames, quoting=csv.QUOTE_ALL)
        writer.writeheader()

        # Loop through recipe URLs with a progress bar using tqdm
        for recipe_url in tqdm(recipe_urls, desc="Scraping recipes", unit="recipe"):
            recipe_url = recipe_url.strip()  # Remove any extra spaces or newlines
            recipe_data = extract_recipe_data(recipe_url)
            if recipe_data:
                writer.writerow(recipe_data)
                print(f"Scraped data for: {recipe_data['title']}")

    print("Recipe scraping completed and saved to recipes.csv")

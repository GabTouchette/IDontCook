import requests
import os

USDA_API_KEY = os.getenv('USDA_API_KEY')
SEARCH_URL = "https://api.nal.usda.gov/fdc/v1/foods/search"

def get_nutrition(ingredient_name: str, grams: float):
    # 1. Search for the best matching food (top result only)
    payload = {
        "query": ingredient_name,
        "dataType": ["Foundation", "Survey (FNDDS)"],
        "pageSize": 1
    }

    response = requests.post(
        SEARCH_URL,
        headers={"Content-Type": "application/json"},
        json=payload,
        params={"api_key": USDA_API_KEY}
    )
    data = response.json()
    
    if not data.get("foods"):
        return {"error": f"No match found for '{ingredient_name}'."}

    best_match = data["foods"][0]
    fdc_id = best_match["fdcId"]

    # 2. Get full food details
    food_url = f"https://api.nal.usda.gov/fdc/v1/food/{fdc_id}"
    food_response = requests.get(food_url, params={"api_key": USDA_API_KEY})
    food_data = food_response.json()

    # 3. Extract nutrients and adjust based on grams
    nutrients = food_data.get("foodNutrients", [])
    nutrient_values = {}

    for nutrient in nutrients:
        name = nutrient.get("nutrientName")
        unit = nutrient.get("unitName")
        value_per_100g = nutrient.get("value")  # this is per 100g
        value_for_amount = (grams / 100) * value_per_100g if value_per_100g is not None else None

        if value_for_amount is not None:
            nutrient_values[name] = {
                "amount": round(value_for_amount, 2),
                "unit": unit
            }

    return {
        "ingredient": ingredient_name,
        "grams": grams,
        "nutrients": nutrient_values
    }

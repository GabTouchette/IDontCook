// Curated recipe-tag vocabulary for the picker and explore filters.
//
// This MIRRORS the backend source of truth in `api/recipes/tag_vocabulary.py`
// (CANONICAL_TAGS). The backend enforces this set on every write and when
// cleaning the catalog, so keep the two in sync — if you add/remove a tag here,
// change it there too (and vice versa). The "Meal Types" category is handled
// specially by the create/edit form (single-select, five required types).
const Map<String, List<String>> tagOptions = {
  "Meal Types": [
    "Breakfast",
    "Lunch",
    "Dinner",
    "Snack",
    "Dessert",
    "Brunch",
    "Appetizer",
    "Beverage",
    "Cocktail"
  ],
  "Dietary": [
    "Vegetarian",
    "Vegan",
    "Gluten-Free",
    "Dairy-Free",
    "Keto",
    "High Protein",
    "Low Carb"
  ],
  "Cooking Methods": [
    "Baked",
    "Grilled",
    "Air Fryer",
    "Slow Cooker",
    "One-Pot",
    "No Cook"
  ],
  "Dish Types": [
    "Soup",
    "Salad",
    "Pasta",
    "Pizza",
    "Curry",
    "Stir-Fry",
    "Sandwich",
    "Stew",
    "Bread"
  ],
  "Cuisines": [
    "Italian",
    "Mexican",
    "Asian",
    "Indian",
    "Mediterranean",
    "American",
    "French",
    "Thai",
    "Chinese",
    "Japanese",
    "Middle Eastern"
  ],
  "Convenience": [
    "Quick",
    "30-Minute Meal",
    "Budget-Friendly",
    "Meal Prep",
    "5 Ingredients or Less"
  ],
  "Other": [
    "Comfort Food",
    "Healthy",
    "Spicy"
  ]
};

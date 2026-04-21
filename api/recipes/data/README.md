# Ingredient Catalog (Data-driven)

This folder stores the ingredient catalog and supporting vocabularies used by the normalizer and the grocery list.

Start with open data (free):
- USDA FoodData Central (bulk CSV) for names, categories, household weights, and nutrients
- Wikidata for multilingual labels (en/fr) and aliases
- Curated lists for synonyms and grocery categories

Files:
- ingredients.schema.json: JSON Schema for entries (fields: canonical_name_en, canonical_name_fr, category=2-letter code)
- ingredients.sample.jsonl: Example entries (one JSON object per line)
- categories.yml: Grocery aisle taxonomy
- synonyms.yml: Safe canonicalization rules (conservative)

Recommended pipeline:
1) Import USDA bulk CSV → seed base names, categories, household weights, nutrients.
2) Enrich with Wikidata to add fr/en labels and aliases.
3) Curate categories with categories.yml; expand synonyms.yml as you see repeats.
4) Use the normalizer first; when unknown/low-confidence → propose to this catalog via review.

Notes:
- Keep entries small and canonical; put product/brand-level items elsewhere.
- Don’t auto-convert volume↔mass without a trusted household mapping or density.

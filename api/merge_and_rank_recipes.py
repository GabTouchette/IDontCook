#!/usr/bin/env python3
"""
Merge filtered AllRecipes with BBC recipes, deduplicate, score, and prepare for import
"""

import csv

def merge_datasets():
    """Merge filtered AllRecipes and BBC recipes"""

    filtered_allrecipes = '/Users/gabrieltouchette/Documents/IDontCook/api/allrecipes_filtered.csv'
    bbc_recipes = '/Users/gabrieltouchette/Documents/IDontCook/api/bbc_1000.csv'
    merged_file = '/Users/gabrieltouchette/Documents/IDontCook/api/recipes_merged.csv'

    print("📚 MERGING RECIPE DATASETS\n")
    print("="*70)

    # Track seen titles and sources
    seen_titles = {}  # title -> (source, row)
    merged_rows = []
    duplicates = []

    # 1. Load AllRecipes (filtered)
    print("\n📖 Loading filtered AllRecipes (6,134 recipes)...")
    allrecipes_count = 0
    with open(filtered_allrecipes, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            title = row['title'].strip()
            if title not in seen_titles:
                row['source'] = 'AllRecipes'
                merged_rows.append(row)
                seen_titles[title] = ('AllRecipes', row)
                allrecipes_count += 1
            else:
                duplicates.append((title, 'AllRecipes', seen_titles[title][0]))

    print(f"✓ Loaded {allrecipes_count} unique AllRecipes recipes")

    # 2. Load BBC (only unique ones not in AllRecipes)
    print("\n📖 Loading BBC recipes (1,000 recipes)...")
    bbc_count = 0
    bbc_duplicates = 0
    with open(bbc_recipes, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            title = row['title'].strip()
            if title not in seen_titles:
                row['source'] = 'BBC'
                merged_rows.append(row)
                seen_titles[title] = ('BBC', row)
                bbc_count += 1
            else:
                bbc_duplicates += 1
                duplicates.append((title, 'BBC', seen_titles[title][0]))

    print(f"✓ Loaded {bbc_count} unique BBC recipes")
    print(f"⚠️  Found {bbc_duplicates} BBC recipes already in AllRecipes (duplicates)")

    # 3. Write merged file
    print(f"\n💾 Writing merged dataset...")
    if merged_rows:
        with open(merged_file, 'w', newline='', encoding='utf-8') as f:
            fieldnames = list(merged_rows[0].keys())
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(merged_rows)

    total_recipes = len(merged_rows)

    print(f"\n" + "="*70)
    print(f"✅ MERGE COMPLETE")
    print(f"="*70)
    print(f"\n📊 Results:")
    print(f"  AllRecipes (unique):    {allrecipes_count:5d}")
    print(f"  BBC (unique):           {bbc_count:5d}")
    print(f"  Duplicates found:       {len(duplicates):5d}")
    print(f"  {'─'*40}")
    print(f"  TOTAL (merged):         {total_recipes:5d} ✅")

    print(f"\n📝 Duplicate breakdown:")
    print(f"  BBC → AllRecipes:        {bbc_duplicates} (BBC recipes with same title as AllRecipes)")

    print(f"\n💾 Files created:")
    print(f"  Merged dataset:         {merged_file}")

    print(f"\n📊 Next step: Rank merged dataset...")
    print(f"   Run: python3 recipe_usefulness_analyzer.py")

    return merged_file, total_recipes


if __name__ == '__main__':
    merge_datasets()

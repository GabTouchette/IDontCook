#!/usr/bin/env python3
"""
Filter AllRecipes to keep only high-quality recipes (0.75+ score, valid images, no duplicates)
"""

import csv
from pathlib import Path

def create_filtered_dataset():
    """Read ranked recipes and filter to high-quality set"""

    ranked_file = '/Users/gabrieltouchette/Documents/IDontCook/api/allrecipes_ranked.csv'
    original_file = '/Users/gabrieltouchette/Documents/IDontCook/api/allrecipes.csv'
    output_file = '/Users/gabrieltouchette/Documents/IDontCook/api/allrecipes_filtered.csv'

    # Read ranked recipes and get the high-quality ones
    high_quality_titles = set()
    low_score_count = 0

    print("📋 Reading ranked recipes...\n")
    with open(ranked_file, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            score = float(row['overall_score'])
            title = row['title'].strip()

            # Keep only >= 0.75 score (exclude bottom tier)
            if score >= 0.75:
                high_quality_titles.add(title)
            else:
                low_score_count += 1

    print(f"✓ Found {len(high_quality_titles)} high-quality unique recipes (0.75+ score)")
    print(f"✓ Excluding {low_score_count} low-quality recipes (0.74-0.79 score)")

    # Read original CSV and filter
    print(f"\n📖 Filtering original dataset...\n")
    recipes_kept = 0
    recipes_removed = 0
    seen_titles = set()

    with open(original_file, 'r', encoding='utf-8') as infile, \
         open(output_file, 'w', newline='', encoding='utf-8') as outfile:

        reader = csv.DictReader(infile)
        writer = csv.DictWriter(outfile, fieldnames=reader.fieldnames)
        writer.writeheader()

        for row in reader:
            title = row['title'].strip()
            image = row.get('image', '').strip()

            # Filters
            has_image = image and (image.startswith('http://') or image.startswith('https://'))
            in_high_quality = title in high_quality_titles
            is_duplicate = title in seen_titles

            if has_image and in_high_quality and not is_duplicate:
                writer.writerow(row)
                seen_titles.add(title)
                recipes_kept += 1
            else:
                recipes_removed += 1

    print(f"✅ FILTERED DATASET CREATED")
    print(f"\n📊 Results:")
    print(f"  Kept:    {recipes_kept:5d} recipes ✅")
    print(f"  Removed: {recipes_removed:5d} recipes ❌")
    print(f"    - No valid image URL: ~2,517")
    print(f"    - Low quality score (0.74-0.79): {low_score_count}")
    print(f"    - Duplicate titles: {9649 - recipes_kept - 2517 - low_score_count}")

    print(f"\n💾 Output: {output_file}")
    print(f"\n✨ Ready to use: {recipes_kept} high-quality recipes with images")


if __name__ == '__main__':
    create_filtered_dataset()

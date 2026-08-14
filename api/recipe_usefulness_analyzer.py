#!/usr/bin/env python3
"""
Recipe Usefulness Scorer - Analyzes AllRecipes dataset to identify high-quality recipes
"""

import csv
import json
import re
from pathlib import Path
from dataclasses import dataclass, field
from typing import List, Dict, Any
from collections import Counter
import statistics

@dataclass
class RecipeScore:
    title: str
    completeness_score: float = 0
    accessibility_score: float = 0
    clarity_score: float = 0
    metadata_score: float = 0
    versatility_score: float = 0
    overall_score: float = 0
    issues: List[str] = field(default_factory=list)
    ingredient_count: int = 0
    total_time_mins: int = 0
    instruction_word_count: int = 0
    has_image: bool = False
    tag_count: int = 0
    is_vegetarian: bool = False


class RecipeAnalyzer:
    def __init__(self):
        self.recipes = []
        self.scores: List[RecipeScore] = []

        # Common ingredients that appear in most recipes
        self.common_ingredients = {
            'salt', 'pepper', 'oil', 'butter', 'water', 'flour', 'sugar',
            'garlic', 'onion', 'tomato', 'lemon', 'lime', 'egg', 'milk',
            'cheese', 'olive oil', 'vegetable oil', 'baking powder', 'baking soda'
        }

        # Exotic/hard-to-find ingredients
        self.exotic_ingredients = {
            'saffron', 'truffle', 'wagyu', 'uni', 'foie gras', 'edible flowers',
            'vintage', 'sustainable', 'heirloom', 'obscure', 'rare'
        }

    def parse_iso_duration(self, duration: str) -> int:
        """Convert ISO 8601 duration (PT45M) to minutes"""
        if not duration or not isinstance(duration, str):
            return 0

        match = re.search(r'PT(\d+)H?(\d+)?M?', duration)
        if match:
            hours = int(match.group(1)) if match.group(1) else 0
            minutes = int(match.group(2)) if match.group(2) else 0
            if hours > 0 and not match.group(2):  # Only hours specified
                return int(match.group(1)) * 60
            return hours * 60 + minutes
        return 0

    def parse_ingredients(self, ingredients_str: str) -> List[str]:
        """Parse semicolon or comma-separated ingredients"""
        if not ingredients_str:
            return []
        # Split by semicolon first, then comma
        parts = ingredients_str.split(';') if ';' in ingredients_str else ingredients_str.split(',')
        return [i.strip() for i in parts if i.strip()]

    def count_instruction_words(self, instructions: str) -> int:
        """Count words in instructions"""
        if not instructions:
            return 0
        return len(instructions.split())

    def count_instruction_steps(self, instructions: str) -> int:
        """Estimate instruction steps (by periods or sentences)"""
        if not instructions:
            return 0
        # Count by periods, but avoid counting decimal points
        return max(1, len([s for s in instructions.split('.') if len(s.strip()) > 10]))

    def is_vegetarian(self, tags: str) -> bool:
        """Check if recipe is marked vegetarian"""
        if not tags:
            return False
        return 'vegetarian' in tags.lower() or 'vegan' in tags.lower()

    def has_exotic_ingredients(self, ingredients: List[str]) -> bool:
        """Check if recipe uses exotic/hard-to-find ingredients"""
        ingredient_str = ' '.join(ingredients).lower()
        return any(exotic in ingredient_str for exotic in self.exotic_ingredients)

    def score_completeness(self, recipe: Dict[str, Any]) -> tuple[float, List[str]]:
        """Score 1: Completeness (25%) - All required fields present"""
        issues = []
        score = 100

        # Check required fields
        required = ['title', 'recipeIngredients', 'recipeInstructions', 'recipeYield']
        for field in required:
            if not recipe.get(field) or recipe.get(field).strip() == '':
                score -= 25
                issues.append(f"Missing {field}")

        # Check ingredient parsing
        ingredients = self.parse_ingredients(recipe.get('recipeIngredients', ''))
        if len(ingredients) == 0:
            score -= 10
            issues.append("No parseable ingredients")

        # Check instruction parsing
        instructions = recipe.get('recipeInstructions', '')
        if len(instructions) < 30:  # Too short
            score -= 15
            issues.append("Instructions too brief (<30 chars)")

        # Check times are reasonable
        prep_time = self.parse_iso_duration(recipe.get('prepTime', ''))
        cook_time = self.parse_iso_duration(recipe.get('cookTime', ''))
        total_time = prep_time + cook_time

        if total_time > 480:  # More than 8 hours
            score -= 10
            issues.append(f"Unreasonable time ({total_time} mins)")

        return max(0, score / 100), issues

    def score_accessibility(self, recipe: Dict[str, Any]) -> tuple[float, List[str]]:
        """Score 2: Accessibility (25%) - Easy to make, ingredients available"""
        issues = []
        score = 100

        ingredients = self.parse_ingredients(recipe.get('recipeIngredients', ''))
        ingredient_count = len(ingredients)

        # Sweet spot: 6-15 ingredients
        if ingredient_count < 3:
            score -= 20
            issues.append(f"Too few ingredients ({ingredient_count})")
        elif ingredient_count < 6:
            score -= 5
        elif ingredient_count > 25:
            score -= 20
            issues.append(f"Too many ingredients ({ingredient_count}) - complex")
        elif ingredient_count > 15:
            score -= 10

        # Check time accessibility (sweet spot: <120 mins)
        prep_time = self.parse_iso_duration(recipe.get('prepTime', ''))
        cook_time = self.parse_iso_duration(recipe.get('cookTime', ''))
        total_time = prep_time + cook_time

        if total_time == 0:
            score -= 10
            issues.append("No time information")
        elif total_time > 180:
            score -= 15
            issues.append(f"Too long ({total_time} mins) - not weekday-friendly")
        elif total_time > 120:
            score -= 5

        # Check for exotic ingredients
        if self.has_exotic_ingredients(ingredients):
            score -= 15
            issues.append("Uses exotic/hard-to-find ingredients")

        # Check allergen restrictions (more tags = fewer people can eat it)
        tags = recipe.get('tags', '').lower()
        allergen_count = len([t for t in tags.split(';') if 'diet_' in t or 'allergy' in t])
        if allergen_count > 5:
            score -= 5

        return max(0, score / 100), issues

    def score_clarity(self, recipe: Dict[str, Any]) -> tuple[float, List[str]]:
        """Score 3: Clarity (20%) - Clear instructions, good formatting"""
        issues = []
        score = 100

        instructions = recipe.get('recipeInstructions', '')
        word_count = self.count_instruction_words(instructions)
        step_count = self.count_instruction_steps(instructions)

        # Sweet spot: 100-500 words, 4-12 steps
        if word_count < 50:
            score -= 30
            issues.append(f"Instructions too vague ({word_count} words)")
        elif word_count < 100:
            score -= 10
        elif word_count > 1000:
            score -= 10
            issues.append(f"Instructions too long ({word_count} words)")

        if step_count < 3:
            score -= 15
            issues.append(f"Not enough steps ({step_count})")
        elif step_count > 20:
            score -= 10
            issues.append(f"Too many steps ({step_count}) - fragmented")

        # Check description quality
        description = recipe.get('description', '')
        if not description or len(description) < 20:
            score -= 20
            issues.append("Missing or inadequate description")
        elif len(description) < 50:
            score -= 5

        return max(0, score / 100), issues

    def has_valid_image_url(self, image: str) -> bool:
        """Check if image is a valid URL"""
        if not image or not isinstance(image, str):
            return False
        image = image.strip()
        return bool(image) and (image.startswith('http://') or image.startswith('https://'))

    def score_metadata(self, recipe: Dict[str, Any]) -> tuple[float, List[str]]:
        """Score 4: Metadata Quality (15%) - Has image, tags, yield info"""
        issues = []
        score = 100

        # Image - CRITICAL: must have valid URL
        image = recipe.get('image', '')
        if not self.has_valid_image_url(image):
            score -= 50  # Heavy penalty - recipes without images are not useful
            issues.append("Missing or invalid image URL")

        # Yield/servings
        yield_info = recipe.get('recipeYield', '')
        if not yield_info or yield_info.strip() == '':
            score -= 15
            issues.append("No yield/servings specified")

        # Tags
        tags = recipe.get('tags', '')
        if not tags or tags.strip() == '':
            score -= 20
            issues.append("No tags/metadata")
        else:
            tag_count = len([t for t in tags.split(';') if t.strip()])
            if tag_count < 5:
                score -= 10
                issues.append(f"Few tags ({tag_count}) - poorly classified")

        return max(0, score / 100), issues

    def score_versatility(self, recipe: Dict[str, Any]) -> tuple[float, List[str]]:
        """Score 5: Versatility (15%) - Broad appeal, useful for many"""
        issues = []
        score = 100

        # Vegetarian appeal
        is_veg = self.is_vegetarian(recipe.get('tags', ''))
        if not is_veg:
            score -= 5  # Meat recipes are less versatile

        # Time-friendly for busy people
        prep_time = self.parse_iso_duration(recipe.get('prepTime', ''))
        cook_time = self.parse_iso_duration(recipe.get('cookTime', ''))
        total_time = prep_time + cook_time

        if total_time > 0 and total_time <= 30:
            score += 10  # Bonus for quick recipes
        elif total_time > 90:
            score -= 10

        # Meal type diversity (favor multi-use recipes)
        tags = recipe.get('tags', '').lower()
        if 'side' in tags:
            score += 5  # Side dishes are versatile
        if 'main-dish' in tags or 'lunch' in tags:
            score += 0  # Neutral
        if 'dessert' in tags:
            score -= 5  # Less daily use

        # Common ingredients increase versatility
        ingredients = self.parse_ingredients(recipe.get('recipeIngredients', ''))
        common_count = sum(1 for ing in ingredients if any(c in ing.lower() for c in self.common_ingredients))
        common_ratio = common_count / len(ingredients) if ingredients else 0

        if common_ratio < 0.3:
            score -= 10
            issues.append("Many uncommon/specialty ingredients")
        elif common_ratio > 0.7:
            score += 5

        return max(0, score / 100), issues

    def analyze_recipe(self, recipe: Dict[str, Any]) -> RecipeScore:
        """Compute overall usefulness score for a recipe"""
        c_score, c_issues = self.score_completeness(recipe)
        a_score, a_issues = self.score_accessibility(recipe)
        cl_score, cl_issues = self.score_clarity(recipe)
        m_score, m_issues = self.score_metadata(recipe)
        v_score, v_issues = self.score_versatility(recipe)

        # Weighted average
        overall = (
            c_score * 0.25 +
            a_score * 0.25 +
            cl_score * 0.20 +
            m_score * 0.15 +
            v_score * 0.15
        )

        ingredients = self.parse_ingredients(recipe.get('recipeIngredients', ''))
        prep_time = self.parse_iso_duration(recipe.get('prepTime', ''))
        cook_time = self.parse_iso_duration(recipe.get('cookTime', ''))

        return RecipeScore(
            title=recipe.get('title', 'Unknown'),
            completeness_score=c_score,
            accessibility_score=a_score,
            clarity_score=cl_score,
            metadata_score=m_score,
            versatility_score=v_score,
            overall_score=overall,
            issues=c_issues + a_issues + cl_issues + m_issues + v_issues,
            ingredient_count=len(ingredients),
            total_time_mins=prep_time + cook_time,
            instruction_word_count=self.count_instruction_words(recipe.get('recipeInstructions', '')),
            has_image=bool(recipe.get('image')),
            tag_count=len([t for t in recipe.get('tags', '').split(';') if t.strip()]),
            is_vegetarian=self.is_vegetarian(recipe.get('tags', ''))
        )

    def load_csv(self, filepath: str):
        """Load recipes from CSV"""
        with open(filepath, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            self.recipes = list(reader)
        print(f"✓ Loaded {len(self.recipes)} recipes")

    def run_analysis(self):
        """Score all recipes"""
        print(f"\n📊 Analyzing {len(self.recipes)} recipes...\n")

        for i, recipe in enumerate(self.recipes):
            score = self.analyze_recipe(recipe)
            self.scores.append(score)

            if (i + 1) % 1000 == 0:
                print(f"  Progress: {i + 1}/{len(self.recipes)}")

        # Sort by overall score
        self.scores.sort(key=lambda x: x.overall_score, reverse=True)
        print(f"\n✓ Analysis complete!")

    def print_summary(self):
        """Print usefulness analysis summary"""
        if not self.scores:
            return

        scores = [s.overall_score for s in self.scores]

        print("\n" + "="*70)
        print("RECIPE USEFULNESS ANALYSIS SUMMARY")
        print("="*70)

        print(f"\n📈 Score Distribution:")
        print(f"  Mean:       {statistics.mean(scores):.2f}")
        print(f"  Median:     {statistics.median(scores):.2f}")
        print(f"  Std Dev:    {statistics.stdev(scores):.2f}")
        print(f"  Min:        {min(scores):.2f}")
        print(f"  Max:        {max(scores):.2f}")

        # Percentiles
        sorted_scores = sorted(scores)
        p25 = sorted_scores[int(len(scores) * 0.25)]
        p75 = sorted_scores[int(len(scores) * 0.75)]
        p90 = sorted_scores[int(len(scores) * 0.90)]

        print(f"\n📊 Percentiles:")
        print(f"  25th:       {p25:.2f} (bottom quartile)")
        print(f"  75th:       {p75:.2f} (top quartile)")
        print(f"  90th:       {p90:.2f} (top 10%)")

        # Distribution by tier
        high = len([s for s in scores if s >= 0.75])
        medium = len([s for s in scores if 0.50 <= s < 0.75])
        low = len([s for s in scores if s < 0.50])

        print(f"\n🎯 Quality Tiers:")
        print(f"  High (≥0.75):       {high:5d} recipes ({high/len(scores)*100:5.1f}%)  ✅ KEEPER")
        print(f"  Medium (0.50-0.75): {medium:5d} recipes ({medium/len(scores)*100:5.1f}%)  ⚠️  REVIEW")
        print(f"  Low (<0.50):        {low:5d} recipes ({low/len(scores)*100:5.1f}%)  ❌ PRUNE")

        # Metadata stats
        has_image = sum(1 for s in self.scores if s.has_image)
        is_veg = sum(1 for s in self.scores if s.is_vegetarian)
        avg_ingredients = statistics.mean([s.ingredient_count for s in self.scores])
        avg_time = statistics.mean([s.total_time_mins for s in self.scores if s.total_time_mins > 0])

        print(f"\n📋 Content Stats:")
        print(f"  Has image:       {has_image:5d} ({has_image/len(self.scores)*100:5.1f}%)")
        print(f"  Vegetarian:      {is_veg:5d} ({is_veg/len(self.scores)*100:5.1f}%)")
        print(f"  Avg ingredients: {avg_ingredients:5.1f}")
        print(f"  Avg time:        {avg_time:5.0f} mins")

    def print_top_bottom(self, n=20):
        """Print top and bottom N recipes"""
        print("\n" + "="*70)
        print(f"TOP {n} BEST RECIPES (Highest Usefulness)")
        print("="*70)

        for i, recipe in enumerate(self.scores[:n], 1):
            print(f"\n{i:2d}. [{recipe.overall_score:.2f}] {recipe.title}")
            print(f"    ⏱️  {recipe.total_time_mins} mins | 🥘 {recipe.ingredient_count} ingredients | 📝 {recipe.tag_count} tags")
            if recipe.has_image:
                print(f"    ✅ Has image | {'🥬' if recipe.is_vegetarian else '🥩 Meat'}")

        print("\n" + "="*70)
        print(f"BOTTOM {n} WORST RECIPES (Lowest Usefulness) - CANDIDATES FOR PRUNING")
        print("="*70)

        for i, recipe in enumerate(self.scores[-n:], 1):
            print(f"\n{i:2d}. [{recipe.overall_score:.2f}] {recipe.title}")
            print(f"    ⏱️  {recipe.total_time_mins} mins | 🥘 {recipe.ingredient_count} ingredients | 📝 {recipe.tag_count} tags")
            if recipe.issues:
                for issue in recipe.issues[:3]:  # Show top 3 issues
                    print(f"    ⚠️  {issue}")

    def export_ranked_csv(self, output_file: str):
        """Export ranked recipes to CSV"""
        with open(output_file, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerow([
                'rank', 'title', 'overall_score', 'completeness', 'accessibility',
                'clarity', 'metadata', 'versatility', 'ingredient_count', 'total_time_mins',
                'has_image', 'is_vegetarian', 'tag_count', 'issues'
            ])

            for rank, recipe in enumerate(self.scores, 1):
                writer.writerow([
                    rank,
                    recipe.title,
                    f"{recipe.overall_score:.2f}",
                    f"{recipe.completeness_score:.2f}",
                    f"{recipe.accessibility_score:.2f}",
                    f"{recipe.clarity_score:.2f}",
                    f"{recipe.metadata_score:.2f}",
                    f"{recipe.versatility_score:.2f}",
                    recipe.ingredient_count,
                    recipe.total_time_mins,
                    recipe.has_image,
                    recipe.is_vegetarian,
                    recipe.tag_count,
                    ' | '.join(recipe.issues[:5])  # First 5 issues
                ])

        print(f"\n✅ Ranked recipes exported to: {output_file}")


if __name__ == '__main__':
    analyzer = RecipeAnalyzer()
    csv_file = '/Users/gabrieltouchette/Documents/IDontCook/api/allrecipes.csv'

    analyzer.load_csv(csv_file)
    analyzer.run_analysis()
    analyzer.print_summary()
    analyzer.print_top_bottom(n=30)
    analyzer.export_ranked_csv('/Users/gabrieltouchette/Documents/IDontCook/api/allrecipes_ranked.csv')

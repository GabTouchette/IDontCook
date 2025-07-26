from django.core.management.base import BaseCommand
from django.db import transaction
from recipes.models import NutritionData

class Command(BaseCommand):
    help = 'Populate basic nutrition data for common ingredients'

    def handle(self, *args, **options):
        # Common ingredients with nutrition data per 100g
        common_ingredients = [
            # Proteins
            {'name': 'chicken breast', 'calories': 165, 'protein': 31, 'fat': 3.6, 'carbs': 0},
            {'name': 'ground beef', 'calories': 250, 'protein': 26, 'fat': 15, 'carbs': 0},
            {'name': 'salmon', 'calories': 208, 'protein': 25, 'fat': 12, 'carbs': 0},
            {'name': 'egg', 'calories': 155, 'protein': 13, 'fat': 11, 'carbs': 1.1},
            {'name': 'tofu', 'calories': 76, 'protein': 8, 'fat': 4.8, 'carbs': 1.9},
            
            # Grains & Starches
            {'name': 'rice', 'calories': 130, 'protein': 2.7, 'fat': 0.3, 'carbs': 28},
            {'name': 'pasta', 'calories': 131, 'protein': 5, 'fat': 1.1, 'carbs': 25},
            {'name': 'bread', 'calories': 265, 'protein': 9, 'fat': 3.2, 'carbs': 49},
            {'name': 'potato', 'calories': 77, 'protein': 2, 'fat': 0.1, 'carbs': 17},
            {'name': 'quinoa', 'calories': 120, 'protein': 4.4, 'fat': 1.9, 'carbs': 22},
            
            # Vegetables
            {'name': 'tomato', 'calories': 18, 'protein': 0.9, 'fat': 0.2, 'carbs': 3.9},
            {'name': 'onion', 'calories': 40, 'protein': 1.1, 'fat': 0.1, 'carbs': 9.3},
            {'name': 'carrot', 'calories': 41, 'protein': 0.9, 'fat': 0.2, 'carbs': 9.6},
            {'name': 'spinach', 'calories': 23, 'protein': 2.9, 'fat': 0.4, 'carbs': 3.6},
            {'name': 'broccoli', 'calories': 34, 'protein': 2.8, 'fat': 0.4, 'carbs': 7},
            
            # Fruits
            {'name': 'apple', 'calories': 52, 'protein': 0.3, 'fat': 0.2, 'carbs': 14},
            {'name': 'banana', 'calories': 89, 'protein': 1.1, 'fat': 0.3, 'carbs': 23},
            {'name': 'orange', 'calories': 47, 'protein': 0.9, 'fat': 0.1, 'carbs': 12},
            
            # Dairy
            {'name': 'milk', 'calories': 42, 'protein': 3.4, 'fat': 1, 'carbs': 5},
            {'name': 'cheese', 'calories': 113, 'protein': 7, 'fat': 9, 'carbs': 1},
            {'name': 'yogurt', 'calories': 59, 'protein': 10, 'fat': 0.4, 'carbs': 3.6},
            {'name': 'butter', 'calories': 717, 'protein': 0.9, 'fat': 81, 'carbs': 0.1},
            
            # Oils & Fats
            {'name': 'olive oil', 'calories': 884, 'protein': 0, 'fat': 100, 'carbs': 0},
            {'name': 'coconut oil', 'calories': 862, 'protein': 0, 'fat': 100, 'carbs': 0},
            
            # Nuts & Seeds
            {'name': 'almonds', 'calories': 579, 'protein': 21, 'fat': 50, 'carbs': 22},
            {'name': 'walnuts', 'calories': 654, 'protein': 15, 'fat': 65, 'carbs': 14},
            
            # Beans & Legumes
            {'name': 'black beans', 'calories': 132, 'protein': 8.9, 'fat': 0.5, 'carbs': 24},
            {'name': 'chickpeas', 'calories': 164, 'protein': 8.9, 'fat': 2.6, 'carbs': 27},
            {'name': 'lentils', 'calories': 116, 'protein': 9, 'fat': 0.4, 'carbs': 20},
        ]
        
        created_count = 0
        updated_count = 0
        
        for ingredient_data in common_ingredients:
            name = ingredient_data['name']
            normalized_name = name.lower().strip()
            
            nutrition_data, created = NutritionData.objects.get_or_create(
                normalized_name=normalized_name,
                defaults={
                    'name': name,
                    'calories_per_100g': ingredient_data['calories'],
                    'protein_per_100g': ingredient_data['protein'],
                    'fat_per_100g': ingredient_data['fat'],
                    'carbs_per_100g': ingredient_data['carbs'],
                    'fiber_per_100g': ingredient_data.get('fiber', 0),
                    'sugar_per_100g': ingredient_data.get('sugar', 0),
                }
            )
            
            if created:
                created_count += 1
                self.stdout.write(f'✓ Created: {name}')
            else:
                # Update existing if values are different
                updated = False
                if nutrition_data.calories_per_100g != ingredient_data['calories']:
                    nutrition_data.calories_per_100g = ingredient_data['calories']
                    updated = True
                if nutrition_data.protein_per_100g != ingredient_data['protein']:
                    nutrition_data.protein_per_100g = ingredient_data['protein']
                    updated = True
                if nutrition_data.fat_per_100g != ingredient_data['fat']:
                    nutrition_data.fat_per_100g = ingredient_data['fat']
                    updated = True
                if nutrition_data.carbs_per_100g != ingredient_data['carbs']:
                    nutrition_data.carbs_per_100g = ingredient_data['carbs']
                    updated = True
                
                if updated:
                    nutrition_data.save()
                    updated_count += 1
                    self.stdout.write(f'↻ Updated: {name}')
                else:
                    self.stdout.write(f'- Exists: {name}')
        
        self.stdout.write(
            self.style.SUCCESS(
                f'Completed! Created: {created_count}, Updated: {updated_count}'
            )
        )
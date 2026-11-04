import logging
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from typing import List, Optional, Dict, Tuple

from .models import MealPlan, PlannedMeal, GroceryList
from .serializers import MealPlanSerializer, PlannedMealSerializer, GroceryListSerializer
from recipes.models import Recipe, SavedRecipe
from recipes.search import RecipeSearchEngine
from .llm_refiner import LLMRefiner, SlotSpec, RecipeInfo, get_refiner
from .grocery_builder import build_grocery_list
from .ga_solver import Slot as GASlot, evolve_plan, FitnessOptions, derive_targets_from_profile, DEFAULT_TARGETS, GAResult


class MealPlanViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    serializer_class = MealPlanSerializer

    def get_queryset(self):
        return MealPlan.objects.filter(user=self.request.user).order_by('-week_start_date')

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=True, methods=['post'])
    def generate(self, request, pk=None):
        """Generate a meal plan in one request: heuristic baseline + safe LLM refinement."""
        meal_plan = self.get_object()
        user = request.user

        description = (request.data.get('description') or '').strip()
        days = request.data.get('days') or list(range(7))
        meal_types = request.data.get('meal_types') or ['breakfast', 'lunch', 'dinner']
        focus_on_saved = bool(request.data.get('focus_on_saved', True))
        servings = int(request.data.get('servings') or 1)
        replace_existing = bool(request.data.get('replace_existing', True))
        # Optional tunables from UI sliders
        try:
            saved_weight = request.data.get('saved_weight', None)
            saved_weight = float(saved_weight) if saved_weight is not None else None
            if saved_weight is not None:
                saved_weight = max(0.0, min(1.0, saved_weight))
        except Exception:
            saved_weight = None
        try:
            repeat_preference = request.data.get('repeat_preference', None)
            repeat_preference = float(repeat_preference) if repeat_preference is not None else None
            if repeat_preference is not None:
                repeat_preference = max(0.0, min(1.0, repeat_preference))
        except Exception:
            repeat_preference = None

        # Validate inputs
        try:
            days = [int(d) for d in days if 0 <= int(d) <= 6]
        except Exception:
            return Response({"detail": "Invalid 'days' parameter."}, status=status.HTTP_400_BAD_REQUEST)
        if not days:
            return Response({"detail": "No valid days provided."}, status=status.HTTP_400_BAD_REQUEST)
        valid_types = {"breakfast", "lunch", "dinner", "snack"}
        meal_types = [str(mt).lower() for mt in meal_types if str(mt).lower() in valid_types]
        # If none selected, treat as no slots to fill (return 400 to prompt selection)
        if not meal_types:
            return Response({"detail": "Select at least one meal type."}, status=status.HTTP_400_BAD_REQUEST)

        # Dietary parsing
        desc_l = description.lower()
        diet = None  # 'vegan' | 'vegetarian' | 'pescatarian' | None
        if 'vegan' in desc_l:
            diet = 'vegan'
        elif any(k in desc_l for k in ['vegetarian', 'veggie', 'plant-based', 'plant based', 'meatless', 'no meat', 'sans viande', 'végétar']):
            diet = 'vegetarian'
        elif 'pescatarian' in desc_l:
            diet = 'pescatarian'

        explicit_excludes = set()

        def _add_excludes_if(phrases, terms):
            if any(p in desc_l for p in phrases):
                explicit_excludes.update(terms)

        _add_excludes_if(['no pork', 'without pork', 'sans porc', 'no porc', 'without porc'], ['pork', 'porc', 'bacon', 'ham', 'prosciutto'])
        _add_excludes_if(['no beef', 'without beef', 'sans boeuf', 'no boeuf'], ['beef', 'boeuf', 'steak', 'ground beef'])
        _add_excludes_if(['no chicken', 'without chicken'], ['chicken'])
        _add_excludes_if(['no turkey', 'without turkey'], ['turkey'])
        _add_excludes_if(['no fish', 'without fish'], ['fish'])
        _add_excludes_if(['no seafood', 'without seafood'], ['fish', 'shrimp', 'tuna', 'salmon', 'crab', 'lobster'])
        
        # Enhanced dietary exclusions
        _add_excludes_if(['gluten free', 'gluten-free', 'no gluten'], ['wheat', 'flour', 'bread', 'pasta', 'barley', 'rye', 'oats'])
        _add_excludes_if(['dairy free', 'dairy-free', 'no dairy'], ['milk', 'cheese', 'butter', 'cream', 'yogurt'])

        MEAT_TERMS = {
            'beef', 'boeuf', 'pork', 'porc', 'ham', 'bacon', 'prosciutto', 'salami', 'sausage', 'chicken', 'turkey', 'duck', 'veal', 'lamb', 'mutton', 'chorizo', 'pepperoni'
        }
        SEAFOOD_TERMS = {
            'fish', 'salmon', 'tuna', 'tilapia', 'cod', 'shrimp', 'prawn', 'crab', 'lobster', 'anchovy', 'anchovies', 'sardine', 'trout', 'scallop', 'oyster', 'clam', 'mussel'
        }
        DAIRY_TERMS = {'milk', 'cheese', 'butter', 'yogurt', 'cream', 'ghee', 'whey', 'casein', 'kefir'}
        EGG_TERMS = {'egg', 'eggs'}
        HONEY_TERMS = {'honey'}

        # Parse high-level goals early so dietary filters can reference them
        goals = request.data.get('goals') or []  # e.g., ['high-protein','low-carb']
        if isinstance(goals, str):
            goals = [goals]
        try:
            goals = set(str(g).lower() for g in goals)
        except Exception:
            goals = None

        # Enhanced goal processing - add implicit goals from description
        if goals is None:
            goals = set()
        # Extract goals from description text
        if 'weight loss' in desc_l or 'lose weight' in desc_l:
            goals.add('weight loss')
        if 'muscle gain' in desc_l or 'build muscle' in desc_l or 'gain muscle' in desc_l:
            goals.add('muscle gain')
        if 'quick' in desc_l or 'fast' in desc_l or 'under 30' in desc_l:
            goals.add('quick')
        if 'budget' in desc_l or 'cheap' in desc_l or 'inexpensive' in desc_l:
            goals.add('budget-friendly')
        if 'high protein' in desc_l or 'high-protein' in desc_l:
            goals.add('high-protein')
        if 'low carb' in desc_l or 'low-carb' in desc_l:
            goals.add('low-carb')
        if 'gluten free' in desc_l or 'gluten-free' in desc_l:
            goals.add('gluten-free')
        if 'dairy free' in desc_l or 'dairy-free' in desc_l:
            goals.add('dairy-free')
        if 'healthy' in desc_l:
            goals.add('healthy')

        def _tokenize(text: str):
            try:
                import re
                return set(re.findall(r"[a-zA-Z]+", (text or '').lower()))
            except Exception:
                return set(((text or '').lower().split()))

        def _recipe_tokens(recipe):
            tokens = set()
            try:
                if recipe.title:
                    tokens |= _tokenize(recipe.title)
                for ing in recipe.ingredients.all():
                    if getattr(ing, 'name', None):
                        tokens |= _tokenize(ing.name)
            except Exception:
                pass
            return tokens

        def _has_tag_like(recipe, values):
            try:
                tags = [((t or '').strip().lower()) for t in (recipe.tags or [])]
                return any(v in tags for v in values)
            except Exception:
                return False

        def _violates_diet(recipe):
            tokens = _recipe_tokens(recipe)
            if explicit_excludes and any(term in tokens for term in explicit_excludes):
                return True
            
            # Enhanced dietary filtering based on goals
            if goals:
                if 'gluten-free' in goals and any(term in tokens for term in {'wheat', 'flour', 'bread', 'pasta', 'barley', 'rye'}):
                    # Allow if recipe is explicitly tagged gluten-free
                    if not _has_tag_like(recipe, ['gluten-free', 'gluten free']):
                        return True
                if 'dairy-free' in goals and any(term in tokens for term in {'milk', 'cheese', 'butter', 'cream', 'yogurt'}):
                    # Allow if recipe is explicitly tagged dairy-free
                    if not _has_tag_like(recipe, ['dairy-free', 'dairy free', 'vegan']):
                        return True
            
            if diet == 'vegan':
                if _has_tag_like(recipe, ['vegan']):
                    return False
                return bool(tokens & (MEAT_TERMS | SEAFOOD_TERMS | DAIRY_TERMS | EGG_TERMS | HONEY_TERMS))
            if diet == 'vegetarian':
                if _has_tag_like(recipe, ['vegetarian', 'vegan']):
                    return False
                return bool(tokens & (MEAT_TERMS | SEAFOOD_TERMS))
            if diet == 'pescatarian':
                if _has_tag_like(recipe, ['pescatarian', 'vegetarian', 'vegan']):
                    return False
                return bool(tokens & MEAT_TERMS)
            return False

        def _filter_by_diet(recipes):
            if diet is None and not explicit_excludes:
                return list(recipes)
            return [r for r in recipes if not _violates_diet(r)]

        def _rank_list(items):
            items = list(items)
            if not items:
                return []
            if description:
                engine = RecipeSearchEngine()
                scored = engine.search(description, items, limit=len(items))
                return [r for (r, _s) in scored] or items
            else:
                import random as _rnd
                _rnd.shuffle(items)
                return items

        # Build candidates
        if focus_on_saved:
            saved_ids = list(SavedRecipe.objects.filter(user=user).values_list('recipe_id', flat=True))
            saved_qs = Recipe.objects.filter(id__in=saved_ids)
            own_qs = Recipe.objects.filter(created_by=user).exclude(id__in=saved_ids)
            public_qs = Recipe.objects.filter(parent__isnull=True).exclude(id__in=saved_ids).exclude(created_by=user)

            saved = _rank_list(_filter_by_diet(list(saved_qs.prefetch_related('ingredients'))))
            own = _rank_list(_filter_by_diet(list(own_qs.prefetch_related('ingredients'))))
            public = _rank_list(_filter_by_diet(list(public_qs.prefetch_related('ingredients')[:200])))
            candidates = saved + own + public
        else:
            own_qs = Recipe.objects.filter(created_by=user)
            saved_ids = list(SavedRecipe.objects.filter(user=user).values_list('recipe_id', flat=True))
            saved_qs = Recipe.objects.filter(id__in=saved_ids)
            base = _filter_by_diet(list((own_qs | saved_qs).distinct().prefetch_related('ingredients')))
            base = _rank_list(base)
            if len(base) < 6:
                public_qs = Recipe.objects.filter(parent__isnull=True).exclude(id__in=[r.id for r in base])
                public = _rank_list(_filter_by_diet(list(public_qs.prefetch_related('ingredients')[:200])))
                candidates = (base + public)[:300]
            else:
                candidates = base

        if not candidates:
            msg = "No recipes available to generate a plan."
            if diet or explicit_excludes:
                msg = "No recipes match your dietary preferences. Try relaxing the request or adding more recipes."
            return Response({"detail": msg}, status=status.HTTP_400_BAD_REQUEST)

        # Diet tag and meal-prep boosts
        if diet in ('vegan', 'vegetarian', 'pescatarian'):
            def _diet_score(r):
                try:
                    tags = [((t or '').strip().lower()) for t in (r.tags or [])]
                except Exception:
                    tags = []
                if diet == 'vegan':
                    return 2 if 'vegan' in tags else 0
                if diet == 'vegetarian':
                    return 2 if ('vegetarian' in tags or 'veggie' in tags or 'plant-based' in tags or 'plant based' in tags) else 0
                if diet == 'pescatarian':
                    return 2 if 'pescatarian' in tags else 0
                return 0
            candidates.sort(key=_diet_score, reverse=True)

        if any(p in desc_l for p in ['meal prep', 'meal-prep', 'prep ahead', 'make ahead', 'batch', 'leftover', 'leftovers']):
            def _prep_score(r):
                title = (r.title or '').lower()
                tags = [((t or '').strip().lower()) for t in (r.tags or [])]
                score = 0
                if any(word in title for word in ['prep', 'batch', 'make-ahead', 'make ahead', 'leftover']):
                    score += 2
                if any(t in tags for t in ['meal prep', 'make ahead', 'batch', 'leftovers']):
                    score += 3
                try:
                    if (r.cooking_time or 0) >= 30:
                        score += 1
                except Exception:
                    pass
                return score
            candidates.sort(key=_prep_score, reverse=True)

        # Clear existing in selected slots
        if replace_existing:
            PlannedMeal.objects.filter(
                meal_plan=meal_plan,
                day_of_week__in=days,
                meal_type__in=meal_types,
            ).delete()

        # Helpers for meal-type
        def _has_tag(recipe, tag):
            try:
                tags = recipe.tags or []
                return any((t or '').strip().lower() == tag for t in tags)
            except Exception:
                return False

        BREAKFAST_KEYS = {'breakfast', 'brunch', 'morning', 'pancake', 'pancakes', 'waffle', 'waffles', 'omelet', 'omelette', 'granola', 'oatmeal', 'porridge', 'smoothie', 'smoothies', 'toast', 'french', 'bagel', 'muffin', 'muffins', 'overnight', 'oats', 'frittata', 'scramble', 'cereal'}
        LUNCH_KEYS = {'lunch', 'sandwich', 'sandwiches', 'wrap', 'wraps', 'salad', 'bowl', 'bento', 'burrito', 'quesadilla', 'panini', 'poke'}
        DINNER_KEYS = {'dinner', 'supper', 'main', 'entree', 'pasta', 'curry', 'stew', 'roast', 'stir', 'stir-fry', 'stirfry', 'casserole', 'chili', 'pizza', 'burger', 'steak', 'meatloaf', 'lasagna', 'noodles', 'gnocchi', 'risotto'}
        SNACK_KEYS = {'snack', 'snacks', 'bar', 'bars', 'energy', 'balls', 'bites', 'trail', 'mix', 'dip', 'hummus', 'popcorn', 'chips', 'cookie', 'cookies', 'brownie', 'brownies', 'granola bar', 'protein bar'}

        def _guess_meal_types(recipe):
            types = set()
            try:
                tags = set(((t or '').strip().lower() for t in (recipe.tags or [])))
            except Exception:
                tags = set()
            toks = _recipe_tokens(recipe)
            if 'breakfast' in tags or toks & BREAKFAST_KEYS:
                types.add('breakfast')
            if 'lunch' in tags or toks & LUNCH_KEYS:
                types.add('lunch')
            if 'dinner' in tags or toks & DINNER_KEYS:
                types.add('dinner')
            if 'snack' in tags or toks & SNACK_KEYS:
                types.add('snack')
            title = (getattr(recipe, 'title', '') or '').lower()
            if 'smoothie' in title:
                types.update({'breakfast', 'snack'})
            if 'salad' in title:
                types.update({'lunch', 'dinner'})
            if 'soup' in title:
                types.update({'lunch', 'dinner'})
            try:
                cook = int(getattr(recipe, 'cooking_time', 0) or 0)
            except Exception:
                cook = 0
            if cook and cook >= 30:
                types.add('dinner')
            if not types:
                types.add('dinner')
            return types

        def _fits_meal_type(recipe, mt):
            # Only allow recipes that have the explicit meal type tag
            # This prevents recipes without proper tags from being assigned to wrong meal slots
            return _has_tag(recipe, mt)

        # Build GA slots per selected meal type/day with strict tag match
        slots = []
        for day in days:
            for mt in meal_types:
                mt_tag = mt.lower()
                pool = [c for c in candidates if _fits_meal_type(c, mt_tag)]
                if not pool:
                    continue  # if no candidates for this slot, let GA skip it
                slots.append(GASlot(day=int(day), meal_type=mt_tag, candidates=pool))

    # Saved set for scoring boost
        saved_set = set(SavedRecipe.objects.filter(user=user).values_list('recipe_id', flat=True))

    # Build fitness options from request (goals already parsed above)

        # Optional per-meal time overrides
        time_limits = request.data.get('time_limits') or {}
        if not isinstance(time_limits, dict):
            time_limits = {}
        
        # Auto-adjust time limits for quick goal
        if 'quick' in goals:
            quick_limits = {'breakfast': 10, 'lunch': 20, 'dinner': 30, 'snack': 10}
            time_limits = {**quick_limits, **time_limits}
            
        # Budget and difficulty
        budget_per_meal = request.data.get('budget_per_meal')
        try:
            budget_per_meal = float(budget_per_meal) if budget_per_meal is not None else None
        except Exception:
            budget_per_meal = None
        difficulty_max = request.data.get('difficulty_max')
        try:
            difficulty_max = int(difficulty_max) if difficulty_max is not None else None
        except Exception:
            difficulty_max = None

        # Optional profile to derive targets; otherwise defaults with goal adjustments
        profile = request.data.get('profile') or None
        targets = None
        if isinstance(profile, dict):
            # Add goals to profile for target calculation
            profile['goals'] = list(goals) if goals else []
            targets = derive_targets_from_profile(profile)
        elif goals:
            # Apply goal-based adjustments to default targets even without profile
            targets = derive_targets_from_profile({'goals': list(goals)})
        
        if not targets:
            targets = DEFAULT_TARGETS

        # Adjust weights when certain goals are selected
        base_weights = FitnessOptions().weights.copy()
        if 'healthy' in goals:
            # Emphasize nutrition when user asks for "Healthy"
            base_weights['nutrition'] = min(0.7, base_weights.get('nutrition', 0.5) + 0.2)
            # Slightly reduce time/cost emphasis to keep weights balanced
            base_weights['time'] = max(0.05, base_weights.get('time', 0.15) - 0.03)
            base_weights['cost'] = max(0.05, base_weights.get('cost', 0.10) - 0.02)

        fit_opts = FitnessOptions(
            targets=targets,
            servings=servings,
            focus_on_saved=focus_on_saved,
            saved_set=saved_set,
            goals=goals,
            time_limits={**FitnessOptions().time_limits, **{k: int(v) for k, v in time_limits.items() if str(k) and str(v).isdigit()}},
            budget_per_meal=budget_per_meal,
            difficulty_max=difficulty_max,
            weights=base_weights,
            saved_weight=saved_weight,
            repeat_preference=repeat_preference,
        )

        ga_result = GAResult(meals=[], fitness_score=0.0, total_slots=0, filled_slots=0, low_quality_slots=[], warnings=[])
        try:
            ga_result = evolve_plan(slots, servings=servings, saved_set=saved_set, focus_on_saved=focus_on_saved, fitness_options=fit_opts)
        except Exception as e:
            ga_result = GAResult(
                meals=[], 
                fitness_score=0.0, 
                total_slots=len(slots), 
                filled_slots=0, 
                low_quality_slots=[], 
                warnings=[f"Error during meal planning: {str(e)}"]
            )

        new_meals = []
        if ga_result.meals:
            for day, mt_tag, recipe in ga_result.meals:
                try:
                    new_meals.append(PlannedMeal(
                        meal_plan=meal_plan,
                        recipe=recipe,
                        day_of_week=int(day),
                        meal_type=str(mt_tag),
                        servings=servings,
                    ))
                except Exception:
                    continue
            if new_meals:
                PlannedMeal.objects.bulk_create(new_meals)
        else:
            # Fallback to previous heuristic if GA returned nothing
            used_ids_global = set()
            used_per_day = {int(d): set() for d in days}
            last_chosen_by_day = {}
            cursor = 0
            for day in days:
                for mt in meal_types:
                    mt_tag = mt.lower()
                    preferred = [c for c in candidates if _fits_meal_type(c, mt_tag)]
                    pool = preferred if preferred else candidates
                    if not pool:
                        continue
                    chosen = None
                    attempts = 0
                    day_used = used_per_day[int(day)]
                    last_id = last_chosen_by_day.get(int(day))
                    limit = max(1, len(pool) * 2)
                    while attempts < limit:
                        cand = pool[cursor % len(pool)]
                        cursor += 1
                        attempts += 1
                        if cand.id not in day_used and cand.id not in used_ids_global:
                            chosen = cand
                            break
                        if chosen is None and cand.id not in day_used:
                            chosen = cand
                        if chosen is None and (last_id is None or cand.id != last_id):
                            chosen = cand
                    if chosen is None:
                        chosen = pool[0]

                    used_ids_global.add(chosen.id)
                    day_used.add(chosen.id)
                    last_chosen_by_day[int(day)] = chosen.id

                    new_meals.append(PlannedMeal(
                        meal_plan=meal_plan,
                        recipe=chosen,
                        day_of_week=int(day),
                        meal_type=mt,
                        servings=servings,
                    ))
            if new_meals:
                PlannedMeal.objects.bulk_create(new_meals)

    # Phase 2: optional LLM refinement over safe candidate sets
        try:
            # Build minimal recipe info map
            saved_set = set(SavedRecipe.objects.filter(user=user).values_list('recipe_id', flat=True))
            rec_info = {}
            for r in candidates:
                rec_info[r.id] = RecipeInfo(
                    id=r.id,
                    is_saved=(r.id in saved_set),
                    is_own=(getattr(r, 'created_by_id', None) == getattr(user, 'id', None)),
                    cooking_time=getattr(r, 'cooking_time', None),
                    tags=[(t or '').strip().lower() for t in (getattr(r, 'tags', []) or [])],
                )

            # By-day lookup of created meals
            by_day = {d: {} for d in days}
            for pm in meal_plan.planned_meals.filter(day_of_week__in=days, meal_type__in=meal_types).all():
                by_day[pm.day_of_week][pm.meal_type] = pm

            def slot_candidate_ids(mt_tag: str, top_n: int = 12):
                prefs = [c for c in candidates if mt_tag in _guess_meal_types(c)]
                pool = prefs if prefs else candidates
                return [c.id for c in pool[:top_n]]

            slots = []
            for d in days:
                for mt in meal_types:
                    pm = by_day.get(d, {}).get(mt)
                    if not pm:
                        continue
                    current_recipe_id = int(pm.recipe_id or pm.recipe.id)
                    slots.append(SlotSpec(
                        day=int(d),
                        meal_type=mt,
                        current_recipe_id=current_recipe_id,
                        candidate_ids=slot_candidate_ids(mt),
                    ))

            if slots:
                refiner = get_refiner()
                try:
                    logging.getLogger(__name__).info("MealPlanRefiner selected: %s", type(refiner).__name__)
                except Exception:
                    pass
                updates: List[PlannedMeal] = []

                # If refiner supports ops, use them; otherwise fallback to replace-only mapping
                patch_mapping = None
                ops = None
                if hasattr(refiner, 'refine_ops'):
                    try:
                        ops = refiner.refine_ops(
                            description=description,
                            slots=slots,
                            recipes=rec_info,
                            focus_on_saved=focus_on_saved,
                        )
                    except Exception:
                        ops = []
                if ops is None:
                    # Back-compat replace-only
                    try:
                        patch_mapping = refiner.refine(
                            description=description,
                            slots=slots,
                            recipes=rec_info,
                            focus_on_saved=focus_on_saved,
                        )
                    except Exception:
                        patch_mapping = {}

                # Validate and apply ops
                def get_pm(dv: int, mtv: str) -> Optional[PlannedMeal]:
                    return by_day.get(int(dv), {}).get(str(mtv).lower())

                # Index slot candidates for validation
                slot_allowed: Dict[Tuple[int, str], set] = {}
                for s in slots:
                    slot_allowed[(int(s.day), str(s.meal_type).lower())] = set(int(cid) for cid in s.candidate_ids)

                # Apply ops if present
                if isinstance(ops, list) and ops:
                    for op in ops:
                        if not isinstance(op, dict):
                            continue
                        typ = str(op.get('op', '')).lower()
                        if typ == 'replace':
                            try:
                                d = int(op.get('day'))
                                mt = str(op.get('meal_type')).lower()
                                rid = int(op.get('recipe_id'))
                            except Exception:
                                continue
                            if (d, mt) not in slot_allowed or rid not in slot_allowed[(d, mt)]:
                                continue
                            pm = get_pm(d, mt)
                            if not pm:
                                continue
                            rec = next((r for r in candidates if r.id == rid), None)
                            if not rec:
                                continue
                            pm.recipe = rec
                            updates.append(pm)
                        elif typ == 'remove':
                            try:
                                d = int(op.get('day'))
                                mt = str(op.get('meal_type')).lower()
                            except Exception:
                                continue
                            pm = get_pm(d, mt)
                            if not pm:
                                continue
                            # Clear by deleting the planned meal for that slot
                            pm.delete()
                            by_day[d].pop(mt, None)
                        elif typ == 'swap':
                            a = op.get('a') or {}
                            b = op.get('b') or {}
                            try:
                                ad, amt = int(a.get('day')), str(a.get('meal_type')).lower()
                                bd, bmt = int(b.get('day')), str(b.get('meal_type')).lower()
                            except Exception:
                                continue
                            pm_a = get_pm(ad, amt)
                            pm_b = get_pm(bd, bmt)
                            if not pm_a or not pm_b:
                                continue
                            # swap recipes
                            pm_a.recipe, pm_b.recipe = pm_b.recipe, pm_a.recipe
                            updates.extend([pm_a, pm_b])

                # Fallback to mapping if provided
                if patch_mapping:
                    for (d, mt), rid in patch_mapping.items():
                        rec = next((r for r in candidates if r.id == rid), None)
                        if not rec:
                            continue
                        pm = get_pm(d, mt)
                        if not pm:
                            continue
                        pm.recipe = rec
                        updates.append(pm)

                if updates:
                    PlannedMeal.objects.bulk_update(list({u.id: u for u in updates}.values()), ['recipe'])
        except Exception:
            # Fail-closed
            pass

        # Recompute grocery list after generation
        try:
            gl, _created = GroceryList.objects.get_or_create(meal_plan=meal_plan)
            gl.ingredients = build_grocery_list(meal_plan)
            gl.save()
        except Exception:
            pass

        serializer = self.get_serializer(meal_plan)
        response_data = serializer.data
        
        # Add GA result metadata to response
        response_data['generation_metadata'] = {
            'fitness_score': ga_result.fitness_score,
            'total_slots': ga_result.total_slots,
            'filled_slots': ga_result.filled_slots,
            'fill_rate': ga_result.filled_slots / max(1, ga_result.total_slots),
            'low_quality_count': len(ga_result.low_quality_slots),
            'warnings': ga_result.warnings,
            'low_quality_slots': [
                {'day': day, 'meal_type': meal_type, 'fitness': fitness}
                for day, meal_type, fitness in ga_result.low_quality_slots
            ]
        }
        
        return Response(response_data, status=status.HTTP_200_OK)

    @action(detail=True, methods=['get'])
    def grocery_list(self, request, pk=None):
        meal_plan = self.get_object()
        recompute = str(request.query_params.get('recompute', 'false')).lower() in ('1', 'true', 'yes')
        gl, _ = GroceryList.objects.get_or_create(meal_plan=meal_plan)
        # Recompute normalized list from current planned meals when requested or if empty
        if recompute or not gl.ingredients:
            try:
                normalized = build_grocery_list(meal_plan)
                gl.ingredients = normalized
                gl.save()
            except Exception:
                # Fail-closed: keep existing list if any
                pass
        return Response(GroceryListSerializer(gl, context={'request': request}).data)

    @action(detail=True, methods=['post'], url_path='grocery-list/purchase')
    def purchase_items(self, request, pk=None):
        meal_plan = self.get_object()
        gl, _ = GroceryList.objects.get_or_create(meal_plan=meal_plan)
        purchased = request.data.get('purchased_items', [])
        gl.purchased_items = purchased
        gl.save()
        return Response({"success": True})


class PlannedMealViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    serializer_class = PlannedMealSerializer

    def get_queryset(self):
        return PlannedMeal.objects.filter(meal_plan__user=self.request.user)

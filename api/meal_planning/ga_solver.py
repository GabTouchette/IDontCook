import math
import random
from dataclasses import dataclass, field
from typing import List, Dict, Tuple, Optional, Callable, NamedTuple
from functools import lru_cache

# Meal-type nutrition targets (per meal, per person). Adjust as needed.
DEFAULT_TARGETS = {
    'breakfast': {'calories': 400, 'protein': 20},
    'lunch': {'calories': 650, 'protein': 30},
    'dinner': {'calories': 800, 'protein': 35},
    'snack': {'calories': 200, 'protein': 10},
}


class GAResult(NamedTuple):
    """Result from GA solver with metadata about solution quality"""
    meals: List[Tuple[int, str, object]]  # (day, meal_type, recipe_obj)
    fitness_score: float
    total_slots: int
    filled_slots: int
    low_quality_slots: List[Tuple[int, str, float]]  # slots with fitness < threshold
    warnings: List[str]  # human-readable warnings

    # Back-compat: behave like a list of (day, meal_type, recipe) when iterated/len()
    # This allows older callers/tests that expect evolve_plan to return a list to keep working.
    def __iter__(self):  # type: ignore[override]
        return iter(self.meals)

    def __len__(self):  # type: ignore[override]
        return len(self.meals)


@dataclass
class Slot:
    day: int
    meal_type: str
    candidates: List  # list of Recipe ORM objects


@dataclass
class GAParams:
    pop_size: int = 80
    generations: int = 60
    crossover_rate: float = 0.9
    mutation_rate: float = 0.1
    elite: int = 2
    top_n_per_slot: int = 100  # limit candidates per slot for performance


# -------- Fitness options and components -------- #

@dataclass
class FitnessOptions:
    targets: Dict[str, Dict[str, float]] = field(default_factory=lambda: DEFAULT_TARGETS)
    servings: int = 1
    focus_on_saved: bool = True
    saved_set: Optional[set] = None
    # User preferences / constraints
    goals: Optional[set] = None  # set of goal strings to match in tags
    time_limits: Dict[str, int] = field(default_factory=lambda: {
        'breakfast': 20, 'lunch': 30, 'dinner': 45, 'snack': 15
    })
    budget_per_meal: Optional[float] = None  # total cost ceiling for recipe * servings
    difficulty_max: Optional[int] = None     # 1 (easy) .. 3 (hard)
    # Component weights
    weights: Dict[str, float] = field(default_factory=lambda: {
        'nutrition': 0.5,
        'time': 0.15,
        'cost': 0.1,
        'difficulty': 0.05,
        'goals': 0.15,  # Increased for stronger preference adherence
        'saved': 0.05,
        'meal_type': 0.05,  # small guardrail to avoid mismatched meal types
    })
    # Tunables
    saved_weight: Optional[float] = None   # 0..1 override for saved weight influence
    repeat_preference: Optional[float] = None  # 0 (no repeats) .. 1 (allow repeats)
    # Variety controls
    variety_strength: float = 0.5  # 0..1 scale for how strongly to penalize repeating protein categories
    same_day_category_allowance: int = 1  # allow this many occurrences of same primary protein per day before penalizing
    weekly_category_soft_limit: int = 5   # soft cap for how often a protein category can repeat in a week before small penalties


def derive_targets_from_profile(profile: Dict) -> Dict[str, Dict[str, float]]:
    """Compute per-meal targets from a user profile (age/height/weight/sex/activity).
    profile keys (optional):
      - sex: 'male'|'female'
      - age: years
      - height_cm: centimeters
      - weight_kg: kilograms
      - activity: one of ['sedentary','light','moderate','active','very']
      - protein_g_per_kg: default 1.6
      - goals: list of goal strings that may affect targets
    Returns same shape as DEFAULT_TARGETS.
    """
    try:
        sex = str(profile.get('sex', 'male')).lower()
        age = float(profile.get('age', 30))
        height_cm = float(profile.get('height_cm', 175))
        weight_kg = float(profile.get('weight_kg', 75))
        activity = str(profile.get('activity', 'moderate')).lower()
        prot_per_kg = float(profile.get('protein_g_per_kg', 1.6))
        goals = profile.get('goals', [])

        # Mifflin-St Jeor BMR
        if sex.startswith('f'):
            bmr = 10 * weight_kg + 6.25 * height_cm - 5 * age - 161
        else:
            bmr = 10 * weight_kg + 6.25 * height_cm - 5 * age + 5

        mult = {
            'sedentary': 1.2,
            'light': 1.375,
            'moderate': 1.55,
            'active': 1.725,
            'very': 1.9,
        }.get(activity, 1.55)
        tdee = bmr * mult

        # Apply goal-based adjustments
        calorie_multiplier = 1.0
        protein_multiplier = 1.0
        
        if goals:
            goal_strings = [str(g).lower() for g in goals]
            # Weight loss: reduce calories
            if any('weight' in g and 'loss' in g for g in goal_strings):
                calorie_multiplier = 0.85  # 15% reduction
            # Muscle gain: increase calories and protein
            elif any('muscle' in g and 'gain' in g for g in goal_strings):
                calorie_multiplier = 1.1  # 10% increase
                protein_multiplier = 1.3  # 30% more protein

        tdee *= calorie_multiplier
        daily_protein = weight_kg * prot_per_kg * protein_multiplier

        # Meal distribution (% of daily)
        meal_pct = {
            'breakfast': 0.25,
            'lunch': 0.35,
            'dinner': 0.35,
            'snack': 0.05,
        }

        # Allocate protein similar to calories
        return {
            mt: {
                'calories': tdee * pct,
                'protein': daily_protein * pct,
            }
            for mt, pct in meal_pct.items()
        }
    except Exception:
        # Fallback to defaults on any error
        return DEFAULT_TARGETS


def _safe(val, default=0.0):
    try:
        if val is None:
            return default
        return float(val)
    except Exception:
        return default


def _difficulty_to_int(recipe) -> Optional[int]:
    # Try field; else infer from tags if present
    try:
        diff = getattr(recipe, 'difficulty', None)
        if diff is not None:
            if isinstance(diff, (int, float)):
                val = int(diff)
                if 1 <= val <= 3:
                    return val
            s = str(diff).lower()
            return 1 if 'easy' in s else (2 if 'medium' in s else (3 if 'hard' in s else None))
    except Exception:
        pass
    # Try tags
    try:
        tags = [str(t).lower() for t in (getattr(recipe, 'tags', []) or [])]
        if 'easy' in tags:
            return 1
        if 'medium' in tags:
            return 2
        if 'hard' in tags:
            return 3
    except Exception:
        pass
    return None


def comp_nutrition(recipe, meal_type: str, ctx: FitnessOptions) -> float:
    t = ctx.targets.get(meal_type, DEFAULT_TARGETS.get(meal_type, {'calories': 600, 'protein': 25}))
    cal_target = _safe(t.get('calories'), 600.0) * max(1, ctx.servings)
    pro_target = _safe(t.get('protein'), 25.0) * max(1, ctx.servings)
    calories = _safe(getattr(recipe, 'calories', None), 0.0)
    protein = _safe(getattr(recipe, 'protein', None), 0.0)
    carbs = _safe(getattr(recipe, 'carbs', None), 0.0)

    # Calorie closeness with a smooth (gaussian-like) falloff; tolerant to modest deviations
    if calories > 0 and cal_target > 0:
        sigma = 0.35 * cal_target  # ~70% band gets high scores
        cal_score = math.exp(-((calories - cal_target) ** 2) / (2.0 * (sigma ** 2)))
    else:
        cal_score = 0.0

    # Protein: reward meeting target, light penalty for small overshoot, stronger for shortfall
    if protein > 0 and pro_target > 0:
        if protein >= pro_target:
            # up to +30% overshoot mostly fine; beyond that taper
            overshoot = (protein - pro_target) / pro_target
            pro_score = max(0.6, 1.0 - max(0.0, overshoot - 0.3))
        else:
            shortfall = (pro_target - protein) / pro_target
            pro_score = max(0.0, 1.0 - min(1.0, shortfall))
    else:
        pro_score = 0.0

    # Add carb penalty for low-carb goals
    carb_score = 1.0
    try:
        if ctx.goals and any('low' in str(g).lower() and 'carb' in str(g).lower() for g in ctx.goals):
            # Penalty for high carbs when low-carb is a goal
            if carbs > 0:
                # Threshold scales lightly by meal type (snacks stricter)
                base = 25 if meal_type.lower() == 'snack' else 30
                carb_penalty = max(0.0, (carbs - base) / 50.0)
                carb_score = max(0.0, 1.0 - min(1.0, carb_penalty))
    except Exception:
        pass

    return max(0.0, 0.6 * cal_score + 0.3 * pro_score + 0.1 * carb_score)


def comp_time(recipe, meal_type: str, ctx: FitnessOptions) -> float:
    prep = _safe(getattr(recipe, 'preparation_time', None), 0.0)
    cook = _safe(getattr(recipe, 'cooking_time', None), 0.0)
    total_time = prep + cook
    limit = ctx.time_limits.get(meal_type, 45)
    penalty = max(0.0, (total_time - limit) / max(10.0, limit))
    return max(0.0, 1.0 - min(1.0, penalty))


def comp_cost(recipe, meal_type: str, ctx: FitnessOptions) -> Optional[float]:
    # If explicit budget isn't provided, allow a default when budget goal is present
    eff_budget = ctx.budget_per_meal
    try:
        has_budget_goal = any(g in (ctx.goals or set()) for g in {'budget', 'budget-friendly', 'cheap', 'low-cost'})
    except Exception:
        has_budget_goal = False
    if eff_budget is None and has_budget_goal:
        eff_budget = 3.5  # default target cost per serving in dollars

    if eff_budget is None:
        return None

    try:
        cps = _safe(getattr(recipe, 'cost_per_serving', None), None)
        if cps is None:
            cps = _estimate_cost_per_serving(recipe)  # heuristic fallback
        if cps is None:
            return None
        cost = cps * max(1, ctx.servings)
        if eff_budget <= 0:
            return 1.0
        pen = max(0.0, (cost - eff_budget) / eff_budget)
        return max(0.0, 1.0 - min(1.0, pen))
    except Exception:
        return None


def _estimate_cost_per_serving(recipe) -> Optional[float]:
    """Heuristic cost-per-serving estimator based on ingredient signals.
    Returns approximate USD per serving or None.
    """
    try:
        servings = int(getattr(recipe, 'servings', 0) or 0)
    except Exception:
        servings = 0
    if servings <= 0:
        servings = 4  # assume family-style if unspecified

    try:
        ings = list(getattr(recipe, 'ingredients', None).all()) if getattr(recipe, 'ingredients', None) else []
    except Exception:
        ings = []

    # Keyword buckets with rough cost weights (per ingredient presence)
    SEAFOOD = {'salmon', 'shrimp', 'prawn', 'lobster', 'crab', 'scallop', 'tuna', 'cod', 'halibut'}
    RED_MEAT = {'beef', 'steak', 'lamb', 'veal', 'short rib', 'ribs'}
    PORK = {'pork', 'bacon', 'ham', 'prosciutto', 'sausage'}
    POULTRY = {'chicken', 'turkey', 'duck'}
    CHEESE = {'cheese', 'parmesan', 'cheddar', 'mozzarella', 'feta', 'goat cheese', 'ricotta'}
    NUTS = {'almond', 'almonds', 'cashew', 'cashews', 'pistachio', 'pistachios', 'walnut', 'walnuts', 'pine nut', 'pine nuts', 'pecan', 'pecans', 'nut'}
    GRAINS = {'rice', 'pasta', 'noodle', 'noodles', 'spaghetti', 'macaroni', 'grain', 'quinoa', 'couscous'}
    LEGUMES = {'bean', 'beans', 'lentil', 'lentils', 'chickpea', 'chickpeas', 'peanut', 'peanuts'}
    TOFU = {'tofu', 'tempeh'}
    EGGS = {'egg', 'eggs'}
    VEG_FRUIT = {'onion', 'garlic', 'tomato', 'pepper', 'carrot', 'celery', 'potato', 'zucchini', 'broccoli', 'spinach', 'kale', 'apple', 'banana', 'lemon', 'lime'}
    SPICES = {'salt', 'pepper', 'cumin', 'paprika', 'turmeric', 'oregano', 'basil', 'thyme', 'chili', 'chilli', 'cinnamon', 'clove', 'ginger'}

    def kw(name: str) -> float:
        n = (name or '').lower()
        # expensive
        if any(k in n for k in SEAFOOD):
            return 6.0  # Calibrated higher for realistic seafood costs
        if any(k in n for k in RED_MEAT):
            return 4.5  # Calibrated higher for meat costs
        if any(k in n for k in PORK):
            return 3.5
        if any(k in n for k in POULTRY):
            return 2.8
        if any(k in n for k in CHEESE):
            return 2.2
        if any(k in n for k in NUTS):
            return 2.5
        # moderate
        if any(k in n for k in GRAINS):
            return 0.8
        if any(k in n for k in LEGUMES):
            return 0.6  # Budget-friendly protein
        if any(k in n for k in TOFU):
            return 1.0
        if any(k in n for k in EGGS):
            return 0.7  # Budget-friendly protein
        # low cost common veg/fruit
        if any(k in n for k in VEG_FRUIT):
            return 0.5
        # spices/condiments likely negligible per recipe
        if any(k in n for k in SPICES):
            return 0.1
        # unknowns
        return 0.8

    base = 2.0  # Increased base cost for pantry staples, oils, etc.
    total = base
    for ing in ings:
        try:
            nm = (getattr(ing, 'usda_name', None) or getattr(ing, 'name', None) or '').strip()
        except Exception:
            nm = ''
        if not nm:
            total += 0.3  # Increased unknown ingredient cost
            continue
        total += kw(nm)

    # Ingredient count overhead (more ingredients => pricier)
    extra_cnt = max(0, len(ings) - 8)
    total += 0.15 * extra_cnt  # Increased overhead

    # Return cost per serving
    return max(0.5, total / max(1, servings))  # Higher minimum cost


def comp_meal_type(recipe, meal_type: str, ctx: FitnessOptions) -> float:
    """Guardrail: ensure recipe tags include the slot meal type (case-insensitive).
    Returns 1.0 for match, else 0.0. Keeps flexibility if upstream pre-filter missed something.
    """
    try:
        tags = [str(t).lower() for t in (getattr(recipe, 'tags', []) or [])]
        return 1.0 if meal_type.lower() in tags else 0.0
    except Exception:
        return 0.0


# Cache for primary protein category detection by recipe id
_RECIPE_CAT_CACHE: Dict[int, str] = {}


def _primary_protein_category(recipe) -> str:
    """Heuristic to infer the primary protein/anchor category of a recipe from ingredients.
    Used for variety penalties. Returns one of: seafood, red_meat, pork, poultry, legumes,
    tofu, eggs, cheese, grains, veg, unknown.
    """
    try:
        rid = getattr(recipe, 'id', None)
        if isinstance(rid, int) and rid in _RECIPE_CAT_CACHE:
            return _RECIPE_CAT_CACHE[rid]
    except Exception:
        rid = None

    # Buckets (aligned loosely with cost estimator terminology)
    SEAFOOD = {'salmon', 'shrimp', 'prawn', 'lobster', 'crab', 'scallop', 'tuna', 'cod', 'halibut', 'mackerel', 'sardine'}
    RED_MEAT = {'beef', 'steak', 'lamb', 'veal', 'short rib', 'ribs'}
    PORK = {'pork', 'bacon', 'ham', 'prosciutto', 'sausage'}
    POULTRY = {'chicken', 'turkey', 'duck'}
    LEGUMES = {'bean', 'beans', 'lentil', 'lentils', 'chickpea', 'chickpeas', 'peanut', 'peanuts'}
    TOFU = {'tofu', 'tempeh'}
    EGGS = {'egg', 'eggs'}
    CHEESE = {'cheese', 'parmesan', 'cheddar', 'mozzarella', 'feta', 'goat cheese', 'ricotta'}
    GRAINS = {'rice', 'pasta', 'noodle', 'noodles', 'spaghetti', 'quinoa', 'couscous'}
    VEG = {'broccoli', 'zucchini', 'spinach', 'kale', 'cauliflower', 'eggplant', 'pepper', 'carrot', 'tomato', 'tomatoes'}

    def cat_for_name(name: str) -> Optional[str]:
        n = (name or '').lower()
        if any(k in n for k in SEAFOOD):
            return 'seafood'
        if any(k in n for k in RED_MEAT):
            return 'red_meat'
        if any(k in n for k in PORK):
            return 'pork'
        if any(k in n for k in POULTRY):
            return 'poultry'
        if any(k in n for k in LEGUMES):
            return 'legumes'
        if any(k in n for k in TOFU):
            return 'tofu'
        if any(k in n for k in EGGS):
            return 'eggs'
        if any(k in n for k in CHEESE):
            return 'cheese'
        if any(k in n for k in GRAINS):
            return 'grains'
        if any(k in n for k in VEG):
            return 'veg'
        return None

    # Prefer ingredient scan; fall back to title
    try:
        ings = list(getattr(recipe, 'ingredients', None).all()) if getattr(recipe, 'ingredients', None) else []
    except Exception:
        ings = []

    for ing in ings:
        try:
            nm = (getattr(ing, 'usda_name', None) or getattr(ing, 'name', None) or '').strip()
        except Exception:
            nm = ''
        c = cat_for_name(nm)
        if c:
            if isinstance(rid, int):
                _RECIPE_CAT_CACHE[rid] = c
            return c

    # Fallback: title-based
    try:
        title = str(getattr(recipe, 'title', '')).lower()
    except Exception:
        title = ''
    c = cat_for_name(title)
    if c:
        if isinstance(rid, int):
            _RECIPE_CAT_CACHE[rid] = c
        return c

    if isinstance(rid, int):
        _RECIPE_CAT_CACHE[rid] = 'unknown'
    return 'unknown'


def comp_difficulty(recipe, meal_type: str, ctx: FitnessOptions) -> Optional[float]:
    if ctx.difficulty_max is None:
        return None
    val = _difficulty_to_int(recipe)
    if val is None:
        return None
    if val <= ctx.difficulty_max:
        return 1.0
    # linear penalty if over
    # e.g., diff=3, max=2 => 0.0; diff=2, max=2 => 1.0
    over = max(0, val - ctx.difficulty_max)
    return max(0.0, 1.0 - 0.5 * over)


def comp_goals(recipe, meal_type: str, ctx: FitnessOptions) -> Optional[float]:
    if not ctx.goals:
        return None
    try:
        tags = {str(t).lower() for t in (getattr(recipe, 'tags', []) or [])}
        g = {str(x).lower() for x in ctx.goals}
        if not g:
            return None
        match = len(tags & g)
        return min(1.0, match / max(1, len(g)))
    except Exception:
        return None


def comp_saved(recipe, meal_type: str, ctx: FitnessOptions) -> float:
    if not ctx.focus_on_saved or not ctx.saved_set:
        return 0.0
    try:
        rid = int(getattr(recipe, 'id', -1))
        return 1.0 if rid in ctx.saved_set else 0.0
    except Exception:
        return 0.0


def _slot_score(recipe, meal_type: str, ctx: FitnessOptions) -> float:
    # Chain components and aggregate with weights
    components: Dict[str, Callable] = {
        'nutrition': comp_nutrition,
        'time': comp_time,
        'cost': comp_cost,
        'difficulty': comp_difficulty,
        'goals': comp_goals,
        'saved': comp_saved,
    'meal_type': comp_meal_type,
    }
    total = 0.0
    wsum = 0.0
    for name, fn in components.items():
        w = float(ctx.weights.get(name, 0.0))
        # Allow UI to scale saved preference without changing other weights
        if name == 'saved' and ctx.saved_weight is not None:
            # Scale within a reasonable band 0..0.2
            w = max(0.0, min(0.2, ctx.saved_weight * 0.2))
        if w <= 0:
            continue
        try:
            val = fn(recipe, meal_type, ctx)
        except Exception:
            val = None
        if val is None:
            continue
        # Ensure 0..1
        val = max(0.0, min(1.0, float(val)))
        total += w * val
        wsum += w
    return (total / wsum) if wsum > 0 else 0.0


def _initial_population(slots: List[Slot], pop_size: int) -> List[List[int]]:
    pop: List[List[int]] = []
    for _ in range(pop_size):
        chrom = []
        for s in slots:
            if not s.candidates:
                chrom.append(-1)
            else:
                chrom.append(random.randrange(0, len(s.candidates)))
        pop.append(chrom)
    return pop


def _fitness(chrom: List[int], slots: List[Slot], ctx: FitnessOptions) -> float:
    total = 0.0
    filled = 0
    used_ids = set()
    duplicate_penalty = 0.0
    # Track variety by primary protein category
    by_day_counts: Dict[int, Dict[str, int]] = {}
    weekly_counts: Dict[str, int] = {}
    for gene, s in zip(chrom, slots):
        if gene is None or gene < 0 or gene >= len(s.candidates):
            continue
        r = s.candidates[gene]
        rid = getattr(r, 'id', None)
        if rid in used_ids:
            # Allow UI to relax or strengthen repeat penalty
            rp = 0.0 if ctx.repeat_preference is None else float(ctx.repeat_preference)
            rp = max(0.0, min(1.0, rp))
            # When rp=0 (no repeats) penalty is 1.0; when rp=1 penalty ~0
            penalty = 1.0 * (1.0 - rp)
            duplicate_penalty += penalty
        else:
            used_ids.add(rid)
        # Variety tracking
        cat = _primary_protein_category(r)
        day_map = by_day_counts.setdefault(int(getattr(s, 'day', 0)), {})
        day_map[cat] = day_map.get(cat, 0) + 1
        weekly_counts[cat] = weekly_counts.get(cat, 0) + 1
        total += _slot_score(r, s.meal_type, ctx)
        filled += 1
    if filled == 0:
        return 0.0
    base = total / filled
    # Apply variety penalties (modest, tunable)
    vs = max(0.0, min(1.0, getattr(ctx, 'variety_strength', 0.5)))
    day_allow = max(0, int(getattr(ctx, 'same_day_category_allowance', 1)))
    week_soft = max(0, int(getattr(ctx, 'weekly_category_soft_limit', 5)))

    day_over = 0
    for day, counts in by_day_counts.items():
        for c, n in counts.items():
            if c == 'unknown':
                continue
            if n > day_allow:
                day_over += (n - day_allow)
    # Each overage reduces score slightly
    day_var_penalty = 0.2 * vs * day_over

    week_over = 0
    for c, n in weekly_counts.items():
        if c == 'unknown':
            continue
        if n > week_soft:
            week_over += (n - week_soft)
    week_var_penalty = 0.1 * vs * week_over

    return max(0.0, base - duplicate_penalty - day_var_penalty - week_var_penalty)


def _tournament(pop, fits, k=3):
    best = None
    for _ in range(k):
        i = random.randrange(0, len(pop))
        if best is None or fits[i] > fits[best]:
            best = i
    return pop[best][:]


def _crossover(a: List[int], b: List[int]) -> Tuple[List[int], List[int]]:
    if len(a) != len(b) or len(a) == 0:
        return a[:], b[:]
    child1, child2 = a[:], b[:]
    for i in range(len(a)):
        if random.random() < 0.5:
            child1[i], child2[i] = child2[i], child1[i]
    return child1, child2


def _mutate(chrom: List[int], slots: List[Slot], rate: float) -> None:
    for i, s in enumerate(slots):
        if random.random() < rate:
            if not s.candidates:
                chrom[i] = -1
                continue
            # pick a different candidate if possible
            cur = chrom[i]
            if len(s.candidates) > 1:
                j = random.randrange(0, len(s.candidates) - 1)
                if j >= cur:
                    j += 1
                chrom[i] = j
            else:
                chrom[i] = 0


def _repair(chrom: List[int], slots: List[Slot]) -> None:
    seen = {}
    for i, s in enumerate(slots):
        gene = chrom[i]
        if gene is None or gene < 0 or gene >= len(s.candidates):
            continue
        rid = getattr(s.candidates[gene], 'id', None)
        if rid is None:
            continue
        if rid in seen:
            # try to find alternative
            for alt in range(len(s.candidates)):
                if alt == gene:
                    continue
                alt_id = getattr(s.candidates[alt], 'id', None)
                if alt_id not in seen:
                    chrom[i] = alt
                    seen[alt_id] = True
                    break
        else:
            seen[rid] = True


def evolve_plan(slots: List[Slot], servings: int, saved_set: Optional[set], focus_on_saved: bool,
                targets: Optional[Dict[str, Dict[str, float]]] = None,
                params: Optional[GAParams] = None,
                fitness_options: Optional[FitnessOptions] = None) -> GAResult:
    """
    Run GA to choose one candidate per slot. Returns GAResult with meals and quality metadata.
    """
    if params is None:
        params = GAParams()
    if fitness_options is None:
        # Build default fitness context (backward compatible defaults)
        fitness_options = FitnessOptions(
            targets=targets or DEFAULT_TARGETS,
            servings=servings,
            focus_on_saved=focus_on_saved,
            saved_set=saved_set,
        )

    # Trim candidate lists to top-N per slot to bound runtime
    trimmed: List[Slot] = []
    total_slots = len(slots)
    empty_slots = []
    
    for s in slots:
        cands = s.candidates[: params.top_n_per_slot] if s.candidates else []
        if not cands:
            empty_slots.append((s.day, s.meal_type))
        trimmed.append(Slot(day=s.day, meal_type=s.meal_type, candidates=cands))

    if not trimmed or all(not s.candidates for s in trimmed):
        warnings = ["No suitable recipes found for any meal slots"]
        if empty_slots:
            warnings.append(f"Empty slots: {', '.join([f'{mt} on day {d+1}' for d, mt in empty_slots])}")
        return GAResult(meals=[], fitness_score=0.0, total_slots=total_slots, 
                       filled_slots=0, low_quality_slots=[], warnings=warnings)

    pop = _initial_population(trimmed, params.pop_size)
    best = None
    best_fit = -1.0

    for gen in range(params.generations):
        fits = [_fitness(ch, trimmed, fitness_options) for ch in pop]

        # Track best
        for ch, f in zip(pop, fits):
            if f > best_fit:
                best, best_fit = ch[:], f

        # Build next population
        next_pop: List[List[int]] = []
        # Elitism
        elite_indices = sorted(range(len(pop)), key=lambda i: fits[i], reverse=True)[: params.elite]
        for i in elite_indices:
            next_pop.append(pop[i][:])

        # Fill rest
        while len(next_pop) < params.pop_size:
            p1 = _tournament(pop, fits)
            p2 = _tournament(pop, fits)
            if random.random() < params.crossover_rate:
                c1, c2 = _crossover(p1, p2)
            else:
                c1, c2 = p1, p2
            _mutate(c1, trimmed, params.mutation_rate)
            _mutate(c2, trimmed, params.mutation_rate)
            _repair(c1, trimmed)
            _repair(c2, trimmed)
            next_pop.append(c1)
            if len(next_pop) < params.pop_size:
                next_pop.append(c2)
        pop = next_pop

    # Decode best and analyze quality
    result_meals: List[Tuple[int, str, object]] = []
    low_quality_slots: List[Tuple[int, str, float]] = []
    warnings: List[str] = []
    
    if not best:
        warnings.append("GA failed to find any valid solution")
        return GAResult(meals=[], fitness_score=0.0, total_slots=total_slots,
                       filled_slots=0, low_quality_slots=[], warnings=warnings)
    
    fitness_threshold = 0.3  # Consider slots with fitness < 0.3 as "low quality"
    
    for gene, s in zip(best, trimmed):
        if gene is None or gene < 0 or gene >= len(s.candidates):
            continue
            
        recipe = s.candidates[gene]
        slot_fitness = _slot_score(recipe, s.meal_type, fitness_options)
        
        result_meals.append((s.day, s.meal_type, recipe))
        
        if slot_fitness < fitness_threshold:
            low_quality_slots.append((s.day, s.meal_type, slot_fitness))
    
    # Generate warnings based on results
    if empty_slots:
        warnings.append(f"Could not fill {len(empty_slots)} meal slots")
    
    if low_quality_slots:
        warnings.append(f"Found {len(low_quality_slots)} recipes that may not match your preferences well")
    
    # Check for specific constraint violations
    total_available_slots = len([s for s in trimmed if s.candidates])
    fill_rate = len(result_meals) / max(1, total_available_slots)
    
    if fill_rate < 0.5:
        warnings.append("Very few suitable recipes found - consider relaxing dietary restrictions")
    elif fill_rate < 0.8:
        warnings.append("Limited recipe options found - some preferences may not be fully satisfied")

    # Variety diagnostics
    try:
        # compute categories across the selection
        per_day: Dict[int, Dict[str, int]] = {}
        weekly: Dict[str, int] = {}
        for day, mt, rec in result_meals:
            c = _primary_protein_category(rec)
            per_day.setdefault(day, {})[c] = per_day.get(day, {}).get(c, 0) + 1
            weekly[c] = weekly.get(c, 0) + 1
        day_allow = fitness_options.same_day_category_allowance
        over_days = sum(
            sum(max(0, n - day_allow) for cat, n in counts.items() if cat != 'unknown')
            for counts in per_day.values()
        )
        week_soft = fitness_options.weekly_category_soft_limit
        over_week = sum(max(0, n - week_soft) for cat, n in weekly.items() if cat != 'unknown')
        if over_days > 0:
            warnings.append("Some days repeat similar mains; consider increasing variety settings")
        if over_week > 0:
            warnings.append("Weekly plan repeats a main category often; consider broadening preferences")
    except Exception:
        pass
    
    return GAResult(
        meals=result_meals,
        fitness_score=best_fit,
        total_slots=total_slots,
        filled_slots=len(result_meals),
        low_quality_slots=low_quality_slots,
        warnings=warnings
    )
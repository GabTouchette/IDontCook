"""Grocery-bag ingredient aggregation.

Turns a set of (recipe, servings) pairs into one shoppable line per canonical
ingredient concept — combined in that ingredient's *natural* purchase dimension
(mass / volume / count), with recipe provenance carried through.

This is the ``MealPlan``-free successor to ``meal_planning.grocery_builder``.
See docs/plans/grocery-bag-implementation.md §3 for the design and the
``ShoppableLine`` output contract (§3.3), which Layer 3 (online ordering)
consumes and must stay stable.

Key differences from the legacy builder:
  * one row per canonical concept, not per (concept, unit);
  * quantities combine in the concept's natural dimension rather than being
    force-converted to grams — ``density_g_per_ml`` / ``portions`` are used only
    as optional bridges to fold a stray mismatched line into the chosen
    dimension (plus an ``approx_g`` hint);
  * provenance (which recipe(s) a line came from) is preserved;
  * resolution confidence drives a ``needs_confirmation`` flag.

Name/category/portions/density all come from the resolved ``CanonicalIngredient``
(the sole anchor); unresolved lines fall back to the name normalizer. The
nutrition tables are deliberately not consulted here.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict, List, Optional, Tuple

from recipes.ingredient_normalizer import normalize_name_and_prep

from .units import normalize_unit, round_qty

# Lines whose canonical match is weaker than this get flagged for the in-app
# confirm step (§5.3). Unresolved lines (no canonical at all) are always flagged.
NEEDS_CONFIRMATION_THRESHOLD = 0.6

# Default physical dimension a concept is combined/sold in, by 2-letter category
# code (see CanonicalIngredient.category). Per-name exceptions live in
# _DIMENSION_OVERRIDES. Seed values — curate over time (§9).
_DIMENSION_BY_CATEGORY = {
    "PR": "count",   # Produce — mostly sold by unit (lemon, pepper, garlic)
    "MS": "mass",    # Meat & Seafood
    "DE": "mass",    # Dairy & Eggs — eggs/milk overridden below
    "BA": "count",   # Bakery — loaf / each
    "CJ": "count",   # Canned & Jars — cans
    "DG": "mass",    # Dry Goods & Pasta
    "BK": "mass",    # Baking — flour / sugar
    "SP": "mass",    # Spices
    "CO": "volume",  # Condiments & Oils
    "FR": "mass",    # Frozen
    "BE": "volume",  # Beverages
    "HO": "count",   # Household / Other
}
_DEFAULT_DIMENSION = "count"

# Per-canonical-name overrides where the category default is wrong. Keyed by
# lowercased canonical_name_en (and its singular form). Seed set; curate (§9).
_DIMENSION_OVERRIDES = {
    # Produce sold by weight
    "spinach": "mass", "mushroom": "mass", "grape": "mass",
    "green bean": "mass", "kale": "mass", "arugula": "mass",
    # Dairy & Eggs exceptions
    "egg": "count",
    "milk": "volume", "cream": "volume", "heavy cream": "volume",
    "buttermilk": "volume", "half and half": "volume",
    # Baking liquids
    "vanilla extract": "volume",
}


def purchase_dimension(name: str, category: Optional[str]) -> str:
    """Pick the dimension (mass/volume/count) a concept is combined in."""
    key = (name or "").strip().lower()
    if key in _DIMENSION_OVERRIDES:
        return _DIMENSION_OVERRIDES[key]
    # also try the normalizer's singular/synonym form
    norm, _ = normalize_name_and_prep(key)
    if norm in _DIMENSION_OVERRIDES:
        return _DIMENSION_OVERRIDES[norm]
    if category and category in _DIMENSION_BY_CATEGORY:
        return _DIMENSION_BY_CATEGORY[category]
    return _DEFAULT_DIMENSION


# --------------------------------------------------------------------------
# Output contract (docs/plans/grocery-bag-implementation.md §3.3)
# --------------------------------------------------------------------------
@dataclass
class Component:
    """A residual quantity that couldn't fold into the primary ``amount``."""
    quantity: Optional[float]
    unit: str

    def to_dict(self) -> dict:
        return {"quantity": self.quantity, "unit": self.unit}


@dataclass
class Source:
    """Provenance: a recipe's (scaled) contribution to a line."""
    recipe_id: int
    title: str
    quantity: Optional[float]
    unit: str

    def to_dict(self) -> dict:
        return {
            "recipe_id": self.recipe_id,
            "title": self.title,
            "quantity": self.quantity,
            "unit": self.unit,
        }


@dataclass
class Amount:
    """The combined quantity in the concept's natural unit."""
    value: Optional[float]
    unit: str
    dimension: str  # "mass" | "volume" | "count"

    def to_dict(self) -> dict:
        return {"value": self.value, "unit": self.unit, "dimension": self.dimension}


@dataclass
class ShoppableLine:
    concept_id: Optional[int]
    name: str
    category: Optional[str]
    amount: Amount
    approx_g: Optional[float]
    components: List[Component]
    sources: List[Source]
    match_confidence: Optional[float]
    needs_confirmation: bool
    variants: List[str]
    # Populated by Part C (grocery/sorting.py); left None by the aggregator.
    staple_score: Optional[float] = None

    @property
    def key(self) -> str:
        """Stable identity for overrides/pantry: ``ci:<id>`` or ``name:<norm>``.

        A single non-null string so uniqueness constraints behave (Postgres
        treats NULLs as distinct, which would break a nullable composite key).
        """
        if self.concept_id is not None:
            return f"ci:{self.concept_id}"
        return f"name:{self.name}"

    def to_dict(self) -> dict:
        return {
            "key": self.key,
            "concept_id": self.concept_id,
            "name": self.name,
            "category": self.category,
            "amount": self.amount.to_dict(),
            "approx_g": self.approx_g,
            "components": [c.to_dict() for c in self.components],
            "sources": [s.to_dict() for s in self.sources],
            "staple_score": self.staple_score,
            "match_confidence": self.match_confidence,
            "needs_confirmation": self.needs_confirmation,
            "variants": self.variants,
        }


# --------------------------------------------------------------------------
# Internals
# --------------------------------------------------------------------------
@dataclass
class _LineRecord:
    """One recipe ingredient line, normalized for aggregation."""
    unit_class: str          # mass | volume | count
    label: str               # g | ml | <count unit>
    qty: Optional[float]     # scaled quantity in `label` units
    grams: Optional[float]   # scaled grams if convertible, else None
    ml: Optional[float]      # scaled ml if convertible, else None

    @property
    def has_qty(self) -> bool:
        return self.qty is not None


@dataclass
class _Group:
    name: str
    category: Optional[str]
    concept_id: Optional[int]
    portions: Dict[str, float]
    density: Optional[float]
    records: List[_LineRecord] = field(default_factory=list)
    sources: List[Source] = field(default_factory=list)
    confidences: List[float] = field(default_factory=list)
    variants: set = field(default_factory=set)


def _scale(recipe, servings) -> float:
    """servings-selected / recipe-base scaling factor (mirrors legacy builder)."""
    try:
        pm = int(servings or 1)
    except (TypeError, ValueError):
        pm = 1
    try:
        base = int(getattr(recipe, "servings", 0) or 0)
    except (TypeError, ValueError):
        base = 0
    if base <= 0:
        base = 1  # assume quantities are for 1 serving when unknown
    return max(1, pm) / float(base)


def _sum_opt(vals: List[Optional[float]]) -> Optional[float]:
    present = [v for v in vals if v is not None]
    return sum(present) if present else None


def _to_grams_ml(
    unit_class: str,
    label: str,
    factor: float,
    qty: Optional[float],
    portions: Dict[str, float],
    density: Optional[float],
) -> Tuple[Optional[float], Optional[float]]:
    """Best-effort conversion of a scaled line to (grams, ml)."""
    if qty is None:
        return None, None
    if unit_class == "mass":
        grams = qty * factor
        ml = grams / density if density else None
        return grams, ml
    if unit_class == "volume":
        ml = qty * factor
        grams = ml * density if density else None
        return grams, ml
    # count — needs a portion weight for this specific unit label
    per = portions.get(label)
    if per:
        grams = qty * per
        ml = grams / density if density else None
        return grams, ml
    return None, None


def _add_line(groups: Dict[Tuple[str, object], _Group], recipe, ing, scale: float) -> None:
    raw_name = (getattr(ing, "name", None) or "").strip()
    canonical = getattr(ing, "canonical", None)

    if canonical is not None:
        name = canonical.canonical_name_en or normalize_name_and_prep(raw_name)[0]
        identity: Tuple[str, object] = ("ci", canonical.id)
        category = canonical.category
        portions = canonical.portions or {}
        density = canonical.density_g_per_ml
        concept_id = canonical.id
        conf = getattr(ing, "canonical_confidence", None)
    else:
        name, _ = normalize_name_and_prep(raw_name)
        if not name:
            name = raw_name.lower()
        identity = ("name", name)
        category = None
        portions = {}
        density = None
        concept_id = None
        conf = None

    group = groups.get(identity)
    if group is None:
        group = _Group(
            name=name, category=category, concept_id=concept_id,
            portions=portions, density=density,
        )
        groups[identity] = group

    qty_raw = getattr(ing, "quantity", None)
    try:
        qty_val = float(qty_raw) if qty_raw is not None else None
    except (TypeError, ValueError):
        qty_val = None
    qty_scaled = qty_val * scale if qty_val is not None else None

    unit_class, label, factor = normalize_unit(getattr(ing, "unit", None))
    grams, ml = _to_grams_ml(unit_class, label, factor, qty_scaled, group.portions, group.density)
    group.records.append(_LineRecord(unit_class, label, qty_scaled, grams, ml))

    if raw_name:
        group.variants.add(raw_name.lower())
    group.sources.append(Source(
        recipe_id=getattr(recipe, "id", None),
        title=getattr(recipe, "title", None) or "",
        quantity=round_qty(qty_scaled) if qty_scaled is not None else None,
        unit=label,
    ))
    if conf is not None:
        group.confidences.append(conf)


def _finalize(group: _Group) -> ShoppableLine:
    dimension = purchase_dimension(group.name, group.category)
    records = group.records
    components: List[Component] = []

    approx_g = _sum_opt([r.grams for r in records])
    approx_g = round_qty(approx_g) if approx_g is not None else None

    if dimension == "mass":
        total = _sum_opt([r.grams for r in records])
        for r in records:
            if r.has_qty and r.grams is None:
                components.append(Component(round_qty(r.qty), r.label))
        amount = Amount(round_qty(total) if total is not None else None, "g", "mass")

    elif dimension == "volume":
        total = _sum_opt([r.ml for r in records])
        for r in records:
            if r.has_qty and r.ml is None:
                components.append(Component(round_qty(r.qty), r.label))
        amount = Amount(round_qty(total) if total is not None else None, "ml", "volume")

    else:  # count
        amount, extra = _finalize_count(group, records)
        components.extend(extra)

    confs = group.confidences
    if group.concept_id is None:
        match_conf: Optional[float] = None
        needs = True
    else:
        match_conf = min(confs) if confs else None
        needs = match_conf is not None and match_conf < NEEDS_CONFIRMATION_THRESHOLD

    return ShoppableLine(
        concept_id=group.concept_id,
        name=group.name,
        category=group.category,
        amount=amount,
        approx_g=approx_g,
        components=components,
        sources=group.sources,
        match_confidence=match_conf,
        needs_confirmation=needs,
        variants=sorted(group.variants),
    )


def _finalize_count(group: _Group, records: List[_LineRecord]) -> Tuple[Amount, List[Component]]:
    components: List[Component] = []

    # Sum native count lines per unit label.
    count_by_label: Dict[str, float] = {}
    for r in records:
        if r.unit_class == "count" and r.has_qty:
            count_by_label[r.label] = count_by_label.get(r.label, 0.0) + r.qty

    # Primary = the count unit with the largest total (ties broken alphabetically).
    primary = None
    if count_by_label:
        primary = sorted(count_by_label.items(), key=lambda kv: (-kv[1], kv[0]))[0][0]

    # Bridge mass/volume lines into the primary count unit via portions, else residual.
    for r in records:
        if r.unit_class in ("mass", "volume") and r.has_qty:
            per = group.portions.get(primary) if primary else None
            if primary and r.grams is not None and per:
                count_by_label[primary] = count_by_label.get(primary, 0.0) + r.grams / per
            else:
                components.append(Component(round_qty(r.qty), r.label))

    if primary is not None:
        value = round_qty(count_by_label.pop(primary))
        amount = Amount(value, primary, "count")
        for lbl, v in sorted(count_by_label.items()):
            components.append(Component(round_qty(v), lbl))
        return amount, components

    # No usable count unit at all. Degrade to grams if we have any, else an
    # empty count amount (concept still appears, quantity unknown).
    total_g = _sum_opt([r.grams for r in records])
    if total_g is not None:
        return Amount(round_qty(total_g), "g", "mass"), components
    first_label = records[0].label if records else "unit"
    return Amount(None, first_label, "count"), components


def aggregate_ingredients(recipe_servings: List[Tuple[object, int]]) -> List[ShoppableLine]:
    """Aggregate ingredients across (recipe, servings) pairs into shoppable lines.

    Caller is responsible for prefetching ``recipe.ingredients`` and each
    ingredient's ``canonical`` to avoid N+1 queries.

    Returns one :class:`ShoppableLine` per canonical concept (unresolved lines
    group by normalized name), sorted by name for a stable order. Staple
    ordering is applied later by Part C.
    """
    groups: Dict[Tuple[str, object], _Group] = {}
    for recipe, servings in recipe_servings:
        if not recipe:
            continue
        scale = _scale(recipe, servings)
        for ing in recipe.ingredients.all():
            _add_line(groups, recipe, ing, scale)

    lines = [_finalize(g) for g in groups.values()]
    lines.sort(key=lambda line: (line.name or "", line.amount.unit or ""))
    return lines

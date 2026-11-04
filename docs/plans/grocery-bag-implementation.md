# Grocery Bag — Implementation Plan (In-App Layers)

**Status:** Draft for review — 2026-11-04
**Scope of this doc:** The in-app layers only (Layer 1 Grocery Bag + Layer 2 sort/pantry).
The online-ordering handoff (Layer 3) is being spiked separately; this doc defines the
**output contract** Layer 3 consumes so the two efforts stay decoupled.

---

## 1. User story (locked)

> The app has a **Grocery Bag**. We queue recipes into it and their ingredients get added to
> a list, each showing which recipe(s) it belongs to. Ingredients are sorted by how likely I am
> to **not** already have them (unusual items at top, staples at bottom). I can easily remove an
> entire recipe or individual ingredients. When I tap **Order**, I see my list on the real grocery
> site to verify, then place the order myself. Goal: the on-site list is as close to perfect as possible.

**Non-goals (this phase):** price comparison, price matching, automated checkout, meal-planner
integration. The Grocery Bag ships as its own surface, independent of `meal_planning`.

---

## 2. What we reuse vs. build

| Need | Already exists | Gap |
|---|---|---|
| Ingredient → canonical concept resolution | `Ingredient.canonical` FK + `canonical_confidence` | — |
| Name/prep/synonym normalization | `recipes.ingredient_normalizer` | — |
| Unit → g/ml normalization | `meal_planning.grocery_builder._normalize_unit` | needs extraction to a neutral module |
| Qty aggregation across recipes | `grocery_builder.build_grocery_list` | keyed by `(concept,unit)`, loses recipe provenance, tied to `MealPlan` |
| Gram reconciliation of mixed units | `CanonicalIngredient.portions` + `density_g_per_ml` | not yet used by the builder |
| Staple sorting | `CanonicalIngredient.category` (12-code taxonomy) | no code→score map, no pantry model |
| Grocery Bag persistence | — | new `grocery` app |

---

## 3. Part A — Ingredient aggregation core (the "optimal ingredients logic")

Extract a pure, `MealPlan`-free aggregator. This is the shared heart both the Bag and (eventually)
any other surface call. New module: `api/grocery/aggregator.py`.

### 3.1 Signature

```python
def aggregate_ingredients(
    recipe_servings: list[tuple[Recipe, int]],
) -> list[ShoppableLine]
```

Input is explicit `(recipe, servings)` pairs — **not** a `MealPlan`. The legacy meal-plan path can
later call this same function; we don't touch it now.

### 3.2 Three upgrades over `build_grocery_list`

1. **One row per concept, not per `(concept, unit)`.**
   Group solely by canonical identity (`("ci", canonical_id)`, falling back to `("name", name)`).
   A shopper buys *one* garlic, regardless of whether recipes asked for grams, cloves, and "to taste."

2. **Aggregate in the ingredient's natural shopping dimension — NOT universally grams.**
   Grocery sites sell garlic by the bulb, eggs by the dozen, lemons each; forcing those to grams and
   back is a lossy round-trip that needs a grams-per-unit constant anyway. Each canonical concept has
   a **purchase dimension** — `mass` (flour, meat, cheese), `volume` (milk, oil, broth), or `count`
   (garlic→clove/bulb, eggs, lemons, cans). Sum contributing lines **within that dimension**, in its
   native unit (garlic stays in cloves, milk in ml, flour in g).
   - `density_g_per_ml` and `portions` are **not** the output anymore — they demote to optional
     *bridges*, used only to fold a stray mismatched line into the chosen dimension (e.g. one recipe
     gives garlic in grams while the rest are cloves — the "sometimes useful" case), plus an optional
     approx-weight hint (`approx_g`) for count items when `portions` allow.
   - Lines that still can't fold in (no bridge, or `canonical is None`) are kept as **residual
     components** in their native unit — never silently dropped.
   - **Pack conversion** (5 cloves → "1 bulb", 270g flour → "1× 2kg bag") stays in **Layer 3** — the
     aggregator stops at the recipe-native combined amount.

   Dimension is chosen from a **category default + a small curated override map** (produce is mixed:
   lemons=count, spinach=mass). Code-level map now; a nullable `purchase_unit` column on
   `CanonicalIngredient` later — same pattern as staple scores (§5).

3. **Carry provenance + ranking signals** (see schema).

### 3.3 Output contract — `ShoppableLine` (this is Layer 3's input, keep stable)

```jsonc
{
  "concept_id": 1234,              // canonical id, or null when unresolved
  "name": "garlic",               // canonical_name_en (localized later)
  "category": "PR",               // 2-letter code, null if unknown
  "amount": {                     // combined quantity in the ingredient's NATURAL unit
    "value": 7.0,
    "unit": "clove",
    "dimension": "count"          // "mass" | "volume" | "count"
  },
  "approx_g": 21.0,               // optional weight hint (count items w/ portions); may be null
  "components": [                  // residuals that couldn't fold into `amount`
    {"quantity": 1.0, "unit": "tbsp"}
  ],
  "sources": [                    // provenance — drives "which recipe(s)"
    {"recipe_id": 7, "title": "Butter Chicken", "quantity": 4, "unit": "clove"},
    {"recipe_id": 9, "title": "Aglio e Olio",  "quantity": 3, "unit": "clove"}
  ],
  "staple_score": 0.05,           // 0 = surely need to buy (top) … 1 = surely have (bottom)
  "match_confidence": 0.4,        // min canonical_confidence across sources
  "needs_confirmation": true,     // canonical null OR confidence < threshold → in-app confirm step
  "variants": ["garlic cloves", "fresh garlic"]
}
```

Layer 3 reads `amount` (+ `approx_g` as a fallback) to pick a SKU and pack count — it never needs
a universal gram total.

### 3.4 Extraction note
Move `_normalize_unit`, `_MASS_TO_G`, `_VOLUME_TO_ML`, `_COUNT_UNITS` into
`api/grocery/units.py` (neutral). `grocery_builder.py` re-imports from there so nothing breaks.

---

## 4. Part B — Layer 1: Grocery Bag (backend)

New Django app `grocery`. Bag membership and per-item overrides persist server-side; the aggregated
+ sorted list is computed on read (the aggregator is cheap and always reflects current recipes).

### 4.1 Models

```python
class GroceryBag(models.Model):          # one active bag per user (MVP)
    user = OneToOne(CustomUser)
    created_at, updated_at

class GroceryBagRecipe(models.Model):    # a queued recipe
    bag = FK(GroceryBag, related_name="recipes")
    recipe = FK(Recipe)
    servings = IntegerField()            # defaults to recipe.servings
    added_at
    # unique_together = (bag, recipe)

class GroceryItemOverride(models.Model): # per-concept user action on the computed list
    bag = FK(GroceryBag, related_name="overrides")
    concept_id = IntegerField(null=True) # canonical id
    name_key = CharField(null=True)      # fallback identity for unresolved lines
    state = CharField(choices=["removed", "checked"])  # removed = hide from this bag
    # unique_together = (bag, concept_id, name_key)
```

Removing a *recipe* = delete the `GroceryBagRecipe` + re-aggregate. Removing an *ingredient* =
upsert a `removed` override (survives re-aggregation; cleared if user re-adds). "Checked" is for
the review/shopping UI.

### 4.2 Endpoints (`/api/grocery/`)

| Method | Path | Purpose |
|---|---|---|
| GET | `bag/` | Full bag: recipes + aggregated, sorted, override-applied `ShoppableLine[]` |
| POST | `bag/recipes/` | Add a recipe `{recipe_id, servings?}` |
| PATCH | `bag/recipes/{id}/` | Change servings |
| DELETE | `bag/recipes/{id}/` | Remove a recipe |
| POST | `bag/items/` | Upsert override `{key, state}` where `key` is the line's stable key (`ci:<id>`/`name:<norm>`, echoed in each item); `state` null clears it |
| POST | `bag/resolve/` | Confirm step: link an unresolved line to a canonical `{name_key, concept_id}` (see §5.3) |
| GET | `bag/resolve/search/` | Canonical-ingredient search for the confirm picker `?q=` |
| DELETE | `bag/` | Empty the bag |

`GET bag/` prefetches `recipe__ingredients__canonical` to avoid N+1. Note it does **not** prefetch
`nutrition_data`: unlike the legacy `build_grocery_list`, the aggregator takes name/category/portions
from `canonical` and falls back to `normalize_name_and_prep(raw_name)` when unresolved — it never
reads a nutrition name field. (Consistent with the recent cleanup that dropped the redundant
`Ingredient.usda_name` / `Ingredient.normalized_name` columns; `canonical` is the sole anchor.)

---

## 5. Part C — Layer 2: Sort & pantry

### 5.1 Static staple prior by category

`staple_score` = P(user already has it). Sort **ascending** → least-likely-to-have on top.

| Code | Category | Score | Rationale |
|---|---|---|---|
| PR | Produce | 0.05 | perishable, buy per trip |
| MS | Meat & Seafood | 0.05 | perishable |
| BA | Bakery | 0.15 | perishable-ish |
| DE | Dairy & Eggs | 0.20 | restock often |
| FR | Frozen | 0.40 | sometimes stocked |
| BE | Beverages | 0.45 | mixed |
| CJ | Canned & Jars | 0.60 | shelf-stable |
| DG | Dry Goods & Pasta | 0.70 | pantry staple |
| BK | Baking | 0.80 | flour/sugar kept |
| CO | Condiments & Oils | 0.90 | almost always on hand |
| SP | Spices | 0.95 | almost always on hand |
| HO | Household/Other | 0.50 | unknown |

Lives as a constant map in `grocery/sorting.py`; unknown/`null` category → 0.5. Tune later.

**Sort behavior (decided):** a single continuous list sorted ascending by effective score — **no
collapsed "staples" section**. Staples just sink to the bottom.

**Always-hidden set (decided):** a tiny hardcoded "assumed on hand" list — `salt`, `pepper`,
`water` (matched by canonical concept) — is dropped from the list entirely, with a muted
"N items hidden · show" affordance to reveal/restore. This is deliberately minimal; everything else
stays visible and merely sorts low. Keep this list short — it's "obvious to everyone," distinct from
the per-user pantry below.

### 5.2 Pantry (personalization — ships right after static)

```python
class UserPantryItem(models.Model):     # "I always have this"
    user = FK(CustomUser)
    concept_id = IntegerField(null=True)
    name_key = CharField(null=True)
    # unique_together = (user, concept_id, name_key)
```

Effective score = `1.0` if the concept is in the user's pantry → it sinks to the bottom of the single
list (no separate section). The "remove ingredient" gesture offers two choices: *remove from this
bag* (override) vs *I always have this* (pantry). Implicit learning (auto-pantry after N removals) is
a later follow-up — not MVP.

### 5.3 Confirm step for unresolved / low-confidence lines (decided)

Lines where `canonical is None` **or** `match_confidence` is below a threshold are flagged
`needs_confirmation: true`. The app surfaces these in an **in-app confirm step** before they count as
fully resolved — the user picks/links the right canonical concept (search via
`GET bag/resolve/search/`, commit via `POST bag/resolve/`). This both fixes the display amount/sort
and gives Layer 3 a resolved concept to match a SKU against — cleaning it up here is far cheaper than
discovering the mismatch during on-site review.

- Resolution is stored at the **line level** so it's reusable: writing the chosen `canonical` back
  onto the underlying `Ingredient` row (via the existing resolver fields `canonical`,
  `canonical_confidence`, `resolution_method="user"`) means every future bag benefits, not just this
  one. (Confirm-time writes to shared recipe rows should only *fill/raise confidence*, never
  overwrite a high-confidence existing match.)
- A line stays usable while unconfirmed (shown in its native units), just badged — confirmation is
  encouraged, not a hard block, except it IS required before the Order handoff for best results.

---

## 6. Part D — Flutter (app layer)

- **`GroceryBagProvider`** (Provider pattern, mirrors existing providers): holds bag state, exposes
  `addRecipe/removeRecipe/setServings/removeItem/markHave/toggleChecked`, calls `/api/grocery/*`
  via `api_helper.dart`.
- **Grocery Bag page**: a **single continuous list** sorted least-likely-to-have → staples at bottom
  (no sections). Each row shows name, combined `amount` in natural units (+ `approx_g` hint and any
  residual `components`), a recipe-provenance chip row, swipe-to-remove. A muted
  "N items hidden · show" footer reveals the always-hidden set (salt/pepper/water). Standard AppBar
  per CLAUDE.md.
- **Add-to-bag affordance** on recipe cards / recipe detail ("Add to Grocery Bag").
- **Confirm step**: lines with `needs_confirmation` get a badge + a picker sheet (search canonical,
  or "I always have this" → pantry). Encouraged inline; prompted before Order.
- **Order button**: present but wired to a stub until the Layer-3 spike lands; it will hand the
  `ShoppableLine[]` to whatever the spike settles on.

---

## 7. Part E — Seam for Layer 3 (the online-order spike)

Layer 3 consumes `ShoppableLine[]` from §3.3 and is responsible only for:
`concept + amount (+ approx_g, components)` → store SKU + pack count → cart on the real site.

To keep the spike unblocked, the contract to hold stable is **the `ShoppableLine` schema**. As long
as the spike targets that, the two tracks never collide. Pack-size mapping
(`canonical → sold-as unit + pack size`, e.g. cloves/bulb, g/bag) belongs to Layer 3 — it converts
the aggregator's native `amount` into purchasable packs. Part A's job is just to deliver a clean,
confirmed `amount` per concept in the right dimension; that's what makes Layer 3 tractable.

---

## 8. Build sequence

1. **A** ✅ *(done 2026-11-04)* — `grocery` app created; units extracted to `grocery/units.py`
   (legacy `grocery_builder` re-imports it); `grocery/aggregator.py` implements per-dimension
   aggregation + purchase-dimension map + bridges + provenance + `needs_confirmation`. 18 unit tests
   in `grocery/tests.py` cover (a)–(d); legacy `build_grocery_list` tests still green.
2. **B** ✅ *(done 2026-11-04)* — models (`GroceryBag`, `GroceryBagRecipe`, `GroceryItemOverride`)
   + migration `0001_initial`; APIView endpoints under `/api/grocery/` (bag GET/DELETE, recipes
   POST/PATCH/DELETE, items POST); serializers; admin. Overrides key off the aggregator's stable
   line `key` (`ci:<id>`/`name:<norm>`) to sidestep the nullable-composite-unique gotcha. 10 endpoint
   tests. **Deploy note:** run `migrate grocery` in each environment.
3. **C1** — static category staple map + sort + always-hidden set in `GET bag/`.
4. **D1** ✅ *(done 2026-11-04)* — Flutter: `models/grocery/grocery_models.dart`,
   `api/grocery_api.dart`, `providers/grocery_bag_provider.dart` (registered in `main.dart`),
   `pages/grocery_bag_page.dart` + `/grocery-bag` route. Entry points: reusable
   `widgets/appbar/grocery_bag_button.dart` placed in the AppBar `actions` (top-right, left of the
   profile) on all 6 main screens — home, explore, recipes, social, chat, meal-plan; plus an
   "add to grocery bag" button on recipe detail. Stub Order button toasts "coming soon".
   `flutter analyze` clean (only pre-existing `withOpacity` infos). Built against the current
   backend (name-sorted list; staple sort C1 still pending).
5. **D2 / 5.3** — confirm step: `resolve` endpoints + picker sheet.
6. **C2** — pantry model + "I always have this" gesture.
7. (parallel, separate) **Layer 3** spike against the `ShoppableLine` contract.

Steps 1–5 deliver a fully usable Grocery Bag with zero grocery-site integration.

---

## 9. Decisions & remaining questions

**Decided (2026-11-04):**
- **One active bag per user** (`OneToOne`).
- **No universal gram reconciliation** — aggregate per ingredient's natural purchase dimension (§3.2).
- Staples **sorted to the bottom**, not hidden; only an obvious set (salt/pepper/water) is hidden with
  a reveal affordance (§5.1).
- Unresolved / low-confidence lines get an **in-app confirm step** (§5.3).

**Still open:**
- Localization: `name` from `canonical_name_en` now; wire `_fr` via request locale later?
- Purchase-dimension override map — seed list of count-vs-mass produce exceptions to curate (garlic,
  lemon, onion, pepper… = count; spinach, grapes… = mass).
- Confirm-step threshold value for `needs_confirmation` (what `match_confidence` counts as "low").

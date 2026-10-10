# Recommendation Algorithm v2 — Variety + Multi-Interest

**Status:** Design draft — for human review, not started. No code changed yet.
**Scope chosen:** Direction **A (variety & diversity)** + **B (multi-interest profile)**, with the signal model centered on the **explore page** interactions the user actually produces: **clicks (opens), downvotes, likes, saves** (plus the existing upvote/comment/created).
**Problem:** "I always get recommended the same things." This is structural, not a bug — see §0.

Builds on `recommendations/api.py`. All changes are additive to the existing `get_similar_recipes` contract (same return type: ranked list of recipe ids); callers (`recipes/views.py` explore, `home/collectors.py` cook-again rail) need no signature change.

---

## 0. Why it repeats today (audit, verified against code)

The personalized score is **only**:

```
score(recipe) = cosine_similarity(user_taste_vector, recipe_text_vector) × image_multiplier
```

| Factor | Where | Effect on repetition |
|---|---|---|
| **One averaged taste vector** | `build_user_profile` (`recommendations/api.py:181`) | All your tastes collapse into a single centroid → you only ever get recipes near that blurry middle. **Root cause.** |
| **Deterministic sort + 30-min cache** | `get_similar_recipes` / `_rank_similar_recipes` (`api/:406,434`); `SIMILAR_RECIPES_CACHE_TIMEOUT` (`api/:56`) | Identical top-of-list every load for 30 min. |
| **Content-only (TF-IDF), no collaboration/popularity/recency** | `_recipe_text` (`api/:84`) | Can only surface text-similar recipes to what you already have. No serendipity. |
| **Downvote = exclude only, never "push away"** | `_excluded_recipe_ids` (`api/:240`) | A thumbs-down removes one recipe but does nothing to demote *similar* ones. |
| **No click/view signal at all** | explore reel captures only up/down (`reel_recipe_card.dart`) | The richest intent signal (which cards you actually open) is thrown away. |
| Only variety source | explore injects 4–10 random recipes (`recipes/views.py:383`) | A hack bolted on top of a frozen list; home rail has none. |

**Signals captured today:** upvote, like, comment, downvote (`UserRecipeInteraction`), save (`SavedRecipe`). **Not captured:** clicks/opens, impressions, dwell.

---

## 1. Signal model (v2)

### 1.1 Factors that drive a suggestion

Each engaged recipe contributes its TF-IDF vector to the profile, signed and weighted. Weights are a starting proposal — tune in §5.

| Signal | Sign | Weight | Capture status |
|---|---|---|---|
| Save | + | 2.0 | exists (`SavedRecipe`) |
| Upvote (reel 👍) | + | 2.0 | exists |
| Like | + | 1.5 | exists |
| Comment | + | 1.25 | exists |
| Created | + | 1.0 | exists |
| **Click / open** (tap reel card → detail) | + | **0.5** | **NEW — instrument (§1.3)** |
| **Downvote (reel 👎)** | **−** | **1.5** | exists, but today exclude-only — promote to a real negative (§2.3) |

Rationale for the signs/magnitudes:
- **Save/upvote** are explicit endorsements → strongest.
- **Click is weak and noisy** (you open things you end up disliking; it's also self-reinforcing — you can only click what was already shown). Low weight, and always paired with the exploration slice (§3.3) so it can't form a filter bubble.
- **Downvote becomes directional**: it builds a *dislike* vector that demotes similar recipes, not just the exact one.

### 1.2 Recency-weighted signals (freshness over time)

Multiply each signal weight by a time-decay on the interaction's age:

```
effective_weight = base_weight × 0.5 ** (age_days / HALF_LIFE_DAYS)   # proposal: HALF_LIFE_DAYS ≈ 75
```

So your *current* taste dominates a year-old taste. This alone makes the feed drift as you do. (`UserRecipeInteraction.created_at` and `SavedRecipe` timestamps already exist.)

### 1.3 Capturing clicks (instrumentation)

The tap already navigates to detail (`reel_recipe_card.dart:137-143`) — it's just not recorded. Two model options:

- **Option A (recommended): append-only event model** — new `RecipeEvent(user, recipe, kind, created_at)` with `kind ∈ {click, impression, …}`. Keeps the clean toggle semantics of like/upvote (which rely on `unique_together`) separate from high-volume, repeatable events; enables recency-weighting and a future seen-suppression (Direction C) without schema churn.
- **Option B: reuse `UserRecipeInteraction`** — add `'click'` to the choices. Problem: `unique_together=(user, recipe, interaction_type)` dedupes repeat clicks to one row; we'd lose frequency/recency unless we add a `count`/`updated_at`.

Mobile change (small): add `recordClick(recipe.id)` on the card `onTap` in `reel_recipe_card.dart`, fire-and-forget like `recordUpvote`. Optionally also log an **impression** on `_onPageChanged` (explore reel) to enable dwell/skip signals and Direction C later — not required for v2.

**Tradeoff to decide:** clicks improve relevance but reinforce the bubble; keep weight low + exploration on. Impressions are only worth capturing if we commit to seen-suppression (Direction C, not in this scope).

---

## 2. Direction B — Multi-interest profile

Replace the single centroid with **K taste clusters** so a candidate matching *any* of your interests ranks high (instead of the average of all of them).

### 2.1 Build

1. Gather the user's **positive** engaged-recipe vectors with effective weights (§1.1–1.2).
2. L2-normalize (cosine space). If the user has ≥ `MIN_FOR_CLUSTER` (≈ 8) engaged recipes, cluster into K centroids with MiniBatchKMeans (spherical / normalized).
   - `K = min(max(2, round(sqrt(n/2))), K_MAX=5)` — small, interpretable (e.g. *quick breakfasts*, *Italian dinners*, *baking*).
   - Fewer than `MIN_FOR_CLUSTER` → fall back to the single centroid (today's behavior).
3. Each centroid gets a **mass** = sum of member effective weights (drives slot allocation in §3.4).

### 2.2 Score (positive term)

```
pos(recipe) = max_k cos(recipe_vector, centroid_k)
```

`max` (not average) is the core fix: a strong match to *one* interest wins, so pasta-nights and dessert-nights both get served. (Soft alternative: weighted log-sum-exp across centroids — smoother, tunable — flagged in §5.)

### 2.3 Dislike vector (negative term)

Average of **downvoted** recipe vectors (optionally fast-skipped later) → `dislike_vec`.

```
content(recipe) = pos(recipe) − λ_neg · max(cos(recipe_vector, dislike_vec), 0)     # proposal: λ_neg ≈ 0.5
```

This demotes recipes *similar* to what you thumbs-downed — the directional downvote the user asked for — on top of still hard-excluding the exact downvoted ids.

### 2.4 Caching / cost

Clustering a few hundred sparse vectors with K≤5 is cheap. Compute at profile-build time and cache the centroids + dislike vector (keep the existing 1h profile cache keyed on vectorizer version). Candidate vectors are already precomputed (`RecipeVector`).

---

## 3. Direction A — Variety & diversity

Applied **after** the content score, on top of the multi-interest ranking.

### 3.1 Blend in popularity + recency

```
base(recipe) = content(recipe)
             × image_multiplier                       # keep existing ×0.1
             × recency_boost(created_at)               # mild; new catalog recipes can surface
             + β · popularity_norm(recipe)             # small global term so strong catalog recipes you'd never reach can break in
```

`popularity_norm` reuses the trending signal already computed (`_compute_ranked_trending_ids`, `api/:299`). `β` kept small so it nudges, not dominates.

### 3.2 MMR de-duplication

Over the top-M (≈300) by `base`, greedily pick next = `argmax [ α·base − (1−α)·max_sim_to_already_picked ]` (α ≈ 0.7). Stops adjacent results being near-identical ("5 chicken alfredos in a row").

### 3.3 Exploration slice (ε-greedy)

Reserve ≈ 15–20% of slots for recipes **outside** your top neighborhood — sampled from the popularity-weighted tail / random catalog. This is the principled version of today's random-injection hack (`recipes/views.py:383`), and the guardrail against the click-driven filter bubble.

### 3.4 Per-request freshness + cross-cluster allocation

- **Cache the scored pool, not the frozen order.** Today we cache the final sliced order for 30 min → identical every load. Instead cache the scored candidate pool (cheap) and apply MMR + a **seeded shuffle within score bands** per request, reusing the `variety_seed` the home feed already generates (`home/views.py:80`) and adding one for explore. Top band still = strong matches; *which* ones and their order rotate on refresh.
- **Allocate slots across clusters** proportional to cluster mass (with a floor per cluster) so one dominant interest doesn't monopolize the page — this is where B and A meet.
- Shorten / rename the similar-recipes cache accordingly (pool TTL can stay ~30 min since the per-request shuffle provides the variety).

---

## 4. Resulting pipeline

```
build_user_profile_v2(user):
  positives  = recency-weighted signed vectors (save/upvote/like/comment/created/click)
  centroids  = cluster(positives, K)        # or single centroid if sparse
  dislike    = mean(downvoted vectors)
  → cache (centroids, dislike, cluster_mass)

rank(user):
  for each candidate (precomputed RecipeVector, minus excluded/downvoted ids):
     content = max_k cos(c, centroid_k) − λ_neg·max(cos(c, dislike),0)
     base    = content × image_mult × recency_boost + β·popularity
  pool = top-M by base                        # cached ~30 min
  ranked = MMR(pool, α) with cross-cluster slot allocation
  ranked = splice in ε exploration slice
  ranked = seeded band-shuffle(ranked, variety_seed)   # per request
  return ranked[:top_n]
```

---

## 5. Parameters to tune / decisions needed

| Knob | Proposal | Decision |
|---|---|---|
| Click weight | 0.5 | how much to trust opens vs endorsements |
| `λ_neg` (downvote push) | 0.5 | how aggressively downvotes demote *similar* recipes |
| `HALF_LIFE_DAYS` | 75 | how fast old taste fades |
| `K` / `K_MAX` | √(n/2), max 5 | fixed vs adaptive number of interests |
| `max` vs soft-LSE over centroids | `max` | sharper vs smoother multi-interest |
| `β` popularity, `α` MMR, `ε` exploration | small / 0.7 / ~0.18 | relevance ↔ serendipity balance |

## 6. Open questions

1. **Click model:** append-only `RecipeEvent` (recommended) vs extend `UserRecipeInteraction`? Affects whether we can also do impressions/dwell later.
2. **Impressions:** worth capturing now (small reel change) to unlock seen-suppression (Direction C) next, or defer entirely?
3. **Explore vs home consistency:** unify explore's random-injection with this exploration slice, or keep explore-specific jitter on top?
4. **Cold start unchanged?** New users still get trending (`get_trending_recipes`) — confirm that stays as-is.
5. **Measurement:** what tells us it worked — click-through rate on explore, downvote rate, distinct-recipes-seen-per-week? Worth defining before building so we can A/B the weights.

## 7. Rollout (when design is approved)

1. Instrument clicks (mobile `recordClick` + backend endpoint/model) — starts collecting data immediately, independent of the ranker.
2. Multi-interest profile + directional downvote (§2) behind a flag, falling back to the single centroid.
3. Variety layer (§3) — MMR, popularity/recency blend, band-shuffle, exploration slice.
4. Tune weights (§5) against the metrics (§6.5).

*Output is a draft for human review; weights and model choices are proposals, not validated against prod data yet.*

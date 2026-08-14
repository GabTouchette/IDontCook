# Catalog-First Pivot

**Status:** Planned — not started
**Thesis:** The product's core asset is the growing recipe catalog (~3,100 today, expanding), not the user's saved list. The user opens the app because they *don't* know what to cook. Every surface should default to discovery of existing catalog recipes; saved recipes are (a) personalization signal and (b) a secondary feature. The AI should be a *librarian first, author second*: retrieve real recipes from the database, and only generate a new one when retrieval genuinely comes up empty or the user explicitly asks for something custom — because generated recipes are reliably more generic than curated ones.

Builds on the adaptive-home architecture (`adaptive-home-implementation.md`); all §1 contracts there remain locked. New contracts below are additive.

---

## 0. Where the "user's recipes first" bias lives today (audit, verified)

| # | Location | Bias |
|---|---|---|
| 1 | `PromptTemplates.chatbot_v2_system` (`api/ai_chatbot/api.py`) | System prompt embeds the user's saved-recipe list as the model's entire recipe universe |
| 2 | `ChatbotV2View.make_block_resolver` (`api/ai_chatbot/views.py`) | `reference_recipe` hard-restricted to `created_by=user` — the AI **cannot reference a catalog recipe at all** |
| 3 | No search tool | The model has no way to query the catalog; its fallback for anything unknown is `create_recipe` (generic output) or web search |
| 4 | `recipes/views.py` explore filter | `exclude_ai_generated` is a no-op (`id=-1 OR parent=-1` matches nothing) — AI-generated recipes are indistinguishable from catalog recipes in every query |
| 5 | `api/home/` feed | Only one `explore_rail` allowed per feed; no trending / new-arrivals / themed modules; `cook_again` + fridge-focused chat prompts assume an established personal library |
| 6 | Nav | "My Recipes" is tab 1, the first destination after Home |

The home feed's hero + explore rail already draw from the catalog recommender (`get_similar_recipes` with popularity cold-start), so the pivot is concentrated in **chat** (the big gap) and **feed variety** (the small one).

---

## 1. New contracts (LOCKED once implementation starts)

### 1.1 `search_recipes` tool (chat v2 — a *data* tool)

Unlike `create_recipe`/`reference_recipe`/`update_recipe` (whose results become UI blocks), `search_recipes` results go **back to the model** as a `tool_result`, and no block is emitted. The model reads the results and then calls `reference_recipe` for the ones it wants to present.

```json
{
  "name": "search_recipes",
  "input_schema": {
    "query":          "str  — free-text description of what to find",
    "tags":           "[str], optional — filter by recipe tags",
    "max_total_time": "int, optional — minutes",
    "max_calories":   "int, optional",
    "exclude_ids":    "[int], optional — already shown/rejected this conversation",
    "limit":          "int, optional, default 8, max 15"
  }
}
```

Tool result content (compact, token-efficient — the model sees this, the user doesn't):
```json
[{"id": 1740, "title": "...", "tags": ["..."], "total_time": 27, "calories": null,
  "desc": "first ~120 chars of description"}]
```

### 1.2 `reference_recipe` semantics widened

Input schema unchanged (`{id, title}`), but the resolver accepts **any catalog recipe id**, not just the user's own. The emitted `recipe_ref` block is unchanged (§1.1 of the adaptive-home plan) — mobile already renders it and `RecipeDetailPage` already opens non-owned recipes (Explore does this today). Zero mobile work.

### 1.3 `tool_activity` SSE event (additive, optional for clients)

So the thread can show "searching the cookbook…" instead of a silent pause during retrieval round-trips:
```json
{ "type": "tool_activity", "tool": "search_recipes" }
```
Emitted when a data-tool call starts. Mobile's forward-compat rule (unknown event types are skipped) means old clients ignore it safely.

### 1.4 `Recipe.source` field (real AI-generated flag)

```python
source = models.CharField(choices=["catalog", "user", "ai", "import", "ocr"], default="user")
```
Backfill migration: superuser/import-owned originals → `catalog`; everything else → `user`; going forward, `create_recipe` saves → `ai`, URL/OCR imports → `import`/`ocr`. `exclude_ai_generated` and all discovery surfaces (recommender candidates, home feed collectors, search_recipes) filter on this instead of the broken `id=-1` check. AI recipes stay fully usable *by their creator* — they're just never suggested to anyone as if they were catalog content.

### 1.5 `search_catalog()` service (shared retrieval, one implementation)

`api/recipes/search_service.py` (or `recommendations/` — implementer's call, but ONE place):
```python
def search_catalog(query, *, user, tags=None, max_total_time=None, max_calories=None,
                   exclude_ids=(), limit=8) -> list[Recipe]
```
Hybrid scoring: existing `RecipeSearchEngine` lexical score (trigram/prefix/exact-title) **+** semantic score (transform `query` with the shared `VectorizerArtifact`, cosine against precomputed `RecipeVector`s) **+** hard filters (tags/time/calories, exclude `source="ai"`, exclude user-downvoted, exclude `exclude_ids`). Personalization tiebreak: small boost from the user's taste-profile similarity when a profile exists. Consumed by the chat tool now; the Explore endpoint can migrate to it later.

---

## 2. Workstreams

### WS-P1 — Retrieval infrastructure (backend, blocking for P2)
**Scope:** `api/recipes/` (search service + `source` field/migration), `api/recommendations/` (expose a `get_trending_recipes()` by extracting the existing `_cold_start_fallback` scorer for reuse).
1. `Recipe.source` field + backfill migration (§1.4) — decide backfill heuristic from real data (who owns the 3,135 imported recipes — check `created_by` distribution before writing it).
2. `search_catalog()` (§1.5) with tests: lexical match, semantic match ("cozy winter soup" should hit soups without the literal words), filter combinations, AI-exclusion, empty-query behavior (falls back to personalized/trending list).
3. `get_trending_recipes(user, exclude_ids, top_n)` — reuse cold-start popularity+recency scorer for all users.
4. Fix `exclude_ai_generated` in `recipes/views.py` to use `source`.

### WS-P2 — Chat: librarian-first assistant (backend, the core of the pivot)
**Scope:** `api/ai_chatbot/` only.
1. Add `SEARCH_RECIPES_TOOL` (§1.1); extend `ask_stream_v2`'s loop to distinguish **UI tools** (emit block + ack tool_result) from **data tools** (tool_result carries real data back to the model, no block, emit `tool_activity` event). Raise the loop's max turns 5 → 7 (search → read → reference × several is more turns than before).
2. Widen `reference_recipe` resolver to any recipe (§1.2), keeping a clear error for nonexistent ids.
3. **System prompt rewrite** — the actual behavior change:
   - Retrieval-first policy: for any "what should I cook / find me / suggest" intent, call `search_recipes` FIRST (refining and re-searching once if results are weak) and present 2–4 existing recipes via `reference_recipe`, each with one line on why it fits.
   - `create_recipe` is the fallback: only when search results genuinely don't fit, or the user explicitly asks for a custom/original recipe ("invent", "make me something with exactly these leftovers"). When creating, say so ("I didn't find a great match, so here's a custom one").
   - Stop embedding the full saved-recipe list. Replace with a compact taste summary (top tags from the user's profile, dietary constraints, saved-recipe *count*) + a note that the user's own recipes are also searchable (`search_recipes` can take a `scope` extension later; for now the saved list only appears in `recipe_edit` context where it's actually relevant).
   - Web search demoted to genuinely-current-events questions, not recipe discovery.
4. Tests (mocked Anthropic): data-tool round-trip (search results reach the model's next turn, no block emitted, `tool_activity` emitted), widened reference resolution, create-as-fallback prompt content, v1 regression untouched.

### WS-P3 — Home feed: discovery-weighted (backend)
**Scope:** `api/home/` only.
1. **More catalog modules, zero new contracts** — emit additional `explore_rail` instances with distinct ids/titles instead of new module types (mobile renders them today, old clients unaffected):
   - `explore-rail-trending` — "Popular right now" via `get_trending_recipes`.
   - `explore-rail-new` — "New in the cookbook": recent `source="catalog"` additions with images.
   - `explore-rail-theme` — rotating tag-based theme picked by daypart/mood/day-of-year seed ("Soups for a cold night", "30-minute weeknight wins").
   Raise `MULTI_ALLOWED['explore_rail']` to 3 and `MAX_MODULES` 6 → 7; give the three rails distinct base scores so ranking (not chance) decides which appear.
2. **Library-size-aware weighting:** compute `saved_count` once in `FeedContext`; when `saved_count < 5`, multiply `cook_again`/`meal_plan_nudge` down and discovery rails up — a new user's feed should be nearly all catalog.
3. Chat-prompt pool: add discovery-flavored prompts that exercise the new search tool ("Find me a spicy noodle dish", "Show me something I've never tried").
4. Hero: already catalog-based — just ensure its candidates exclude `source="ai"` once WS-P1 lands.

### WS-P4 — Mobile (small)
**Scope:** `mobile/lib/providers/chat_provider.dart`, `mobile/lib/pages/home_page.dart`, models for the new event.
1. Parse `tool_activity` → show "Searching the cookbook…" as the typing-indicator label while active (falls back to plain dots).
2. Verify multi-`recipe_ref` rendering reads well as a "here are 3 options" answer (they render as compact tappable rows today — likely fine; adjust spacing only if needed).
3. Nothing else — blocks, rails, and detail navigation already work for arbitrary catalog recipes.

### WS-P5 — Product framing (nav order confirmed by user)
1. Nav order: `Home · Explore · My Recipes · Social · Meal Plan` (My Recipes demoted from tab 1; confirmed, not a default assumption).
2. Save-funnel check: discovery only compounds if viewing → saving is one obvious tap on `RecipeDetailPage` (the SavedRecipe copy flow exists; verify prominence, don't rebuild).
3. Later (not this phase): "cooked it" lightweight interaction as a stronger profile signal than save.

---

## 3. Sequencing & dependencies

```
Phase 1:  WS-P1 (search service, source flag, trending)   ← blocking
Phase 2:  WS-P2 (chat librarian)   ∥   WS-P3 (feed rails)   ← parallel, disjoint apps
Phase 3:  WS-P4 (mobile polish)  +  WS-P5 (nav, pending sign-off)  +  e2e verify
```

WS-P2 and WS-P3 both import from WS-P1's service, so P1 goes first (it's the smallest). P2/P3 have disjoint file boundaries (`ai_chatbot/` vs `home/`) and can run as parallel agents like previous waves.

## 4. What deliberately does NOT change

- `create_recipe` stays — custom requests ("use up these leftovers", allergy mashups) are a real use case; it just stops being the default answer.
- Saved recipes remain the backbone of the taste profile, meal planning, and `recipe_edit` chat.
- All adaptive-home §1 contracts (blocks, modules, SSE v2, moods, dayparts) — untouched; every addition here is forward-compatible with shipped clients.

## 5. Open questions to resolve before/during Phase 1

1. **`source` backfill heuristic** — inspect `created_by` distribution of the imported 3,135 recipes to write a correct migration (probably "owned by the superuser import account → catalog").
2. **Semantic quality ceiling** — TF-IDF vectors give word-overlap semantics, not true meaning ("cozy" won't match "comforting"). Good enough for v1 since the hybrid includes lexical + tags; if retrieval feels dumb in practice, the contained upgrade is swapping `RecipeVector` contents for real embeddings (the storage is already version-tagged for exactly this).
3. **Should `search_recipes` also search the user's own recipes?** Proposed v1: no (catalog only), model told the user's saved recipes exist for edit/meal-plan contexts. A `scope: "mine" | "catalog" | "all"` param is the obvious extension if it feels wrong in use.

# Adaptive Home Implementation Plan

**Status:** Wave 1 complete (verified via live smoke tests 2026-07-18); Wave 2 in progress (WS-D home surface, module cards, WS-E)
**Goal:** Turn the home screen into a conversational, adaptive surface. The home *is* a chat thread: on open, the assistant greets you and drops contextual module cards (suggestion, friend post, meal-plan nudge, mood question, event card…). You can tap a card or just reply in text ("something vegetarian instead"). Module selection is driven by a rules ranker with time-of-day priors, user mood, and ephemeral events.

This subsumes four features:
1. **Conversational home** — feed and chat are one surface.
2. **Moods** — a rotating micro-question card; answering re-ranks the feed and colors chat context.
3. **Time-of-day personalities** — daypart × weekday/weekend multipliers in the ranker.
4. **Ephemeral events** — admin-managed + computed time-boxed event cards ("Soup week", "5 friends cooked this").

It is built on top of the **chat tool-use refactor** (replacing the `$$`/`&&`/`@@` delimiter protocol with Anthropic tool use + typed SSE events), which is Workstream A.

---

## 1. Shared contracts (LOCKED — do not change without updating this doc)

All workstreams build against these. Backend and mobile agents must match them exactly.

### 1.1 Block schema

A **block** is the unit of rich content in both chat messages and the home feed. JSON:

```json
{ "block_type": "text",          "text": "string (markdown)" }
{ "block_type": "recipe",        "recipe": <RecipeFull> }
{ "block_type": "recipe_ref",    "recipe": <RecipeSummary> }
{ "block_type": "recipe_update", "recipe_id": 123, "changes": { ...changed Recipe fields } }
{ "block_type": "module",        "module": <Module> }
```

`RecipeFull` = the exact JSON shape currently emitted inside `$$…$$` (matches `RecipeSerializer` input).
`RecipeSummary` = `{ "id": int, "title": str, "image_url": str|null, "total_time": int|null, "calories": int|null, "tags": [str] }`

### 1.2 Module schema

```json
{
  "id": "string (unique per feed, e.g. 'hero-812')",
  "module_type": "hero_suggestion | cook_again | friend_post | meal_plan_nudge | grocery_shortcut | chat_prompt | explore_rail | event_card | mood_question",
  "reason": "string — human-readable 'why you're seeing this'",
  "payload": { ...type-specific, see below }
}
```

Payloads:

| module_type | payload |
|---|---|
| `hero_suggestion` | `{ "recipe": RecipeSummary, "tagline": str }` |
| `cook_again` | `{ "recipe": RecipeSummary, "saved_at": iso8601 }` |
| `friend_post` | `{ "post_id": int, "author": {"id": int, "username": str, "avatar_url": str\|null}, "recipe": RecipeSummary\|null, "preview_text": str, "created_at": iso8601 }` |
| `meal_plan_nudge` | `{ "week_start": iso8601-date, "planned_days": int, "cta": str }` |
| `grocery_shortcut` | `{ "item_count": int, "cta": str }` |
| `chat_prompt` | `{ "prompt_text": str }` — tapping sends `prompt_text` as a user chat message |
| `explore_rail` | `{ "title": str, "recipes": [RecipeSummary] }` (3–8 recipes) |
| `event_card` | `{ "event_slug": str, "title": str, "body": str, "image_url": str\|null, "cta": str\|null, "recipes": [RecipeSummary] }` |
| `mood_question` | `{ "question": str, "options": [{"mood": MoodEnum, "label": str, "emoji": str}] }` |

**Forward-compat rule (mobile):** unknown `block_type` or `module_type` is silently skipped, never an error.

### 1.3 Mood taxonomy

`MoodEnum = "rushed" | "ambitious" | "cooking_for_someone" | "comfort" | "healthy" | "surprise_me"`

Mood affects (a) module ranking multipliers, (b) recipe selection inside modules (e.g. `rushed` → `total_time <= 30`), (c) chat context (the system prompt is told the user's current mood).

### 1.4 Dayparts

Computed from **client-provided** local time (never server clock): `morning` 05–11, `midday` 11–15, `evening` 15–21, `late` 21–05. Crossed with `weekday`/`weekend` → 8 contexts.

### 1.5 Home feed endpoint

```
GET /api/home/feed/?local_hour=17&weekday=4&mood=rushed
```
`mood` optional. Response:

```json
{
  "feed_id": "uuid",
  "context": { "daypart": "evening", "is_weekend": false, "mood": "rushed" },
  "greeting": "string",
  "blocks": [ Block, ... ]
}
```

`blocks[0]` is a `text` block containing the greeting/framing line; then 3–6 `module` blocks, ranked. A `mood_question` module appears when no mood is set for the session (client re-fetches with `?mood=` after the user answers).

### 1.6 Chat SSE protocol v2

New endpoint alongside v1 (v1 untouched during migration): `POST /api/ai/chat/v2/` (the existing chatbot path + `v2/`; same auth). Request body adds:

```json
{
  "message": "...",
  "conversation_id": 123 | null,
  "context": "home" | "global" | "recipe_edit",
  "recipe_id": 456,                  // recipe_edit only
  "mood": "rushed" | null,
  "home_feed": { ...the feed response the user is replying to } | null
}
```

SSE events (each a `data:` line of JSON):

```json
{ "type": "message_start", "conversation_id": 123 }
{ "type": "text_delta", "text": "..." }
{ "type": "block", "block": <Block> }        // emitted when a tool call completes (recipe / recipe_ref / recipe_update)
{ "type": "error", "message": "..." }
{ "type": "done" }
```

Backend uses **Anthropic tool use** — tools `create_recipe`, `update_recipe`, `reference_recipe` with strict JSON schemas — instead of prompt-instructed `$$`/`@@`/`&&` delimiters. Conversation history is persisted **server-side** (user + assistant turns, including blocks as JSON); the client sends only the new message + `conversation_id`.

Models: recipe-generating chat calls use `claude-sonnet-5` (`CHAT_MODEL`); lightweight formatting stays on `claude-haiku-4-5` (`LIGHT_MODEL`).

---

## 2. Workstreams

### WS-A — Backend: chat v2 (tool use + typed SSE + server-side history)
**Owner:** backend agent 1 · **Scope:** `api/ai_chatbot/` only (incl. its `urls.py`; do NOT touch `api/api/settings.py`, `api/api/urls.py`, or other apps).

- Define tools `create_recipe` / `update_recipe` / `reference_recipe`; input schemas mirror the current `$$` JSON shape (`create`), the `@@` changed-fields shape (`update`), and `{id,title}` (`reference`).
- New `ChatbotV2View` streaming the §1.6 events. Tool-call results become `block` events. Keep v1 (`ChatbotView`) fully working.
- Persist both sides of the conversation: extend `ChatHistory` (or add a `ChatMessage` model) with role + `blocks` JSONField; v2 rebuilds Anthropic message history server-side from `conversation_id`.
- Accept and use `context`, `mood`, `home_feed` (serialize the feed's modules compactly into the system/first-turn context so "something vegetarian instead" resolves against what was shown).
- `CHAT_MODEL = "claude-sonnet-5"`, `LIGHT_MODEL` stays haiku. Keep the web_search tool in global/home context.
- Tests with mocked Anthropic client: tool-call → block event mapping, history persistence, malformed-tool-input resilience, v1 regression.

### WS-B — Backend: home feed composer (ranker + signals + events)
**Owner:** backend agent 2 · **Scope:** new Django app `api/home/`; owns the one-line registrations in `api/api/settings.py` (INSTALLED_APPS) and `api/api/urls.py`. Read-only imports from `recipes`, `social`, `recommendations`, `accounts`. Do NOT modify `ai_chatbot`.

- **Module registry:** one collector class per module type producing candidate modules + base scores from signals: taste-profile suggestion via `recommendations.api.get_similar_recipes` (hero), recently saved & untouched (cook_again), unseen followed-user posts (friend_post), meal-plan state (nudge/grocery), curated prompts (chat_prompt), personalized rail (explore_rail).
- **Ranker:** `score = base × DAYPART_PRIORS[daypart, is_weekend][module_type] × MOOD_PRIORS[mood][module_type]`, plain dicts in `home/ranking.py` with sensible defaults (morning-weekday boosts meal_plan_nudge; evening-weekday boosts hero_suggestion with quick recipes; weekend boosts ambitious/social). Mood also filters recipe candidates (`rushed` → total_time ≤ 30, `healthy` → calorie cap, etc.). Dedup, cap at 6 modules, inject `mood_question` when no mood param.
- **Ephemeral events:** `HomeEvent` model (`slug`, `title`, `body`, `image_url`, `cta`, `starts_at`, `ends_at`, `priority`, `is_active`, optional `tag_filter` to attach matching recipes) + Django admin + migration. Plus one computed event: "N friends cooked this week" when ≥3 followed users posted in 7 days. Active events → `event_card` modules, priority-boosted.
- **Greetings:** template pool keyed by daypart/mood (Tier 1 — no LLM call yet).
- Endpoint per §1.5. Tests: ranking priors, mood filtering, event windows, empty-data fallbacks (new user must still get a valid feed — explore_rail + chat_prompt at minimum).

### WS-C — Mobile: block models + v2 chat client + widget registry
**Owner:** mobile agent 1 · **Scope:** `mobile/lib/models/`, `mobile/lib/api/`, `mobile/lib/providers/chat_provider.dart`, new `mobile/lib/widgets/blocks/`. Do NOT touch `dashboard_page.dart`, `navbar.dart`, or create the home page (Wave 2).

- Freezed models: `Block` (union per §1.1), `HomeModule`, `RecipeSummary`, `HomeFeed`, `Mood` enum. Unknown-type tolerance built into `fromJson`.
- `ChatApi` v2 method + SSE event parsing in `ChatProvider` (replace live `$$`/`&&`/`@@` regex watching with typed events; keep the v1 parser code path compiling until Wave 2 removes it).
- **Block widget registry:** `Map<String, Widget Function(BuildContext, Block)>` in `widgets/blocks/block_registry.dart`; renderers for `text` (markdown bubble), `recipe` (reuse existing `recipe_card.dart`), `recipe_ref`, `recipe_update`, and module cards for `hero_suggestion`, `chat_prompt`, `mood_question`, `explore_rail` (remaining cards in Wave 2). Unknown → `SizedBox.shrink()`.
- Follow existing conventions (Nunito, MD3 ColorScheme, toast types). `flutter pub run build_runner build`, `flutter analyze`, `flutter test` with JSON fixtures matching §1.1–1.6 exactly.

### WS-D — Mobile: conversational home surface (**Wave 2**, after A–C land)
- New `HomePage`: chat-thread UI; on open calls `GET /api/home/feed/` and renders greeting + module blocks as the assistant's opening message; input bar sends replies to chat v2 with `context: "home"` and the feed payload; mood chips re-fetch the feed and animate the re-rank; pull-to-refresh = new feed.
- Remaining module cards: `cook_again`, `friend_post`, `meal_plan_nudge`, `grocery_shortcut`, `event_card`.
- **Nav restructure (default, veto-able):** tab 0 becomes Home (conversation); dedicated AI-chat tab is removed (it *is* home now); tabs become Home · My Recipes · Explore · Meal Plan · Social.

### WS-E — Backend: recommender quick wins (independent, any time)
- Weight positive interactions into `build_user_profile` (upvote 2.0, like 1.5, comment 1.25 vs save 1.0); currently only downvotes do anything.
- Cold-start fallback: no profile → popularity + recency blend instead of pure random.
- Precompute per-recipe vectors (Celery on save) instead of per-request TF-IDF over the whole corpus.

## 3. Sequencing & integration

```
Wave 1 (parallel):  WS-A          WS-B          WS-C
                      \             |             /
Wave 2:                +--- integration check ---+
                       WS-D (home surface + nav) ,  WS-E
Wave 3:                e2e verify, v1 delimiter-path removal, polish
```

Wave-1 file boundaries are disjoint by design: A owns `api/ai_chatbot/`, B owns `api/home/` + the two registration lines, C owns mobile models/providers/widgets. Integration check after Wave 1: run backend test suite, hit both endpoints with curl fixtures, `flutter analyze && flutter test`, reconcile any contract drift back into §1.

## 4. Open product decisions (defaults chosen, flag to veto)

1. Nav restructure per WS-D (chat tab merges into Home).
2. Mood persists per app-session only (not stored server-side) — reopening the app re-asks contextually.
3. Greeting is template-based in Tier 1; LLM-composed greeting/copy is a later upgrade behind the same contract.
4. `recipes/global/filter/` (Explore tab) stays as-is; the home feed is additive.

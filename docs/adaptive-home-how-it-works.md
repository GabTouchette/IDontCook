# Adaptive Home & Chat v2 — How It Works

This is the technical reference for the feature built from `docs/plans/adaptive-home-implementation.md`. That file was the *plan*; this file describes what actually exists in the code today, and how the pieces connect at runtime.

For product framing (why moods, why dayparts, why "the home is a conversation"), see the plan doc and the brainstorm earlier in this project's history. This doc is code-first: file paths, data shapes, and call sequences.

---

## 1. The big picture

Three things were built, in this order of dependency:

1. **Chat v2** (`api/ai_chatbot/`) — replaced a fragile text-delimiter protocol (`$$...$$`, `@@...@@`, `&&...&&`) with real Anthropic tool use and typed SSE events. Everything else depends on this.
2. **Home feed** (`api/home/`, a new Django app) — a rules-based ranker that assembles a personalized, time/mood-aware feed of "module" cards.
3. **Mobile conversational home** (`mobile/lib/pages/home_page.dart` + supporting models/providers/widgets) — a chat-thread UI where the home feed *is* the assistant's opening message, and users can reply in text or tap cards.

A fourth, independent improvement (`api/recommendations/`) upgraded the underlying recipe recommender that both the home feed and the old Explore tab draw from.

```
┌─────────────────────────┐        ┌──────────────────────────┐
│   Flutter: HomePage      │        │   Django: HomeFeedView    │
│   (home_page.dart)       │  GET   │   (api/home/views.py)     │
│                          │───────▶│                            │
│  HomeFeedProvider        │        │  collect_modules() ────┐  │
│  ChatProvider (v2)       │        │  rank_modules()        │  │
└───────────┬──────────────┘        │  get_greeting()        │  │
            │ seeds conversation    └─────────┬───────────────┘  │
            │ with feed's blocks              │                  │
            ▼                                 ▼                  │
┌─────────────────────────┐        ┌──────────────────────────┐  │
│  BlockRegistry           │        │ recommendations/api.py    │◀─┘
│  (widgets/blocks/*)      │        │ (TF-IDF taste profile,    │
│  renders each block as   │        │  cold-start fallback,     │
│  a card/pill/rail        │        │  precomputed vectors)     │
└───────────┬──────────────┘        └────────────────────────────┘
            │ user types a reply
            ▼
┌─────────────────────────┐        ┌──────────────────────────┐
│  ChatProvider            │  POST  │  ChatbotV2View             │
│  .sendMessageV2()         │───────▶│  (api/ai_chatbot/views.py)│
│                          │  SSE   │                            │
│  parses typed events:    │◀───────│  AnthropicService          │
│  text_delta / block /    │        │  .ask_stream_v2()          │
│  error / done            │        │  (tool use, Claude Sonnet) │
└──────────────────────────┘        └──────────────────────────┘
```

---

## 2. Shared contracts

Every piece below agrees on a small set of JSON shapes. These are documented in full (with exact field lists) in `docs/plans/adaptive-home-implementation.md` §1 — this section is the short version.

### Block
The unit of content in both chat messages and the home feed:

```json
{ "block_type": "text",          "text": "..." }
{ "block_type": "recipe",        "recipe": { ...full recipe... } }
{ "block_type": "recipe_ref",    "recipe": { "id", "title", "image_url", "total_time", "calories", "tags" } }
{ "block_type": "recipe_update", "recipe_id": 123, "changes": { ... } }
{ "block_type": "module",        "module": { ...HomeModule... } }
```

**Forward-compat rule**: an unknown `block_type` must never crash either side. Backend: n/a (backend only emits known types). Mobile: `Block.fromJson` has `fallbackUnion: 'unknown'` (Freezed), so any unrecognized type parses to `Block.unknown()` and every renderer treats it as "render nothing."

### HomeModule
```json
{ "id": "hero-812", "module_type": "hero_suggestion", "reason": "...", "payload": { ... } }
```
Nine `module_type`s exist: `hero_suggestion`, `cook_again`, `friend_post`, `meal_plan_nudge`, `grocery_shortcut`, `chat_prompt`, `explore_rail`, `event_card`, `mood_question`. Each has its own payload shape (see plan §1.2).

### Mood
`rushed | ambitious | cooking_for_someone | comfort | healthy | surprise_me` — six values, shared verbatim between `api/home/ranking.py`'s `MOODS` list, `api/ai_chatbot/api.py`'s `MOOD_DESCRIPTIONS`, and `mobile/lib/models/mood/mood.dart`'s `Mood` enum.

### Daypart
Computed from **client-supplied local hour**, never the server clock (a user's phone knows their timezone; the server doesn't): `morning` 05–11, `midday` 11–15, `evening` 15–21, `late` 21–05. See `api/home/ranking.py::compute_daypart()`.

---

## 3. Backend: Chat v2 (`api/ai_chatbot/`)

### The problem it replaced
The original chatbot (`ChatbotView`, still present and untouched) asks Claude to embed recipe JSON directly in its prose, wrapped in delimiters the client regex-scans for: `$$...$$` for a new recipe, `@@...@@` for an edit, `&&...&&` for a reference to an existing recipe. This is fragile — a stray `$$` in normal text, or a truncated JSON blob, breaks parsing on both ends.

### The fix: Anthropic tool use
`api/ai_chatbot/api.py` defines three tools with strict JSON schemas:

- `CREATE_RECIPE_TOOL` — schema mirrors the old `$$` payload (title, ingredients, instructions, etc.)
- `UPDATE_RECIPE_TOOL` — schema mirrors the old `@@` "changed fields" payload
- `REFERENCE_RECIPE_TOOL` — `{ id: int }`, for pointing at one of the user's own saved recipes

Claude is instructed (via the system prompt built by `PromptTemplates.chatbot_v2_system` / `recipe_edit_v2_system`) to call these tools instead of writing recipe JSON in text. When the model actually needs recipe data, the API response contains a **tool_use content block** instead of freeform text — this is enforced by Anthropic's API, not by prompt discipline alone.

`CHAT_MODEL = "claude-sonnet-5"` is used for recipe-generating calls (v1 and v2 both); `LIGHT_MODEL = "claude-haiku-4-5"` stays on OCR/ingredient-formatting paths where a full model isn't needed.

### The streaming loop: `AnthropicService.ask_stream_v2`
(`api/ai_chatbot/api.py:260`)

This is an **agentic loop**, not a single API call, because Claude can call a tool, get a result back, and continue talking — up to 5 turns:

1. Call the Anthropic Messages API with `stream=True` and the tool list.
2. As the stream comes in:
   - Plain `text_delta` events from Claude → yielded upward immediately as `{"type": "text_delta", "text": "..."}`.
   - `input_json_delta` events (a tool call's arguments streaming in) are buffered per content-block index — they arrive in fragments and aren't valid JSON until complete.
   - On `content_block_stop`, the buffered JSON is parsed. If parsing succeeds, `resolve_block(tool_name, tool_input)` (a callback passed in from the view) converts it into a plan-§1.1 `Block` dict, and that's yielded as `{"type": "block", "block": {...}}`.
   - If the tool input is malformed (bad JSON, wrong types), a `{"type": "error", ...}` event is yielded **and** an `is_error: true` tool_result is sent back to Claude — so the model knows its call failed and can retry or apologize, rather than the whole stream crashing.
3. If Claude's response included tool calls, the loop feeds the tool results back and continues (this is what allows "create a recipe, then tell me about it" in one turn).
4. A final `{"type": "done"}` is not emitted by this method — that's added by the view, after history is persisted (see below).

### The view: `ChatbotV2View` (`api/ai_chatbot/views.py:163`)

`POST /api/ai/chat/v2/` (the `ai_chatbot` app is mounted at `/api/ai/` in the project urlconf; `v2/` is appended in `ai_chatbot/urls.py`).

Request body:
```json
{
  "message": "...",
  "conversation_id": 123 | null,
  "context": "home" | "global" | "recipe_edit",
  "recipe_id": 456,          // required only for recipe_edit
  "mood": "rushed" | null,
  "home_feed": { ...the feed the user is replying to... } | null
}
```

What the view does, in order:
1. Validates `context` and `mood` against the allowed sets — 400 on anything else.
2. **Conversation resolution**: if `conversation_id` is given, loads that `Conversation` (404 if it doesn't belong to the requesting user); otherwise creates a new one.
3. **Context setup**: `recipe_edit` loads the target recipe (404 if not found/not owned) and builds a recipe-editing system prompt with only the `update_recipe` tool available (no web search — you're not browsing the web while editing one specific recipe). `global`/`home` build a system prompt listing the user's saved recipes and enable `create_recipe` + `reference_recipe` + Anthropic's built-in `web_search_20250305` tool.
4. If `mood` or `home_feed` were provided, they're folded into the system prompt (`PromptTemplates.chatbot_v2_system`'s `mood_section` / `home_feed_section` helpers) — this is how "something vegetarian instead" resolves against what the feed just showed: the feed's greeting + module reasons + recipe titles/ids are serialized compactly into the prompt.
5. **History rebuild**: `build_anthropic_messages(conversation)` reconstructs the full Anthropic `messages` array from stored `ChatMessage` rows — the client never re-sends chat history; only the new `message` string. Past assistant tool calls are re-serialized as compact bracketed text (`[create_recipe: {...}]`) so Claude "remembers" what it created/referenced/changed in earlier turns of the same conversation.
6. The user's turn is persisted immediately (`ChatMessage(role="user", text=message)`).
7. The SSE response streams: `message_start` (carries `conversation_id`, so a fresh client-side conversation can attach subsequent replies to it) → the `ask_stream_v2` event stream → `done`. In the `finally` block, the assistant's full turn (concatenated text + all blocks) is persisted as one `ChatMessage(role="assistant", ...)`.

### Server-side history model (`api/ai_chatbot/models.py`)

`ChatMessage` is new: `conversation` (FK), `user` (FK), `role` (`user`/`assistant`), `text`, `blocks` (JSONField — a list of block dicts), ordered by `created_at`. The pre-existing `Conversation` and `ChatHistory` models are untouched — v1 still uses `ChatHistory` for its own bookkeeping; v2 uses the new `ChatMessage` exclusively.

---

## 4. Backend: Home feed (`api/home/`)

A new Django app, four files worth knowing:

### `collectors.py` — one function per module type

Each `collect_*(ctx)` function takes a `FeedContext` (user, current time, daypart, weekend flag, mood) and returns a list of `(module_dict, base_score)` tuples — zero, one, or (for `event_card`) several. **Every collector is wrapped in a try/except at the call site** (`collect_modules`), so one collector's bug degrades that module away rather than 500ing the whole feed.

What each one actually queries:

| Collector | Signal | Notes |
|---|---|---|
| `collect_hero_suggestion` | `recommendations.api.get_similar_recipes` (falls back to `get_popular_recipes`) | The single top recipe; tagline picked from mood or daypart string tables |
| `collect_cook_again` | `SavedRecipe` saved 7–30 days ago | The Goldilocks window: too recent isn't stale yet, too old isn't "recently saved" |
| `collect_friend_post` | `social.Follow` + `social.Post` in the last 72h | Silently returns `[]` if the user follows no one |
| `collect_meal_plan_nudge` | `meal_planning.MealPlan` / `PlannedMeal` for the current week | Different copy for "no plan yet" vs. "partially planned"; returns `[]` once 7/7 days are planned |
| `collect_grocery_shortcut` | `meal_planning.GroceryList` tied to the active plan | Returns `[]` if the list is fully checked off |
| `collect_chat_prompt` | Static curated pools in `CHAT_PROMPTS`/`MOOD_CHAT_PROMPTS`, indexed by `ctx.copy_seed` (day-of-year + per-request `variety_seed`) | Rotates per refresh (and daily) without needing a database table |
| `collect_explore_rail` | Same recommender as hero, but 6 recipes, mood-filtered | Reason text differs: "Based on your taste profile" vs. "Popular with the community right now" |
| `collect_event_card` | `HomeEvent` model (admin-managed) + a **computed** event | The computed one: "N friends cooked this week" fires when ≥3 followed users posted in 7 days |
| `collect_mood_question` | Nothing — pure UI prompt | Only returned when `ctx.mood` is `None`; once a mood is set, this collector contributes nothing, which is *why* the mood question disappears from the feed after you pick one |

`apply_mood_recipe_filter(recipes, mood)` is a shared helper: `rushed` hard-filters to `total_time <= 30` (falling back to the unfiltered list if that would empty it — a mood should never starve a module); `healthy` re-sorts by ascending calories rather than filtering (a preference, not an exclusion).

### `ranking.py` — the scoring function

```
final_score = base_score
            × DAYPART_PRIORS[(daypart, is_weekend)].get(module_type, 1.0)
            × MOOD_PRIORS[mood].get(module_type, 1.0)
```

Both prior tables are plain dicts keyed by `(daypart, is_weekend)` or `mood`, each mapping to `{module_type: multiplier}`. Missing keys default to a neutral `1.0` — this is what makes the "time-of-day personality" and "mood" behaviors tunable without touching any other code: e.g. `('evening', False)` boosts `hero_suggestion` ×1.6 (dinner-decision urgency), `('morning', True)` (weekend mornings) boosts `explore_rail`/`friend_post`/`event_card` (browsing mode, not "what do I cook right now" mode).

`rank_modules()` then: scores every candidate, sorts descending, deduplicates by `module_type` (max 1 of most types, but `event_card` is allowed twice via `MULTI_ALLOWED`), and caps at `MAX_MODULES = 6`.

### `views.py` — `HomeFeedView`

`GET /api/home/feed/?local_hour=17&weekday=4&mood=rushed`

- `local_hour` (0–23) and `weekday` (0=Monday..6=Sunday) are **required** — 400 if missing or out of range. This is the client-provided-time contract: the server has no idea what timezone the phone is in.
- `mood` is optional; 400 if provided but not one of the six valid values.
- Builds a `FeedContext` (injecting a fresh per-request `variety_seed = random.randint(0, 10_000)`), runs `collect_modules` → `rank_modules`, generates a `greeting` from `greetings.py`'s template pools (keyed by daypart/mood), and returns the JSON below.

**Variety seed** (`FeedContext.variety_seed` / `.copy_seed`): the copy/selection rotators — greeting, chat prompt, mood-question wording, theme rail, and the hero pick — index off `ctx.copy_seed`, which is `rotation_seed` (day-of-year, the stable base) **plus** the per-request `variety_seed`. The hero also samples from the top `HERO_SAMPLE_POOL` (5) recommendations rather than always index 0. Net effect: a pull-to-refresh (or a mood re-rank) lands on a different greeting/prompt/theme/hero instead of byte-identical content, while recommendation *quality* stays high (still drawn from the top of the ranked pool). `variety_seed` defaults to `0` on a directly-constructed `FeedContext`, which keeps unit tests deterministic — only the view injects randomness.

The response shape:

```json
{
  "feed_id": "<uuid>",
  "context": { "daypart": "evening", "is_weekend": false, "mood": "rushed" },
  "greeting": "Busy evening? Dinner in 30 or less, coming up.",
  "blocks": [
    { "block_type": "text", "text": "<the greeting>" },
    { "block_type": "module", "module": { ... } },
    ...
  ]
}
```

### `models.py` — `HomeEvent`

The only new table in this app: `slug`, `title`, `body`, `image_url`, `cta`, `starts_at`/`ends_at` (the active window), `priority` (float multiplier on top of the base `event_card` score), `is_active`, `tag_filter` (optional — when set, up to 4 recipes carrying that tag are attached to the card). Managed entirely through the Django admin; no dedicated CRUD API. This is how "Soup week" gets created without a code change.

---

## 5. Backend: Recommender upgrades (`api/recommendations/`)

This wasn't part of the adaptive-home surface directly, but both `collect_hero_suggestion` and `collect_explore_rail` depend on it, so it's worth understanding.

### What changed and why (`api.py`)

**Before**: `build_user_profile` averaged TF-IDF vectors of only the recipes a user created or saved, with a fresh `TfidfVectorizer` fit *per request* from that user's own text — meaning the vector space itself was user-specific, which made precomputing recipe vectors impossible (a stored vector would be meaningless against a different user's vocabulary).

**Now**:
- **Shared vectorizer**: `VectorizerArtifact` stores one pickled `TfidfVectorizer` fit over the *entire* recipe corpus, tagged with a `version` (a hash of its vocabulary). `get_active_vectorizer()` loads the latest one, or fits and persists a new one if none exists. Every profile and every stored recipe vector is computed against this same shared space, so they're directly comparable.
- **Weighted profile**: a recipe counts toward a user's taste profile at the *max* weight across how they've engaged with it — created/saved (1.0), commented (1.25), liked (1.5), upvoted (2.0). Previously only creates/saves counted at all; likes/upvotes/comments were recorded (`UserRecipeInteraction`) but never used.
- **Cold-start fallback**: `_cold_start_fallback` kicks in when a user has zero signal (new account). Instead of returning nothing (which used to mean "random recipes" upstream), it scores all recipes by a cross-user popularity count (weighted upvotes/likes/saves) with a 30-day half-life recency decay, so a recently-popular recipe outranks an old one with similar raw popularity.
- **Precomputed vectors**: `RecipeVector` stores each recipe's sparse TF-IDF vector (as `[[index, weight], ...]` pairs) tagged with the vectorizer version it was computed against. `get_similar_recipes` prefers these stored vectors and only falls back to an on-the-fly transform for recipes missing one — turning what used to be a full-corpus TF-IDF transform on every single request into a lookup.
- A `post_save` signal on `Recipe` (in `apps.py`) recomputes that one recipe's vector synchronously whenever it's saved — deliberately *not* dispatched through Celery, because in testing the Celery dispatch silently no-op'd when no worker was consuming it, and the computation itself is cheap (one transform + upsert).
- The commented-out collaborative-filtering block at the bottom of `api.py` (NMF-based) was left untouched — it predates this work and was never wired in; there wasn't enough interaction volume to justify resurrecting it yet.

**Operational note**: existing recipes don't get a `RecipeVector` retroactively just by this code shipping — run `python manage.py rebuild_recipe_vectors` once after migrating (this is also how you'd refit the vectorizer after a large batch of new recipes changes the corpus's vocabulary shape).

---

## 6. Mobile: models (`mobile/lib/models/`)

All Freezed classes, all hand-verified against the JSON contracts above.

- **`block/block.dart`** — `Block` is a Freezed union keyed on `block_type`. The critical bit: `@Freezed(unionKey: 'block_type', fallbackUnion: 'unknown')` — an unrecognized type parses to `Block.unknown()` instead of throwing, satisfying the forward-compat rule.
- **`home_module/home_module.dart`** — `HomeModule`'s JSON handling is **hand-written**, not Freezed-generated, because the payload's shape depends on a sibling field (`module_type`) rather than being self-describing the way `Block`'s union is. `HomeModule.fromJson` switches on `module_type` and dispatches to the matching typed payload class; both an unrecognized `module_type` *and* a recognized type with a malformed payload (parse throws) degrade to `UnknownModulePayload` — never a crash.
- **`home_module/module_payloads.dart`** — one class per module type (`HeroSuggestionPayload`, `CookAgainPayload`, `FriendPostPayload`, etc.), matching plan §1.2 field-for-field.
- **`recipe_summary/recipe_summary.dart`** — the compact recipe shape used everywhere a full `Recipe` would be overkill (`id`, `title`, `image_url`, `total_time`, `calories`, `tags`).
- **`mood/mood.dart`** — the six-value enum, with `wireValue` (enum → API string) and `Mood.fromWire` (API string → enum, nullable so an unrecognized value doesn't crash — it's just treated as "no mood").
- **`home_feed/home_feed.dart`** — `HomeFeed` (top-level feed response) plus `HomeFeedContext`; exposes `renderableBlocks`, which filters out unknown blocks so calling code never has to think about the forward-compat rule.
- **`chat_v2_event/chat_v2_event.dart`** — a Freezed union over the SSE event `type` field: `message_start`, `text_delta`, `block`, `error`, `done`, plus `unknown` fallback.

---

## 7. Mobile: API layer

### `api_helper.dart` — the shared HTTP client

Two relevant pieces:
- `streamSseEvents(endpoint, data, headers)` — used by chat v2. Buffers across chunk boundaries (a `data:` line can be split across two network reads) and yields decoded JSON events one at a time.
- **The UTF-8 fix**: `_handleResponse` (used by all regular GET/POST calls, including the home feed) now explicitly does `utf8.decode(response.bodyBytes)` before `json.decode`. This mattered because Dart's `http` package decodes `response.body` using the response's declared charset, defaulting to **Latin-1** when none is declared — and Django's JSON responses don't declare one (per RFC 8259, JSON is always UTF-8, so DRF doesn't bother). Without this fix, every em dash, curly quote, or accented character in greeting/tagline text got silently mangled. The same fix was applied in `auth_api.dart` (login/register/Google-auth) for the same reason.

### `home_api.dart`

`fetchHomeFeed({Mood? mood})` — computes `local_hour` and `weekday` from `DateTime.now()` on the device (converting Dart's `1=Mon..7=Sun` to the API's `0=Mon..6=Sun`), calls `GET home/feed/`, parses into `HomeFeed`.

### `ai_chatbot_api.dart`

`chatWithBotStreamV2({message, conversationId, context, recipeId, mood, homeFeed})` — posts to `ai/chat/v2/`, returns a `Stream<ChatV2Event>` by decoding each SSE line through the `chat_v2_event.dart` union.

---

## 8. Mobile: providers

### `HomeFeedProvider` (`providers/home_feed_provider.dart`)

Thin state wrapper: `feed`, `isLoading`, `error`, `currentMood`. `loadFeed({mood})` fetches and stores; `selectMood(mood)` is just `loadFeed(mood: mood)`; `refresh()` reloads with whatever mood is currently active.

### `ChatProvider` — the v2 additions (`providers/chat_provider.dart`)

The v1 chat state (delimiter-based, still used by the standalone `AiChatbotPage`) is untouched. New alongside it:

- `ChatV2Message { sender, blocks: List<Block>, isLoading }` — a message is a list of blocks, not a single string, because an assistant turn can interleave plain text with recipe cards.
- `v2Messages` (read-only list), `v2ConversationId`, `isV2Sending`.
- `addV2AssistantMessage(blocks)` — appends a pre-built message; this is how the home feed's blocks become the conversation's opening turn without a network round-trip.
- `replaceV2Message(index, blocks)` — swaps one message's blocks in place; used when a mood selection re-ranks the feed and the opening message needs to reflect it.
- `sendMessageV2({message, chatContext, recipeId, mood, homeFeed, onError})` — opens the SSE stream, appends a placeholder loading message, and updates it in place as `text_delta`/`block` events arrive; `onError` surfaces failures to the caller (home_page shows a toast) instead of silently swallowing them.
- `resetV2Conversation()` — clears `v2Messages` entirely (used by pull-to-refresh).

---

## 9. Mobile: the conversational home (`pages/home_page.dart`)

### Seeding: how the feed becomes a conversation

On `initState`, `_initializeHome()` runs once (guarded by `if (chatProvider.v2Messages.isNotEmpty) return;` — see the bug note below) and:
1. Calls `homeFeedProvider.loadFeed()`.
2. Passes `feed.renderableBlocks` to `chatProvider.addV2AssistantMessage(...)` — this becomes `v2Messages[0]`, the conversation's first (and initially only) message.

Nothing about this is chat-specific at the network level — it's a local, synchronous seed. The actual chat endpoint isn't hit until the user types something or taps a `chat_prompt` chip.

### Rendering: `_buildAssistantMessage`

Each assistant message is rendered as a `Row`: a fixed `_AssistantAvatar` (a small circular icon — see §11) on the left, and an `Expanded` column of blocks on the right. Each block gets:
- A `ValueKey` derived from its own content (`_blockKey`) — this matters because Flutter only replays enter-animations (`flutter_animate`'s `.fadeIn().slideY()`) when a widget's key changes; a plain data-only rebuild (e.g. after a mood switch replaces the same message's block list) reuses the same Element and the animation silently doesn't replay without this.
- The very first block of the very first message, if it's a `TextBlock`, renders via `TextBlockBubble(isGreeting: true)` — the only block that gets the large headline treatment; every other text block (ordinary chat replies) renders at normal body size.

If `homeFeedProvider.currentMood` is set, a `MoodChosenIndicator` ("Feeling: Rushed" + a "change" tap target) is inserted above the blocks — this is the persistent trace that a mood was selected, replacing the mood-question card that's no longer in the feed.

### Sending a message

`_sendMessage()` reads the text field, and — critically — only attaches the `home_feed` payload **on the first user message of the conversation** (`isFirstUserMessage` check). After that, the backend's persisted `ChatMessage` history carries the context forward; re-sending the whole feed on every turn would be wasteful and isn't needed since Claude "remembers" via the reconstructed message history.

### Mood selection (`_handleMoodSelected`)

1. Sets `_pendingMood` **synchronously**, before the network call — this fills the tapped pill's background immediately, so the tap always reads as registered even before the round-trip completes.
2. Awaits `homeFeedProvider.selectMood(mood)` (a re-fetch of `/api/home/feed/` with `?mood=`).
3. On success, replaces message 0's blocks **in place** via `chatProvider.replaceV2Message(0, feed.renderableBlocks)` — the cards re-rank where they sit; nothing is appended below and the viewport doesn't move. (This is a deliberate revert of a short-lived variant that instead appended the whole re-ranked feed as a new message — that duplicated the entire page and slammed the scroll to the bottom.)

The mood-question module naturally disappears from the new blocks (per `collect_mood_question`'s "only when no mood is set" rule) — the `_MoodChosenIndicator` (keyed off `_pendingMood`, at the top of message 0) is what replaces it, so the disappearance reads as "your choice was recorded," not "the UI broke." Its **"change"** tap target runs `_handleMoodCleared`, which reloads the feed with no mood and re-ranks message 0 in place again, bringing the mood-question pills back.

### Pull-to-refresh, typing indicator, scroll-to-latest

- `_handleRefresh` only runs if there's no conversation beyond the seeded message (`v2Messages.length > 1` blocks it) — refreshing mid-conversation would be destructive.
- `message.isLoading` renders as `_TypingIndicator` — three staggered pulsing dots — instead of a bare spinner.
- A scroll listener (`_handleScroll`) tracks `_isNearBottom`; a floating "scroll to latest" pill appears when the user has scrolled away from the bottom while a reply is streaming or new content just landed.

---

## 10. Mobile: block widgets (`widgets/blocks/`)

`block_registry.dart` is the single dispatch point: `BlockRegistry.build(context, block, callbacks: BlockCallbacks(...))` switches on the block's runtime type (and, for `ModuleBlock`, on `module.moduleType`) and returns the matching widget. Unknown types return `SizedBox.shrink()`.

`BlockCallbacks` carries everything a card might need to trigger: `onChatPromptTap` (send text), `onMoodSelected`, `onModuleCtaTap` (meal-plan/grocery/event CTAs), and `selectedMood` (for the instant-fill pill state described above).

One widget per module type, each with a deliberately different visual weight rather than a uniform card:

| Widget | Treatment |
|---|---|
| `hero_suggestion_card.dart` | Full-bleed image + gradient scrim + overlaid text — the feed's visual anchor. No-image and image-load-failure both fall back to a neutral `surfaceContainerHighest` panel with a centered icon (not the accent color — see §11). |
| `explore_rail.dart` | No enclosing card at all — a label + horizontal scroll of tiles |
| `cook_again_card.dart`, `friend_post_card.dart` | Lightweight list-rows with a bottom divider, not boxed |
| `meal_plan_nudge_card.dart`, `grocery_shortcut_card.dart` | Compact colored banner strips (warm vs. cool tint, so they read as distinct at a glance) |
| `event_card.dart` | The most "festive" treatment on purpose — it's rare/ephemeral by design |
| `mood_question_card.dart` | Inline question + rounded pill row, no bordering box |
| `chat_prompt_chip.dart` | A single light outline pill |
| `text_block_bubble.dart` | No card — just typography (see §11 for the greeting/body split) |
| `recipe_ref_row.dart`, `recipe_update_card.dart` | Compact rows for the chat-specific block types |

`block_styles.dart` centralizes shared constants: `kBlockAccent`/`kBlockAccentInk` (the lime accent pair), `kBlockFeedGap` (the single place inter-item spacing is applied — individual widgets stay margin-free to avoid doubling it), `blockCardDecoration`/`blockPillDecoration` (shared box styles), `reasonTextStyle` (one consistent style for every module's "why you're seeing this" line), `dayPartIcon`/`reasonIcon`/`moodIcon` (icon mappings — see next section).

---

## 11. Two rounds of bug fixes worth understanding

These were found by direct testing, not by a plan — worth knowing why they happened so similar bugs don't recur.

### Emoji rendered as garbled boxes
The app's font (`GoogleFonts.spaceGrotesk`) has no emoji glyphs, and the Flutter environment wasn't falling back to a color-emoji font. Any `Text('⏱️', style: GoogleFonts.spaceGrotesk(...))` showed tofu/mojibake instead of an emoji. The fix wasn't a font-fallback config — it was to stop using emoji entirely in favor of the app's existing Material Icons vocabulary (the same `Icons.timer_outlined`/`Icons.eco_outlined`/etc. style already used in `ai_chatbot_page.dart` and `navbar.dart`). `block_styles.dart`'s `dayPartIcon()`, `reasonIcon()`, and `moodIcon()` return `IconData`, not strings — and for `mood_question_card.dart` specifically, the backend's `emoji` field on each mood option (e.g. `"⏱️"` in `collectors.py`'s `MOOD_OPTIONS`) is **intentionally ignored client-side** in favor of the `moodIcon(mood)` mapping keyed off the enum.

### Non-ASCII characters mangled in regular API responses (`À??` style)
Not a display bug — a decoding bug. `api_helper.dart::_handleResponse` used `response.body`, which Dart's `http` package decodes using the response's declared charset, defaulting to Latin-1 when absent. Django's JSON responses don't declare a charset (correctly — JSON is always UTF-8 per spec), so any em dash or curly quote in, say, a greeting string (`api/home/greetings.py`) got misinterpreted byte-by-byte. Fixed by decoding `response.bodyBytes` as UTF-8 explicitly before `json.decode`. The streaming SSE paths were never affected — they already used `stream.transform(utf8.decoder)`.

### The hero card's lime-green flash
Two different fallback paths existed for the hero card's image, and only one had been fixed in an earlier pass. The **no-image** case used a neutral panel from the start of that fix; but the **image-load-error** handler (`Image.network`'s `errorBuilder`) still fell back to solid `kBlockAccent` (lime) — so any broken or slow-to-fail image URL flashed lime before/instead of showing the real image. Fixed by using the same neutral fallback in both places, plus adding a `loadingBuilder` so there's no flash of anything while the image is still fetching.

### "Chat text too big" / "no agent icon"
Two related issues traced to one root cause: `TextBlockBubble` was used for *every* text block — including ordinary assistant chat replies, not just the feed's opening greeting — and always applied the greeting's large 21px headline style. It also carried a `dayPartIcon()` prefix (a weather icon) meant to decorate the greeting, but which then appeared before *every* assistant sentence, including plain conversational replies — which is also why it read as an odd, inconsistent "cloud" rather than a stable "this is the agent" marker. Fixed by: (1) adding `TextBlockBubble.isGreeting` so only the very first block of the very first message gets the headline treatment, everything else renders at normal 15px body size; (2) removing the per-block weather icon entirely and adding one persistent `_AssistantAvatar` (a small circular icon, robot glyph) that leads every assistant turn in `home_page.dart`, independent of content or time of day.

### Duplicate feed cards on tab revisit
`dashboard_page.dart`'s tab switcher wraps each page in `KeyedSubtree(key: ValueKey(_selectedIndex))` under an `AnimatedSwitcher` (needed for the fade transition between tabs). This means `HomePage`'s entire `State` is destroyed and recreated every time you leave and return to the Home tab — but `ChatProvider` is a long-lived top-level provider (registered once in `main.dart`), so its `v2Messages` list survives across tab switches. Without a guard, `_initializeHome()`'s `initState` call would re-seed the conversation on every revisit, appending another copy of the greeting + cards on top of the old ones. Fixed with a one-line guard: `if (chatProvider.v2Messages.isNotEmpty) return;` before fetching/seeding.

---

## 12. Nav restructure

`dashboard_page.dart` tabs changed from `[Recipes, AI Chat, Explore, Meal Plan, Social]` to `[Home, My Recipes, Explore, Meal Plan, Social]` — the dedicated AI chat tab was removed because Home *is* now the chat surface (per the plan's "conversational home" concept). The `AiChatBotPage` file and its route still exist and work (recipe-editing chat entry points elsewhere in the app still link to it directly) — it's just no longer a bottom-nav tab. All `onNavigateToTab(index)` call sites (e.g. the "Ask Cookbot" button on `RecipesPage`) were updated to the new indices.

---

## 13. Running it locally

```bash
cd api
python manage.py migrate                 # applies ai_chatbot, home, recommendations migrations
python manage.py rebuild_recipe_vectors   # one-time backfill for existing recipes
python manage.py runserver 0.0.0.0:8000

cd mobile
flutter pub get
flutter run
```

Key endpoints to sanity-check directly:
```bash
curl -H "Authorization: Token $TOKEN" \
  "http://127.0.0.1:8000/api/home/feed/?local_hour=17&weekday=4&mood=rushed"

curl -N -X POST "http://127.0.0.1:8000/api/ai/chat/v2/" \
  -H "Authorization: Token $TOKEN" -H "Content-Type: application/json" \
  -d '{"message": "quick dinner ideas", "conversation_id": null, "context": "home", "mood": "rushed"}'
```

---

## 14. What's deliberately not done yet

- **No exit animation** when the mood-question card is replaced by the mood-confirmed indicator — it just disappears while the new content fades in. Flagged as a possible follow-up, not a bug.
- **No LLM-composed greeting** — greetings are template pools rotated by day-of-year, not generated per-request. This is the plan's explicit "Tier 1" scope; an LLM-composer tier was discussed as a later upgrade behind the same `blocks` contract.
- **Collaborative filtering** remains commented out in `recommendations/api.py` — there isn't enough interaction volume yet to justify it over the content-based approach.
- **Mood doesn't persist server-side** — it resets each app session; re-opening the app re-asks contextually rather than remembering last time's answer.

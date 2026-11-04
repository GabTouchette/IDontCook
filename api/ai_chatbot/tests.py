"""
Tests for the AI chatbot app.

Chat v2 (tool use + typed SSE + server-side history) and v1 regression tests.
The Anthropic client is fully mocked — no network calls.
"""
import json
from unittest.mock import patch, MagicMock

from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient

from recipes.models import Recipe
from .models import Conversation, ChatMessage

V2_URL = "/api/ai/chat/v2/"
V1_URL = "/api/ai/chat/"

User = get_user_model()


class NS:
    """Simple namespace to fake Anthropic stream event objects."""
    def __init__(self, **kwargs):
        self.__dict__.update(kwargs)


def text_events(index, text, chunks=2):
    """Fake stream events for a text content block."""
    events = [NS(type="content_block_start", index=index, content_block=NS(type="text"))]
    step = max(1, len(text) // chunks)
    for i in range(0, len(text), step):
        events.append(NS(
            type="content_block_delta", index=index,
            delta=NS(type="text_delta", text=text[i:i + step]),
        ))
    events.append(NS(type="content_block_stop", index=index))
    return events


def tool_use_events(index, tool_id, name, input_json_str, chunks=3):
    """Fake stream events for a tool_use content block with buffered JSON input."""
    events = [NS(
        type="content_block_start", index=index,
        content_block=NS(type="tool_use", id=tool_id, name=name),
    )]
    step = max(1, len(input_json_str) // chunks)
    for i in range(0, len(input_json_str), step):
        events.append(NS(
            type="content_block_delta", index=index,
            delta=NS(type="input_json_delta", partial_json=input_json_str[i:i + step]),
        ))
    events.append(NS(type="content_block_stop", index=index))
    return events


def end_of_message(stop_reason):
    return [
        NS(type="message_delta", delta=NS(stop_reason=stop_reason)),
        NS(type="message_stop"),
    ]


SAMPLE_RECIPE = {
    "title": "Spaghetti Bolognese",
    "ingredients": [
        {"name": "spaghetti", "quantity": 100.0, "unit": "g"},
        {"name": "tomato sauce", "quantity": 1.0, "unit": "cup"},
    ],
    "instructions": ["Boil the spaghetti.", "Add the sauce."],
    "preparation_time": 10,
    "cooking_time": 20,
    "servings": 2,
    "tags": ["italian", "pasta"],
    "description": "Classic pasta.",
    "notes": None,
}


def parse_sse(response):
    """Collects the streamed response and parses each `data:` line into a dict."""
    body = b"".join(response.streaming_content).decode("utf-8")
    events = []
    for line in body.split("\n\n"):
        line = line.strip()
        if line.startswith("data: "):
            events.append(json.loads(line[len("data: "):]))
    return events


class ChatV2TestCase(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username="alice", password="pw")
        self.client = APIClient()
        self.client.force_authenticate(user=self.user)

    def post_v2(self, payload, streams):
        """
        POSTs to the v2 endpoint with the Anthropic client mocked.
        `streams` is a list of event iterables — one per messages.create call.
        Returns (parsed SSE events, mocked client).
        """
        with patch("ai_chatbot.api.anthropic.Anthropic") as MockAnthropic:
            mock_client = MockAnthropic.return_value
            mock_client.messages.create.side_effect = [iter(s) for s in streams]
            response = self.client.post(V2_URL, payload, format="json")
            self.assertEqual(response.status_code, 200)
            events = parse_sse(response)  # consume inside the patch context
        return events, mock_client

    # ------------------------------------------------------------------
    # Tool-call stream → SSE event sequence
    # ------------------------------------------------------------------

    def test_create_recipe_tool_call_emits_block_event_sequence(self):
        first_stream = (
            text_events(0, "Here's a recipe for you. ")
            + tool_use_events(1, "toolu_1", "create_recipe", json.dumps(SAMPLE_RECIPE))
            + end_of_message("tool_use")
        )
        second_stream = text_events(0, "Enjoy!") + end_of_message("end_turn")

        events, mock_client = self.post_v2(
            {"message": "Give me a pasta recipe", "conversation_id": None, "context": "global"},
            [first_stream, second_stream],
        )

        types = [e["type"] for e in events]
        # message_start first, done last
        self.assertEqual(types[0], "message_start")
        self.assertIn("conversation_id", events[0])
        self.assertEqual(types[-1], "done")
        # text deltas before the block, then the block, then follow-up text
        self.assertIn("block", types)
        block_idx = types.index("block")
        self.assertTrue(all(t == "text_delta" for t in types[1:block_idx]))
        self.assertIn("text_delta", types[block_idx + 1:-1])
        self.assertNotIn("error", types)

        block = events[block_idx]["block"]
        self.assertEqual(block["block_type"], "recipe")
        self.assertEqual(block["recipe"]["title"], "Spaghetti Bolognese")
        self.assertEqual(block["recipe"]["ingredients"][0]["quantity"], 100.0)

        # The agentic loop fed a tool_result back to the second call
        self.assertEqual(mock_client.messages.create.call_count, 2)
        second_call = mock_client.messages.create.call_args_list[1].kwargs
        tool_result_msg = second_call["messages"][-1]
        self.assertEqual(tool_result_msg["role"], "user")
        self.assertEqual(tool_result_msg["content"][0]["type"], "tool_result")
        self.assertEqual(tool_result_msg["content"][0]["tool_use_id"], "toolu_1")

    def test_reference_recipe_builds_recipe_ref_summary(self):
        recipe = Recipe.objects.create(
            created_by=self.user, title="Saved Tacos",
            tags=["mexican"], preparation_time=10, cooking_time=15, calories=450.0,
        )
        stream = (
            tool_use_events(0, "toolu_ref", "reference_recipe",
                            json.dumps({"id": recipe.id, "title": "Saved Tacos"}))
            + end_of_message("tool_use")
        )
        closing = text_events(0, "There you go.") + end_of_message("end_turn")

        events, _ = self.post_v2({"message": "Show me my tacos", "context": "global"}, [stream, closing])

        blocks = [e["block"] for e in events if e["type"] == "block"]
        self.assertEqual(len(blocks), 1)
        self.assertEqual(blocks[0]["block_type"], "recipe_ref")
        summary = blocks[0]["recipe"]
        self.assertEqual(summary["id"], recipe.id)
        self.assertEqual(summary["title"], "Saved Tacos")
        self.assertEqual(summary["total_time"], 25)
        self.assertEqual(summary["calories"], 450)
        # Recipe.save() canonicalizes tags ("mexican" -> "Mexican") and
        # auto-appends a meal-type tag ("Dinner")
        self.assertIn("Mexican", summary["tags"])

    def test_reference_recipe_allows_catalog_recipe_owned_by_another_user(self):
        other = User.objects.create_user(username="chef", password="pw")
        recipe = Recipe.objects.create(
            created_by=other, title="Chef's Ramen", tags=["japanese"],
            preparation_time=20, cooking_time=30, source=Recipe.SOURCE_CATALOG,
        )
        stream = (
            tool_use_events(0, "toolu_ref", "reference_recipe",
                             json.dumps({"id": recipe.id, "title": "Chef's Ramen"}))
            + end_of_message("tool_use")
        )
        closing = text_events(0, "Great pick!") + end_of_message("end_turn")

        events, _ = self.post_v2({"message": "show me ramen", "context": "global"}, [stream, closing])

        blocks = [e["block"] for e in events if e["type"] == "block"]
        self.assertEqual(len(blocks), 1)
        self.assertEqual(blocks[0]["block_type"], "recipe_ref")
        self.assertEqual(blocks[0]["recipe"]["id"], recipe.id)
        self.assertNotIn("error", [e["type"] for e in events])

    def test_reference_recipe_rejects_another_users_ai_generated_recipe(self):
        other = User.objects.create_user(username="chef2", password="pw")
        recipe = Recipe.objects.create(
            created_by=other, title="Generated Slop", source=Recipe.SOURCE_AI,
        )
        stream = (
            tool_use_events(0, "toolu_ref", "reference_recipe",
                             json.dumps({"id": recipe.id, "title": "Generated Slop"}))
            + end_of_message("tool_use")
        )
        closing = text_events(0, "Sorry about that.") + end_of_message("end_turn")

        events, _ = self.post_v2({"message": "show me that recipe", "context": "global"}, [stream, closing])

        types = [e["type"] for e in events]
        self.assertIn("error", types)
        self.assertNotIn("block", types)
        error = next(e for e in events if e["type"] == "error")
        self.assertIn("AI-generated", error["message"])

    def test_reference_recipe_allows_own_ai_generated_recipe(self):
        recipe = Recipe.objects.create(
            created_by=self.user, title="My Generated Recipe", source=Recipe.SOURCE_AI,
        )
        stream = (
            tool_use_events(0, "toolu_ref", "reference_recipe",
                             json.dumps({"id": recipe.id, "title": "My Generated Recipe"}))
            + end_of_message("tool_use")
        )
        closing = text_events(0, "Here it is again.") + end_of_message("end_turn")

        events, _ = self.post_v2({"message": "show me that one I made earlier", "context": "global"}, [stream, closing])

        blocks = [e["block"] for e in events if e["type"] == "block"]
        self.assertEqual(len(blocks), 1)
        self.assertEqual(blocks[0]["recipe"]["id"], recipe.id)

    def test_reference_recipe_nonexistent_id_errors(self):
        stream = (
            tool_use_events(0, "toolu_ref", "reference_recipe",
                             json.dumps({"id": 999999, "title": "Ghost Recipe"}))
            + end_of_message("tool_use")
        )
        closing = text_events(0, "Hmm.") + end_of_message("end_turn")

        events, _ = self.post_v2({"message": "show me that recipe", "context": "global"}, [stream, closing])
        types = [e["type"] for e in events]
        self.assertIn("error", types)
        self.assertNotIn("block", types)

    def test_recipe_edit_context_emits_recipe_update_block(self):
        recipe = Recipe.objects.create(
            created_by=self.user, title="Soup", instructions=["Boil water."],
        )
        changes = {"cooking_time": 25, "tags": ["soup", "cozy"]}
        stream = (
            tool_use_events(0, "toolu_up", "update_recipe",
                            json.dumps({"recipe_id": None, "changes": changes}))
            + end_of_message("tool_use")
        )
        closing = text_events(0, "Updated!") + end_of_message("end_turn")

        events, mock_client = self.post_v2(
            {"message": "Make it cook longer", "context": "recipe_edit", "recipe_id": recipe.id},
            [stream, closing],
        )

        blocks = [e["block"] for e in events if e["type"] == "block"]
        self.assertEqual(len(blocks), 1)
        self.assertEqual(blocks[0]["block_type"], "recipe_update")
        # recipe_id resolved from the request context when the tool passed null
        self.assertEqual(blocks[0]["recipe_id"], recipe.id)
        self.assertEqual(blocks[0]["changes"], changes)

        # recipe_edit: update_recipe tool only, no web_search
        call = mock_client.messages.create.call_args_list[0].kwargs
        tool_names = [t.get("name") for t in call["tools"]]
        self.assertEqual(tool_names, ["update_recipe"])
        self.assertIn("Soup", call["system"])

    def test_global_context_includes_web_search_tool(self):
        stream = text_events(0, "Hi!") + end_of_message("end_turn")
        _, mock_client = self.post_v2({"message": "hello", "context": "global"}, [stream])
        call = mock_client.messages.create.call_args_list[0].kwargs
        tool_names = [t.get("name") for t in call["tools"]]
        self.assertIn("web_search", tool_names)
        self.assertIn("create_recipe", tool_names)
        self.assertIn("reference_recipe", tool_names)
        self.assertIn("search_recipes", tool_names)

    def test_recipe_edit_context_excludes_search_recipes_tool(self):
        recipe = Recipe.objects.create(
            created_by=self.user, title="Soup", instructions=["Boil water."],
        )
        stream = text_events(0, "Sure.") + end_of_message("end_turn")
        _, mock_client = self.post_v2(
            {"message": "make it spicier", "context": "recipe_edit", "recipe_id": recipe.id},
            [stream],
        )
        call = mock_client.messages.create.call_args_list[0].kwargs
        tool_names = [t.get("name") for t in call["tools"]]
        self.assertNotIn("search_recipes", tool_names)
        self.assertEqual(tool_names, ["update_recipe"])

    # ------------------------------------------------------------------
    # search_recipes: a *data* tool — no block, real data reaches the model,
    # tool_activity fires on call start (catalog-first-pivot.md §1.1/§1.3)
    # ------------------------------------------------------------------

    def test_search_recipes_returns_data_no_block_and_emits_tool_activity(self):
        catalog_hit = Recipe.objects.create(
            created_by=self.user, title="Butternut Squash Bisque",
            tags=["soup", "cozy"], preparation_time=10, cooking_time=20,
            calories=310.0, description="A silky, warming soup for a cold night." * 3,
        )
        first_stream = (
            tool_use_events(0, "toolu_search", "search_recipes",
                             json.dumps({"query": "cozy winter soup", "limit": 5}))
            + end_of_message("tool_use")
        )
        second_stream = text_events(0, "Found a great match!") + end_of_message("end_turn")

        with patch("ai_chatbot.api.search_catalog") as mock_search:
            mock_search.return_value = [catalog_hit]
            events, mock_client = self.post_v2(
                {"message": "something cozy for a cold night", "context": "global"},
                [first_stream, second_stream],
            )

        types = [e["type"] for e in events]
        self.assertNotIn("block", types)
        self.assertIn("tool_activity", types)
        activity = next(e for e in events if e["type"] == "tool_activity")
        self.assertEqual(activity["tool"], "search_recipes")
        # tool_activity fires before the tool's result comes back (i.e. before
        # the follow-up call happens) — it must be present in the first batch
        # of events, ahead of any text from the second turn.
        self.assertNotIn("error", types)

        mock_search.assert_called_once()
        _, search_kwargs = mock_search.call_args
        self.assertEqual(mock_search.call_args[0][0], "cozy winter soup")
        self.assertEqual(search_kwargs["limit"], 5)

        second_call = mock_client.messages.create.call_args_list[1].kwargs
        tool_result_msg = second_call["messages"][-1]
        self.assertEqual(tool_result_msg["role"], "user")
        result_content = tool_result_msg["content"][0]
        self.assertEqual(result_content["type"], "tool_result")
        self.assertNotIn("is_error", result_content)
        payload = json.loads(result_content["content"])
        self.assertEqual(len(payload), 1)
        self.assertEqual(payload[0]["id"], catalog_hit.id)
        self.assertEqual(payload[0]["title"], "Butternut Squash Bisque")
        self.assertEqual(payload[0]["total_time"], 30)
        self.assertEqual(payload[0]["calories"], 310)
        self.assertLessEqual(len(payload[0]["desc"]), 120)

    def test_search_recipes_requires_nonempty_query(self):
        stream = (
            tool_use_events(0, "toolu_bad_search", "search_recipes", json.dumps({"query": "  "}))
            + end_of_message("tool_use")
        )
        closing = text_events(0, "Let me try again.") + end_of_message("end_turn")

        with patch("ai_chatbot.api.search_catalog") as mock_search:
            events, _ = self.post_v2({"message": "find me something", "context": "global"}, [stream, closing])

        types = [e["type"] for e in events]
        self.assertIn("error", types)
        self.assertNotIn("block", types)
        mock_search.assert_not_called()

    def test_search_then_reference_flow_produces_recipe_ref_blocks(self):
        """search_recipes -> model reads results -> reference_recipe x2 -> done."""
        soup = Recipe.objects.create(
            created_by=self.user, title="Miso Soup", tags=["soup"],
            preparation_time=5, cooking_time=10,
        )
        chili = Recipe.objects.create(
            created_by=self.user, title="Turkey Chili", tags=["stew"],
            preparation_time=15, cooking_time=40,
        )

        search_stream = (
            tool_use_events(0, "toolu_search", "search_recipes",
                             json.dumps({"query": "warm and cozy"}))
            + end_of_message("tool_use")
        )
        reference_stream = (
            text_events(0, "Here are two great options: ")
            + tool_use_events(1, "toolu_ref1", "reference_recipe",
                               json.dumps({"id": soup.id, "title": soup.title}))
            + tool_use_events(2, "toolu_ref2", "reference_recipe",
                               json.dumps({"id": chili.id, "title": chili.title}))
            + end_of_message("tool_use")
        )
        closing_stream = text_events(0, "Enjoy!") + end_of_message("end_turn")

        with patch("ai_chatbot.api.search_catalog") as mock_search:
            mock_search.return_value = [soup, chili]
            events, mock_client = self.post_v2(
                {"message": "what should I cook tonight?", "context": "global"},
                [search_stream, reference_stream, closing_stream],
            )

        types = [e["type"] for e in events]
        self.assertEqual(types.count("tool_activity"), 1)
        self.assertEqual(types.count("block"), 2)
        self.assertNotIn("error", types)

        blocks = [e["block"] for e in events if e["type"] == "block"]
        self.assertEqual([b["block_type"] for b in blocks], ["recipe_ref", "recipe_ref"])
        self.assertEqual({b["recipe"]["id"] for b in blocks}, {soup.id, chili.id})

        # Three turns: search -> reference x2 -> closing text.
        self.assertEqual(mock_client.messages.create.call_count, 3)

    # ------------------------------------------------------------------
    # Server-side history: persisted and rebuilt across turns
    # ------------------------------------------------------------------

    def test_history_persisted_and_rebuilt_across_turns(self):
        # Turn 1: creates the conversation and a recipe block
        first = (
            text_events(0, "Sure! ")
            + tool_use_events(1, "toolu_1", "create_recipe", json.dumps(SAMPLE_RECIPE))
            + end_of_message("tool_use")
        )
        first_close = text_events(0, "Done.") + end_of_message("end_turn")
        events, _ = self.post_v2(
            {"message": "Give me pasta", "conversation_id": None, "context": "global"},
            [first, first_close],
        )
        conversation_id = events[0]["conversation_id"]

        conversation = Conversation.objects.get(id=conversation_id, user=self.user)
        msgs = list(conversation.messages.all())
        self.assertEqual([m.role for m in msgs], ["user", "assistant"])
        self.assertEqual(msgs[0].text, "Give me pasta")
        self.assertEqual(msgs[1].text, "Sure! Done.")
        self.assertEqual(len(msgs[1].blocks), 1)
        self.assertEqual(msgs[1].blocks[0]["block_type"], "recipe")

        # Turn 2: server rebuilds the messages array from stored history
        second = text_events(0, "It has 2 servings.") + end_of_message("end_turn")
        events2, mock_client = self.post_v2(
            {"message": "How many servings?", "conversation_id": conversation_id, "context": "global"},
            [second],
        )
        self.assertEqual(events2[0]["conversation_id"], conversation_id)

        sent_messages = mock_client.messages.create.call_args_list[0].kwargs["messages"]
        self.assertEqual(sent_messages[0], {"role": "user", "content": "Give me pasta"})
        self.assertEqual(sent_messages[1]["role"], "assistant")
        self.assertIn("Sure! Done.", sent_messages[1]["content"])
        self.assertIn("create_recipe", sent_messages[1]["content"])
        self.assertIn("Spaghetti Bolognese", sent_messages[1]["content"])
        self.assertEqual(sent_messages[2], {"role": "user", "content": "How many servings?"})

        # Both turns persisted
        self.assertEqual(conversation.messages.count(), 4)

    def test_unknown_conversation_returns_404(self):
        response = self.client.post(V2_URL, {"message": "hi", "conversation_id": 99999}, format="json")
        self.assertEqual(response.status_code, 404)

    def test_missing_message_returns_400(self):
        response = self.client.post(V2_URL, {"conversation_id": None}, format="json")
        self.assertEqual(response.status_code, 400)

    # ------------------------------------------------------------------
    # Malformed tool input → error event, stream never crashes
    # ------------------------------------------------------------------

    def test_malformed_tool_json_emits_error_event(self):
        bad_json = '{"title": "Broken", "ingredients": [oops'
        stream = (
            tool_use_events(0, "toolu_bad", "create_recipe", bad_json)
            + end_of_message("tool_use")
        )
        closing = text_events(0, "Sorry about that.") + end_of_message("end_turn")

        events, mock_client = self.post_v2({"message": "recipe please", "context": "global"}, [stream, closing])

        types = [e["type"] for e in events]
        self.assertIn("error", types)
        self.assertNotIn("block", types)
        self.assertEqual(types[-1], "done")
        error = next(e for e in events if e["type"] == "error")
        self.assertIn("create_recipe", error["message"])

        # The error was fed back to the model as an is_error tool_result
        second_call = mock_client.messages.create.call_args_list[1].kwargs
        tool_result = second_call["messages"][-1]["content"][0]
        self.assertTrue(tool_result["is_error"])

    def test_invalid_tool_input_shape_emits_error_event(self):
        # Valid JSON but fails recipe validation (no ingredients)
        invalid_recipe = {"title": "Empty", "ingredients": [], "instructions": ["x"]}
        stream = (
            tool_use_events(0, "toolu_inv", "create_recipe", json.dumps(invalid_recipe))
            + end_of_message("tool_use")
        )
        closing = text_events(0, "Let me retry.") + end_of_message("end_turn")

        events, _ = self.post_v2({"message": "recipe", "context": "global"}, [stream, closing])
        types = [e["type"] for e in events]
        self.assertIn("error", types)
        self.assertNotIn("block", types)
        self.assertEqual(types[-1], "done")

    # ------------------------------------------------------------------
    # mood / home_feed reach the prompt
    # ------------------------------------------------------------------

    def test_mood_and_home_feed_reach_system_prompt(self):
        home_feed = {
            "feed_id": "abc",
            "greeting": "Good evening!",
            "blocks": [
                {"block_type": "text", "text": "Good evening!"},
                {
                    "block_type": "module",
                    "module": {
                        "id": "hero-1",
                        "module_type": "hero_suggestion",
                        "reason": "Because you liked pasta",
                        "payload": {
                            "recipe": {"id": 42, "title": "Pesto Gnocchi"},
                            "tagline": "Quick and green",
                        },
                    },
                },
                {
                    "block_type": "module",
                    "module": {
                        "id": "rail-1",
                        "module_type": "explore_rail",
                        "reason": "Popular now",
                        "payload": {"title": "Trending", "recipes": [
                            {"id": 7, "title": "Miso Soup"}, {"id": 8, "title": "Pad Thai"},
                        ]},
                    },
                },
            ],
        }
        stream = text_events(0, "Something veggie coming up.") + end_of_message("end_turn")
        _, mock_client = self.post_v2(
            {"message": "something vegetarian instead", "context": "home",
             "mood": "rushed", "home_feed": home_feed},
            [stream],
        )

        system = mock_client.messages.create.call_args_list[0].kwargs["system"]
        self.assertIn("rushed", system)
        self.assertIn("30 minutes", system)               # mood meaning per §1.3
        self.assertIn("Good evening!", system)            # greeting
        self.assertIn("hero_suggestion", system)          # module_type
        self.assertIn("Because you liked pasta", system)  # reason
        self.assertIn("Pesto Gnocchi (ID: 42)", system)   # recipe title/id
        self.assertIn("Miso Soup (ID: 7)", system)

    def test_global_context_uses_taste_summary_not_full_recipe_list(self):
        Recipe.objects.create(created_by=self.user, title="Alice's Secret Lasagna", tags=["italian"])
        stream = text_events(0, "Hi!") + end_of_message("end_turn")
        _, mock_client = self.post_v2({"message": "hello", "context": "global"}, [stream])
        system = mock_client.messages.create.call_args_list[0].kwargs["system"]
        # The full saved-recipe list (with titles) must no longer be embedded —
        # only a compact count + tag summary (catalog-first-pivot.md §2 WS-P2).
        self.assertNotIn("Alice's Secret Lasagna", system)
        self.assertIn("recipe(s) they created/own", system)
        self.assertIn("search_recipes", system)
        self.assertIn("fallback", system.lower())

    def test_invalid_mood_returns_400(self):
        response = self.client.post(V2_URL, {"message": "hi", "mood": "hangry"}, format="json")
        self.assertEqual(response.status_code, 400)

    def test_invalid_context_returns_400(self):
        response = self.client.post(V2_URL, {"message": "hi", "context": "kitchen"}, format="json")
        self.assertEqual(response.status_code, 400)


class ChatV1RegressionTestCase(TestCase):
    """v1 delimiter-protocol endpoint must keep working unchanged."""

    def setUp(self):
        self.user = User.objects.create_user(username="bob", password="pw")
        self.client = APIClient()
        self.client.force_authenticate(user=self.user)

    def test_v1_still_streams_tokens(self):
        with patch("ai_chatbot.api.anthropic.Anthropic") as MockAnthropic:
            mock_client = MockAnthropic.return_value
            stream_cm = MagicMock()
            stream_cm.__enter__.return_value = NS(
                text_stream=iter(["Hello", " world", ' $${"title": "X"}$$'])
            )
            mock_client.messages.stream.return_value = stream_cm

            response = self.client.post(V1_URL, {"query": "hi"}, format="json")
            self.assertEqual(response.status_code, 200)
            body = b"".join(response.streaming_content).decode("utf-8")

        tokens = [
            json.loads(line[len("data: "):])["token"]
            for line in body.split("\n\n") if line.startswith("data: ")
        ]
        self.assertEqual("".join(tokens), 'Hello world $${"title": "X"}$$')

        # v1 persists Conversation + ai ChatHistory as before
        conversation = Conversation.objects.get(user=self.user)
        self.assertEqual(conversation.ai_response, 'Hello world $${"title": "X"}$$')

    def test_v1_requires_query(self):
        response = self.client.post(V1_URL, {}, format="json")
        self.assertEqual(response.status_code, 400)

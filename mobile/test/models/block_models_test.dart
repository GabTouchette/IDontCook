import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:i_cant_cook/models/block/block.dart';
import 'package:i_cant_cook/models/chat_v2_event/chat_v2_event.dart';
import 'package:i_cant_cook/models/home_feed/home_feed.dart';
import 'package:i_cant_cook/models/home_module/home_module.dart';
import 'package:i_cant_cook/models/home_module/module_payloads.dart';
import 'package:i_cant_cook/models/mood/mood.dart';
import 'package:i_cant_cook/models/recipe_summary/recipe_summary.dart';

Map<String, dynamic> decode(String source) =>
    jsonDecode(source) as Map<String, dynamic>;

void main() {
  // ------------------------------------------------------------------
  // §1.1 Block schema
  // ------------------------------------------------------------------
  group('Block (§1.1)', () {
    test('text block parses', () {
      final block = Block.fromJson(decode(
          '{ "block_type": "text", "text": "Here is a **quick** idea." }'));
      expect(block, isA<TextBlock>());
      expect((block as TextBlock).text, 'Here is a **quick** idea.');
    });

    test('recipe block parses RecipeFull with the existing Recipe model', () {
      final block = Block.fromJson(decode('''
        {
          "block_type": "recipe",
          "recipe": {
            "title": "Garlic Butter Pasta",
            "description": "Fast weeknight pasta.",
            "preparation_time": 5,
            "cooking_time": 15,
            "servings": 2,
            "ingredients": [
              {"name": "spaghetti", "quantity": 200, "unit": "g"},
              {"name": "garlic", "quantity": 3, "unit": "cloves"}
            ],
            "instructions": ["Boil pasta.", "Toss with garlic butter."],
            "tags": ["quick", "pasta"]
          }
        }
      '''));
      expect(block, isA<RecipeBlock>());
      final recipe = (block as RecipeBlock).recipe;
      expect(recipe.title, 'Garlic Butter Pasta');
      expect(recipe.ingredients.length, 2);
      expect(recipe.instructions.length, 2);
    });

    test('recipe_ref block parses RecipeSummary', () {
      final block = Block.fromJson(decode('''
        {
          "block_type": "recipe_ref",
          "recipe": {
            "id": 12,
            "title": "Pad Thai",
            "image_url": null,
            "total_time": 25,
            "calories": 540,
            "tags": ["thai"]
          }
        }
      '''));
      expect(block, isA<RecipeRefBlock>());
      final summary = (block as RecipeRefBlock).recipe;
      expect(summary.id, 12);
      expect(summary.title, 'Pad Thai');
      expect(summary.image_url, isNull);
      expect(summary.total_time, 25);
      expect(summary.calories, 540);
      expect(summary.tags, ['thai']);
    });

    test('recipe_update block parses recipe_id and changes', () {
      final block = Block.fromJson(decode('''
        {
          "block_type": "recipe_update",
          "recipe_id": 123,
          "changes": {"title": "Spicier Pad Thai", "cooking_time": 20}
        }
      '''));
      expect(block, isA<RecipeUpdateBlock>());
      final update = block as RecipeUpdateBlock;
      expect(update.recipe_id, 123);
      expect(update.changes['title'], 'Spicier Pad Thai');
      expect(update.changes['cooking_time'], 20);
    });

    test('unknown block_type parses into UnknownBlock, never throws', () {
      final block = Block.fromJson(
          decode('{ "block_type": "hologram", "foo": 1 }'));
      expect(block, isA<UnknownBlock>());
    });

    test('missing block_type parses into UnknownBlock, never throws', () {
      final block = Block.fromJson(decode('{ "text": "orphan" }'));
      expect(block, isA<UnknownBlock>());
    });
  });

  // ------------------------------------------------------------------
  // §1.2 Module schema
  // ------------------------------------------------------------------
  group('HomeModule (§1.2)', () {
    test('module block with hero_suggestion payload parses', () {
      final block = Block.fromJson(decode('''
        {
          "block_type": "module",
          "module": {
            "id": "hero-812",
            "module_type": "hero_suggestion",
            "reason": "Quick dinner for a busy weeknight",
            "payload": {
              "recipe": {
                "id": 812,
                "title": "15-Minute Garlic Noodles",
                "image_url": "https://cdn.example.com/812.jpg",
                "total_time": 15,
                "calories": 520,
                "tags": ["quick", "asian"]
              },
              "tagline": "Fast, savory, zero stress"
            }
          }
        }
      '''));
      expect(block, isA<ModuleBlock>());
      final module = (block as ModuleBlock).module;
      expect(module.id, 'hero-812');
      expect(module.moduleType, 'hero_suggestion');
      expect(module.reason, 'Quick dinner for a busy weeknight');
      expect(module.isKnownType, isTrue);
      final payload = module.payload as HeroSuggestionPayload;
      expect(payload.recipe.id, 812);
      expect(payload.tagline, 'Fast, savory, zero stress');
    });

    test('all nine module_type payloads parse into their typed classes', () {
      final cases = <String, Map<String, dynamic>>{
        'hero_suggestion': {
          'recipe': {'id': 1, 'title': 'A'},
          'tagline': 't',
        },
        'cook_again': {
          'recipe': {'id': 2, 'title': 'B'},
          'saved_at': '2026-07-10T18:30:00Z',
        },
        'friend_post': {
          'post_id': 7,
          'author': {'id': 3, 'username': 'sam', 'avatar_url': null},
          'recipe': null,
          'preview_text': 'Made this tonight!',
          'created_at': '2026-07-15T09:00:00Z',
        },
        'meal_plan_nudge': {
          'week_start': '2026-07-13',
          'planned_days': 2,
          'cta': 'Plan your week',
        },
        'grocery_shortcut': {'item_count': 9, 'cta': 'Open grocery list'},
        'chat_prompt': {'prompt_text': 'Something vegetarian tonight?'},
        'explore_rail': {
          'title': 'Fresh picks',
          'recipes': [
            {'id': 4, 'title': 'C'},
            {'id': 5, 'title': 'D'},
            {'id': 6, 'title': 'E'},
          ],
        },
        'event_card': {
          'event_slug': 'soup-week',
          'title': 'Soup week',
          'body': 'Seven soups, seven days.',
          'image_url': null,
          'cta': 'See the soups',
          'recipes': <Map<String, dynamic>>[],
        },
        'mood_question': {
          'question': "What's the vibe tonight?",
          'options': [
            {'mood': 'rushed', 'label': 'Rushed', 'emoji': '⏱️'},
            {'mood': 'comfort', 'label': 'Comfort', 'emoji': '🍜'},
          ],
        },
      };
      cases.forEach((moduleType, payload) {
        final module = HomeModule.fromJson({
          'id': 'm-$moduleType',
          'module_type': moduleType,
          'reason': 'because',
          'payload': payload,
        });
        expect(module.isKnownType, isTrue,
            reason: '$moduleType should parse into a typed payload');
        expect(module.payload, isA<ModulePayload>());
        expect(
          _payloadMatchesType(module.payload, moduleType),
          isTrue,
          reason: '$moduleType parsed into ${module.payload.runtimeType}',
        );
      });
    });

    test('friend_post payload fields parse (author, created_at)', () {
      final module = HomeModule.fromJson(decode('''
        {
          "id": "fp-7",
          "module_type": "friend_post",
          "reason": "sam posted a recipe",
          "payload": {
            "post_id": 7,
            "author": {"id": 3, "username": "sam", "avatar_url": null},
            "recipe": {"id": 9, "title": "Ramen", "image_url": null,
                       "total_time": 40, "calories": 610, "tags": []},
            "preview_text": "Made this tonight!",
            "created_at": "2026-07-15T09:00:00Z"
          }
        }
      '''));
      final payload = module.payload as FriendPostPayload;
      expect(payload.post_id, 7);
      expect(payload.author.username, 'sam');
      expect(payload.recipe!.title, 'Ramen');
      expect(payload.created_at, DateTime.utc(2026, 7, 15, 9));
    });

    test('mood_question options resolve moods; unknown mood → null', () {
      final module = HomeModule.fromJson(decode('''
        {
          "id": "mood-1",
          "module_type": "mood_question",
          "reason": "no mood set this session",
          "payload": {
            "question": "What's the vibe tonight?",
            "options": [
              {"mood": "rushed", "label": "Rushed", "emoji": "⏱️"},
              {"mood": "cooking_for_someone", "label": "Date night", "emoji": "🥂"},
              {"mood": "existential_dread", "label": "???", "emoji": "🌀"}
            ]
          }
        }
      '''));
      final payload = module.payload as MoodQuestionPayload;
      expect(payload.options.length, 3);
      expect(payload.options[0].moodValue, Mood.rushed);
      expect(payload.options[1].moodValue, Mood.cookingForSomeone);
      expect(payload.options[2].moodValue, isNull,
          reason: 'unknown mood must not throw');
    });

    test('unknown module_type parses into UnknownModulePayload, never throws',
        () {
      final module = HomeModule.fromJson(decode(
          '{"id": "x-1", "module_type": "vr_kitchen", "reason": "?", '
          '"payload": {"anything": true}}'));
      expect(module.moduleType, 'vr_kitchen');
      expect(module.isKnownType, isFalse);
      expect(module.payload, isA<UnknownModulePayload>());
      expect((module.payload as UnknownModulePayload).raw['anything'], true);
    });

    test('malformed payload for a known type degrades to unknown, no throw',
        () {
      final module = HomeModule.fromJson(decode(
          '{"id": "hero-bad", "module_type": "hero_suggestion", '
          '"reason": "r", "payload": {"recipe": "not-an-object"}}'));
      expect(module.payload, isA<UnknownModulePayload>());
    });

    test('toJson round-trips the wire shape', () {
      final json = decode(
          '{"id": "cp-1", "module_type": "chat_prompt", "reason": "r", '
          '"payload": {"prompt_text": "Ideas for lunch?"}}');
      final module = HomeModule.fromJson(json);
      expect(module.toJson(), json);
    });
  });

  // ------------------------------------------------------------------
  // §1.3 Mood taxonomy
  // ------------------------------------------------------------------
  group('Mood (§1.3)', () {
    test('wire values match the locked taxonomy', () {
      expect(Mood.values.map((m) => m.wireValue), [
        'rushed',
        'ambitious',
        'cooking_for_someone',
        'comfort',
        'healthy',
        'surprise_me',
      ]);
    });

    test('fromWire is tolerant', () {
      expect(Mood.fromWire('surprise_me'), Mood.surpriseMe);
      expect(Mood.fromWire('vibing'), isNull);
      expect(Mood.fromWire(null), isNull);
    });
  });

  // ------------------------------------------------------------------
  // §1.5 Home feed endpoint
  // ------------------------------------------------------------------
  group('HomeFeed (§1.5)', () {
    test('feed response parses: feed_id, context, greeting, blocks', () {
      final feed = HomeFeed.fromJson(decode('''
        {
          "feed_id": "3f2c9e2e-8a11-4a44-9b99-abcdefabcdef",
          "context": { "daypart": "evening", "is_weekend": false, "mood": "rushed" },
          "greeting": "Long day? Let's keep dinner easy.",
          "blocks": [
            { "block_type": "text", "text": "Long day? Let's keep dinner easy." },
            {
              "block_type": "module",
              "module": {
                "id": "hero-812",
                "module_type": "hero_suggestion",
                "reason": "Quick dinner for a busy weeknight",
                "payload": {
                  "recipe": {"id": 812, "title": "15-Minute Garlic Noodles",
                             "image_url": null, "total_time": 15,
                             "calories": 520, "tags": ["quick"]},
                  "tagline": "Fast, savory, zero stress"
                }
              }
            },
            {
              "block_type": "module",
              "module": {
                "id": "mood-1",
                "module_type": "mood_question",
                "reason": "no mood set",
                "payload": {
                  "question": "What's the vibe tonight?",
                  "options": [
                    {"mood": "rushed", "label": "Rushed", "emoji": "⏱️"}
                  ]
                }
              }
            },
            { "block_type": "hologram", "beam": "up" },
            {
              "block_type": "module",
              "module": {
                "id": "x-1",
                "module_type": "vr_kitchen",
                "reason": "?",
                "payload": {}
              }
            }
          ]
        }
      '''));

      expect(feed.feed_id, '3f2c9e2e-8a11-4a44-9b99-abcdefabcdef');
      expect(feed.context.daypart, 'evening');
      expect(feed.context.is_weekend, isFalse);
      expect(feed.context.moodValue, Mood.rushed);
      expect(feed.greeting, "Long day? Let's keep dinner easy.");
      expect(feed.blocks.length, 5, reason: 'nothing thrown, nothing lost');
      expect(feed.blocks[0], isA<TextBlock>());
      expect(feed.blocks[3], isA<UnknownBlock>());

      final renderable = feed.renderableBlocks;
      expect(renderable.length, 3,
          reason: 'unknown block + unknown module are skipped');
      expect(renderable[0], isA<TextBlock>());
      expect(renderable[1], isA<ModuleBlock>());
      expect(renderable[2], isA<ModuleBlock>());
    });

    test('context without mood resolves to null mood', () {
      final context = HomeFeedContext.fromJson(
          decode('{ "daypart": "morning", "is_weekend": true, "mood": null }'));
      expect(context.moodValue, isNull);
      expect(context.is_weekend, isTrue);
    });
  });

  // ------------------------------------------------------------------
  // §1.6 Chat SSE protocol v2
  // ------------------------------------------------------------------
  group('ChatV2Event (§1.6)', () {
    test('message_start carries conversation_id', () {
      final event = ChatV2Event.fromJson(
          decode('{ "type": "message_start", "conversation_id": 123 }'));
      expect(event, isA<ChatV2MessageStart>());
      expect((event as ChatV2MessageStart).conversation_id, 123);
    });

    test('text_delta carries text', () {
      final event = ChatV2Event.fromJson(
          decode('{ "type": "text_delta", "text": "Here you go" }'));
      expect(event, isA<ChatV2TextDelta>());
      expect((event as ChatV2TextDelta).text, 'Here you go');
    });

    test('block event carries a typed Block', () {
      final event = ChatV2Event.fromJson(decode('''
        {
          "type": "block",
          "block": {
            "block_type": "recipe_ref",
            "recipe": {"id": 12, "title": "Pad Thai", "image_url": null,
                       "total_time": 25, "calories": 540, "tags": []}
          }
        }
      '''));
      expect(event, isA<ChatV2BlockEvent>());
      final block = (event as ChatV2BlockEvent).block;
      expect(block, isA<RecipeRefBlock>());
    });

    test('tool_activity carries the tool name (plan §1.3)', () {
      final event = ChatV2Event.fromJson(
          decode('{ "type": "tool_activity", "tool": "search_recipes" }'));
      expect(event, isA<ChatV2ToolActivity>());
      expect((event as ChatV2ToolActivity).tool, 'search_recipes');
    });

    test('error and done parse', () {
      expect(
          ChatV2Event.fromJson(
              decode('{ "type": "error", "message": "boom" }')),
          isA<ChatV2Error>());
      expect(ChatV2Event.fromJson(decode('{ "type": "done" }')),
          isA<ChatV2Done>());
    });

    test('unknown event type parses into ChatV2Unknown, never throws', () {
      final event =
          ChatV2Event.fromJson(decode('{ "type": "telemetry", "x": 1 }'));
      expect(event, isA<ChatV2Unknown>());
    });
  });

  // ------------------------------------------------------------------
  // RecipeSummary (§1.1)
  // ------------------------------------------------------------------
  group('RecipeSummary (§1.1)', () {
    test('tags default to empty when absent', () {
      final summary =
          RecipeSummary.fromJson(decode('{"id": 1, "title": "Toast"}'));
      expect(summary.tags, isEmpty);
      expect(summary.image_url, isNull);
      expect(summary.total_time, isNull);
      expect(summary.calories, isNull);
    });
  });
}

bool _payloadMatchesType(ModulePayload payload, String moduleType) {
  switch (moduleType) {
    case 'hero_suggestion':
      return payload is HeroSuggestionPayload;
    case 'cook_again':
      return payload is CookAgainPayload;
    case 'friend_post':
      return payload is FriendPostPayload;
    case 'meal_plan_nudge':
      return payload is MealPlanNudgePayload;
    case 'grocery_shortcut':
      return payload is GroceryShortcutPayload;
    case 'chat_prompt':
      return payload is ChatPromptPayload;
    case 'explore_rail':
      return payload is ExploreRailPayload;
    case 'event_card':
      return payload is EventCardPayload;
    case 'mood_question':
      return payload is MoodQuestionPayload;
    default:
      return false;
  }
}

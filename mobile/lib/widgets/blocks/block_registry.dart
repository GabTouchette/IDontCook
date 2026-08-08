import 'package:flutter/material.dart';
import 'package:i_cant_cook/models/block/block.dart';
import 'package:i_cant_cook/models/home_module/home_module.dart';
import 'package:i_cant_cook/models/home_module/module_payloads.dart';
import 'package:i_cant_cook/models/mood/mood.dart';
import 'package:i_cant_cook/widgets/blocks/chat_prompt_chip.dart';
import 'package:i_cant_cook/widgets/blocks/cook_again_card.dart';
import 'package:i_cant_cook/widgets/blocks/event_card.dart';
import 'package:i_cant_cook/widgets/blocks/explore_rail.dart';
import 'package:i_cant_cook/widgets/blocks/friend_post_card.dart';
import 'package:i_cant_cook/widgets/blocks/grocery_shortcut_card.dart';
import 'package:i_cant_cook/widgets/blocks/hero_suggestion_card.dart';
import 'package:i_cant_cook/widgets/blocks/meal_plan_nudge_card.dart';
import 'package:i_cant_cook/widgets/blocks/mood_question_card.dart';
import 'package:i_cant_cook/widgets/blocks/recipe_ref_row.dart';
import 'package:i_cant_cook/widgets/blocks/recipe_update_card.dart';
import 'package:i_cant_cook/widgets/blocks/text_block_bubble.dart';
import 'package:i_cant_cook/widgets/chatbot/recipe_card.dart';

/// Interaction callbacks a block surface (chat thread, home feed) can wire
/// into interactive module cards. Wave 2 connects these to sending a chat
/// message (`chat_prompt`) and to re-fetching the feed (`mood_question`).
class BlockCallbacks {
  /// `chat_prompt` tap — receives the payload's `prompt_text`, to be sent
  /// as a user chat message.
  final void Function(String promptText)? onChatPromptTap;

  /// `mood_question` selection — receives the chosen [Mood].
  final void Function(Mood mood)? onMoodSelected;

  /// CTA tap on a `meal_plan_nudge`, `grocery_shortcut`, or `event_card`
  /// module — receives the whole [HomeModule] so the surface can route on
  /// `module.moduleType` (e.g. open meal plan, open grocery list, open the
  /// event's recipes).
  final void Function(HomeModule module)? onModuleCtaTap;

  /// The mood pill the surface has optimistically marked as selected (set
  /// synchronously on tap, before the feed refetch resolves) — lets
  /// `MoodQuestionCard` show immediate tap feedback instead of waiting on
  /// the network round trip. Null when no mood is pending selection.
  final Mood? selectedMood;

  const BlockCallbacks({
    this.onChatPromptTap,
    this.onMoodSelected,
    this.onModuleCtaTap,
    this.selectedMood,
  });

  static const BlockCallbacks none = BlockCallbacks();
}

/// Builds a widget for one [Block], given the surface's [BlockCallbacks].
typedef BlockWidgetBuilder = Widget Function(
    BuildContext context, Block block, BlockCallbacks callbacks);

/// Maps typed [Block]s (plan §1.1) to their renderers.
///
/// Unknown block types, unknown module types, and module types without a
/// Wave-1 renderer all render as `SizedBox.shrink()` — never an error
/// (plan §1.2 forward-compat rule).
class BlockRegistry {
  BlockRegistry._();

  /// Renderers keyed by `block_type`. A missing key renders as nothing, so
  /// Wave 2 can extend this map without touching call sites.
  static final Map<String, BlockWidgetBuilder> builders =
      <String, BlockWidgetBuilder>{
    'text': (context, block, callbacks) =>
        TextBlockBubble(text: (block as TextBlock).text),
    'recipe': (context, block, callbacks) =>
        RecipeCard(recipe: (block as RecipeBlock).recipe),
    'recipe_ref': (context, block, callbacks) =>
        RecipeRefRow(recipe: (block as RecipeRefBlock).recipe),
    'recipe_update': (context, block, callbacks) {
      final update = block as RecipeUpdateBlock;
      return RecipeUpdateCard(
        recipeId: update.recipe_id,
        changes: update.changes,
      );
    },
    'module': (context, block, callbacks) =>
        buildModule(context, (block as ModuleBlock).module, callbacks),
  };

  /// Builds the widget for [block]. Main entry point for block surfaces.
  static Widget build(
    BuildContext context,
    Block block, {
    BlockCallbacks callbacks = BlockCallbacks.none,
  }) {
    final builder = builders[_blockTypeKey(block)];
    if (builder == null) return const SizedBox.shrink();
    return builder(context, block, callbacks);
  }

  /// Builds the card for a home-feed [module]. All plan §1.2 module types
  /// have renderers: `hero_suggestion`, `chat_prompt`, `mood_question`,
  /// `explore_rail`, `cook_again`, `friend_post`, `meal_plan_nudge`,
  /// `grocery_shortcut`, `event_card`. Unknown module types render as
  /// nothing (forward-compat rule).
  static Widget buildModule(
    BuildContext context,
    HomeModule module, [
    BlockCallbacks callbacks = BlockCallbacks.none,
  ]) {
    final payload = module.payload;
    if (payload is HeroSuggestionPayload) {
      return HeroSuggestionCard(payload: payload, reason: module.reason);
    }
    if (payload is ChatPromptPayload) {
      return ChatPromptChip(
        payload: payload,
        onTap: callbacks.onChatPromptTap,
      );
    }
    if (payload is MoodQuestionPayload) {
      return MoodQuestionCard(
        payload: payload,
        onMoodSelected: callbacks.onMoodSelected,
        selectedMood: callbacks.selectedMood,
      );
    }
    if (payload is ExploreRailPayload) {
      return ExploreRail(payload: payload);
    }
    if (payload is CookAgainPayload) {
      return CookAgainCard(payload: payload, reason: module.reason);
    }
    if (payload is FriendPostPayload) {
      return FriendPostCard(payload: payload, reason: module.reason);
    }
    if (payload is MealPlanNudgePayload) {
      return MealPlanNudgeCard(
        module: module,
        onCtaTap: callbacks.onModuleCtaTap,
      );
    }
    if (payload is GroceryShortcutPayload) {
      return GroceryShortcutCard(
        module: module,
        onCtaTap: callbacks.onModuleCtaTap,
      );
    }
    if (payload is EventCardPayload) {
      return EventCard(module: module, onCtaTap: callbacks.onModuleCtaTap);
    }
    // Unknown module types → forward-compat skip.
    return const SizedBox.shrink();
  }

  static String _blockTypeKey(Block block) => block.map(
        text: (_) => 'text',
        recipe: (_) => 'recipe',
        recipeRef: (_) => 'recipe_ref',
        recipeUpdate: (_) => 'recipe_update',
        module: (_) => 'module',
        unknown: (_) => 'unknown',
      );
}

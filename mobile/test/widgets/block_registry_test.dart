import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/block/block.dart';
import 'package:i_cant_cook/models/home_module/home_module.dart';
import 'package:i_cant_cook/models/home_module/module_payloads.dart';
import 'package:i_cant_cook/models/mood/mood.dart';
import 'package:i_cant_cook/models/recipe_summary/recipe_summary.dart';
import 'package:i_cant_cook/widgets/blocks/block_registry.dart';
import 'package:i_cant_cook/widgets/blocks/chat_prompt_chip.dart';
import 'package:i_cant_cook/widgets/blocks/hero_suggestion_card.dart';
import 'package:i_cant_cook/widgets/blocks/mood_question_card.dart';
import 'package:i_cant_cook/widgets/blocks/text_block_bubble.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('BlockRegistry', () {
    testWidgets('text block renders a markdown bubble', (tester) async {
      await tester.pumpWidget(_host(Builder(
        builder: (context) => BlockRegistry.build(
            context, const Block.text(text: 'Hello **there**')),
      )));
      expect(find.byType(TextBlockBubble), findsOneWidget);
    });

    testWidgets('unknown block renders nothing', (tester) async {
      await tester.pumpWidget(_host(Builder(
        builder: (context) =>
            BlockRegistry.build(context, const Block.unknown()),
      )));
      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byType(TextBlockBubble), findsNothing);
    });

    testWidgets('unknown module renders nothing', (tester) async {
      const block = Block.module(
        module: HomeModule(
          id: 'x-1',
          moduleType: 'vr_kitchen',
          payload: UnknownModulePayload(),
        ),
      );
      await tester.pumpWidget(_host(Builder(
        builder: (context) => BlockRegistry.build(context, block),
      )));
      expect(find.byType(HeroSuggestionCard), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('hero_suggestion module renders title, tagline and reason',
        (tester) async {
      const block = Block.module(
        module: HomeModule(
          id: 'hero-812',
          moduleType: 'hero_suggestion',
          reason: 'Quick dinner for a busy weeknight',
          payload: HeroSuggestionPayload(
            recipe: RecipeSummary(
              id: 812,
              title: '15-Minute Garlic Noodles',
              total_time: 15,
              calories: 520,
            ),
            tagline: 'Fast, savory, zero stress',
          ),
        ),
      );
      await tester.pumpWidget(_host(Builder(
        builder: (context) => BlockRegistry.build(context, block),
      )));
      expect(find.byType(HeroSuggestionCard), findsOneWidget);
      expect(find.text('15-Minute Garlic Noodles'), findsOneWidget);
      expect(find.text('Quick dinner for a busy weeknight'), findsOneWidget);
      expect(find.text('15 min'), findsOneWidget);
      expect(find.text('520 cal'), findsOneWidget);
    });

    testWidgets('chat_prompt chip fires onChatPromptTap with prompt_text',
        (tester) async {
      const block = Block.module(
        module: HomeModule(
          id: 'cp-1',
          moduleType: 'chat_prompt',
          payload: ChatPromptPayload(prompt_text: 'Something vegetarian?'),
        ),
      );
      String? tapped;
      await tester.pumpWidget(_host(Builder(
        builder: (context) => BlockRegistry.build(
          context,
          block,
          callbacks:
              BlockCallbacks(onChatPromptTap: (text) => tapped = text),
        ),
      )));
      await tester.tap(find.byType(ChatPromptChip));
      expect(tapped, 'Something vegetarian?');
    });

    testWidgets('mood_question fires onMoodSelected and skips unknown moods',
        (tester) async {
      const block = Block.module(
        module: HomeModule(
          id: 'mood-1',
          moduleType: 'mood_question',
          payload: MoodQuestionPayload(
            question: "What's the vibe tonight?",
            options: [
              MoodOption(mood: 'comfort', label: 'Comfort', emoji: '🍜'),
              MoodOption(mood: 'not_a_mood', label: 'Mystery', emoji: '🌀'),
            ],
          ),
        ),
      );
      Mood? selected;
      await tester.pumpWidget(_host(Builder(
        builder: (context) => BlockRegistry.build(
          context,
          block,
          callbacks: BlockCallbacks(onMoodSelected: (mood) => selected = mood),
        ),
      )));
      expect(find.byType(MoodQuestionCard), findsOneWidget);
      expect(find.text('Mystery'), findsNothing,
          reason: 'options with unknown moods are skipped');
      await tester.tap(find.text('Comfort'));
      expect(selected, Mood.comfort);
    });

    testWidgets('explore_rail renders one tile per recipe', (tester) async {
      const block = Block.module(
        module: HomeModule(
          id: 'rail-1',
          moduleType: 'explore_rail',
          payload: ExploreRailPayload(
            title: 'Fresh picks',
            recipes: [
              RecipeSummary(id: 1, title: 'Shakshuka'),
              RecipeSummary(id: 2, title: 'Bibimbap'),
              RecipeSummary(id: 3, title: 'Minestrone'),
            ],
          ),
        ),
      );
      await tester.pumpWidget(_host(Builder(
        builder: (context) => BlockRegistry.build(context, block),
      )));
      expect(find.text('Fresh picks'), findsOneWidget);
      expect(find.text('Shakshuka'), findsOneWidget);
      expect(find.text('Bibimbap'), findsOneWidget);
      expect(find.text('Minestrone'), findsOneWidget);
    });
  });
}

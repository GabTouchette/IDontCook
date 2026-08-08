import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/block/block.dart';
import 'package:i_cant_cook/models/home_module/home_module.dart';
import 'package:i_cant_cook/models/home_module/module_payloads.dart';
import 'package:i_cant_cook/models/recipe_summary/recipe_summary.dart';
import 'package:i_cant_cook/widgets/blocks/block_registry.dart';
import 'package:i_cant_cook/widgets/blocks/cook_again_card.dart';
import 'package:i_cant_cook/widgets/blocks/event_card.dart';
import 'package:i_cant_cook/widgets/blocks/friend_post_card.dart';
import 'package:i_cant_cook/widgets/blocks/grocery_shortcut_card.dart';
import 'package:i_cant_cook/widgets/blocks/meal_plan_nudge_card.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('cook_again_card', () {
    testWidgets('renders title, saved-ago label and reason from fixture JSON',
        (tester) async {
      final module = HomeModule.fromJson(<String, dynamic>{
        'id': 'cook-again-1',
        'module_type': 'cook_again',
        'reason': "You haven't made this in a while",
        'payload': <String, dynamic>{
          'recipe': <String, dynamic>{
            'id': 42,
            'title': 'Weeknight Chili',
            'image_url': null,
            'total_time': 40,
            'calories': 610,
            'tags': <String>[],
          },
          'saved_at':
              DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
        },
      });
      final block = Block.module(module: module);

      await tester.pumpWidget(_host(Builder(
        builder: (context) => BlockRegistry.build(context, block),
      )));

      expect(find.byType(CookAgainCard), findsOneWidget);
      expect(find.text('Weeknight Chili'), findsOneWidget);
      expect(find.textContaining('SAVED'), findsOneWidget);
      expect(
        find.textContaining("You haven't made this in a while"),
        findsOneWidget,
        reason: 'reason line now carries a leading contextual emoji badge',
      );
    });

    testWidgets('renders with null saved_at and no reason', (tester) async {
      const block = Block.module(
        module: HomeModule(
          id: 'cook-again-2',
          moduleType: 'cook_again',
          payload: CookAgainPayload(
            recipe: RecipeSummary(id: 1, title: 'Plain Soup'),
          ),
        ),
      );
      await tester.pumpWidget(_host(Builder(
        builder: (context) => BlockRegistry.build(context, block),
      )));
      expect(find.byType(CookAgainCard), findsOneWidget);
      expect(find.text('Plain Soup'), findsOneWidget);
    });
  });

  group('friend_post_card', () {
    testWidgets('renders author initial fallback, preview text and recipe',
        (tester) async {
      final module = HomeModule.fromJson(<String, dynamic>{
        'id': 'fp-1',
        'module_type': 'friend_post',
        'payload': <String, dynamic>{
          'post_id': 9,
          'author': <String, dynamic>{
            'id': 5,
            'username': 'maya',
            'avatar_url': null,
          },
          'recipe': <String, dynamic>{
            'id': 100,
            'title': 'Miso Ramen',
          },
          'preview_text': 'Made this for dinner tonight!',
          'created_at':
              DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        },
      });
      final block = Block.module(module: module);

      await tester.pumpWidget(_host(Builder(
        builder: (context) => BlockRegistry.build(context, block),
      )));

      expect(find.byType(FriendPostCard), findsOneWidget);
      expect(find.text('maya'), findsOneWidget);
      expect(find.text('M'), findsOneWidget); // avatar fallback initial
      expect(find.text('Made this for dinner tonight!'), findsOneWidget);
      expect(find.text('Miso Ramen'), findsOneWidget);
      expect(find.textContaining('ago'), findsOneWidget);
    });

    testWidgets('renders with null recipe and empty username',
        (tester) async {
      const block = Block.module(
        module: HomeModule(
          id: 'fp-2',
          moduleType: 'friend_post',
          payload: FriendPostPayload(
            post_id: 1,
            author: PostAuthor(id: 2, username: ''),
          ),
        ),
      );
      await tester.pumpWidget(_host(Builder(
        builder: (context) => BlockRegistry.build(context, block),
      )));
      expect(find.byType(FriendPostCard), findsOneWidget);
      expect(find.text('Someone'), findsOneWidget);
      expect(find.text('?'), findsOneWidget);
    });
  });

  group('meal_plan_nudge_card', () {
    testWidgets('renders week framing and fires onModuleCtaTap',
        (tester) async {
      final module = HomeModule.fromJson(<String, dynamic>{
        'id': 'nudge-1',
        'module_type': 'meal_plan_nudge',
        'payload': <String, dynamic>{
          'week_start': '2026-07-14',
          'planned_days': 0,
          'cta': 'Plan your week',
        },
      });
      final block = Block.module(module: module);
      HomeModule? tapped;

      await tester.pumpWidget(_host(Builder(
        builder: (context) => BlockRegistry.build(
          context,
          block,
          callbacks: BlockCallbacks(onModuleCtaTap: (m) => tapped = m),
        ),
      )));

      expect(find.byType(MealPlanNudgeCard), findsOneWidget);
      expect(find.text('0 of 7 days planned'), findsOneWidget);
      expect(find.text('Week of Jul 14'), findsOneWidget);
      expect(find.text('Plan your week'), findsOneWidget);

      await tester.tap(find.text('Plan your week'));
      expect(tapped?.id, 'nudge-1');
    });

    testWidgets('renders with defaults when fields are empty/zero',
        (tester) async {
      const block = Block.module(
        module: HomeModule(
          id: 'nudge-2',
          moduleType: 'meal_plan_nudge',
          payload: MealPlanNudgePayload(),
        ),
      );
      await tester.pumpWidget(_host(Builder(
        builder: (context) => BlockRegistry.build(context, block),
      )));
      expect(find.byType(MealPlanNudgeCard), findsOneWidget);
      expect(find.text('0 of 7 days planned'), findsOneWidget);
      expect(find.text('This week'), findsOneWidget);
    });
  });

  group('grocery_shortcut_card', () {
    testWidgets('renders item count and fires onModuleCtaTap',
        (tester) async {
      final module = HomeModule.fromJson(<String, dynamic>{
        'id': 'grocery-1',
        'module_type': 'grocery_shortcut',
        'payload': <String, dynamic>{
          'item_count': 12,
          'cta': 'View list',
        },
      });
      final block = Block.module(module: module);
      HomeModule? tapped;

      await tester.pumpWidget(_host(Builder(
        builder: (context) => BlockRegistry.build(
          context,
          block,
          callbacks: BlockCallbacks(onModuleCtaTap: (m) => tapped = m),
        ),
      )));

      expect(find.byType(GroceryShortcutCard), findsOneWidget);
      expect(find.text('12 items'), findsOneWidget);
      expect(find.text('View list'), findsOneWidget);

      await tester.tap(find.byType(GroceryShortcutCard));
      expect(tapped?.id, 'grocery-1');
    });

    testWidgets('singularizes item count and renders without cta',
        (tester) async {
      const block = Block.module(
        module: HomeModule(
          id: 'grocery-2',
          moduleType: 'grocery_shortcut',
          payload: GroceryShortcutPayload(item_count: 1),
        ),
      );
      await tester.pumpWidget(_host(Builder(
        builder: (context) => BlockRegistry.build(context, block),
      )));
      expect(find.text('1 item'), findsOneWidget);
    });
  });

  group('event_card', () {
    testWidgets('renders title, body, recipe rail and fires onModuleCtaTap',
        (tester) async {
      final module = HomeModule.fromJson(<String, dynamic>{
        'id': 'event-1',
        'module_type': 'event_card',
        'payload': <String, dynamic>{
          'event_slug': 'soup-week',
          'title': 'Soup Week',
          'body': 'Five friends cooked soup this week.',
          'image_url': null,
          'cta': 'See soup recipes',
          'recipes': [
            <String, dynamic>{'id': 1, 'title': 'Tomato Soup'},
            <String, dynamic>{'id': 2, 'title': 'Lentil Soup'},
          ],
        },
      });
      final block = Block.module(module: module);
      HomeModule? tapped;

      await tester.pumpWidget(_host(Builder(
        builder: (context) => BlockRegistry.build(
          context,
          block,
          callbacks: BlockCallbacks(onModuleCtaTap: (m) => tapped = m),
        ),
      )));

      expect(find.byType(EventCard), findsOneWidget);
      expect(find.text('SOUP WEEK'), findsOneWidget);
      expect(find.text('Five friends cooked soup this week.'), findsOneWidget);
      expect(find.text('Tomato Soup'), findsOneWidget);
      expect(find.text('Lentil Soup'), findsOneWidget);
      expect(find.text('See soup recipes'), findsOneWidget);

      await tester.tap(find.text('See soup recipes'));
      expect(tapped?.id, 'event-1');
    });

    testWidgets('renders with no recipes, no image and no cta',
        (tester) async {
      const block = Block.module(
        module: HomeModule(
          id: 'event-2',
          moduleType: 'event_card',
          payload: EventCardPayload(
            event_slug: 'mystery',
            title: 'Mystery Event',
            body: 'Something is happening.',
          ),
        ),
      );
      await tester.pumpWidget(_host(Builder(
        builder: (context) => BlockRegistry.build(context, block),
      )));
      expect(find.byType(EventCard), findsOneWidget);
      expect(find.text('MYSTERY EVENT'), findsOneWidget);
      expect(find.text('Something is happening.'), findsOneWidget);
    });
  });
}

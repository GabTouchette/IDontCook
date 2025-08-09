import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:i_cant_cook/providers/meal_plan_provider.dart';
import 'package:i_cant_cook/widgets/meal_planning/weekly_calendar_widget.dart';
import 'package:i_cant_cook/widgets/meal_planning/meal_slot_widget.dart';
import 'package:i_cant_cook/pages/meal_plan_generator_page.dart';
import 'package:i_cant_cook/pages/meal_selector_page.dart';
import 'package:i_cant_cook/pages/manual_planning_page.dart';

class MealPlanPage extends StatelessWidget {
  const MealPlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: const SizedBox.shrink(),
        title: Text(
          'Meal Plans',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w900,
            fontSize: 28,
            letterSpacing: -0.5,
          ),
        ),
      ),
      floatingActionButton: Consumer<MealPlanProvider>(
        builder: (_, mp, __) => mp.activeMealPlan == null
            ? const SizedBox.shrink()
            : FloatingActionButton.extended(
                onPressed: () async {
                  await mp.buildGroceryList();
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const _GroceryListPage()),
                  );
                },
                backgroundColor: Theme.of(context).colorScheme.primary,
                label: Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined,
                        color: Colors.white),
                    const SizedBox(width: 8),
                    Text('View Grocery List',
                        style: GoogleFonts.nunito(
                            color: Colors.white, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
      ),
      body: Consumer<MealPlanProvider>(
        builder: (context, mp, child) {
          final weekStart = mp.visibleWeekStart;
          final hasPlan = mp.activeMealPlan != null;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                WeeklyCalendar(
                  weekStart: weekStart,
                  selectedDay: mp.selectedDay,
                  rangeStart: mp.rangeStart,
                  rangeEnd: mp.rangeEnd,
                  onDaySelected: mp.tapDay,
                  onSwipeLeft: mp.nextWeek,
                  onSwipeRight: mp.prevWeek,
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: mp.isGenerating
                              ? null
                              : () async {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const MealPlanGeneratorPage()),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: mp.isGenerating
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary),
                                )
                              : Text('Generate AI Meal Plan',
                                  style: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () {
                          final mp = context.read<MealPlanProvider>();
                          Navigator.of(context).push(PageRouteBuilder(
                            pageBuilder: (_, __, ___) => ManualPlanningPage(
                              initialWeek: mp.visibleWeekStart,
                              preselectedDays:
                                  mp.rangeStart != null && mp.rangeEnd != null
                                      ? List.generate(
                                          mp.rangeEnd! - mp.rangeStart! + 1,
                                          (i) => mp.rangeStart! + i)
                                      : [mp.selectedDay],
                            ),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              final offsetAnimation = Tween(
                                      begin: const Offset(0, 1),
                                      end: Offset.zero)
                                  .animate(CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutCubic));
                              return SlideTransition(
                                  position: offsetAnimation, child: child);
                            },
                          ));
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text('Manual Planning',
                            style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (!hasPlan)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 24),
                    child: Center(
                      child: Text('Start planning your meals!',
                          style: GoogleFonts.nunito(fontSize: 16)),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        MealSlot(
                          label: 'Breakfast',
                          title: _titleFor(mp, 'breakfast'),
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => MealSelectorPage(
                                  dayIndex: mp.selectedDay,
                                  mealType: 'breakfast'),
                            ));
                          },
                          onLongPress: () =>
                              _showSlotActions(context, mp, 'breakfast'),
                        ),
                        const SizedBox(height: 10),
                        MealSlot(
                          label: 'Lunch',
                          title: _titleFor(mp, 'lunch'),
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => MealSelectorPage(
                                  dayIndex: mp.selectedDay, mealType: 'lunch'),
                            ));
                          },
                          onLongPress: () =>
                              _showSlotActions(context, mp, 'lunch'),
                        ),
                        const SizedBox(height: 10),
                        MealSlot(
                          label: 'Dinner',
                          title: _titleFor(mp, 'dinner'),
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => MealSelectorPage(
                                  dayIndex: mp.selectedDay, mealType: 'dinner'),
                            ));
                          },
                          onLongPress: () =>
                              _showSlotActions(context, mp, 'dinner'),
                        ),
                        const SizedBox(height: 10),
                        MealSlot(
                          label: 'Snack',
                          title: _titleFor(mp, 'snack'),
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => MealSelectorPage(
                                  dayIndex: mp.selectedDay, mealType: 'snack'),
                            ));
                          },
                          onLongPress: () =>
                              _showSlotActions(context, mp, 'snack'),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String? _titleFor(MealPlanProvider mp, String mealType) {
    final meals = mp.mealsForDay(mp.selectedDay);
    for (final m in meals) {
      if (m.mealType == mealType) return m.title;
    }
    return null;
  }

  void _showSlotActions(
      BuildContext context, MealPlanProvider mp, String mealType) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Replace'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => MealSelectorPage(
                      dayIndex: mp.selectedDay, mealType: mealType),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart_outlined),
              title: const Text('Add to Grocery List'),
              onTap: () async {
                Navigator.pop(context);
                await mp.buildGroceryList();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Remove'),
              onTap: () {
                Navigator.pop(context);
                mp.removeMeal(mp.selectedDay, mealType);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GroceryListPage extends StatelessWidget {
  const _GroceryListPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text('Grocery List',
            style:
                GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 24)),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<MealPlanProvider>(
        builder: (_, mp, __) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (_, i) {
            final item = mp.groceryList[i];
            return ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.2))),
              tileColor: Theme.of(context).colorScheme.surface,
              leading: Checkbox(
                value: item.purchased,
                onChanged: (_) => mp.togglePurchased(i),
              ),
              title: Text(
                '${item.quantity} ${item.unit ?? ''} ${item.name}',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w700,
                  decoration:
                      item.purchased ? TextDecoration.lineThrough : null,
                ),
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemCount: mp.groceryList.length,
        ),
      ),
    );
  }
}

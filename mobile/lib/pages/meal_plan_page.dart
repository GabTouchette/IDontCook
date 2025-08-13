import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:i_cant_cook/providers/meal_plan_provider.dart';
import 'package:i_cant_cook/widgets/meal_planning/weekly_calendar_widget.dart';
import 'package:i_cant_cook/widgets/meal_planning/meal_slot_widget.dart';
import 'package:i_cant_cook/pages/meal_plan_generator_page.dart';
import 'package:i_cant_cook/pages/manual_planning_page.dart';
import 'package:i_cant_cook/widgets/appbar/appbar_user_menu.dart';
import 'package:i_cant_cook/models/meal_planning/meal_plan.dart';
import 'package:i_cant_cook/pages/plan_library_page.dart';
import 'package:i_cant_cook/pages/templates_page.dart';
import 'package:i_cant_cook/widgets/recipe_browser_list.dart';
import 'package:i_cant_cook/models/recipe_preview/recipe_preview.dart';

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
        actions: [
          Builder(builder: (context) {
            final mp = context.watch<MealPlanProvider>();
            final selected = mp.selectedDaysList;
            return PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                final mp = context.read<MealPlanProvider>();
                switch (value) {
                  case 'copy':
                    _copyFrom(context, mp);
                    break;
                  case 'clear':
                    mp.clearMealsForRange(selected,
                        const ['breakfast', 'lunch', 'dinner', 'snack']);
                    break;
                  case 'templates':
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Templates coming soon')));
                    break;
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'copy',
                  child: const Text('Copy From…'),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: Text('Clear Selected'),
                ),
                const PopupMenuItem(
                  value: 'templates',
                  child: Text('Templates'),
                ),
              ],
            );
          }),
          const UserMenuWidget(),
        ],
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
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: mp.isGenerating
                          ? null
                          : () => _openCreatePlanSheet(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
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
                                  color:
                                      Theme.of(context).colorScheme.onPrimary),
                            )
                          : Text('Plan this week',
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // This Week summary if a plan exists
                if (hasPlan)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildWeekSummary(context, mp),
                  ),
                if (hasPlan) const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Show four slots always; when empty they render as dotted placeholders
                      MealSlot(
                        label: 'Breakfast',
                        title: _titleFor(mp, 'breakfast'),
                        onTap: () {
                          mp.ensureActivePlanForWeek();
                          _openRecipePicker(
                              context, 'breakfast', mp.selectedDay);
                        },
                        onLongPress: () =>
                            _showSlotActions(context, mp, 'breakfast'),
                      ),
                      const SizedBox(height: 10),
                      MealSlot(
                        label: 'Lunch',
                        title: _titleFor(mp, 'lunch'),
                        onTap: () {
                          mp.ensureActivePlanForWeek();
                          _openRecipePicker(context, 'lunch', mp.selectedDay);
                        },
                        onLongPress: () =>
                            _showSlotActions(context, mp, 'lunch'),
                      ),
                      const SizedBox(height: 10),
                      MealSlot(
                        label: 'Dinner',
                        title: _titleFor(mp, 'dinner'),
                        onTap: () {
                          mp.ensureActivePlanForWeek();
                          _openRecipePicker(context, 'dinner', mp.selectedDay);
                        },
                        onLongPress: () =>
                            _showSlotActions(context, mp, 'dinner'),
                      ),
                      const SizedBox(height: 10),
                      MealSlot(
                        label: 'Snack',
                        title: _titleFor(mp, 'snack'),
                        onTap: () {
                          mp.ensureActivePlanForWeek();
                          _openRecipePicker(context, 'snack', mp.selectedDay);
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

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Future<void> _openRecipePicker(
      BuildContext context, String mealType, int dayIndex) async {
    final scheme = Theme.of(context).colorScheme;
    final controller = TextEditingController();
    bool savedOnly = true;
    final List<String> tags = [
      'breakfast',
      'lunch',
      'dinner',
      'dessert',
      'snack'
    ];
    final Set<String> selected = {mealType.toLowerCase()};
    RecipePreview? chosen;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          maxChildSize: 0.95,
          minChildSize: 0.6,
          builder: (ctx, scrollController) {
            return StatefulBuilder(builder: (ctx, setSheetState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.search),
                                hintText: 'Search recipes…',
                              ),
                              onChanged: (_) => setSheetState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Saved only'),
                            selected: savedOnly,
                            onSelected: (v) =>
                                setSheetState(() => savedOnly = v),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 44,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            for (int i = 0; i < tags.length; i++) ...[
                              if (i > 0) const SizedBox(width: 8),
                              Builder(builder: (context) {
                                final t = tags[i];
                                final isSel = selected.contains(t);
                                return ChoiceChip(
                                  label: Text(
                                    _capitalize(t),
                                    style: TextStyle(
                                      fontWeight: isSel
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: isSel
                                          ? scheme.primary
                                          : scheme.onSurfaceVariant,
                                    ),
                                  ),
                                  selected: isSel,
                                  onSelected: (v) => setSheetState(() {
                                    if (v) {
                                      selected.add(t);
                                    } else {
                                      selected.remove(t);
                                    }
                                  }),
                                  shape: const StadiumBorder(),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: const VisualDensity(
                                      horizontal: -2, vertical: -2),
                                  side: BorderSide(
                                      color: scheme.outlineVariant
                                          .withOpacity(0.6)),
                                  backgroundColor: scheme
                                      .surfaceContainerHighest
                                      .withOpacity(0.6),
                                  selectedColor:
                                      scheme.primary.withOpacity(0.12),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: RecipeBrowserList(
                        query: controller.text,
                        savedOnly: savedOnly,
                        includeTags: selected.toList(),
                        selectedId: chosen?.id,
                        onSelect: (r) => setSheetState(() => chosen = r),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: chosen == null
                              ? null
                              : () {
                                  final mp = context.read<MealPlanProvider>();
                                  mp.setMeal(
                                    dayIndex,
                                    mealType,
                                    PlannedMeal(
                                      dayOfWeek: dayIndex,
                                      mealType: mealType,
                                      recipeId: chosen!.id,
                                      title: chosen!.title,
                                      thumbnailUrl: chosen!.thumbnail_url,
                                      servings: 1,
                                    ),
                                  );
                                  Navigator.pop(ctx);
                                },
                          child: const Text('Add to plan'),
                        ),
                      ),
                    )
                  ],
                ),
              );
            });
          },
        );
      },
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
                _openRecipePicker(context, mealType, mp.selectedDay);
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

  void _openCreatePlanSheet(BuildContext context) {
    final mp = context.read<MealPlanProvider>();
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
              leading: const Icon(Icons.auto_awesome),
              title: const Text('Generate with AI'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const MealPlanGeneratorPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_calendar),
              title: const Text('Manual planning'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(PageRouteBuilder(
                  pageBuilder: (_, __, ___) => ManualPlanningPage(
                    initialWeek: mp.visibleWeekStart,
                    preselectedDays: mp.selectedDaysList,
                  ),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    final offsetAnimation =
                        Tween(begin: const Offset(0, 1), end: Offset.zero)
                            .animate(CurvedAnimation(
                                parent: animation, curve: Curves.easeOutCubic));
                    return SlideTransition(
                        position: offsetAnimation, child: child);
                  },
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Load existing plan'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PlanLibraryPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.view_module),
              title: const Text('Apply template'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TemplatesPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _copyFrom(BuildContext context, MealPlanProvider mp) async {
    final days = List<int>.generate(7, (i) => i);
    final from = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Copy from which day?'),
        children: days
            .map((d) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, d),
                  child: Text('Day ${d + 1}'),
                ))
            .toList(),
      ),
    );
    if (from == null) return;
    mp.copyDayMeals(from, mp.selectedDaysList, replace: false);
  }

  Widget _buildWeekSummary(BuildContext context, MealPlanProvider mp) {
    final scheme = Theme.of(context).colorScheme;
    final List<PlannedMeal> meals =
        List<PlannedMeal>.from(mp.activeMealPlan?.plannedMeals ?? const []);
    meals.sort((a, b) => a.dayOfWeek != b.dayOfWeek
        ? a.dayOfWeek.compareTo(b.dayOfWeek)
        : _mealTypeOrder(a.mealType).compareTo(_mealTypeOrder(b.mealType)));
    final display = meals.take(6).toList();
    if (display.isEmpty) return const SizedBox.shrink();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This Week',
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 0; i < display.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    _WeekChip(meal: display[i], colorScheme: scheme),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _mealTypeOrder(String mt) {
    switch (mt) {
      case 'breakfast':
        return 0;
      case 'lunch':
        return 1;
      case 'dinner':
        return 2;
      case 'snack':
        return 3;
    }
    return 99;
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

class _WeekChip extends StatelessWidget {
  final PlannedMeal meal;
  final ColorScheme colorScheme;
  const _WeekChip({required this.meal, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: _thumb(meal.thumbnailUrl),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_capitalize(meal.mealType),
                  style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant)),
              SizedBox(
                width: 140,
                child: Text(meal.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w800, fontSize: 14)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _thumb(String? url) {
    final placeholder = Container(
      width: 36,
      height: 36,
      color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
      child: const Icon(Icons.image_outlined, size: 18),
    );
    if (url == null || url.trim().isEmpty) return placeholder;
    return Image.network(
      url,
      width: 36,
      height: 36,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

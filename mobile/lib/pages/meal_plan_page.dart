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
import 'package:i_cant_cook/pages/recipe_detail_page.dart';
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
          final selectedDays = [...mp.selectedDaysList]..sort();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              WeeklyCalendar(
                weekStart: weekStart,
                selectedDay: mp.selectedDay,
                selectedDays: mp.selectedDays,
                onDaySelected: mp.tapDay,
                onSwipeLeft: mp.nextWeek,
                onSwipeRight: mp.prevWeek,
                weekOffset: mp.weekOffset,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Make a plan button
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        onPressed: mp.isGenerating
                            ? null
                            : () => _openCreatePlanSheet(context),
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
                            : Text('Make a plan',
                                style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Clear button
                    Expanded(
                      flex: 1,
                      child: OutlinedButton.icon(
                        onPressed: mp.isGenerating
                            ? null
                            : () {
                                final selectedDays = [...mp.selectedDaysList];
                                if (selectedDays.isNotEmpty) {
                                  mp.clearMealsForRange(
                                    selectedDays,
                                    ['breakfast', 'lunch', 'dinner', 'snack'],
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Cleared planned meals for selected days'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Please select days to clear'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                        icon: Icon(
                          Icons.clear_all,
                          size: 18,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        label: Text(
                          'Clear',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.error,
                            width: 1.5,
                          ),
                          foregroundColor: Theme.of(context).colorScheme.error,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Scrollable meal slots list grouped by selected days
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: selectedDays.length,
                  itemBuilder: (context, index) {
                    final dayIndex = selectedDays[index];
                    return _DaySection(
                      dayIndex: dayIndex,
                      weekStart: weekStart,
                      titleFor: (mealType) =>
                          _titleForDay(mp, mealType, dayIndex),
                      onTapSlot: (mealType) {
                        mp.ensureActivePlanForWeek();
                        _openRecipePicker(context, mealType, dayIndex);
                      },
                      onLongPressSlot: (mealType) =>
                          _showSlotActions(context, mp, mealType),
                    );
                  },
                ),
              ),
            ],
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

  String? _titleForDay(MealPlanProvider mp, String mealType, int dayIndex) {
    final meals = mp.mealsForDay(dayIndex);
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

  // _buildWeekSummary removed per new design
}

class _DaySection extends StatelessWidget {
  final int dayIndex;
  final DateTime weekStart;
  final String? Function(String mealType) titleFor;
  final void Function(String mealType) onTapSlot;
  final void Function(String mealType) onLongPressSlot;

  const _DaySection({
    required this.dayIndex,
    required this.weekStart,
    required this.titleFor,
    required this.onTapSlot,
    required this.onLongPressSlot,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day divider header
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: Divider(color: scheme.outlineVariant.withOpacity(0.6)),
                ),
                const SizedBox(width: 8),
                Text(
                  _dayLabelPlain(weekStart, dayIndex),
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w900),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Divider(color: scheme.outlineVariant.withOpacity(0.6)),
                ),
              ],
            ),
          ),
          _SlotRow(
              label: 'Breakfast',
              mealType: 'breakfast',
              titleFor: titleFor,
              onTapSlot: onTapSlot,
              onLongPressSlot: onLongPressSlot),
          const SizedBox(height: 10),
          _SlotRow(
              label: 'Lunch',
              mealType: 'lunch',
              titleFor: titleFor,
              onTapSlot: onTapSlot,
              onLongPressSlot: onLongPressSlot),
          const SizedBox(height: 10),
          _SlotRow(
              label: 'Dinner',
              mealType: 'dinner',
              titleFor: titleFor,
              onTapSlot: onTapSlot,
              onLongPressSlot: onLongPressSlot),
          const SizedBox(height: 10),
          _SlotRow(
              label: 'Snack',
              mealType: 'snack',
              titleFor: titleFor,
              onTapSlot: onTapSlot,
              onLongPressSlot: onLongPressSlot),
        ],
      ),
    );
  }

  String _dayLabelPlain(DateTime weekStart, int dayIndex) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final idx = dayIndex.clamp(0, 6);
    final date = weekStart.add(Duration(days: idx));
    final md = '${months[date.month - 1]} ${date.day}';
    return '${names[idx]} $md';
  }
}

class _SlotRow extends StatelessWidget {
  final String label;
  final String mealType;
  final String? Function(String mealType) titleFor;
  final void Function(String mealType) onTapSlot;
  final void Function(String mealType) onLongPressSlot;

  const _SlotRow({
    required this.label,
    required this.mealType,
    required this.titleFor,
    required this.onTapSlot,
    required this.onLongPressSlot,
  });

  @override
  Widget build(BuildContext context) {
    final mp = context.watch<MealPlanProvider>();
    final dayIndex =
        (context.findAncestorWidgetOfExactType<_DaySection>()?.dayIndex) ??
            mp.selectedDay;
    final filled = mp.mealsForDay(dayIndex).firstWhere(
          (m) => m.mealType == mealType,
          orElse: () => PlannedMeal(
              dayOfWeek: dayIndex, mealType: mealType, recipeId: -1, title: ''),
        );
    final hasMeal = filled.recipeId != -1 && filled.title.isNotEmpty;

    return MealSlot(
      label: label,
      title: titleFor(mealType),
      thumbnailUrl: hasMeal ? filled.thumbnailUrl : null,
      onTap: () {
        if (hasMeal) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => RecipeDetailPage(recipeId: filled.recipeId),
          ));
        } else {
          onTapSlot(mealType);
        }
      },
      onLongPress: () => onLongPressSlot(mealType),
      onRemove: hasMeal ? () => mp.removeMeal(dayIndex, mealType) : null,
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
            return Dismissible(
              key: Key('grocery_${i}_${item.name}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.delete,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              onDismissed: (_) => mp.removeGroceryItem(i),
              child: GestureDetector(
                onTap: () => mp.togglePurchased(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Quantity container (similar to checkbox positioning)
                      Container(
                        width: 60,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            item.quantity.toStringAsFixed(2),
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Name and unit
                      Expanded(
                        child: Text(
                          '${item.unit?.isNotEmpty == true ? '${item.unit} ' : ''}${item.name}',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            decoration: item.purchased ? TextDecoration.lineThrough : null,
                            color: item.purchased 
                                ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
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

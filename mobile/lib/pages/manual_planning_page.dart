import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:i_cant_cook/providers/meal_plan_provider.dart';
import 'package:i_cant_cook/widgets/meal_planning/weekly_calendar_widget.dart';
import 'package:i_cant_cook/models/recipe_preview/recipe_preview.dart';
import 'package:i_cant_cook/models/meal_planning/meal_plan.dart';
// removed unused imports after refactor
import 'package:i_cant_cook/widgets/recipe_browser_list.dart';

class ManualPlanningPage extends StatefulWidget {
  final DateTime initialWeek;
  final List<int> preselectedDays;
  const ManualPlanningPage(
      {super.key, required this.initialWeek, required this.preselectedDays});

  @override
  State<ManualPlanningPage> createState() => _ManualPlanningPageState();
}

enum _TopMenuAction { planSelected, copyFrom, clearSelected, templates }

class _ManualPlanningPageState extends State<ManualPlanningPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  RecipePreview? _selectedRecipe;
  bool _savedOnly = true;
  final List<String> _tagPills = const [
    'breakfast',
    'lunch',
    'dinner',
    'dessert',
    'snack',
  ];
  final Set<String> _selectedTags = {};
  static const List<String> _allMealTypes = [
    'breakfast',
    'lunch',
    'dinner',
    'snack'
  ];

  @override
  void initState() {
    super.initState();
    // Keep provider in sync with incoming context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mp = context.read<MealPlanProvider>();
      // Align week to initialWeek (bounded 0..4 weeks ahead)
      DateTime _startOfWeek(DateTime d) {
        final wd = d.weekday; // Mon=1
        return DateTime(d.year, d.month, d.day - (wd - 1));
      }

      final target = _startOfWeek(widget.initialWeek);
      DateTime current = mp.visibleWeekStart;
      // Move week offset towards target within bounds
      int safety = 10; // prevent infinite loops
      while (current.isBefore(target) && mp.weekOffset < 4 && safety-- > 0) {
        mp.nextWeek();
        current = mp.visibleWeekStart;
      }
      while (current.isAfter(target) && mp.weekOffset > 0 && safety-- > 0) {
        mp.prevWeek();
        current = mp.visibleWeekStart;
      }

      // Apply preselected days
      if (widget.preselectedDays.isNotEmpty) {
        final sorted = [...widget.preselectedDays]..sort();
        if (sorted.length == 1) {
          mp.selectDay(sorted.first);
        } else {
          mp.tapDay(sorted.first);
          mp.tapDay(sorted.last);
        }
      }

      mp.ensureActivePlanForWeek();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mp = context.watch<MealPlanProvider>();
    final selected = mp.selectedDaysList;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 16,
        title: Text(
          'Manual Planning',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        leading: const SizedBox.shrink(),
        actions: [
          Builder(builder: (context) {
            final mp = context.watch<MealPlanProvider>();
            final selected = mp.selectedDaysList;
            return PopupMenuButton<_TopMenuAction>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                final mp = context.read<MealPlanProvider>();
                final selected = mp.selectedDaysList;
                switch (value) {
                  case _TopMenuAction.planSelected:
                    _openBatchPlanner(context, selected);
                    break;
                  case _TopMenuAction.copyFrom:
                    _copyFrom(context, mp);
                    break;
                  case _TopMenuAction.clearSelected:
                    mp.clearMealsForRange(selected, _allMealTypes);
                    break;
                  case _TopMenuAction.templates:
                    _openTemplates(context);
                    break;
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _TopMenuAction.planSelected,
                  enabled: selected.length > 1,
                  child: const Text('Plan Selected Days'),
                ),
                const PopupMenuItem(
                  value: _TopMenuAction.copyFrom,
                  child: Text('Copy From…'),
                ),
                const PopupMenuItem(
                  value: _TopMenuAction.clearSelected,
                  child: Text('Clear Selected'),
                ),
                const PopupMenuItem(
                  value: _TopMenuAction.templates,
                  child: Text('Templates'),
                ),
              ],
            );
          }),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Close',
          ),
        ],
      ),
      body: Column(
        children: [
          // Top: Enhanced calendar (reuse WeeklyCalendar for now)
          SizedBox(
            height: 140,
            child: Column(
              children: [
                Expanded(
                  child: WeeklyCalendar(
                    weekStart: mp.visibleWeekStart,
                    selectedDay: mp.selectedDay,
                    rangeStart: mp.rangeStart,
                    rangeEnd: mp.rangeEnd,
                    onDaySelected: mp.tapDay,
                    onSwipeLeft: mp.nextWeek,
                    onSwipeRight: mp.prevWeek,
                    height: 140,
                  ),
                ),
              ],
            ),
          ),

          // Middle pills removed; actions are in the top menu

          // Bottom: Responsive detailed planning
          Expanded(child: _buildResponsivePlanning(context, mp, selected)),
        ],
      ),
    );
  }

  Widget _buildResponsivePlanning(
      BuildContext context, MealPlanProvider mp, List<int> days) {
    final width = MediaQuery.of(context).size.width;
    final leftPanel = Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search recipes…',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Saved only'),
                selected: _savedOnly,
                onSelected: (v) => setState(() => _savedOnly = v),
              ),
            ],
          ),
        ),
        // Tag filter pills (rounded, horizontal scroll)
        SizedBox(
          height: 44,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                for (int i = 0; i < _tagPills.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Builder(builder: (context) {
                    final t = _tagPills[i];
                    final isSel = _selectedTags.contains(t);
                    final scheme = Theme.of(context).colorScheme;
                    return ChoiceChip(
                      label: Text(
                        _capitalize(t),
                        style: TextStyle(
                          fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                          color:
                              isSel ? scheme.primary : scheme.onSurfaceVariant,
                        ),
                      ),
                      selected: isSel,
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            _selectedTags.add(t);
                          } else {
                            _selectedTags.remove(t);
                          }
                        });
                      },
                      shape: const StadiumBorder(),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity:
                          const VisualDensity(horizontal: -2, vertical: -2),
                      side: BorderSide(
                          color: scheme.outlineVariant.withOpacity(0.6)),
                      backgroundColor:
                          scheme.surfaceContainerHighest.withOpacity(0.6),
                      selectedColor: scheme.primary.withOpacity(0.12),
                      pressElevation: 0,
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Tip: Select a recipe then tap a slot to assign',
                style: Theme.of(context).textTheme.bodySmall),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Scrollbar(
            thumbVisibility: true,
            radius: const Radius.circular(8),
            thickness: 6,
            child: RecipeBrowserList(
              query: _searchCtrl.text,
              savedOnly: _savedOnly,
              selectedId: _selectedRecipe?.id,
              includeTags: _selectedTags.toList(),
              onSelect: (r) => setState(() => _selectedRecipe = r),
            ),
          ),
        ),
      ],
    );

    final rightPanel = ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: days.length,
      itemBuilder: (ctx, i) {
        final d = days[i];
        final label = _dayLabel(mp.visibleWeekStart, d);
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.today,
                          size: 18,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _SlotRow(
                    day: d,
                    mealType: 'Breakfast',
                    compact: true,
                    selected: _selectedRecipe,
                    onAssigned: () => setState(() => _selectedRecipe = null)),
                _SlotRow(
                    day: d,
                    mealType: 'Lunch',
                    compact: true,
                    selected: _selectedRecipe,
                    onAssigned: () => setState(() => _selectedRecipe = null)),
                _SlotRow(
                    day: d,
                    mealType: 'Dinner',
                    compact: true,
                    selected: _selectedRecipe,
                    onAssigned: () => setState(() => _selectedRecipe = null)),
                _SlotRow(
                    day: d,
                    mealType: 'Snack',
                    compact: true,
                    selected: _selectedRecipe,
                    onAssigned: () => setState(() => _selectedRecipe = null)),
              ],
            ),
          ),
        );
      },
    );

    if (width < 700) {
      // Stacked layout for phones: recipe browser on top, days list below
      return Column(
        children: [
          SizedBox(
              height: MediaQuery.of(context).size.height * 0.38,
              child: leftPanel),
          const Divider(height: 1),
          Expanded(child: rightPanel),
        ],
      );
    }

    // Side-by-side for larger widths
    return Row(children: [
      Expanded(flex: 45, child: leftPanel),
      Expanded(flex: 55, child: rightPanel)
    ]);
  }

  void _openBatchPlanner(BuildContext context, List<int> selected) {
    // Placeholder for future BatchPlanningModal
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Batch planner coming soon')));
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

  void _openTemplates(BuildContext context) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Templates coming soon')));
  }

  String _dayLabel(DateTime weekStart, int dayIndex) {
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
    return '${names[idx]} • $md';
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// RecipeBrowserList moved to widgets/recipe_browser_list.dart

class _SlotRow extends StatelessWidget {
  final int day;
  final String mealType;
  final bool compact;
  final RecipePreview? selected;
  final VoidCallback? onAssigned;
  const _SlotRow(
      {required this.day,
      required this.mealType,
      this.compact = false,
      this.selected,
      this.onAssigned});

  @override
  Widget build(BuildContext context) {
    final mp = context.watch<MealPlanProvider>();
    final keyType = mealType.toLowerCase();
    final existing =
        mp.mealsForDay(day).where((m) => m.mealType == keyType).toList();
    final bool canAssign = selected != null;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: canAssign ? Colors.green : Colors.grey.shade300,
            width: canAssign ? 2 : 1),
        color: canAssign ? Colors.green.withOpacity(0.03) : null,
      ),
      child: InkWell(
        onTap: () {
          if (selected != null) {
            final recipe = selected!;
            mp.setMeal(
              day,
              keyType,
              PlannedMeal(
                dayOfWeek: day,
                mealType: keyType,
                recipeId: recipe.id,
                title: recipe.title,
                thumbnailUrl: recipe.thumbnail_url,
                servings: 1,
              ),
            );
            onAssigned?.call();
          }
        },
        child: Row(
          children: [
            SizedBox(width: 20, child: _mealIcon(mealType)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mealType,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  existing.isEmpty
                      ? Text(
                          canAssign
                              ? 'Tap to assign'
                              : 'Select a recipe from the list',
                          style: TextStyle(color: Colors.grey.shade700))
                      : Text(
                          existing.first.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                ],
              ),
            ),
            if (existing.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => mp.removeMeal(day, keyType),
              ),
          ],
        ),
      ),
    );
  }

  Widget _mealIcon(String type) {
    switch (type) {
      case 'Breakfast':
        return const Icon(Icons.wb_sunny, size: 18);
      case 'Lunch':
        return const Icon(Icons.ramen_dining, size: 18);
      case 'Dinner':
        return const Icon(Icons.restaurant, size: 18);
      case 'Snack':
        return const Icon(Icons.local_pizza, size: 18);
    }
    return const SizedBox.shrink();
  }
}

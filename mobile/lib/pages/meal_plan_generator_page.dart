import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:i_cant_cook/providers/user_recipes_provider.dart';
import 'package:i_cant_cook/providers/meal_plan_provider.dart';

class MealPlanGeneratorPage extends StatefulWidget {
  const MealPlanGeneratorPage({super.key});

  @override
  State<MealPlanGeneratorPage> createState() => _MealPlanGeneratorPageState();
}

class _MealPlanGeneratorPageState extends State<MealPlanGeneratorPage> {
  final _formKey = GlobalKey<FormState>();
  // Removed free-text description; using structured toggles
  // Preferences state
  final Map<String, bool> _dietPrefs = {
    'Vegetarian': false,
    'Vegan': false,
    'Low Carb': false,
    'High Protein': false,
    'Gluten Free': false,
    'Dairy Free': false,
  };
  final Map<String, bool> _goals = {
    'Quick (<30m)': false,
    'Meal Prep / Leftovers': false,
    'Budget Friendly': false,
    'Weight Loss': false,
    'Muscle Gain': false,
  };
  final Map<String, bool> _mealTypes = {
    'Breakfast': false,
    'Lunch': true,
    'Dinner': true,
    'Snacks': false,
  };
  int _people = 2; // servings per recipe
  bool _loading = false;
  bool _focusSaved = true;
  final Set<int> _preferredRecipeIds = {};

  // _dayLabel was removed as unused

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

  @override
  Widget build(BuildContext context) {
    final mp = context.watch<MealPlanProvider>();
    // Lazy fetch user recipes when page opens
    final urp = context.watch<UserRecipesProvider>();
    if (urp.allRecipes.isEmpty && !_loading) {
      // avoid aggressive refetch: provider debounces internally
      Future.microtask(
          () => context.read<UserRecipesProvider>().fetchRecipes());
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text('Generate Meal Plan',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w900)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selected days reminder
                    Builder(builder: (context) {
                      final selected = [...mp.selectedDaysList]..sort();
                      if (selected.isEmpty) return const SizedBox.shrink();
                      final ws = mp.visibleWeekStart;
                      return Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('You\'re planning for:',
                                  style: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 8),
                              Text(
                                selected.length == 1
                                    ? _dayLabelPlain(ws, selected.first)
                                    : '${_dayLabelPlain(ws, selected.first)} - ${_dayLabelPlain(ws, selected.last)}',
                                style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    _SectionHeader('Dietary Preferences'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _dietPrefs.entries.map((e) {
                        return FilterChip(
                          label: Text(e.key),
                          selected: e.value,
                          onSelected: (v) =>
                              setState(() => _dietPrefs[e.key] = v),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    _SectionHeader('Goals / Focus'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _goals.entries.map((e) {
                        return FilterChip(
                          label: Text(e.key),
                          selected: e.value,
                          onSelected: (v) => setState(() => _goals[e.key] = v),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    _SectionHeader('Include Meal Types'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _mealTypes.entries.map((e) {
                        return FilterChip(
                          label: Text(e.key),
                          selected: e.value,
                          onSelected: (v) =>
                              setState(() => _mealTypes[e.key] = v),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    _SectionHeader('People'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.people,
                            color: Theme.of(context).colorScheme.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Number of people',
                            style: GoogleFonts.nunito(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),

                          // People Controls
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withOpacity(0.5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withOpacity(0.2),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      size: 22),
                                  onPressed: _people > 1
                                      ? () => setState(() =>
                                          _people = (_people - 1).clamp(1, 12))
                                      : null,
                                  constraints: const BoxConstraints(
                                      minWidth: 36, minHeight: 36),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14),
                                  child: Text(
                                    '$_people',
                                    style: GoogleFonts.nunito(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.add,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      size: 22),
                                  onPressed: _people < 12
                                      ? () => setState(() =>
                                          _people = (_people + 1).clamp(1, 12))
                                      : null,
                                  constraints: const BoxConstraints(
                                      minWidth: 36, minHeight: 36),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionHeader('Your Recipes'),
                    const SizedBox(height: 8),

                    if (_preferredRecipeIds.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('${_preferredRecipeIds.length} selected',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant)),
                    ],
                    const SizedBox(height: 12),
                    FilterChip(
                      label: const Text('Focus on my saved recipes'),
                      selected: _focusSaved,
                      onSelected: (v) => setState(() => _focusSaved = v),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'We\'ll prioritize your saved recipes when possible.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 24), // Extra space before button
                  ],
                ),
              ),
            ),
          ),
          // Fixed button at bottom
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  elevation: 4,
                  shadowColor:
                      Theme.of(context).colorScheme.secondary.withOpacity(0.4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _loading
                    ? null
                    : () async {
                        setState(() => _loading = true);
                        final specialRequests = _buildSpecialRequest();
                        final selectedMealTypes = _mealTypes.entries
                            .where((e) => e.value)
                            .map((e) => e.key.toLowerCase())
                            .map((k) => k == 'snacks' ? 'snack' : k)
                            .toList();
                        if (selectedMealTypes.isEmpty) {
                          // Require at least one meal type to avoid backend defaulting unexpectedly
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Please select at least one meal type.')),
                            );
                          }
                          setState(() => _loading = false);
                          return;
                        }
                        await mp.generateAIMealPlan(
                          context,
                          specialRequests: specialRequests,
                          focusOnSaved: _focusSaved,
                          preferredRecipeIds: _preferredRecipeIds.toList(),
                          mealTypes: selectedMealTypes,
                          servings: _people,
                        );
                        // ignore: use_build_context_synchronously
                        Navigator.pop(context);
                      },
                child: _loading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onSecondary))
                    : Text('Generate Meal Plan',
                        style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
    );
  }
}

extension _MealPlanPrefs on _MealPlanGeneratorPageState {
  String _buildSpecialRequest() {
    final diets =
        _dietPrefs.entries.where((e) => e.value).map((e) => e.key).toList();
    final goals =
        _goals.entries.where((e) => e.value).map((e) => e.key).toList();
    final mealTypes =
        _mealTypes.entries.where((e) => e.value).map((e) => e.key).toList();
    final buffer = StringBuffer();
    if (diets.isNotEmpty) buffer.writeln('Dietary: ${diets.join(', ')}');
    if (goals.isNotEmpty) buffer.writeln('Goals: ${goals.join(', ')}');
    if (mealTypes.isNotEmpty)
      buffer.writeln('Meal Types: ${mealTypes.join(', ')}');
    if (_focusSaved) buffer.writeln('Focus on saved recipes.');
    return buffer.toString().trim();
  }
}

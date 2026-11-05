import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:i_cant_cook/providers/user_recipes_provider.dart';
import 'package:i_cant_cook/providers/meal_plan_provider.dart';
import 'package:i_cant_cook/services/haptic_service.dart';
import 'package:i_cant_cook/widgets/toasts/information_toast.dart';
import 'package:i_cant_cook/enums/toast_type.dart';

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
    'Healthy': false,
  };
  final Map<String, bool> _mealTypes = {
    'Breakfast': false,
    'Lunch': true,
    'Dinner': true,
    'Snacks': false,
  };
  // Removed per-page people/servings control; backend uses defaults or profile
  bool _loading = false;
  // Sliders
  double _focusSavedWeight = 0.6; // 0..1 prioritize saved recipes
  double _repeatPreference = 0.2; // 0..1 allow repeats
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
        centerTitle: true,
        leading: IconButton(
          padding: const EdgeInsets.only(left: 16.0),
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.chevron_left,
            color: Theme.of(context).colorScheme.primary,
            size: 32,
          ),
        ),
        title: Text(
          'GENERATE MEAL PLAN',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            letterSpacing: 2.5,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
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
                            borderRadius: BorderRadius.circular(4)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('You\'re planning for:',
                                  style: GoogleFonts.spaceGrotesk(
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 8),
                              Text(
                                selected
                                    .map((d) => _dayLabelPlain(ws, d))
                                    .join(', '),
                                style: GoogleFonts.spaceGrotesk(
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    // Focus on saved recipes slider
                    _SectionHeader('Focus on my recipes'),
                    Slider(
                      value: _focusSavedWeight,
                      onChanged: (v) =>
                          setState(() => _focusSavedWeight = v.clamp(0.0, 1.0)),
                      onChangeEnd: (_) => HapticService.selectionClick(),
                      min: 0,
                      max: 1,
                      divisions: 10,
                      label: '${(_focusSavedWeight * 100).round()}%',
                    ),
                    Text(
                      'How strongly to prioritize your saved recipes',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 12),
                    // Allow repetitions slider
                    _SectionHeader('Allow repetitions of meals'),
                    Slider(
                      value: _repeatPreference,
                      onChanged: (v) =>
                          setState(() => _repeatPreference = v.clamp(0.0, 1.0)),
                      onChangeEnd: (_) => HapticService.selectionClick(),
                      min: 0,
                      max: 1,
                      divisions: 10,
                      label: '${(_repeatPreference * 100).round()}%',
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Never',
                            style: Theme.of(context).textTheme.bodySmall),
                        Text('Often',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionHeader('Dietary Preferences'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _dietPrefs.entries.map((e) {
                        return FilterChip(
                          label: Text(e.key),
                          selected: e.value,
                          onSelected: (v) {
                              HapticService.selectionClick();
                              setState(() => _dietPrefs[e.key] = v);
                            },
                          selectedColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.15),
                          side: BorderSide(
                            color: e.value
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.6)
                                : Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withOpacity(0.3),
                            width: 1.5,
                          ),
                          labelStyle: TextStyle(
                            color: e.value
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight:
                                e.value ? FontWeight.w600 : FontWeight.w500,
                          ),
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
                          onSelected: (v) {
                              HapticService.selectionClick();
                              setState(() => _goals[e.key] = v);
                            },
                          selectedColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.15),
                          side: BorderSide(
                            color: e.value
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.6)
                                : Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withOpacity(0.3),
                            width: 1.5,
                          ),
                          labelStyle: TextStyle(
                            color: e.value
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight:
                                e.value ? FontWeight.w600 : FontWeight.w500,
                          ),
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
                          onSelected: (v) {
                              HapticService.selectionClick();
                              setState(() => _mealTypes[e.key] = v);
                            },
                          selectedColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.15),
                          side: BorderSide(
                            color: e.value
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.6)
                                : Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withOpacity(0.3),
                            width: 1.5,
                          ),
                          labelStyle: TextStyle(
                            color: e.value
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight:
                                e.value ? FontWeight.w600 : FontWeight.w500,
                          ),
                        );
                      }).toList(),
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
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  elevation: 4,
                  shadowColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                onPressed: _loading
                    ? null
                    : () async {
                        HapticService.mediumImpact();
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
                            InformationToast.show(
                              context: context,
                              message:
                                  'Please select at least one meal type.',
                              type: ToastType.warning,
                            );
                          }
                          setState(() => _loading = false);
                          return;
                        }
                        await mp.generateAIMealPlan(
                          context,
                          specialRequests: specialRequests,
                          focusOnSaved: _focusSavedWeight >= 0.5,
                          savedWeight: _focusSavedWeight,
                          repeatPreference: _repeatPreference,
                          preferredRecipeIds: _preferredRecipeIds.toList(),
                          mealTypes: selectedMealTypes,
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
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : Text(
                        'Generate Meal Plan',
                        style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onPrimary),
                      ),
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
      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
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
    // No explicit focus text; sliders are passed as params
    return buffer.toString().trim();
  }
}

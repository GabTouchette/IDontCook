import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/recipe_api.dart';
import 'package:i_cant_cook/api/meal_plan_api.dart';
import 'package:i_cant_cook/models/recipe_preview/recipe_preview.dart';
import 'package:i_cant_cook/models/meal_planning/meal_plan.dart';
import 'package:i_cant_cook/models/meal_planning/grocery_item.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';

class MealPlanProvider with ChangeNotifier {
  List<MealPlan> _mealPlans = [];
  MealPlan? _activeMealPlan;
  List<GroceryItem> _groceryList = [];
  bool _isGenerating = false;
  int _selectedDay = _getTodayIndex();
  Set<int> _selectedDays = {
    _getTodayIndex()
  }; // Changed to Set for multiple selection
  int _weekOffset = 0; // 0 = current week, up to 4 weeks ahead
  final Map<int, RecipePreview> _previewCache = {};

  // Store selections per week (weekOffset -> Set<int>)
  final Map<int, Set<int>> _weekSelections = {
    0: {_getTodayIndex()}
  };

  static int _getTodayIndex() {
    final today = DateTime.now();
    final weekday = today.weekday; // Monday = 1, Sunday = 7
    return weekday - 1; // Convert to 0-based index (Monday = 0, Sunday = 6)
  }

  List<MealPlan> get mealPlans => _mealPlans;
  MealPlan? get activeMealPlan => _activeMealPlan;
  List<GroceryItem> get groceryList => _groceryList;
  bool get isGenerating => _isGenerating;
  int get selectedDay => _selectedDay;
  Set<int> get selectedDays => Set.from(
      _weekSelections[_weekOffset] ?? {}); // Get selections for current week
  int get weekOffset => _weekOffset;
  Map<int, RecipePreview> get previewCache => _previewCache;

  final MealPlanApi _api = MealPlanApi();

  void selectDay(int dayIndex) {
    _selectedDay = dayIndex;
    notifyListeners();
  }

  // Toggle individual day selection for current week
  void tapDay(int dayIndex) {
    _selectedDay = dayIndex; // Keep track of last tapped day

    // Get or create selections for current week
    final currentWeekSelections = _weekSelections[_weekOffset] ?? <int>{};

    if (currentWeekSelections.contains(dayIndex)) {
      currentWeekSelections.remove(dayIndex);
    } else {
      currentWeekSelections.add(dayIndex);
    }

    // Ensure at least one day is always selected
    if (currentWeekSelections.isEmpty) {
      currentWeekSelections.add(dayIndex);
    }

    // Update the selections for this week
    _weekSelections[_weekOffset] = currentWeekSelections;
    _selectedDays = Set.from(currentWeekSelections); // Update current view
    notifyListeners();
  }

  Future<void> generateMealPlan({
    List<String> dietaryRestrictions = const [],
    List<String> cuisines = const [],
    int maxPrepTime = 60,
  }) async {
    _isGenerating = true;
    notifyListeners();

    List<RecipePreview> recipes = [];
    try {
      recipes = await RecipeApi().fetchRecipes();
    } catch (_) {}

    if (recipes.isEmpty) {
      // Mock a small recipe pool if API not available
      recipes = List.generate(
          12,
          (i) => RecipePreview(
                id: i + 1,
                title: 'Sample Recipe ${i + 1}',
                description: 'Delicious and easy.',
                preparation_time: 15 + (i % 3) * 10,
                cooking_time: 10 + (i % 4) * 10,
                thumbnail_url: null,
                tags: const [],
                is_favorite: false,
                is_saved: true,
                ingredients_count: 5 + i,
                last_visited_at: null,
              ));
    }

    // Meal types order
    const mealTypes = ['breakfast', 'lunch', 'dinner'];

    // Build 7-day plan by rotating through available recipes
    final List<PlannedMeal> planned = [];
    int cursor = 0;
    for (int day = 0; day < 7; day++) {
      for (final mt in mealTypes) {
        final r = recipes[cursor % recipes.length];
        planned.add(PlannedMeal(
          dayOfWeek: day,
          mealType: mt,
          recipeId: r.id,
          title: r.title,
          thumbnailUrl: r.thumbnail_url,
          servings: 1,
        ));
        cursor++;
      }
    }

    final monday = _startOfWeek(DateTime.now());
    _activeMealPlan = MealPlan(
      name: 'My Meal Plan',
      weekStartDate: monday,
      plannedMeals: planned,
    );

    _isGenerating = false;
    notifyListeners();
  }

  Future<void> generateAIMealPlan(
    BuildContext context, {
    List<String> dietaryRestrictions = const [],
    List<String> cuisines = const [],
    int maxPrepTime = 60,
    String? specialRequests,
    bool focusOnSaved = true,
    double? savedWeight,
    double? repeatPreference,
    List<int> preferredRecipeIds = const [],
    List<String> mealTypes = const ['breakfast', 'lunch', 'dinner'],
  }) async {
    _isGenerating = true;
    notifyListeners();

    // Ensure there's an active plan object for the visible week
    await ensureActivePlanForWeek();
    // Persist a placeholder plan if needed to obtain an id
    if (_activeMealPlan!.id == null) {
      await saveActivePlan();
    }

    print('Using meal plan ID: ${_activeMealPlan!.id}');
    final selectedDays = selectedDaysList;
    final payload = {
      'id': _activeMealPlan!.id,
      'description': specialRequests ?? '',
      'days': selectedDays,
      'meal_types': mealTypes,
      'focus_on_saved': focusOnSaved,
      if (savedWeight != null) 'saved_weight': savedWeight,
      if (repeatPreference != null) 'repeat_preference': repeatPreference,
      'replace_existing': true,
      'preferred_recipes': preferredRecipeIds,
    };

    print('Generate AI meal plan payload: $payload');

    try {
      final res = await _api.generate(payload);
      // Load the returned plan into local state
      final wsStr = (res['week_start_date'] as String?) ?? '';
      final wsParts =
          wsStr.split('-').map((e) => int.tryParse(e) ?? 1).toList();
      final ws = wsParts.length == 3
          ? DateTime(wsParts[0], wsParts[1], wsParts[2])
          : visibleWeekStart;
      final meals = List<Map<String, dynamic>>.from(res['planned_meals'] ?? []);
      final planned = meals
          .map((m) => PlannedMeal(
                id: m['id'] as int?,
                dayOfWeek: (m['day_of_week'] as num?)?.toInt() ?? 0,
                mealType: (m['meal_type'] as String?)?.toLowerCase() ?? 'lunch',
                recipeId: (m['recipe'] as num?)?.toInt() ?? -1,
                title: (m['title'] as String?) ?? 'Recipe',
                thumbnailUrl: m['thumbnail_url'] as String?,
                servings: (m['servings'] as num?)?.toInt() ?? 1,
              ))
          .toList();
      _activeMealPlan = MealPlan(
        id: res['id'] as int?,
        name: (res['name'] as String?) ?? 'Meal Plan',
        weekStartDate: ws,
        isActive: (res['is_active'] as bool?) ?? true,
        plannedMeals: planned,
      );

      // Handle generation metadata and show appropriate feedback
      final metadata = res['generation_metadata'] as Map<String, dynamic>?;
      if (metadata != null && context.mounted) {
        _handleGenerationFeedback(context, metadata);
      }
    } catch (error) {
      print('Error generating AI meal plan: $error');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate meal plan: ${error.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }

    _isGenerating = false;
    notifyListeners();
  }

  void _handleGenerationFeedback(
      BuildContext context, Map<String, dynamic> metadata) {
    final warnings = List<String>.from(metadata['warnings'] ?? []);
    final fillRate = (metadata['fill_rate'] as num?)?.toDouble() ?? 1.0;
    final filledSlots = (metadata['filled_slots'] as num?)?.toInt() ?? 0;
    final totalSlots = (metadata['total_slots'] as num?)?.toInt() ?? 0;
    final lowQualityCount =
        (metadata['low_quality_count'] as num?)?.toInt() ?? 0;

    // Determine feedback type and message
    Color backgroundColor;
    String message;
    IconData icon;

    if (fillRate >= 0.9 && lowQualityCount == 0) {
      // Great success
      backgroundColor = Theme.of(context).colorScheme.primary;
      icon = Icons.check_circle;
      message = 'Meal plan generated successfully!';
    } else if (fillRate >= 0.8) {
      // Good with some warnings
      backgroundColor = Theme.of(context).colorScheme.secondary;
      icon = Icons.info;
      if (lowQualityCount > 0) {
        message =
            'Meal plan generated with $lowQualityCount recipe(s) that may not fully match your preferences';
      } else {
        message = 'Meal plan generated with some limitations';
      }
    } else if (fillRate >= 0.5) {
      // Partial success with significant issues
      backgroundColor = Colors.orange;
      icon = Icons.warning;
      message =
          'Only ${filledSlots}/${totalSlots} meal slots could be filled. Consider relaxing dietary restrictions.';
    } else {
      // Poor results
      backgroundColor = Theme.of(context).colorScheme.error;
      icon = Icons.error;
      message =
          'Very few suitable recipes found (${filledSlots}/${totalSlots}). Try different preferences.';
    }

    // Show appropriate feedback
    if (fillRate < 0.8 || warnings.isNotEmpty) {
      // Show detailed dialog for problematic cases
      _showGenerationWarningDialog(context, message, warnings, metadata);
    } else {
      // Simple snackbar for successful cases
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showGenerationWarningDialog(BuildContext context, String mainMessage,
      List<String> warnings, Map<String, dynamic> metadata) {
    final lowQualitySlots =
        List<Map<String, dynamic>>.from(metadata['low_quality_slots'] ?? []);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_amber,
          color: Colors.orange,
          size: 32,
        ),
        title: const Text('Meal Plan Generation'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(mainMessage),
              if (warnings.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Issues found:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...warnings.map((w) => Padding(
                      padding: const EdgeInsets.only(top: 4, left: 8),
                      child: Text('• $w'),
                    )),
              ],
              if (lowQualitySlots.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Low-quality matches:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...lowQualitySlots.take(3).map((slot) => Padding(
                      padding: const EdgeInsets.only(top: 4, left: 8),
                      child: Text(
                          '• ${_capitalize(slot['meal_type'])} on day ${slot['day'] + 1}'),
                    )),
                if (lowQualitySlots.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 8),
                    child: Text('• ... and ${lowQualitySlots.length - 3} more'),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  // Removed old AI prompt and local mapping helpers; backend now generates directly

  DateTime _startOfWeek(DateTime date) {
    final weekday = date.weekday; // Mon=1
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }

  DateTime get visibleWeekStart {
    final base = _startOfWeek(DateTime.now());
    return base.add(Duration(days: 7 * _weekOffset));
  }

  List<int> plannedCountsForWeek() {
    final counts = List<int>.filled(7, 0);
    if (_activeMealPlan == null) return counts;
    for (final m in _activeMealPlan!.plannedMeals) {
      if (m.dayOfWeek >= 0 && m.dayOfWeek < 7) counts[m.dayOfWeek] += 1;
    }
    return counts;
  }

  List<PlannedMeal> mealsForDay(int dayIndex) {
    if (_activeMealPlan == null) return [];
    return _activeMealPlan!.plannedMeals
        .where((m) => m.dayOfWeek == dayIndex)
        .toList();
  }

  void setMeal(int dayIndex, String mealType, PlannedMeal plannedMeal) {
    if (_activeMealPlan == null) return;
    final others = _activeMealPlan!.plannedMeals
        .where((m) => !(m.dayOfWeek == dayIndex && m.mealType == mealType))
        .toList();
    _activeMealPlan =
        _activeMealPlan!.copyWith(plannedMeals: [...others, plannedMeal]);
    notifyListeners();
  }

  void removeMeal(int dayIndex, String mealType) {
    if (_activeMealPlan == null) return;
    final remaining = _activeMealPlan!.plannedMeals
        .where((m) => !(m.dayOfWeek == dayIndex && m.mealType == mealType))
        .toList();
    _activeMealPlan = _activeMealPlan!.copyWith(plannedMeals: remaining);
    notifyListeners();
  }

  // Manual planning helpers
  Future<void> ensureActivePlanForWeek() async {
    if (_activeMealPlan == null ||
        _activeMealPlan!.weekStartDate != visibleWeekStart) {
      _activeMealPlan = MealPlan(
        name: 'My Meal Plan',
        weekStartDate: visibleWeekStart,
        plannedMeals: const [],
      );
      notifyListeners();
    }
  }

  List<int> get selectedDaysList {
    final currentWeekSelections = _weekSelections[_weekOffset] ?? <int>{};
    return currentWeekSelections.toList()..sort();
  }

  void clearMealsForRange(List<int> days, List<String> mealTypes) {
    if (_activeMealPlan == null) return;
    final remaining = _activeMealPlan!.plannedMeals
        .where((m) =>
            !days.contains(m.dayOfWeek) || !mealTypes.contains(m.mealType))
        .toList();
    _activeMealPlan = _activeMealPlan!.copyWith(plannedMeals: remaining);
    notifyListeners();
  }

  void copyDayMeals(int fromDay, List<int> toDays, {bool replace = true}) {
    if (_activeMealPlan == null) return;
    final fromMeals = mealsForDay(fromDay);
    List<PlannedMeal> newMeals = List.of(_activeMealPlan!.plannedMeals);
    for (final day in toDays) {
      if (replace) {
        newMeals = newMeals.where((m) => m.dayOfWeek != day).toList();
      }
      for (final fm in fromMeals) {
        // Remove any existing meal in same slot when adding
        newMeals = newMeals
            .where((m) => !(m.dayOfWeek == day && m.mealType == fm.mealType))
            .toList();
        newMeals.add(PlannedMeal(
          dayOfWeek: day,
          mealType: fm.mealType,
          recipeId: fm.recipeId,
          title: fm.title,
          thumbnailUrl: fm.thumbnailUrl,
          servings: fm.servings,
        ));
      }
    }
    _activeMealPlan = _activeMealPlan!.copyWith(plannedMeals: newMeals);
    notifyListeners();
  }

  Future<void> saveActivePlan() async {
    if (_activeMealPlan == null) return;

    try {
      final payload = {
        'name': _activeMealPlan!.name,
        'week_start_date':
            _activeMealPlan!.weekStartDate.toIso8601String().split('T').first,
        'is_active': _activeMealPlan!.isActive,
        'planned_meals': _activeMealPlan!.plannedMeals
            .map((m) => {
                  'day_of_week': m.dayOfWeek,
                  'meal_type': m.mealType,
                  'recipe': m.recipeId,
                  'servings': m.servings,
                })
            .toList(),
      };

      if (_activeMealPlan!.id == null) {
        print('Creating new meal plan with payload: $payload');
        final res = await _api.create(payload);
        print('Create meal plan response: $res');
        _activeMealPlan = _activeMealPlan!.copyWith(id: res['id'] as int?);
        print('Set meal plan ID to: ${_activeMealPlan!.id}');
      } else {
        print('Updating existing meal plan ${_activeMealPlan!.id}');
        await _api.update(_activeMealPlan!.id!, payload);
      }
      notifyListeners();
    } catch (error) {
      print('Error saving meal plan: $error');
    }
  }

  Future<List<Map<String, dynamic>>> listPlans() async {
    try {
      final res = await _api.list();
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  Future<void> loadPlanById(int id) async {
    try {
      final data = await _api.get(id);
      // Expecting backend to return week_start_date and planned_meals
      final wsStr = (data['week_start_date'] as String?) ?? '';
      final wsParts =
          wsStr.split('-').map((e) => int.tryParse(e) ?? 1).toList();
      final ws = wsParts.length == 3
          ? DateTime(wsParts[0], wsParts[1], wsParts[2])
          : visibleWeekStart;
      final meals =
          List<Map<String, dynamic>>.from(data['planned_meals'] ?? []);
      final planned = meals
          .map((m) => PlannedMeal(
                id: m['id'] as int?,
                dayOfWeek: (m['day_of_week'] as num?)?.toInt() ?? 0,
                mealType: (m['meal_type'] as String?)?.toLowerCase() ?? 'lunch',
                recipeId: (m['recipe'] as num?)?.toInt() ?? -1,
                title: (m['title'] as String?) ?? 'Recipe',
                thumbnailUrl: m['thumbnail_url'] as String?,
                servings: (m['servings'] as num?)?.toInt() ?? 1,
              ))
          .toList();
      _activeMealPlan = MealPlan(
        id: data['id'] as int?,
        name: (data['name'] as String?) ?? 'Meal Plan',
        weekStartDate: ws,
        isActive: (data['is_active'] as bool?) ?? true,
        plannedMeals: planned,
      );
      // Align week view to the plan's week
      _weekOffset = ((ws.difference(_startOfWeek(DateTime.now())).inDays) ~/ 7)
          .clamp(0, 4);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> buildGroceryList() async {
    if (_activeMealPlan == null) return;
    final Map<String, GroceryItem> map = {};

    // Fetch full recipe details, consolidate by name+unit
    final Set<int> recipeIds =
        _activeMealPlan!.plannedMeals.map((m) => m.recipeId).toSet();
    final Map<int, Recipe> recipeCache = {};
    for (final id in recipeIds) {
      try {
        final data = await RecipeApi().getRecipeById(id);
        recipeCache[id] = Recipe.fromJson(data);
      } catch (_) {}
    }

    for (final m in _activeMealPlan!.plannedMeals) {
      final recipe = recipeCache[m.recipeId];
      if (recipe == null) continue;
      for (final ing in recipe.ingredients) {
        // Normalize ingredient name and unit for better consolidation
        final normalizedName = (ing.name ?? '')
            .trim()
            .toLowerCase()
            .replaceAll(RegExp(r'\s+'), ' ') // normalize whitespace
            .replaceAll(RegExp(r'[^\w\s]'), ''); // remove punctuation
        final normalizedUnit = (ing.unit ?? '')
            .trim()
            .toLowerCase()
            .replaceAll(RegExp(r'\s+'), ' ')
            .replaceAll('tablespoons', 'tbsp')
            .replaceAll('tablespoon', 'tbsp')
            .replaceAll('teaspoons', 'tsp')
            .replaceAll('teaspoon', 'tsp')
            .replaceAll('ounces', 'oz')
            .replaceAll('ounce', 'oz')
            .replaceAll('pounds', 'lbs')
            .replaceAll('pound', 'lb')
            .replaceAll('cups', 'cup')
            .replaceAll('grams', 'g')
            .replaceAll('gram', 'g')
            .replaceAll('kilograms', 'kg')
            .replaceAll('kilogram', 'kg')
            .replaceAll('milliliters', 'ml')
            .replaceAll('milliliter', 'ml')
            .replaceAll('liters', 'l')
            .replaceAll('liter', 'l');

        final key = '${normalizedName}|${normalizedUnit}';
        final quantity =
            (ing.quantity ?? 0) * m.servings / (recipe.servings ?? 1);

        if (map.containsKey(key)) {
          final existing = map[key]!;
          map[key] = existing.copyWith(quantity: existing.quantity + quantity);
        } else {
          map[key] = GroceryItem(
            name: normalizedName,
            unit: normalizedUnit.isEmpty ? null : normalizedUnit,
            quantity: quantity,
          );
        }
      }
    }

    _groceryList = map.values.toList();
    notifyListeners();
  }

  void togglePurchased(int index) {
    if (index < 0 || index >= _groceryList.length) return;
    final item = _groceryList[index];
    _groceryList[index] = item.copyWith(purchased: !item.purchased);
    notifyListeners();
  }

  void removeGroceryItem(int index) {
    if (index < 0 || index >= _groceryList.length) return;
    _groceryList.removeAt(index);
    notifyListeners();
  }

  void nextWeek() {
    if (_weekOffset < 4) {
      _weekOffset += 1;
      // Load or create selections for this week
      final weekSelections = _weekSelections[_weekOffset];
      if (weekSelections != null) {
        _selectedDays = Set.from(weekSelections);
        _selectedDay = _selectedDays.first;
      } else {
        // Initialize new week with smart default
        final defaultDay = _getTodayIndexForWeek(visibleWeekStart);
        _weekSelections[_weekOffset] = {defaultDay};
        _selectedDays = {defaultDay};
        _selectedDay = defaultDay;
      }
      notifyListeners();
    }
  }

  void prevWeek() {
    if (_weekOffset > 0) {
      _weekOffset -= 1;
      // Load or create selections for this week
      final weekSelections = _weekSelections[_weekOffset];
      if (weekSelections != null) {
        _selectedDays = Set.from(weekSelections);
        _selectedDay = _selectedDays.first;
      } else {
        // Initialize new week with smart default
        final defaultDay = _getTodayIndexForWeek(visibleWeekStart);
        _weekSelections[_weekOffset] = {defaultDay};
        _selectedDays = {defaultDay};
        _selectedDay = defaultDay;
      }
      notifyListeners();
    }
  }

  // Helper to get today's index within the visible week, or default to 0 if not in visible week
  int _getTodayIndexForWeek(DateTime weekStart) {
    final today = DateTime.now();
    final weekEnd = weekStart.add(const Duration(days: 6));

    // Check if today falls within the visible week
    if (today.isAfter(weekStart.subtract(const Duration(days: 1))) &&
        today.isBefore(weekEnd.add(const Duration(days: 1)))) {
      return today.difference(weekStart).inDays.clamp(0, 6);
    }

    // Default to Monday (index 0) if today is not in the visible week
    return 0;
  }
}

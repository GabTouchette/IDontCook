import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/recipe_api.dart';
import 'package:i_cant_cook/api/meal_plan_api.dart';
import 'package:i_cant_cook/models/recipe_preview/recipe_preview.dart';
import 'package:i_cant_cook/models/meal_planning/meal_plan.dart';
import 'package:i_cant_cook/models/meal_planning/grocery_item.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:provider/provider.dart';
import 'package:i_cant_cook/providers/chat_provider.dart';
import 'dart:convert';

class MealPlanProvider with ChangeNotifier {
  List<MealPlan> _mealPlans = [];
  MealPlan? _activeMealPlan;
  List<GroceryItem> _groceryList = [];
  bool _isGenerating = false;
  int _selectedDay = 0;
  int? _rangeStart;
  int? _rangeEnd;
  int _weekOffset = 0; // 0 = current week, up to 4 weeks ahead
  final Map<int, RecipePreview> _previewCache = {};

  List<MealPlan> get mealPlans => _mealPlans;
  MealPlan? get activeMealPlan => _activeMealPlan;
  List<GroceryItem> get groceryList => _groceryList;
  bool get isGenerating => _isGenerating;
  int get selectedDay => _selectedDay;
  int? get rangeStart => _rangeStart;
  int? get rangeEnd => _rangeEnd;
  int get weekOffset => _weekOffset;
  Map<int, RecipePreview> get previewCache => _previewCache;

  final MealPlanApi _api = MealPlanApi();

  void selectDay(int dayIndex) {
    _selectedDay = dayIndex;
    notifyListeners();
  }

  // Handles range selection when a day is tapped in the calendar.
  // First tap starts a new range, second tap completes it (inclusive),
  // third tap starts a new range from the tapped day.
  void tapDay(int dayIndex) {
    _selectedDay = dayIndex;
    if (_rangeStart == null || _rangeEnd != null) {
      // Start new range
      _rangeStart = dayIndex;
      _rangeEnd = null;
    } else {
      // Complete range
      if (dayIndex < _rangeStart!) {
        _rangeEnd = _rangeStart;
        _rangeStart = dayIndex;
      } else {
        _rangeEnd = dayIndex;
      }
    }
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
  }) async {
    _isGenerating = true;
    notifyListeners();

    // Build prompt requesting strict JSON only.
    final ws = visibleWeekStart;
    final prompt = _buildMealPlanPrompt(
      ws,
      dietaryRestrictions: dietaryRestrictions,
      cuisines: cuisines,
      maxPrepTime: maxPrepTime,
      specialRequests: specialRequests,
    );

    final chat = context.read<ChatProvider>();
    await chat.sendMessage(query: prompt, isRecipeChat: false);

    final String aiText = chat.globalMessages.isNotEmpty
        ? (chat.globalMessages.last['text'] as String? ?? '')
        : '';
    final String jsonText = _extractJson(aiText);
    Map<String, dynamic>? data;
    try {
      data = json.decode(jsonText) as Map<String, dynamic>;
    } catch (_) {
      data = null;
    }

    if (data == null) {
      _isGenerating = false;
      notifyListeners();
      return;
    }

    // Fetch previews to map titles → ids
    List<RecipePreview> previews = [];
    try {
      previews = await RecipeApi().fetchRecipes();
      for (final p in previews) {
        _previewCache[p.id] = p;
      }
    } catch (_) {}

    final List<PlannedMeal> planned =
        _mapAIPlanToMeals(data, previews, focusOnSaved: focusOnSaved);
    _activeMealPlan = MealPlan(
      name: 'AI Meal Plan',
      weekStartDate: ws,
      plannedMeals: planned,
    );

    _isGenerating = false;
    notifyListeners();
  }

  String _buildMealPlanPrompt(
    DateTime weekStart, {
    required List<String> dietaryRestrictions,
    required List<String> cuisines,
    required int maxPrepTime,
    String? specialRequests,
  }) {
    final diet =
        dietaryRestrictions.isEmpty ? 'none' : dietaryRestrictions.join(', ');
    final cuis = cuisines.isEmpty ? 'any' : cuisines.join(', ');
    final req = (specialRequests == null || specialRequests.trim().isEmpty)
        ? ''
        : '\nSpecial requests: ${specialRequests.trim()}';
    final dateStr = weekStart.toIso8601String().split('T').first;
    return '''You are planning meals for a 7-day week starting on $dateStr (Monday=0..Sunday=6).
Return ONLY a minified JSON object with this exact schema and nothing else:
{"week_start_date":"YYYY-MM-DD","days":[{"day_index":0,"meals":[{"meal_type":"breakfast","title":"...","servings":1},{"meal_type":"lunch","title":"...","servings":1},{"meal_type":"dinner","title":"...","servings":1}]} ... for day_index 0..6 ]}
Constraints: dietary restrictions: $diet; cuisines: $cuis; max prep time per meal: $maxPrepTime minutes.$req
Titles MUST be common recipe names a typical home cook recognizes.''';
  }

  String _extractJson(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start >= 0 && end > start) {
      return text.substring(start, end + 1);
    }
    return text;
  }

  List<PlannedMeal> _mapAIPlanToMeals(
      Map<String, dynamic> data, List<RecipePreview> previews,
      {bool focusOnSaved = false}) {
    List<dynamic> days = (data['days'] as List?) ?? [];
    final lowerPreviews = previews
        .map((p) => {
              'id': p.id,
              'title': p.title.toLowerCase(),
              'obj': p,
            })
        .toList();
    final savedIds =
        previews.where((p) => (p.is_saved) == true).map((p) => p.id).toSet();
    final lowerPreviewsSaved =
        lowerPreviews.where((p) => savedIds.contains(p['id'] as int)).toList();
    final List<PlannedMeal> out = [];
    int fallbackCursorAll = 0;
    int fallbackCursorSaved = 0;
    for (final d in days) {
      final int di = (d['day_index'] as num?)?.toInt() ?? 0;
      final List meals = (d['meals'] as List?) ?? [];
      for (final m in meals) {
        final String mt = (m['meal_type'] as String?)?.toLowerCase() ?? 'lunch';
        final String title = (m['title'] as String?) ?? '';
        final int servings = (m['servings'] as num?)?.toInt() ?? 1;
        int recipeId = -1;
        if (focusOnSaved && lowerPreviewsSaved.isNotEmpty) {
          recipeId = _matchTitleToPreviewId(
              title, lowerPreviewsSaved, fallbackCursorSaved);
        }
        if (recipeId == -1) {
          recipeId =
              _matchTitleToPreviewId(title, lowerPreviews, fallbackCursorAll);
        }
        if (recipeId == -1 && previews.isNotEmpty) {
          // fallback rotation prefers saved if requested
          RecipePreview p;
          if (focusOnSaved && savedIds.isNotEmpty) {
            final savedList =
                previews.where((e) => savedIds.contains(e.id)).toList();
            p = savedList[fallbackCursorSaved % savedList.length];
            fallbackCursorSaved++;
          } else {
            p = previews[fallbackCursorAll % previews.length];
            fallbackCursorAll++;
          }
          out.add(PlannedMeal(
            dayOfWeek: di.clamp(0, 6),
            mealType: mt,
            recipeId: p.id,
            title: p.title,
            thumbnailUrl: p.thumbnail_url,
            servings: servings,
          ));
        } else {
          final p = previews.firstWhere((e) => e.id == recipeId,
              orElse: () => previews[(fallbackCursorAll++) % previews.length]);
          out.add(PlannedMeal(
            dayOfWeek: di.clamp(0, 6),
            mealType: mt,
            recipeId: p.id,
            title: p.title,
            thumbnailUrl: p.thumbnail_url,
            servings: servings,
          ));
        }
      }
    }
    return out;
  }

  int _matchTitleToPreviewId(
      String aiTitle, List<Map<String, dynamic>> lowerPreviews, int seed) {
    final t = aiTitle.toLowerCase().trim();
    if (t.isEmpty) return -1;
    int bestId = -1;
    double bestScore = 0;
    for (final p in lowerPreviews) {
      final String pt = p['title'];
      double score = _titleSimilarity(t, pt);
      if (score > bestScore) {
        bestScore = score;
        bestId = p['id'] as int;
      }
    }
    return bestScore >= 0.4 ? bestId : -1; // threshold
  }

  double _titleSimilarity(String a, String b) {
    final aw =
        a.split(RegExp(r"[^a-z0-9]+")).where((w) => w.isNotEmpty).toSet();
    final bw =
        b.split(RegExp(r"[^a-z0-9]+")).where((w) => w.isNotEmpty).toSet();
    if (aw.isEmpty || bw.isEmpty) return 0;
    final inter = aw.intersection(bw).length.toDouble();
    final union = aw.union(bw).length.toDouble();
    return inter / union;
  }

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
    if (_rangeStart != null && _rangeEnd != null) {
      return List<int>.generate(
          _rangeEnd! - _rangeStart! + 1, (i) => _rangeStart! + i);
    }
    return [_selectedDay];
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
      final res = await _api.create(payload);
      _activeMealPlan = _activeMealPlan!.copyWith(id: res['id'] as int?);
    } else {
      await _api.update(_activeMealPlan!.id!, payload);
    }
    notifyListeners();
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
        final key =
            '${(ing.name ?? '').trim().toLowerCase()}|${(ing.unit ?? '').trim().toLowerCase()}';
        final quantity =
            (ing.quantity ?? 0) * m.servings / (recipe.servings ?? 1);
        if (map.containsKey(key)) {
          final existing = map[key]!;
          map[key] = existing.copyWith(quantity: existing.quantity + quantity);
        } else {
          map[key] = GroceryItem(
              name: (ing.name ?? '').trim().toLowerCase(),
              unit: ing.unit?.toLowerCase(),
              quantity: quantity);
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

  void nextWeek() {
    if (_weekOffset < 4) {
      _weekOffset += 1;
      notifyListeners();
    }
  }

  void prevWeek() {
    if (_weekOffset > 0) {
      _weekOffset -= 1;
      notifyListeners();
    }
  }
}

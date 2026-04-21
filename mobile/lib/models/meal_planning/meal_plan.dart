class PlannedMeal {
  final int? id; // backend id
  final int dayOfWeek; // 0=Mon ... 6=Sun
  final String mealType; // breakfast, lunch, dinner, snack
  final int recipeId;
  final String title;
  final String? thumbnailUrl;
  final int servings;

  PlannedMeal({
    this.id,
    required this.dayOfWeek,
    required this.mealType,
    required this.recipeId,
    required this.title,
    this.thumbnailUrl,
    this.servings = 1,
  });
}

class MealPlan {
  final int? id; // backend id
  final String name;
  final DateTime weekStartDate;
  final bool isActive;
  final List<PlannedMeal> plannedMeals;

  MealPlan({
    this.id,
    required this.name,
    required this.weekStartDate,
    this.isActive = true,
    this.plannedMeals = const [],
  });

  MealPlan copyWith({
    int? id,
    String? name,
    DateTime? weekStartDate,
    bool? isActive,
    List<PlannedMeal>? plannedMeals,
  }) {
    return MealPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      isActive: isActive ?? this.isActive,
      plannedMeals: plannedMeals ?? this.plannedMeals,
    );
  }
}

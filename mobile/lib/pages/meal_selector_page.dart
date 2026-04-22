import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:i_cant_cook/models/meal_planning/meal_plan.dart';
import 'package:i_cant_cook/models/recipe_preview/recipe_preview.dart';
import 'package:i_cant_cook/api/recipe_api.dart';
import 'package:i_cant_cook/providers/meal_plan_provider.dart';

class MealSelectorPage extends StatefulWidget {
  final int dayIndex;
  final String mealType;
  const MealSelectorPage(
      {super.key, required this.dayIndex, required this.mealType});

  @override
  State<MealSelectorPage> createState() => _MealSelectorPageState();
}

class _MealSelectorPageState extends State<MealSelectorPage> {
  List<RecipePreview> _recipes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _recipes = await RecipeApi().fetchRecipes();
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final mp = context.read<MealPlanProvider>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text('Select ${widget.mealType}',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w900)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (_, i) {
                final r = _recipes[i];
                return ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withOpacity(0.2))),
                  tileColor: Theme.of(context).colorScheme.surface,
                  leading: r.thumbnail_url != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                              r.thumbnail_url!,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(
                                width: 56,
                                height: 56,
                                child: Icon(Icons.image_not_supported_outlined),
                              )))
                      : const Icon(Icons.image_outlined),
                  title: Text(r.title,
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
                  subtitle: Text(
                      '${r.preparation_time ?? '-'} + ${r.cooking_time ?? '-'} min'),
                  onTap: () {
                    mp.setMeal(
                        widget.dayIndex,
                        widget.mealType,
                        PlannedMeal(
                          dayOfWeek: widget.dayIndex,
                          mealType: widget.mealType,
                          recipeId: r.id,
                          title: r.title,
                          thumbnailUrl: r.thumbnail_url,
                          servings: 1,
                        ));
                    Navigator.pop(context);
                  },
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: _recipes.length,
            ),
    );
  }
}

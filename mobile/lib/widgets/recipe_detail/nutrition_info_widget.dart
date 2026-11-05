import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';

class NutritionInfo extends StatelessWidget {
  final Recipe recipe;
  final double servings;
  final bool isCalculating;

  const NutritionInfo({
    Key? key,
    required this.recipe,
    required this.servings,
    this.isCalculating = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasData = _hasNutritionData();

    if (!hasData && isCalculating) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NUTRITION',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                    width: 28,
                    height: 3,
                    color: Theme.of(context).colorScheme.secondary),
              ],
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'calculating…',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                color:
                    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    if (!hasData) return const SizedBox.shrink();

    final cal = _scale(recipe.calories);
    final protein = _scale(recipe.protein);
    final fat = _scale(recipe.fat);
    final carbs = _scale(recipe.carbs);

    final macros = <_MacroItem>[
      if (cal != null)
        _MacroItem(label: 'KCAL', value: cal.round().toString()),
      if (protein != null)
        _MacroItem(label: 'PROTEIN', value: '${protein.toStringAsFixed(0)}g'),
      if (carbs != null)
        _MacroItem(label: 'CARBS', value: '${carbs.toStringAsFixed(0)}g'),
      if (fat != null)
        _MacroItem(label: 'FAT', value: '${fat.toStringAsFixed(0)}g'),
    ];

    if (macros.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NUTRITION',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                  width: 28,
                  height: 3,
                  color: Theme.of(context).colorScheme.secondary),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Divider(
          height: 1,
          thickness: 1.5,
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              for (int i = 0; i < macros.length; i++) ...[
                if (i > 0)
                  Container(
                    width: 1,
                    height: 40,
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.12),
                  ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        macros[i].value,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        macros[i].label,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.38),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.10),
        ),
        if (servings > 1 || servings == 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'per serving',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                color:
                    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
              ),
            ),
          ),
      ],
    );
  }

  bool _hasNutritionData() =>
      recipe.calories != null ||
      recipe.protein != null ||
      recipe.fat != null ||
      recipe.carbs != null;

  double? _scale(double? perServing) => perServing;
}

class _MacroItem {
  final String label;
  final String value;
  const _MacroItem({required this.label, required this.value});
}

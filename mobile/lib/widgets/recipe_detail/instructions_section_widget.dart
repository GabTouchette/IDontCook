import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/services/haptic_service.dart';
import 'package:i_cant_cook/theme/theme.dart';

class InstructionsSection extends StatelessWidget {
  final Recipe recipe;
  final List<bool> completedInstructions;
  final Function onCompletedInstructions;
  final Set<String> updatedFields;

  const InstructionsSection({
    Key? key,
    required this.recipe,
    required this.completedInstructions,
    required this.onCompletedInstructions,
    required this.updatedFields,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUpdated = updatedFields.contains('instructions');
    final lime = Theme.of(context).colorScheme.secondary;
    final changeColor = Theme.of(context).colorScheme.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'INSTRUCTIONS',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                      color: isUpdated
                          ? changeColor
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${recipe.instructions.length}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.35),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(width: 28, height: 3, color: lime),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Divider(
          height: 1,
          thickness: 1.5,
          color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
        ),

        // Steps
        ...List.generate(recipe.instructions.length, (index) {
          final isCompleted = index < completedInstructions.length
              ? completedInstructions[index]
              : false;
          final stepNum = (index + 1).toString().padLeft(2, '0');

          return GestureDetector(
            onTap: () {
              HapticService.selectionClick();
              onCompletedInstructions(index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              color: isCompleted
                  ? lime.withOpacity(0.06)
                  : Colors.transparent,
              child: Column(
                children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Step number badge
                      Container(
                        width: 36,
                        height: 36,
                        color: isCompleted
                            ? Theme.of(context).colorScheme.onSurface
                            : lime,
                        child: Center(
                          child: isCompleted
                              ? Icon(
                                  Icons.check,
                                  size: 18,
                                  color:
                                      Theme.of(context).colorScheme.surface,
                                )
                              : Text(
                                  stepNum,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Instruction text
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            recipe.instructions[index],
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              height: 1.55,
                              color: isCompleted
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.3)
                                  : isUpdated
                                      ? changeColor
                                      : Theme.of(context).colorScheme.onSurface,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              fontStyle: isUpdated && !isCompleted
                                  ? FontStyle.italic
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                  color:
                      Theme.of(context).colorScheme.outline.withOpacity(0.08),
                ),
              ],
            ),
          ),
        );
        }),
      ],
    );
  }
}

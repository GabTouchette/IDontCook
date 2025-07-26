import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/recipe/recipe.dart';
import 'package:i_cant_cook/theme/colors.dart';

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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorPalette.darkgray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorPalette.lightgray.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.clipboardList,
                color: ColorPalette.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Instructions',
                style: GoogleFonts.nunito(
                  color: updatedFields.contains("instructions")
                      ? ColorPalette.mustard
                      : ColorPalette.offWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ColorPalette.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ColorPalette.blue.withOpacity(0.3)),
                ),
                child: Text(
                  '${recipe.instructions.length} steps',
                  style: const TextStyle(
                    color: ColorPalette.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Instructions List
          ...List.generate(
            recipe.instructions.length,
            (index) {
              final isCompleted = (index < completedInstructions.length)
                  ? completedInstructions[index]
                  : false;

              return GestureDetector(
                onTap: () => onCompletedInstructions(index),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? ColorPalette.green.withOpacity(0.1)
                        : ColorPalette.darkergray.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCompleted
                          ? ColorPalette.green.withOpacity(0.3)
                          : ColorPalette.lightgray.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Step Number/Checkmark
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? ColorPalette.green
                              : ColorPalette.lightgray.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isCompleted
                                        ? Colors.white
                                        : ColorPalette.offWhite,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Instruction Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Step ${index + 1}',
                              style: TextStyle(
                                color: isCompleted
                                    ? ColorPalette.green
                                    : ColorPalette.lightgray,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              recipe.instructions[index],
                              style: TextStyle(
                                color: isCompleted
                                    ? ColorPalette.green
                                    : ColorPalette.offWhite,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

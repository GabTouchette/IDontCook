import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/theme/theme.dart';

/// Banner shown directly under the prep/cook stat bar when a recipe's
/// ingredients haven't been run through the LLM formatting pass
/// (`is_formatted == false`). The "Reformat" button triggers the same
/// formatting the backend does automatically on create.
class RecipeFormatBanner extends StatelessWidget {
  final bool isReformatting;
  final VoidCallback? onReformat;

  const RecipeFormatBanner({
    Key? key,
    required this.isReformatting,
    required this.onReformat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final warning = cs.warning;

    return Container(
      width: double.infinity,
      color: warning.withOpacity(0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 20, color: warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Recipe improperly formatted',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: isReformatting ? null : onReformat,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: isReformatting ? warning.withOpacity(0.5) : warning,
              child: isReformatting
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onSurface,
                      ),
                    )
                  : Text(
                      'Reformat',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0A0A0A),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

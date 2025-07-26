import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/theme/colors.dart';

class ServingsSection extends StatelessWidget {
  final int servings;
  final Function incrementServings;
  final Function decrementServings;
  final Set<String> updatedFields;

  const ServingsSection({
    Key? key,
    required this.servings,
    required this.incrementServings,
    required this.decrementServings,
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
      child: Row(
        children: [
          const FaIcon(
            FontAwesomeIcons.users,
            color: ColorPalette.mustard,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Servings',
            style: GoogleFonts.nunito(
              color: updatedFields.contains("servings")
                  ? ColorPalette.mustard
                  : ColorPalette.offWhite,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),

          // Servings Controls
          Container(
            decoration: BoxDecoration(
              color: ColorPalette.darkergray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove,
                      color: ColorPalette.offWhite, size: 20),
                  onPressed: () => decrementServings(),
                  constraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '$servings',
                    style: GoogleFonts.nunito(
                      color: ColorPalette.mustard,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add,
                      color: ColorPalette.offWhite, size: 20),
                  onPressed: () => incrementServings(),
                  constraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

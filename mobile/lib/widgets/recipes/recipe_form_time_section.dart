import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TimeSection extends StatelessWidget {
  final TextEditingController prepTimeController;
  final TextEditingController cookTimeController;

  const TimeSection({
    Key? key,
    required this.prepTimeController,
    required this.cookTimeController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TIMING',
            style: GoogleFonts.spaceGrotesk(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Container(width: 20, height: 2, color: const Color(0xFFCAFF00)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _timeField(context, prepTimeController, 'PREP')),
              const SizedBox(width: 12),
              Expanded(
                  child: _timeField(context, cookTimeController, 'COOK')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeField(
    BuildContext context,
    TextEditingController controller,
    String label,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.5),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: GoogleFonts.spaceGrotesk(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: GoogleFonts.spaceGrotesk(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            suffixText: 'min',
            suffixStyle: GoogleFonts.spaceGrotesk(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
              fontSize: 13,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(
                color: Color(0xFFCAFF00),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/home_module/module_payloads.dart';
import 'package:i_cant_cook/widgets/blocks/block_styles.dart';

/// Renders a `chat_prompt` module: a light, outlined pill suggestion.
/// Tapping calls [onTap] with the payload's `prompt_text` — Wave 2 wires
/// this to sending it as a user chat message (plan §1.2).
class ChatPromptChip extends StatelessWidget {
  final ChatPromptPayload payload;
  final void Function(String promptText)? onTap;

  const ChatPromptChip({super.key, required this.payload, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (payload.prompt_text.isEmpty) return const SizedBox.shrink();

    final onSurface = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: () => onTap?.call(payload.prompt_text),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
        decoration: blockPillDecoration(context, outlineOpacity: 0.25),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 15, color: onSurface),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                payload.prompt_text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward,
              size: 15,
              color: onSurface.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

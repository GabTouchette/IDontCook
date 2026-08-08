import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/widgets/chatbot/parts/markdown_style.dart';

/// Renders a `text` block. The feed's opening greeting line ([isGreeting])
/// gets an editorial headline treatment; every other text block — ordinary
/// assistant replies in the conversation — renders as normal body copy, the
/// same size as the rest of the app's chat text. Un-carded either way: this
/// should read as plain prose, not another bordered box, so the module cards
/// that follow stand out by comparison.
///
/// The agent is identified by a dedicated avatar (see `home_page.dart`'s
/// `_AssistantAvatar`), not by an icon on the text itself — the previous
/// day-part weather icon here read as decoration, not as "the AI is
/// speaking", and looked like a plain weather cloud for half the day.
class TextBlockBubble extends StatelessWidget {
  final String text;
  final bool isGreeting;

  const TextBlockBubble({
    super.key,
    required this.text,
    this.isGreeting = false,
  });

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    final onSurface = Theme.of(context).colorScheme.onSurface;
    final style = isGreeting
        // Editorial treatment for the feed's opening greeting: a tighter,
        // heavier headline weight with negative letter-spacing, so it reads
        // as a considered headline rather than a chat message.
        ? markdownStyle.copyWith(
            p: GoogleFonts.spaceGrotesk(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              height: 1.28,
              letterSpacing: -0.3,
              color: onSurface,
            ),
          )
        // Ordinary conversational reply — normal body-text size, matching
        // the rest of the app's chat surfaces.
        : markdownStyle.copyWith(
            p: GoogleFonts.spaceGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.4,
              color: onSurface,
            ),
          );

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: MarkdownBody(data: text, styleSheet: style),
    );
  }
}

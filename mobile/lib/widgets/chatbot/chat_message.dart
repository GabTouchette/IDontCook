import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MessageWidget extends StatelessWidget {
  final String messageText;
  final bool isUser;

  const MessageWidget({
    super.key,
    required this.messageText,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: isUser ? 16.0 : 8.0,
        bottom: isUser ? 16.0 : 8.0,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.onSurface
              : Theme.of(context).colorScheme.surface,
          border: isUser
              ? null
              : Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withOpacity(0.15),
                  width: 1.5,
                ),
        ),
        child: Text(
          messageText,
          style: GoogleFonts.spaceGrotesk(
            color: isUser
                ? Theme.of(context).colorScheme.surface
                : Theme.of(context).colorScheme.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

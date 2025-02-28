import 'package:flutter/material.dart';
import 'package:i_cant_cook/theme/colors.dart';

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
    String finalMessageText = messageText;
    TextStyle messageStyle = TextStyle(
      color: isUser ? ColorPalette.offBlack : ColorPalette.offWhite,
      fontSize: 16,
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isUser ? 24.0 : 0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
        decoration: BoxDecoration(
          color: isUser ? ColorPalette.lightgray : ColorPalette.darkgray,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          finalMessageText,
          style: messageStyle,
        ),
      ),
    );
  }
}

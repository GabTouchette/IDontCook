import 'package:flutter/material.dart';
import 'package:mobile/theme/colors.dart';

class AiResponseBubble extends StatefulWidget {
  const AiResponseBubble({super.key});

  @override
  AiResponseBubbleState createState() => AiResponseBubbleState();
}

class AiResponseBubbleState extends State<AiResponseBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.75, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: ColorPalette.darkgray,
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Icon(
          Icons.more_horiz,
          color: ColorPalette.offWhite,
        ),
      ),
    );
  }
}
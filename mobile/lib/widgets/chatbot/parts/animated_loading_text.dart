import 'dart:async';
import 'package:flutter/material.dart';
import 'package:i_cant_cook/theme/colors.dart';

class AnimatedLoadingText extends StatefulWidget {
  @override
  State<AnimatedLoadingText> createState() => _AnimatedLoadingTextState();
}

class _AnimatedLoadingTextState extends State<AnimatedLoadingText>
    with SingleTickerProviderStateMixin {
  int _loadingDots = 0;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(_controller);

    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        _loadingDots = (_loadingDots + 1) % 4;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String loadingText = "Generating recipe" + "." * _loadingDots;
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Opacity(
        opacity: _animation.value,
        child: Text(
          loadingText,
          style: const TextStyle(
            color: ColorPalette.offWhite,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

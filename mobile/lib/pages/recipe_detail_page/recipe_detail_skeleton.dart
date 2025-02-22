import 'package:flutter/material.dart';
import 'package:mobile/theme/colors.dart';

class RecipeDetailSkeleton extends StatefulWidget {
  const RecipeDetailSkeleton({Key? key}) : super(key: key);

  @override
  _RecipeDetailSkeletonState createState() => _RecipeDetailSkeletonState();
}

class _RecipeDetailSkeletonState extends State<RecipeDetailSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.9, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorPalette.darkergray,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeTransition(
              opacity: _animation,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: ColorPalette.darkgray,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _animation,
              child: Container(
                width: double.infinity,
                height: 30,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: ColorPalette.darkgray,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                FadeTransition(
                  opacity: _animation,
                  child: Container(
                    width: 80,
                    height: 20,
                    decoration: BoxDecoration(
                      color: ColorPalette.darkgray,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    margin: const EdgeInsets.only(right: 16),
                  ),
                ),
                FadeTransition(
                  opacity: _animation,
                  child: Container(
                    width: 80,
                    height: 20,
                    decoration: BoxDecoration(
                      color: ColorPalette.darkgray,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FadeTransition(
              opacity: _animation,
              child: Container(
                width: double.infinity,
                height: 24,
                decoration: BoxDecoration(
                  color: ColorPalette.darkgray,
                  borderRadius: BorderRadius.circular(6),
                ),
                margin: const EdgeInsets.only(bottom: 8),
              ),
            ),
            const SizedBox(height: 16),
            FadeTransition(
              opacity: _animation,
              child: Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  color: ColorPalette.darkgray,
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeTransition(
                      opacity: _animation,
                      child: Container(
                        height: 20,
                        width: 100,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 77, 77, 77),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (int i = 0; i < 3; i++)
                      FadeTransition(
                        opacity: _animation,
                        child: Container(
                          height: 20,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: ColorPalette.darkgray,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          margin: const EdgeInsets.only(bottom: 4),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            FadeTransition(
              opacity: _animation,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: ColorPalette.darkgray,
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeTransition(
                      opacity: _animation,
                      child: Container(
                        height: 20,
                        width: 100,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 77, 77, 77),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (int i = 0; i < 4; i++)
                      FadeTransition(
                        opacity: _animation,
                        child: Container(
                          height: 20,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: ColorPalette.darkgray,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          margin: const EdgeInsets.only(bottom: 4),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

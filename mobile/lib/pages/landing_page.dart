import 'package:flutter/material.dart';
import '../theme/colors.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/images/landing_page_background.png',
            fit: BoxFit.cover,
          ),
          // Main content
          Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center vertically
            crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
            children: [
              // 'IDontCook' title
              Text(
                'IDontCook',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: ColorPalette.offWhite,
                      fontSize: 72,
                      fontWeight: FontWeight.w300,
                    ),
              ),
              const SizedBox(height: 16),
              // Subtitle text
              Text(
                'Your culinary companion for effortless meals.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ColorPalette.offWhite,
                      fontWeight: FontWeight.w200,
                    ),
              ),
              const SizedBox(height: 100), // Space between text and button
              // Button
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/recipes');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.yellow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Get Cookin\'',
                    style: TextStyle(
                      fontSize: 18,
                      color: ColorPalette.offBlack,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

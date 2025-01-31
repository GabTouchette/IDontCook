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
          Image.asset(
            'assets/images/landing_page_background.png',
            fit: BoxFit.cover,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 200),
              Text(
                'IDontCook',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: ColorPalette.offWhite,
                      fontSize: 72,
                      fontWeight: FontWeight.w300,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your culinary companion for effortless meals.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ColorPalette.offWhite,
                      fontWeight: FontWeight.w200,
                    ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 100.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/recipes');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorPalette.lightgray,
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
            ),
          ),
        ],
      ),
    );
  }
}

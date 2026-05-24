import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/widgets/appbar/appbar_user_menu.dart';

class MealPlanPage extends StatelessWidget {
  const MealPlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    const lime = Color(0xFFCAFF00);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: const SizedBox.shrink(),
        title: Text(
          'MEAL PLANS',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            letterSpacing: 2.5,
            color: scheme.onSurface,
          ),
        ),
        actions: const [UserMenuWidget()],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lime icon block
              Container(
                width: 72,
                height: 72,
                color: lime,
                child: const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF0A0A0A),
                  size: 30,
                ),
              ),
              const SizedBox(height: 28),
              // Title + underline
              Column(
                children: [
                  Text(
                    'COMING SOON',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w700,
                      fontSize: 26,
                      letterSpacing: 3.0,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(width: 40, height: 3, color: lime),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'AI-powered meal planning is on its way. Stay tuned!',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.6,
                  color: scheme.onSurface.withOpacity(0.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

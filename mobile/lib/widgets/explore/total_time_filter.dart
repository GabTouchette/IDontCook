import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/providers/explore_provider.dart';
import 'package:i_cant_cook/services/haptic_service.dart';
import 'package:provider/provider.dart';

class TotalTimeFilter extends StatelessWidget {
  const TotalTimeFilter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExploreProvider>(
      builder: (context, provider, child) {
        final int totalTime = (provider.filters['totalTime'] as num).toInt();
        final outlineColor = Theme.of(context).colorScheme.outline;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL TIME',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.8,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: Text(
                      totalTime == 0 ? 'ANY' : '${totalTime}m',
                      key: ValueKey(totalTime),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.5,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.0,
                      ),
                    ),
                  ),
                  Text(
                    'Includes prep and cook time',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: outlineColor, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CtrlBtn(
                      icon: Icons.remove,
                      onTap: () {
                        if (totalTime > 0) {
                          final newVal = (totalTime - 15).clamp(0, 9999);
                          provider.updateFilter('totalTime', newVal);
                        }
                      },
                    ),
                    Container(
                      width: 1.5,
                      height: 44,
                      color: outlineColor,
                    ),
                    _CtrlBtn(
                      icon: Icons.add,
                      onTap: () {
                        final newVal = totalTime == 0 ? 15 : totalTime + 15;
                        provider.updateFilter('totalTime', newVal);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CtrlBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticService.selectionClick();
        onTap();
      },
      child: SizedBox(
        width: 48,
        height: 44,
        child: Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

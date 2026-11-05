import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/services/haptic_service.dart';

class ServingsSection extends StatelessWidget {
  final double servings;
  final Function incrementServings;
  final Function decrementServings;
  final Set<String> updatedFields;

  const ServingsSection({
    Key? key,
    required this.servings,
    required this.incrementServings,
    required this.decrementServings,
    required this.updatedFields,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUpdated = updatedFields.contains('servings');
    final lime = Theme.of(context).colorScheme.secondary;
    final labelColor = isUpdated
        ? lime
        : Theme.of(context).colorScheme.onSurface;
    final outlineColor = Theme.of(context).colorScheme.outline;

    return Column(
      children: [
        _Divider(context),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SERVINGS',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.8,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.4),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: Text(
                      _formatServings(servings),
                      key: ValueKey(_formatServings(servings)),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.5,
                        color: labelColor,
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Sharp +/- control
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: outlineColor, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CtrlBtn(
                      icon: Icons.remove,
                      onTap: () => decrementServings(),
                    ),
                    Container(
                      width: 1.5,
                      height: 44,
                      color: outlineColor,
                    ),
                    _CtrlBtn(
                      icon: Icons.add,
                      onTap: () => incrementServings(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _Divider(context),
      ],
    );
  }

  String _formatServings(double value) {
    if ((value - value.floor()).abs() < 1e-9) return value.toInt().toString();
    if ((value - 0.5).abs() < 1e-9) return '½';
    if ((value - 0.25).abs() < 1e-9) return '¼';
    return value.toStringAsFixed(1);
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

Widget _Divider(BuildContext context) => Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).colorScheme.outline.withOpacity(0.12),
    );

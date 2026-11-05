import 'package:flutter/material.dart';
import 'package:i_cant_cook/services/haptic_service.dart';

/// Haptic intensity fired when a [Pressable] is pressed.
enum PressHaptic { none, selection, light, medium, heavy }

/// Wraps any tappable child (IconButton, PopupMenuButton, GestureDetector…)
/// with a quick press-in scale and a haptic tick, so icons feel responsive
/// without rewriting their tap logic.
///
/// Built on a [Listener] rather than a [GestureDetector] so it never swallows
/// the child's own gesture — the inner button still fires its onPressed / opens
/// its menu. This lets it wrap even [PopupMenuButton], which has no onTap hook.
class Pressable extends StatefulWidget {
  final Widget child;
  final PressHaptic haptic;
  final double pressedScale;

  const Pressable({
    super.key,
    required this.child,
    this.haptic = PressHaptic.light,
    this.pressedScale = 0.88,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _fireHaptic() {
    switch (widget.haptic) {
      case PressHaptic.none:
        break;
      case PressHaptic.selection:
        HapticService.selectionClick();
        break;
      case PressHaptic.light:
        HapticService.lightImpact();
        break;
      case PressHaptic.medium:
        HapticService.mediumImpact();
        break;
      case PressHaptic.heavy:
        HapticService.heavyImpact();
        break;
    }
  }

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        _fireHaptic();
        _setPressed(true);
      },
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

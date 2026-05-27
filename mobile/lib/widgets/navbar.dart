import 'package:flutter/material.dart';
import 'package:i_cant_cook/services/haptic_service.dart';

class Navbar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onTabChanged;

  const Navbar({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  int? _activeIndex; // tracks tab during drag to avoid redundant callbacks

  static const _lime = Color(0xFFCAFF00);

  static const _iconsOutlined = [
    Icons.menu_book_outlined,
    Icons.chat_bubble_outline,
    Icons.explore_outlined,
    Icons.calendar_today_outlined,
    Icons.people_outline,
  ];

  static const _iconsFilled = [
    Icons.menu_book,
    Icons.chat_bubble,
    Icons.explore,
    Icons.calendar_today,
    Icons.people,
  ];

  int _indexFromX(double x) {
    final tabWidth =
        MediaQuery.of(context).size.width / _iconsOutlined.length;
    return (x / tabWidth).floor().clamp(0, _iconsOutlined.length - 1);
  }

  void _selectAt(double x) {
    final index = _indexFromX(x);
    if (index != _activeIndex) {
      _activeIndex = index;
      HapticService.selectionClick();
      widget.onTabChanged(index);
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    _activeIndex = widget.selectedIndex;
    _selectAt(event.localPosition.dx);
  }

  void _handlePointerMove(PointerMoveEvent event) {
    _selectAt(event.localPosition.dx);
  }

  void _handlePointerUp(PointerUpEvent event) {
    _activeIndex = null;
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _activeIndex = null;
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surface;
    final outline = Theme.of(context).colorScheme.outline;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      color: bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(height: 1, thickness: 1, color: outline.withOpacity(0.15)),
          SafeArea(
            top: false,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: _handlePointerDown,
              onPointerMove: _handlePointerMove,
              onPointerUp: _handlePointerUp,
              onPointerCancel: _handlePointerCancel,
              child: SizedBox(
                height: 68,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(_iconsOutlined.length, (index) {
                    final isSelected = widget.selectedIndex == index;
                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            height: 3,
                            width: isSelected ? 32 : 0,
                            color: _lime,
                          ),
                          const SizedBox(height: 14),
                          Icon(
                            isSelected
                                ? _iconsFilled[index]
                                : _iconsOutlined[index],
                            size: isSelected ? 30 : 24,
                            color: isSelected
                                ? onSurface
                                : onSurface.withOpacity(0.35),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

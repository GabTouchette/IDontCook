import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/widgets/common/pressable.dart';

/// Shared top corner radius for all app sheets.
const double kAppSheetRadius = 20;

/// Normalized modal bottom sheet launcher. Wrap the widget returned by
/// [builder] in an [AppSheet] for the shared chrome (rounded top, grab handle,
/// header). The sheet itself is transparent so [AppSheet] paints the surface.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: builder,
  );
}

/// The centered "pull to dismiss" grab handle shown at the top of every sheet.
class AppSheetHandle extends StatelessWidget {
  const AppSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

/// A standard sheet/drawer header — title on the left, optional [actions] then
/// a close button on the right. Shared by bottom sheets, the side filter drawer
/// and full-page surfaces so they all read the same.
class AppSheetHeader extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final bool showClose;
  final VoidCallback? onClose;

  const AppSheetHeader({
    super.key,
    required this.title,
    this.actions = const [],
    this.showClose = true,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                color: onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),
          ...actions,
          if (showClose)
            Pressable(
              haptic: PressHaptic.selection,
              child: IconButton(
                tooltip: 'Close',
                onPressed: onClose ?? () => Navigator.of(context).maybePop(),
                icon: Icon(Icons.close, color: onSurface, size: 24),
              ),
            ),
        ],
      ),
    );
  }
}

/// Standard bottom-sheet chrome: a rounded-top [surface] panel with a grab
/// handle, an optional header ([title] + [headerActions] + close), and the
/// content below.
///
/// Content-sized by default (wraps [child]). Set [fullHeight] for tall or
/// scrollable content that should fill most of the screen — the [child] then
/// manages its own scrolling and is given the remaining space.
class AppSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final List<Widget> headerActions;
  final bool showHandle;
  final bool showClose;
  final bool fullHeight;

  /// Fraction of the screen height used when [fullHeight] is true.
  final double heightFactor;

  const AppSheet({
    super.key,
    required this.child,
    this.title,
    this.headerActions = const [],
    this.showHandle = true,
    // Handled sheets dismiss via the grab handle, barrier tap and drag-down;
    // no close button needed. Pass true only for chrome without a handle.
    this.showClose = false,
    this.fullHeight = false,
    this.heightFactor = 0.92,
  });

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surfaceContainer;
    final hasHeader = title != null || headerActions.isNotEmpty;

    final column = Column(
      mainAxisSize: fullHeight ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (showHandle) const AppSheetHandle(),
        if (hasHeader)
          AppSheetHeader(
            title: title ?? '',
            actions: headerActions,
            showClose: showClose,
          ),
        if (fullHeight)
          Expanded(child: _DragToDismiss(child: child))
        else
          Flexible(child: _DragToDismiss(child: child)),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(kAppSheetRadius)),
      ),
      clipBehavior: Clip.antiAlias,
      child: fullHeight
          ? SizedBox(
              height: MediaQuery.of(context).size.height * heightFactor,
              child: column,
            )
          : column,
    );
  }
}

/// Lets a sheet's scrollable content dismiss the sheet when the user keeps
/// dragging down after reaching the top. Accumulates downward overscroll and
/// pops once it passes [_threshold]; the accumulator resets whenever a new
/// scroll gesture starts. Relies on bouncing overscroll (default on iOS); on
/// platforms with clamping physics the grab handle / barrier tap still dismiss.
class _DragToDismiss extends StatefulWidget {
  final Widget child;

  const _DragToDismiss({required this.child});

  @override
  State<_DragToDismiss> createState() => _DragToDismissState();
}

class _DragToDismissState extends State<_DragToDismiss> {
  static const double _threshold = 80;
  double _pulled = 0;
  bool _dismissing = false;

  bool _onNotification(ScrollNotification n) {
    if (n is ScrollStartNotification) {
      _pulled = 0;
    } else if (n is OverscrollNotification) {
      // Overscroll is negative when pulling down past the top.
      if (n.overscroll < 0 && n.metrics.pixels <= 0) {
        _pulled += -n.overscroll;
        if (_pulled > _threshold && !_dismissing) {
          _dismissing = true;
          Navigator.of(context).maybePop();
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onNotification,
      child: widget.child,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/services/haptic_service.dart';
import 'package:i_cant_cook/widgets/appbar/appbar_user_menu.dart';
import 'package:i_cant_cook/widgets/appbar/grocery_bag_button.dart';
import 'package:i_cant_cook/widgets/common/pressable.dart';

/// Shared app-bar scaffold for the main tabs, so every page's bar is built from
/// the same pieces.
///
/// Layout: [leadingActions…] [search] · TITLE · [grocery-bag] [profile].
///
/// The search button reveals an expandable area ([expandedBuilder]) holding the
/// page's search field and any extras (filter tabs, pickers). It:
///   • opens on tap — the field should set `autofocus: true` so the keyboard
///     comes up immediately,
///   • has no explicit close control — it collapses as soon as the body is
///     scrolled.
class SearchAppBarScaffold extends StatefulWidget {
  final String title;

  /// Widgets placed to the LEFT of the search button (e.g. an add button).
  final List<Widget> leadingActions;

  /// Trailing actions; defaults to the grocery-bag + profile buttons.
  final List<Widget> trailingActions;

  /// Builds the content revealed when search is expanded. When null there is no
  /// search button and no expandable area (e.g. a page with nothing to search).
  final WidgetBuilder? expandedBuilder;

  /// The main (scrollable) content. Scrolling it collapses the search area.
  final Widget body;

  final Color? backgroundColor;

  const SearchAppBarScaffold({
    super.key,
    required this.title,
    required this.body,
    this.leadingActions = const [],
    this.trailingActions = const [GroceryBagButton(), UserMenuWidget()],
    this.expandedBuilder,
    this.backgroundColor,
  });

  @override
  State<SearchAppBarScaffold> createState() => _SearchAppBarScaffoldState();
}

class _SearchAppBarScaffoldState extends State<SearchAppBarScaffold> {
  bool _expanded = false;

  bool get _searchable => widget.expandedBuilder != null;

  void _openSearch() {
    HapticService.selectionClick();
    if (!_expanded) setState(() => _expanded = true);
  }

  void _collapse() {
    if (_expanded) setState(() => _expanded = false);
  }

  /// Close the search area as soon as the body is dragged down — there is no
  /// explicit close button; the scroll gesture dismisses it.
  bool _onScroll(ScrollNotification n) {
    if (_expanded &&
        n is ScrollUpdateNotification &&
        (n.scrollDelta ?? 0) > 2) {
      _collapse();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldBg =
        widget.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;
    // The bars sit a shade above the page background (the same elevated surface
    // the nav bar uses) so they read as distinct chrome rather than blending in.
    final barColor = Theme.of(context).colorScheme.surfaceContainer;
    final primary = Theme.of(context).colorScheme.primary;

    final leftButtons = <Widget>[
      ...widget.leadingActions,
      if (_searchable)
        Pressable(
          // Haptic handled by _openSearch; wrapper just adds the press-scale.
          haptic: PressHaptic.none,
          child: IconButton(
            tooltip: 'Search',
            onPressed: _openSearch,
            icon: Icon(Icons.search, color: primary, size: 28),
          ),
        ),
    ];

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: barColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        // Hairline under the bar — mirrors the nav bar's top divider — so the
        // chrome stays legible even where the surface/background step is subtle.
        shape: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        automaticallyImplyLeading: false,
        centerTitle: true,
        // Match the 16px edge margin the profile button carries on the right
        // ([UserMenuWidget] uses `EdgeInsets.only(right: 16)`), so the leftmost
        // button sits the same distance from its edge.
        leadingWidth:
            leftButtons.isEmpty ? null : leftButtons.length * 48.0 + 20,
        leading: leftButtons.isEmpty
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: 16),
                child:
                    Row(mainAxisSize: MainAxisSize.min, children: leftButtons),
              ),
        title: Text(
          widget.title,
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            letterSpacing: 2.5,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: widget.trailingActions,
      ),
      body: Column(
        children: [
          // The expandable search area sits on the page background; its own
          // surface-coloured search box provides the contrast.
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _expanded && _searchable
                ? widget.expandedBuilder!(context)
                : const SizedBox(width: double.infinity),
          ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: Stack(
                children: [
                  widget.body,
                  // While expanded, a transparent barrier over the body catches
                  // a tap anywhere to dismiss — and absorbs it, so nothing
                  // underneath (a recipe tile, a card) fires. It's translucent
                  // and only recognises taps, so a drag falls through to the
                  // list: the search then closes via the scroll gesture
                  // (_onScroll) instead of vanishing the instant you touch down.
                  if (_expanded)
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: _collapse,
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

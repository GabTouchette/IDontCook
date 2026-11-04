import 'package:flutter/material.dart';

/// A single rounded placeholder block. Fill is theme-aware (a translucent tint
/// of onSurface) so it stays visible in both light and dark mode — unlike
/// surfaceContainerHighest, which is pure black in dark mode and would vanish on
/// the near-black scaffold.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double radius;
  final EdgeInsetsGeometry? margin;

  const SkeletonBox({
    this.width,
    this.height,
    this.radius = 8,
    this.margin,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Wraps a subtree in a slow opacity pulse — the app's established skeleton
/// animation (see RecipeDetailSkeleton). One controller drives the whole tree.
class _SkeletonPulse extends StatefulWidget {
  final Widget child;
  const _SkeletonPulse({required this.child});

  @override
  State<_SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<_SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

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
    return FadeTransition(opacity: _animation, child: widget.child);
  }
}

/// Loading placeholder for the adaptive home feed. Mirrors the real layout:
/// greeting row, a divider, a hero card, then two horizontal rails of tiles.
class HomeFeedSkeleton extends StatelessWidget {
  const HomeFeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return _SkeletonPulse(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        children: [
          // Greeting row: avatar + two text lines.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonBox(width: 36, height: 36, radius: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(width: 180, height: 14),
                    SizedBox(height: 8),
                    SkeletonBox(width: 240, height: 14),
                  ],
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(0, 16, 0, 16),
            height: 1,
            color: onSurface.withValues(alpha: 0.08),
          ),
          // Hero suggestion card.
          const SkeletonBox(width: double.infinity, height: 210, radius: 16),
          const SizedBox(height: 24),
          // Rail 1.
          _railBlock(),
          const SizedBox(height: 24),
          // Rail 2.
          _railBlock(),
        ],
      ),
    );
  }

  Widget _railBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonBox(width: 150, height: 16),
        const SizedBox(height: 12),
        SizedBox(
          height: 176,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, __) => const _RailTileSkeleton(),
          ),
        ),
      ],
    );
  }
}

/// Matches the ExploreRail _RailTile shape: 140 wide, 96 image box + two bars.
class _RailTileSkeleton extends StatelessWidget {
  const _RailTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SkeletonBox(width: 140, height: 96, radius: 10),
          Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 120, height: 12),
                SizedBox(height: 8),
                SkeletonBox(width: 70, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading placeholder for the Recipes list. Mirrors RecipeTile's three tile
/// modes (0 = small list rows, 1 = medium thumbnail rows, 2 = large cards) so
/// the skeleton matches whatever layout the user last selected.
class RecipesListSkeleton extends StatelessWidget {
  /// 0 = small, 1 = medium, 2 = large — matches UserRecipesProvider.tileMode.
  final int tileMode;
  final int itemCount;

  const RecipesListSkeleton({
    this.tileMode = 1,
    this.itemCount = 8,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final divider =
        Theme.of(context).colorScheme.outline.withValues(alpha: 0.08);
    return _SkeletonPulse(
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // List header: "N RECIPES" bar + the three layout-toggle squares.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: const [
                SkeletonBox(width: 90, height: 14),
                Spacer(),
                SkeletonBox(width: 42, height: 42, radius: 0),
                SizedBox(width: 6),
                SkeletonBox(width: 42, height: 42, radius: 0),
                SizedBox(width: 6),
                SkeletonBox(width: 42, height: 42, radius: 0),
              ],
            ),
          ),
          for (int i = 0; i < itemCount; i++) ...[
            _tileForMode(context),
            if (tileMode != 2)
              Divider(
                height: 1,
                thickness: 1,
                indent: 16,
                endIndent: 16,
                color: divider,
              )
            else
              Divider(height: 1, thickness: 1, color: divider),
          ],
        ],
      ),
    );
  }

  Widget _tileForMode(BuildContext context) {
    switch (tileMode) {
      case 0:
        return _smallTile();
      case 2:
        return _largeTile();
      default:
        return _mediumTile();
    }
  }

  // Small: title + meta line, no thumbnail.
  Widget _smallTile() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 200, height: 16),
          SizedBox(height: 8),
          SkeletonBox(width: 110, height: 12),
        ],
      ),
    );
  }

  // Medium: 80px square thumbnail + title/meta.
  Widget _mediumTile() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 80, height: 80, radius: 0),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: double.infinity, height: 16),
                SizedBox(height: 8),
                SkeletonBox(width: 150, height: 16),
                SizedBox(height: 10),
                SkeletonBox(width: 90, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Large: full-bleed image + title, stats and tag chips.
  Widget _largeTile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SkeletonBox(width: double.infinity, height: 200, radius: 0),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 240, height: 22),
              SizedBox(height: 10),
              SkeletonBox(width: 160, height: 12),
              SizedBox(height: 12),
              Row(
                children: [
                  SkeletonBox(width: 64, height: 22, radius: 0),
                  SizedBox(width: 6),
                  SkeletonBox(width: 80, height: 22, radius: 0),
                  SizedBox(width: 6),
                  SkeletonBox(width: 52, height: 22, radius: 0),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Loading placeholder for the full-bleed Explore reel card. Mirrors
/// ReelRecipeCard: a rounded full-viewport block with a bottom content area
/// (title, time, tag chips) and the right-hand circular action rail.
class ExploreReelSkeleton extends StatelessWidget {
  const ExploreReelSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _SkeletonPulse(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Full-bleed card background.
              const SkeletonBox(radius: 20),
              // Right-hand action rail (favorite / thumb-down).
              Positioned(
                right: 12,
                bottom: 130,
                child: Column(
                  children: const [
                    SkeletonBox(width: 46, height: 46, radius: 23),
                    SizedBox(height: 16),
                    SkeletonBox(width: 46, height: 46, radius: 23),
                  ],
                ),
              ),
              // Bottom content: title, time line, tag chips.
              Positioned(
                left: 20,
                right: 88,
                bottom: 28,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonBox(width: double.infinity, height: 26),
                    const SizedBox(height: 10),
                    const SkeletonBox(width: 160, height: 14),
                    const SizedBox(height: 14),
                    Row(
                      children: const [
                        SkeletonBox(width: 64, height: 22, radius: 11),
                        SizedBox(width: 6),
                        SkeletonBox(width: 80, height: 22, radius: 11),
                        SizedBox(width: 6),
                        SkeletonBox(width: 52, height: 22, radius: 11),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

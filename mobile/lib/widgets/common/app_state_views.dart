import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/services/haptic_service.dart';

/// Shared "no content" view — lime icon block, tracked headline, underline
/// rule, body copy, optional action — matching the pattern already used by
/// Recipes/Explore so every feed renders the same empty state instead of
/// each page inventing its own (some pages previously fell back to a single
/// line of plain text with no icon or retry affordance).
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lime = scheme.secondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              color: lime,
              child: Icon(icon, color: scheme.onSecondary, size: 24),
            ),
            const SizedBox(height: 20),
            Column(
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    letterSpacing: 2.0,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Container(width: 32, height: 2, color: lime),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.6,
                color: scheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 22),
              GestureDetector(
                onTap: () {
                  HapticService.lightImpact();
                  onAction!();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 11, horizontal: 28),
                  decoration: BoxDecoration(color: lime),
                  child: Text(
                    actionLabel!.toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 1.1,
                      color: scheme.onSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shared "something went wrong" view with a retry affordance, so network/
/// load failures get a consistent recovery path instead of a one-off toast
/// with no way back in.
class ErrorStateView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String title;

  const ErrorStateView({
    super.key,
    this.title = 'Something went wrong',
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              color: scheme.error,
              child: Icon(Icons.error_outline, color: scheme.onError, size: 24),
            ),
            const SizedBox(height: 20),
            Column(
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    letterSpacing: 2.0,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Container(width: 32, height: 2, color: scheme.error),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.6,
                color: scheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: () {
                HapticService.lightImpact();
                onRetry();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 11, horizontal: 28),
                decoration: BoxDecoration(color: scheme.error),
                child: Text(
                  'RETRY',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 1.1,
                    color: scheme.onError,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared lightweight loading view for pages that don't have a bespoke
/// shimmer skeleton — a centered spinner plus an optional caption, so
/// "loading" at least looks the same everywhere instead of a bare
/// CircularProgressIndicator on some pages and nothing comparable on others.
class LoadingStateView extends StatelessWidget {
  final String? message;

  const LoadingStateView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: scheme.secondary),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

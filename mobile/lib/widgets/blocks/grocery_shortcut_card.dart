import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/home_module/home_module.dart';
import 'package:i_cant_cook/models/home_module/module_payloads.dart';
import 'package:i_cant_cook/theme/theme.dart';
import 'package:i_cant_cook/widgets/blocks/block_styles.dart';

/// Renders a `grocery_shortcut` module as a compact, cool-tinted banner
/// strip (cart icon, "N items", CTA) — distinct from the recipe-related
/// cards elsewhere in the feed. Tapping the row calls [onCtaTap] with the
/// owning [module] (`BlockCallbacks.onModuleCtaTap`).
class GroceryShortcutCard extends StatelessWidget {
  final HomeModule module;
  final void Function(HomeModule module)? onCtaTap;

  const GroceryShortcutCard({
    super.key,
    required this.module,
    this.onCtaTap,
  });

  GroceryShortcutPayload get payload =>
      module.payload as GroceryShortcutPayload;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = Theme.of(context).colorScheme.info;
    final itemLabel =
        '${payload.item_count} ${payload.item_count == 1 ? 'item' : 'items'}';

    return GestureDetector(
      onTap: () => onCtaTap?.call(module),
      child: Container(
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.10),
          border: Border(left: BorderSide(color: accent, width: 3.0)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shopping_cart_outlined, size: 18, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itemLabel,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: onSurface,
                    ),
                  ),
                  if (module.reason.isNotEmpty)
                    Text(
                      module.reason,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: reasonTextStyle(context),
                    ),
                ],
              ),
            ),
            if (payload.cta.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                payload.cta,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward,
                size: 16,
                color: accent,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

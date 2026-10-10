import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/api/api_config.dart';
import 'package:i_cant_cook/models/home_module/module_payloads.dart';
import 'package:i_cant_cook/widgets/blocks/block_styles.dart';
import 'package:i_cant_cook/widgets/blocks/deals_rail.dart'
    show dealPriceLabel, dealSavingsColor;

/// Opens the deal-detail drawer for [item] as a draggable modal bottom sheet.
///
/// Shared by the home-feed deals rail and the "See all deals" grid so a tapped
/// deal shows the same full details + full (uncropped, pinch-zoomable) image
/// everywhere.
Future<void> showDealDetail(BuildContext context, DealItem item) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DealDetailSheet(item: item),
  );
}

/// The drawer body: full image up top, then every detail we have for the deal.
class DealDetailSheet extends StatelessWidget {
  final DealItem item;

  const DealDetailSheet({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          clipBehavior: Clip.antiAlias,
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              _grabHandle(theme),
              _image(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.brand.isNotEmpty) ...[
                      Text(
                        item.brand.toUpperCase(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      item.name,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        letterSpacing: -0.3,
                        color: onSurface,
                      ),
                    ),
                    if (item.name_alt != null && item.name_alt!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.name_alt!,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _priceRow(context),
                    const SizedBox(height: 20),
                    _detailRow(
                      context,
                      Icons.storefront_outlined,
                      item.distanceLabel != null
                          ? '${item.merchant} · ${item.distanceLabel}'
                          : item.merchant,
                    ),
                    if (item.validUntilLabel != null) ...[
                      const SizedBox(height: 12),
                      _detailRow(
                        context,
                        Icons.event_outlined,
                        item.validUntilLabel!,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _grabHandle(ThemeData theme) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 6),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _image(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Container(
          height: 280,
          width: double.infinity,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
          child: item.image_url != null
              // InteractiveViewer lets the user pinch-zoom the flyer cutout;
              // BoxFit.contain keeps the whole image visible (uncropped).
              ? InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Image.network(
                    ApiConfig.resolveImageUrl(item.image_url!),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(context),
                  ),
                )
              : _imagePlaceholder(context),
        ),
        if (item.discount != null && item.discount! > 0)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: kBlockAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '-${item.discount}%',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: kBlockAccentInk,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _priceRow(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          dealPriceLabel(item),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: onSurface,
          ),
        ),
        if (item.savingsLabel != null) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: dealSavingsColor(context).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.savingsLabel!,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: dealSavingsColor(context),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _detailRow(BuildContext context, IconData icon, String text) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Icon(icon, size: 18, color: onSurface.withValues(alpha: 0.55)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: onSurface.withValues(alpha: 0.75),
            ),
          ),
        ),
      ],
    );
  }

  Widget _imagePlaceholder(BuildContext context) {
    return Center(
      child: Icon(
        Icons.shopping_basket_outlined,
        size: 48,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25),
      ),
    );
  }
}

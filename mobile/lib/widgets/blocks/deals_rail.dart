import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/api/api_config.dart';
import 'package:i_cant_cook/enums/toast_type.dart';
import 'package:i_cant_cook/models/home_module/module_payloads.dart';
import 'package:i_cant_cook/pages/deals_page.dart';
import 'package:i_cant_cook/providers/home_feed_provider.dart';
import 'package:i_cant_cook/providers/settings_provider.dart';
import 'package:i_cant_cook/services/location_service.dart';
import 'package:i_cant_cook/widgets/blocks/block_styles.dart';
import 'package:i_cant_cook/widgets/deals/deal_detail_sheet.dart';
import 'package:i_cant_cook/widgets/toasts/information_toast.dart';
import 'package:provider/provider.dart';

/// Renders a `deals_rail` module — the biggest discounts pooled from the user's
/// nearest stores. Three states:
///  * `setup`   — no location yet: a prompt to turn on location.
///  * `loading` — location known, deals still warming server-side: a "finding
///     deals" placeholder while the client polls for the ready rail.
///  * `ready`   — a horizontal rail of the top deals nearby, each tagged with
///     the store it's from, plus "See all".
class DealsRail extends StatelessWidget {
  final DealsRailPayload payload;
  final String reason;

  const DealsRail({super.key, required this.payload, required this.reason});

  @override
  Widget build(BuildContext context) {
    if (payload.needsSetup) return _SetupCard(reason: reason);
    if (payload.isLoading) return _LoadingCard(reason: reason);
    if (payload.items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.local_offer_outlined,
                size: 16, color: theme.colorScheme.onSurface),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                reason.isNotEmpty ? reason : 'Best deals near you right now',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            _SeeAllButton(onTap: () => _openAll(context)),
          ],
        ),
        if (payload.stores.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 24, top: 2),
            child: Text(
              'across ${payload.stores.length} stores nearby',
              style: reasonTextStyle(context),
            ),
          ),
        const SizedBox(height: 10),
        SizedBox(
          height: 214,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: payload.items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) =>
                _DealTile(item: payload.items[index]),
          ),
        ),
      ],
    );
  }

  void _openAll(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DealsPage()),
    );
  }
}

/// Formats a deal's price: a clean `$X.XX` from the parsed unit price when
/// available, else the raw flyer string (e.g. "2/$5.00"), else a fallback.
String dealPriceLabel(DealItem item) {
  if (item.price_value != null) {
    return '\$${item.price_value!.toStringAsFixed(2)}';
  }
  if (item.price != null && item.price!.isNotEmpty) return item.price!;
  return 'See flyer';
}

/// A readable "savings" green that works on light and dark surfaces (deals are
/// ranked by $ saved, so this is the emphasis color for the "Save $X" label).
Color dealSavingsColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF4ADE80)
      : const Color(0xFF16A34A);
}

class _DealTile extends StatelessWidget {
  final DealItem item;

  const _DealTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: () => showDealDetail(context, item),
      child: Container(
        width: 150,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 100,
                  width: double.infinity,
                  child: item.image_url != null
                      ? Image.network(
                          ApiConfig.resolveImageUrl(item.image_url!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _imagePlaceholder(context),
                        )
                      : _imagePlaceholder(context),
                ),
                if (item.discount != null && item.discount! > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: kBlockAccent(context),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '-${item.discount}%',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: kBlockAccentInk(context),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          color: onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          dealPriceLabel(item),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: onSurface,
                          ),
                        ),
                        if (item.savingsLabel != null) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.savingsLabel!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: dealSavingsColor(context),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    // Which store this deal is from, and how far.
                    Row(
                      children: [
                        Icon(Icons.storefront_outlined,
                            size: 11, color: onSurface.withValues(alpha: 0.5)),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            item.distanceLabel != null
                                ? '${item.merchant} · ${item.distanceLabel}'
                                : item.merchant,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
      child: Icon(
        Icons.shopping_basket_outlined,
        size: 24,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
      ),
    );
  }
}

class _SeeAllButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SeeAllButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      child: Row(
        children: [
          Text(
            'See all',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Icon(Icons.chevron_right, size: 18),
        ],
      ),
    );
  }
}

/// The `setup` state: prompts to turn on location, then refreshes the feed so
/// the deals rail populates from the nearest stores.
class _SetupCard extends StatefulWidget {
  final String reason;

  const _SetupCard({required this.reason});

  @override
  State<_SetupCard> createState() => _SetupCardState();
}

class _SetupCardState extends State<_SetupCard> {
  final LocationService _location = LocationService();
  bool _busy = false;

  Future<void> _enableLocation() async {
    setState(() => _busy = true);
    final result = await _location.current();
    if (!mounted) return;
    setState(() => _busy = false);

    if (result.status == LocationStatus.ok && result.location != null) {
      final loc = result.location!;
      await context.read<SettingsProvider>().saveLocation(
            latitude: loc.latLng.latitude,
            longitude: loc.latLng.longitude,
            postalCode: loc.postalCode,
          );
      // Refetch to pick up the new coords, then keep polling until the deals
      // rail warms server-side (cold cache) — otherwise the rail would never
      // appear until a manual refresh minutes later. The poll lives on the
      // provider so it survives this setup card being replaced by the loading
      // card on the first refetch.
      if (mounted) {
        unawaited(context.read<HomeFeedProvider>().refreshForNewLocation());
      }
      return;
    }

    final message = switch (result.status) {
      LocationStatus.serviceDisabled =>
        'Location services are off. Turn them on to see nearby deals.',
      LocationStatus.deniedForever =>
        'Location is blocked in Settings. Enable it to see nearby deals.',
      _ => 'Couldn’t get your location. Please try again.',
    };
    InformationToast.show(
        context: context, message: message, type: ToastType.warning);
    if (result.status == LocationStatus.deniedForever) {
      _location.openSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: blockCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_offer_outlined,
                  size: 18, color: theme.colorScheme.onSurface),
              const SizedBox(width: 8),
              Text(
                'Weekly grocery deals',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.reason.isNotEmpty
                ? widget.reason
                : 'Turn on location to see the best deals at stores near you.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13.5,
              height: 1.35,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _enableLocation,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: kBlockAccent(context),
                foregroundColor: kBlockAccentInk(context),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              label: Text(
                _busy ? 'Locating…' : 'Turn on location',
                style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown while the deals rail is warming server-side (cold cache) after the
/// user has enabled location — keeps a card in place instead of a blank gap
/// while [HomeFeedProvider.refreshForNewLocation] polls for the ready rail.
class _LoadingCard extends StatelessWidget {
  final String reason;

  const _LoadingCard({required this.reason});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: blockCardDecoration(context),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              reason.isNotEmpty ? reason : 'Finding the best deals near you…',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

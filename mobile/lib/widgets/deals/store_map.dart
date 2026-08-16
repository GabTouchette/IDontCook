import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/grocery_store/grocery_store.dart';
import 'package:i_cant_cook/widgets/blocks/block_styles.dart';
import 'package:latlong2/latlong.dart';

/// A themed map of nearby grocery stores. Base tiles are neutral greyscale
/// (CARTO light/dark, following the app theme) so the app's lime accent on the
/// pins carries the branding. Tapping a pin selects that store.
class StoreMap extends StatefulWidget {
  final LatLng center;
  final List<GroceryStore> stores; // only stores with coordinates
  final int? selectedMerchantId;
  final void Function(GroceryStore store) onStoreTap;

  /// Fixed height for an inline card; null lets the map fill its parent (e.g.
  /// inside a tab). The parent must supply bounded constraints when null.
  final double? height;
  final double borderRadius;

  const StoreMap({
    super.key,
    required this.center,
    required this.stores,
    required this.selectedMerchantId,
    required this.onStoreTap,
    this.height = 220,
    this.borderRadius = 14,
  });

  @override
  State<StoreMap> createState() => _StoreMapState();
}

class _StoreMapState extends State<StoreMap> {
  final MapController _mapController = MapController();

  LatLng get center => widget.center;
  List<GroceryStore> get stores => widget.stores;
  int? get selectedMerchantId => widget.selectedMerchantId;

  void _zoomBy(double delta) {
    final cam = _mapController.camera;
    final z = (cam.zoom + delta).clamp(10.0, 18.0);
    _mapController.move(cam.center, z);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // CARTO basemaps — brand-neutral greyscale that reads as light/dark.
    final tileUrl = isDark
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
        : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';

    final content = ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Stack(
        children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 13,
                minZoom: 10,
                maxZoom: 18,
                interactionOptions: const InteractionOptions(
                  // Everything except rotate — notably scrollWheelZoom (mouse
                  // wheel / trackpad on web + desktop) so zoom isn't touch-only.
                  flags: InteractiveFlag.pinchZoom |
                      InteractiveFlag.drag |
                      InteractiveFlag.doubleTapZoom |
                      InteractiveFlag.scrollWheelZoom |
                      InteractiveFlag.flingAnimation |
                      InteractiveFlag.pinchMove,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: tileUrl,
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.icantcook.app',
                  tileProvider: NetworkTileProvider(),
                ),
                MarkerLayer(markers: _buildMarkers(context)),
                const RichAttributionWidget(
                  alignment: AttributionAlignment.bottomLeft,
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                    TextSourceAttribution('CARTO'),
                  ],
                ),
              ],
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: _ZoomControls(
                onZoomIn: () => _zoomBy(1),
                onZoomOut: () => _zoomBy(-1),
              ),
            ),
          ],
        ),
      );

    return widget.height == null
        ? content
        : SizedBox(height: widget.height, child: content);
  }

  List<Marker> _buildMarkers(BuildContext context) {
    final markers = <Marker>[
      // The user's area center — a small neutral dot.
      Marker(
        point: center,
        width: 18,
        height: 18,
        child: _CenterDot(),
      ),
    ];
    for (final store in stores) {
      final selected = store.merchant_id == selectedMerchantId;
      markers.add(
        Marker(
          point: LatLng(store.lat!, store.lng!),
          width: 128,
          height: 58,
          // Icon sits on the point; the name label hangs just below it.
          alignment: Alignment.topCenter,
          child: _StorePin(
            store: store,
            selected: selected,
            onTap: () => widget.onStoreTap(store),
          ),
        ),
      );
    }
    return markers;
  }
}

class _CenterDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.primary,
        shape: BoxShape.circle,
        border: Border.all(color: scheme.surface, width: 3),
      ),
    );
  }
}

class _StorePin extends StatelessWidget {
  final GroceryStore store;
  final bool selected;
  final VoidCallback onTap;

  const _StorePin({
    required this.store,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Marker dot — filled lime when selected.
          Container(
            width: selected ? 30 : 26,
            height: selected ? 30 : 26,
            decoration: BoxDecoration(
              color: selected ? kBlockAccent : scheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: kBlockAccent, width: selected ? 3 : 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.storefront,
              size: selected ? 16 : 14,
              color: selected ? kBlockAccentInk : scheme.onSurface,
            ),
          ),
          const SizedBox(height: 3),
          // Always-visible name label.
          Container(
            constraints: const BoxConstraints(maxWidth: 120),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: selected ? kBlockAccent : scheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: selected
                    ? kBlockAccent
                    : scheme.outline.withValues(alpha: 0.25),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              store.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: selected ? kBlockAccentInk : scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stacked +/- buttons — a reliable zoom affordance in addition to scroll /
/// pinch / double-tap (on web the page can swallow wheel events).
class _ZoomControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const _ZoomControls({required this.onZoomIn, required this.onZoomOut});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ZoomButton(icon: Icons.add, onTap: onZoomIn),
          Divider(
              height: 1, thickness: 1,
              color: scheme.outline.withValues(alpha: 0.2)),
          _ZoomButton(icon: Icons.remove, onTap: onZoomOut),
        ],
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ZoomButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 38,
        height: 38,
        child: Icon(icon,
            size: 20, color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }
}

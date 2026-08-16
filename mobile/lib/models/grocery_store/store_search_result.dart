import 'package:i_cant_cook/models/grocery_store/grocery_store.dart';
import 'package:latlong2/latlong.dart';

/// Result of a store search: the nearby stores plus the map center (present
/// only when the client passed a location to enrich stores with coordinates).
class StoreSearchResult {
  final List<GroceryStore> stores;
  final LatLng? center;

  /// The postal code the results are for — echoed by the backend, which may
  /// have resolved it from GPS coordinates. Used to persist the chosen store.
  final String? postalCode;

  const StoreSearchResult({required this.stores, this.center, this.postalCode});

  static const empty = StoreSearchResult(stores: []);

  factory StoreSearchResult.fromJson(Map<String, dynamic> json) {
    final rawStores = json['stores'];
    final stores = rawStores is List
        ? rawStores
            .map((s) => GroceryStore.fromJson(s as Map<String, dynamic>))
            .toList()
        : <GroceryStore>[];

    LatLng? center;
    final rawCenter = json['center'];
    if (rawCenter is Map &&
        rawCenter['lat'] is num &&
        rawCenter['lng'] is num) {
      center = LatLng(
        (rawCenter['lat'] as num).toDouble(),
        (rawCenter['lng'] as num).toDouble(),
      );
    }
    final postal = json['postal_code'];
    return StoreSearchResult(
      stores: stores,
      center: center,
      postalCode: postal is String && postal.isNotEmpty ? postal : null,
    );
  }

  /// Stores that matched an OSM POI and can be shown as map pins.
  List<GroceryStore> get locatedStores =>
      stores.where((s) => s.hasLocation).toList();
}

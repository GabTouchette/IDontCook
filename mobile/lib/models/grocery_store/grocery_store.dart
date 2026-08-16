import 'package:freezed_annotation/freezed_annotation.dart';

part 'grocery_store.freezed.dart';
part 'grocery_store.g.dart';

/// A grocery merchant with an active weekly flyer near the user, as returned
/// by `GET /api/home/stores/`. Field names mirror the API wire format.
@freezed
class GroceryStore with _$GroceryStore {
  const GroceryStore._();

  const factory GroceryStore({
    required String merchant,
    required int merchant_id,
    int? flyer_id,
    String? logo_url,
    String? valid_from,
    String? valid_to,
    // Specific location name from OSM (e.g. "Metro Marcano"); falls back to the
    // banner name. Present + lat/lng/distance_m set when a location matched.
    String? name,
    double? lat,
    double? lng,
    int? distance_m,
  }) = _GroceryStore;

  factory GroceryStore.fromJson(Map<String, dynamic> json) =>
      _$GroceryStoreFromJson(json);

  bool get hasLocation => lat != null && lng != null;

  /// Best display name: the specific location when known, else the banner.
  String get displayName => (name != null && name!.isNotEmpty) ? name! : merchant;

  /// True when the location has a more specific name than its banner.
  bool get hasSpecificName =>
      name != null && name!.isNotEmpty && name != merchant;

  /// "800 m" / "1.2 km" — null when distance is unknown.
  String? get distanceLabel {
    final d = distance_m;
    if (d == null) return null;
    if (d < 1000) return '$d m';
    return '${(d / 1000).toStringAsFixed(1)} km';
  }
}

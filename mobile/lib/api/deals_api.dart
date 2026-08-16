import 'package:i_cant_cook/api/api_helper.dart';
import 'package:i_cant_cook/models/grocery_store/store_search_result.dart';
import 'package:i_cant_cook/models/store_deals/store_deals.dart';

/// Client for the grocery-deals endpoints (Flipp-backed).
class DealsApi {
  final ApiHelper _apiHelper = ApiHelper();

  /// Grocery stores with an active weekly flyer near [postalCode]. When exact
  /// [lat]/[lng] from GPS are supplied they override the postal-code centroid,
  /// so the map center and proximity are exact; the postal code is still needed
  /// for Flipp's banner lookup.
  Future<StoreSearchResult> searchStores(
    String postalCode, {
    double? lat,
    double? lng,
  }) async {
    final queryParams = <String, String>{'postal_code': postalCode};
    if (lat != null && lng != null) {
      queryParams['lat'] = lat.toString();
      queryParams['lng'] = lng.toString();
    }
    final data = await _apiHelper.getRequest(
      'home/stores/',
      queryParams: queryParams,
    );
    if (data is Map<String, dynamic>) {
      return StoreSearchResult.fromJson(data);
    }
    return StoreSearchResult.empty;
  }

  /// The full "see all" list: biggest discounts pooled from the nearest stores.
  /// Pass exact [lat]/[lng] (GPS) for precise proximity; otherwise the backend
  /// uses the user's persisted settings location. [merchantIds] aggregates that
  /// curated set of stores instead of the nearest ones.
  Future<StoreDeals?> fetchDeals({
    double? lat,
    double? lng,
    List<int>? merchantIds,
  }) async {
    final queryParams = <String, String>{};
    if (lat != null && lng != null) {
      queryParams['lat'] = lat.toString();
      queryParams['lng'] = lng.toString();
    }
    if (merchantIds != null && merchantIds.isNotEmpty) {
      queryParams['merchant_ids'] = merchantIds.join(',');
    }
    final data = await _apiHelper.getRequest(
      'home/deals/',
      queryParams: queryParams.isEmpty ? null : queryParams,
    );
    if (data is Map<String, dynamic>) {
      return StoreDeals.fromJson(data);
    }
    return null;
  }
}

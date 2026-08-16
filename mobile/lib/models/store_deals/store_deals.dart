import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:i_cant_cook/models/home_module/module_payloads.dart';

part 'store_deals.freezed.dart';
part 'store_deals.g.dart';

/// The full "See all deals" payload from `GET /api/home/deals/` — the biggest
/// discounts pooled from the nearest stores. Reuses [DealItem] (tagged with its
/// store) and [DealStore] from the module payloads.
@freezed
class StoreDeals with _$StoreDeals {
  const factory StoreDeals({
    String? postal_code,
    @Default(<DealStore>[]) List<DealStore> stores,
    @Default(0) int total_count,
    @Default(<DealItem>[]) List<DealItem> items,
  }) = _StoreDeals;

  factory StoreDeals.fromJson(Map<String, dynamic> json) =>
      _$StoreDealsFromJson(json);
}

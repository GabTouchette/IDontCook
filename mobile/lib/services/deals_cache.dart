import 'dart:convert';

import 'package:i_cant_cook/models/home_module/module_payloads.dart';
import 'package:i_cant_cook/models/store_deals/store_deals.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local (SharedPreferences) cache for the "Deals near you" page: the last
/// fetched deals payload (instant load on future visits), the user's curated
/// store list (proposed + manually added, minus removed), and the chosen store
/// filter (which of those to show).
class DealsCache {
  static const _dealsKey = 'deals_cache_v1';
  static const _filterKey = 'deals_store_filter_v1';
  static const _storesKey = 'deals_managed_stores_v1';
  static const _seededKey = 'deals_seeded_v1';

  Future<StoreDeals?> readDeals() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dealsKey);
    if (raw == null) return null;
    try {
      return StoreDeals.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> writeDeals(StoreDeals deals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dealsKey, jsonEncode(deals.toJson()));
  }

  /// The set of merchant names the user has filtered to (empty = all stores).
  Future<Set<String>> readStoreFilter() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_filterKey) ?? const <String>[]).toSet();
  }

  Future<void> writeStoreFilter(Set<String> merchants) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_filterKey, merchants.toList());
  }

  /// The user's curated store list (proposed nearby + manually added, minus any
  /// removed). Empty when never curated — the page then seeds from nearby.
  Future<List<DealStore>> readManagedStores() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storesKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((s) => DealStore.fromJson(s as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> writeManagedStores(List<DealStore> stores) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storesKey,
      jsonEncode(stores.map((s) => s.toJson()).toList()),
    );
  }

  /// Whether the store list has been seeded from nearby at least once — so an
  /// empty managed list means "user removed all" (don't re-seed) rather than
  /// "first visit" (seed from nearby).
  Future<bool> readSeeded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seededKey) ?? false;
  }

  Future<void> writeSeeded(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seededKey, value);
  }
}

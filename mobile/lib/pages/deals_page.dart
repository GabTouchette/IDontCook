import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/api/api_config.dart';
import 'package:i_cant_cook/api/deals_api.dart';
import 'package:i_cant_cook/models/grocery_store/grocery_store.dart';
import 'package:i_cant_cook/models/home_module/module_payloads.dart';
import 'package:i_cant_cook/models/store_deals/store_deals.dart';
import 'package:i_cant_cook/pages/store_finder_page.dart';
import 'package:i_cant_cook/services/deals_cache.dart';
import 'package:i_cant_cook/services/location_service.dart';
import 'package:i_cant_cook/widgets/blocks/block_styles.dart';
import 'package:i_cant_cook/widgets/blocks/deals_rail.dart';
import 'package:i_cant_cook/widgets/deals/deal_detail_sheet.dart';

/// Full "See all deals" list — the biggest discounts pooled from a curated set
/// of nearby stores. The store list is seeded from the nearest stores, then the
/// user can add stores (via the picker "+") or remove them. Deals, the store
/// list, and the view filter are all cached locally so they persist.
class DealsPage extends StatefulWidget {
  const DealsPage({super.key});

  @override
  State<DealsPage> createState() => _DealsPageState();
}

class _DealsPageState extends State<DealsPage> {
  final DealsApi _dealsApi = DealsApi();
  final LocationService _location = LocationService();
  final DealsCache _cache = DealsCache();

  StoreDeals? _deals;
  List<DealStore> _managedStores = [];
  Set<String> _selectedMerchants = {};
  bool _isLoading = true;
  bool _seeded = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final cached = await _cache.readDeals();
    final stores = await _cache.readManagedStores();
    final filter = await _cache.readStoreFilter();
    final seeded = await _cache.readSeeded();
    if (mounted) {
      setState(() {
        _deals = cached;
        _managedStores = stores;
        _selectedMerchants = filter;
        _seeded = seeded;
        _isLoading = cached == null;
      });
    }
    await _refresh();
  }

  List<int> get _managedIds =>
      _managedStores.map((s) => s.merchant_id).toList();

  Future<void> _refresh() async {
    final latLng = await _location.currentIfPermitted();
    final lat = latLng?.latitude;
    final lng = latLng?.longitude;

    StoreDeals? deals;
    if (_managedStores.isNotEmpty) {
      deals = await _dealsApi.fetchDeals(
          lat: lat, lng: lng, merchantIds: _managedIds);
    } else if (!_seeded) {
      // First visit — seed the store list from the nearest stores.
      deals = await _dealsApi.fetchDeals(lat: lat, lng: lng);
    }
    if (!mounted) return;

    if (deals != null) {
      await _cache.writeDeals(deals);
      if (_managedStores.isEmpty && !_seeded && deals.stores.isNotEmpty) {
        _managedStores = List.of(deals.stores);
        _seeded = true;
        await _cache.writeManagedStores(_managedStores);
        await _cache.writeSeeded(true);
      }
    }
    setState(() {
      if (deals != null) _deals = deals;
      _isLoading = false;
    });
  }

  List<DealItem> get _filteredItems {
    var items = _deals?.items ?? const <DealItem>[];
    if (_selectedMerchants.isNotEmpty) {
      items = items
          .where((it) => _selectedMerchants.contains(it.merchant))
          .toList();
    }
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      items = items
          .where((it) =>
              it.name.toLowerCase().contains(q) ||
              (it.name_alt?.toLowerCase().contains(q) ?? false) ||
              it.brand.toLowerCase().contains(q) ||
              it.merchant.toLowerCase().contains(q))
          .toList();
    }
    return items;
  }

  void _toggleMerchant(String merchant) {
    setState(() {
      if (_selectedMerchants.contains(merchant)) {
        _selectedMerchants.remove(merchant);
      } else {
        _selectedMerchants.add(merchant);
      }
    });
    _cache.writeStoreFilter(_selectedMerchants);
  }

  void _clearFilter() {
    setState(() => _selectedMerchants = {});
    _cache.writeStoreFilter(_selectedMerchants);
  }

  Future<void> _removeStore(DealStore store) async {
    setState(() {
      _managedStores = _managedStores
          .where((s) => s.merchant_id != store.merchant_id)
          .toList();
      _selectedMerchants.remove(store.merchant);
      _isLoading = true;
    });
    await _cache.writeManagedStores(_managedStores);
    await _cache.writeStoreFilter(_selectedMerchants);
    await _refresh();
  }

  Future<void> _addStoreViaPicker() async {
    final picked = await Navigator.push<GroceryStore>(
      context,
      MaterialPageRoute(builder: (_) => const StoreFinderPage()),
    );
    if (picked == null || !mounted) return;
    if (_managedStores.any((s) => s.merchant_id == picked.merchant_id)) {
      return; // already in the list
    }
    setState(() {
      _managedStores = [
        ..._managedStores,
        DealStore(
          merchant: picked.merchant,
          merchant_id: picked.merchant_id,
          merchant_logo: picked.logo_url,
          distance_m: picked.distance_m?.round(),
        ),
      ];
      _isLoading = true;
    });
    await _cache.writeManagedStores(_managedStores);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        leading: IconButton(
          padding: const EdgeInsets.only(left: 16.0),
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.chevron_left,
              size: 32, color: theme.colorScheme.primary),
        ),
        title: Text(
          'DEALS NEAR YOU',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            letterSpacing: 2.5,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: (_isLoading && _deals == null)
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    final items = _filteredItems;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSearchBar(theme),
        _buildStoreChips(theme),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: Text(
            _selectedMerchants.isEmpty
                ? '${items.length} deals · ${_managedStores.length} stores in your list'
                : '${items.length} deals · ${_selectedMerchants.length} of ${_managedStores.length} stores',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ),
        Expanded(child: _buildGrid(theme, items)),
      ],
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    final onSurface = theme.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        textInputAction: TextInputAction.search,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
          color: onSurface,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search deals, brands or stores',
          hintStyle: GoogleFonts.spaceGrotesk(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: onSurface.withValues(alpha: 0.4),
          ),
          prefixIcon: Icon(Icons.search,
              size: 20, color: onSurface.withValues(alpha: 0.5)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close,
                      size: 18, color: onSurface.withValues(alpha: 0.5)),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: theme.colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: kBlockAccent(context), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildStoreChips(ThemeData theme) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        children: [
          if (_managedStores.isNotEmpty)
            _Chip(
              label: 'All',
              selected: _selectedMerchants.isEmpty,
              onTap: _clearFilter,
            ),
          for (final store in _managedStores)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _Chip(
                label: store.merchant,
                selected: _selectedMerchants.contains(store.merchant),
                onTap: () => _toggleMerchant(store.merchant),
                onRemove: () => _removeStore(store),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _Chip(
              label: 'Add',
              icon: Icons.add,
              selected: false,
              onTap: _addStoreViaPicker,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(ThemeData theme, List<DealItem> items) {
    if (_managedStores.isEmpty) {
      return _emptyState(
          theme, 'No stores in your list.\nTap "Add" to pick a store.');
    }
    if (items.isEmpty) {
      if (_searchQuery.trim().isNotEmpty) {
        return _emptyState(theme, 'No deals match "${_searchQuery.trim()}".');
      }
      return _emptyState(
        theme,
        _selectedMerchants.isEmpty
            ? 'No deals from your stores right now.'
            : 'No deals from the selected stores.',
        showClear: _selectedMerchants.isNotEmpty,
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisExtent: 250,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _DealGridCard(item: items[index]),
    );
  }

  Widget _emptyState(ThemeData theme, String message,
      {bool showClear = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            if (showClear) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: _clearFilter,
                child: Text('Show all stores',
                    style:
                        GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final IconData? icon;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.onRemove,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.only(
            left: icon != null ? 10 : 14, right: onRemove != null ? 6 : 14),
        decoration: BoxDecoration(
          color: selected ? kBlockAccent(context) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? kBlockAccent(context)
                : theme.colorScheme.outline.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: theme.colorScheme.onSurface),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color:
                    selected ? kBlockAccentInk(context) : theme.colorScheme.onSurface,
              ),
            ),
            if (onRemove != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onRemove,
                child: Icon(
                  Icons.close,
                  size: 15,
                  color: (selected
                          ? kBlockAccentInk(context)
                          : theme.colorScheme.onSurface)
                      .withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DealGridCard extends StatelessWidget {
  final DealItem item;

  const _DealGridCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return GestureDetector(
      onTap: () => showDealDetail(context, item),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.12),
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: item.image_url != null
                      ? Image.network(
                          ApiConfig.resolveImageUrl(item.image_url!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(context),
                        )
                      : _placeholder(context),
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
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          dealPriceLabel(item),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 15,
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
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: dealSavingsColor(context),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
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

  Widget _placeholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
      child: Icon(
        Icons.shopping_basket_outlined,
        size: 26,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
      ),
    );
  }
}

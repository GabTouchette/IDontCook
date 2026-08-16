import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/api/deals_api.dart';
import 'package:i_cant_cook/enums/toast_type.dart';
import 'package:i_cant_cook/models/grocery_store/grocery_store.dart';
import 'package:i_cant_cook/providers/settings_provider.dart';
import 'package:i_cant_cook/services/location_service.dart';
import 'package:i_cant_cook/widgets/deals/store_map.dart';
import 'package:i_cant_cook/widgets/toasts/information_toast.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

/// Lets the user find and pick their grocery store from one field: type a
/// postal code to load nearby stores, or a name to filter the loaded ones.
/// Results show in List / Map tabs. The choice is persisted to settings and
/// drives the nearby-deals home module.
class StoreFinderPage extends StatefulWidget {
  const StoreFinderPage({super.key});

  @override
  State<StoreFinderPage> createState() => _StoreFinderPageState();
}

class _StoreFinderPageState extends State<StoreFinderPage>
    with SingleTickerProviderStateMixin {
  static const _lime = Color(0xFFCAFF00);

  final DealsApi _dealsApi = DealsApi();
  final LocationService _locationService = LocationService();
  final TextEditingController _queryController = TextEditingController();
  late final TabController _tabController;

  bool _locating = false;

  List<GroceryStore> _stores = [];
  LatLng? _center;
  String _query = '';
  String _nameFilter = '';
  bool _isLoading = false;
  bool _hasSearched = false;
  int? _savingMerchantId;

  // A full Canadian postal code (A1A1A1) — triggers a nearby-store fetch.
  static final RegExp _fullPostal = RegExp(r'^[A-Za-z]\d[A-Za-z]\d[A-Za-z]\d$');
  // The start of a postal code (letter then digit) — tells apart "H2X…" from a
  // store name like "Metro" or "IGA", so we don't name-filter a postal code.
  static final RegExp _postalish = RegExp(r'^[A-Za-z]\d');

  /// Stores narrowed by the live name filter — matches the banner name and the
  /// specific location name, so "Marcano" finds a "Metro Marcano" location.
  List<GroceryStore> get _filteredStores {
    if (_nameFilter.isEmpty) return _stores;
    final q = _nameFilter.toLowerCase();
    return _stores
        .where((s) =>
            s.merchant.toLowerCase().contains(q) ||
            s.displayName.toLowerCase().contains(q))
        .toList();
  }

  /// Filtered stores that have coordinates — the ones shown as map pins.
  List<GroceryStore> get _mappableStores =>
      _filteredStores.where((s) => s.hasLocation).toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Try the device's exact location first; fall back to the saved store's
    // neighbourhood so there's always something to show / filter.
    WidgetsBinding.instance.addPostFrameCallback((_) => _useMyLocation(auto: true));
  }

  /// Get GPS + reverse-geocoded postal code, then search with exact coords.
  /// [auto] silences failures (used on first open); a manual tap reports them.
  Future<void> _useMyLocation({bool auto = false}) async {
    setState(() => _locating = true);
    final result = await _locationService.current();
    if (!mounted) return;
    setState(() => _locating = false);

    if (result.status == LocationStatus.ok && result.location != null) {
      final loc = result.location!;
      _queryController.clear();
      // Postal may be null (e.g. web) — the backend resolves it from the coords.
      await _fetchByPostal(
        loc.postalCode ?? '',
        lat: loc.latLng.latitude,
        lng: loc.latLng.longitude,
      );
      return;
    }

    if (auto) {
      // Silent fallback to the saved neighbourhood on first open.
      await _loadSavedNeighbourhood();
    } else {
      _reportLocationProblem(result.status);
    }
  }

  Future<void> _loadSavedNeighbourhood() async {
    final settings = context.read<SettingsProvider>();
    if (settings.postalCode.isEmpty) {
      await settings.fetchAndLoadPersonalInfo();
    }
    if (mounted && settings.postalCode.isNotEmpty) {
      _fetchByPostal(settings.postalCode);
    }
  }

  void _reportLocationProblem(LocationStatus status) {
    final message = switch (status) {
      LocationStatus.serviceDisabled =>
        'Location services are off. Turn them on, or enter a postal code.',
      LocationStatus.denied =>
        'Location permission denied. Enter a postal code instead.',
      LocationStatus.deniedForever =>
        'Location is blocked in Settings. Enable it, or enter a postal code.',
      _ => 'Couldn’t get your location. Enter a postal code instead.',
    };
    InformationToast.show(
      context: context,
      message: message,
      type: ToastType.warning,
    );
    if (status == LocationStatus.deniedForever) _locationService.openSettings();
  }

  @override
  void dispose() {
    _queryController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String text) {
    setState(() {
      _query = text;
      // A postal-code query isn't a name filter; anything else filters live.
      _nameFilter = _postalish.hasMatch(text.trim()) ? '' : text.trim();
    });
  }

  void _onSubmit() {
    final norm = _query.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    if (_fullPostal.hasMatch(norm)) {
      _fetchByPostal(norm);
      return;
    }
    if (_postalish.hasMatch(_query.trim())) {
      InformationToast.show(
        context: context,
        message: 'Enter your full postal code (e.g. H2X 1Y4).',
        type: ToastType.warning,
      );
      return;
    }
    // Name query: results are filtered live. If nothing is loaded yet, pull the
    // saved store's neighbourhood so there's something to filter.
    if (_query.trim().isNotEmpty && _stores.isEmpty) {
      final saved = context.read<SettingsProvider>().postalCode;
      if (saved.isNotEmpty) {
        _fetchByPostal(saved, keepNameFilter: true);
      } else {
        InformationToast.show(
          context: context,
          message: 'Enter a postal code first to load nearby stores.',
          type: ToastType.info,
        );
      }
    }
  }

  Future<void> _fetchByPostal(
    String postal, {
    bool keepNameFilter = false,
    double? lat,
    double? lng,
  }) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _center = null;
      if (!keepNameFilter) _nameFilter = '';
    });
    final result = await _dealsApi.searchStores(postal, lat: lat, lng: lng);
    if (!mounted) return;
    setState(() {
      _stores = result.stores;
      _center = result.center;
      _isLoading = false;
    });
  }

  /// Picker: return the chosen store to the caller (the deals page adds it to
  /// its store list).
  void _select(GroceryStore store) {
    Navigator.pop(context, store);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedId = context.watch<SettingsProvider>().dealsStoreMerchantId;

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
          'YOUR STORE',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            letterSpacing: 2.5,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(
              height: 1,
              thickness: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.15)),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
            child: Text(
              'Find weekly deals near you',
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Use your location, or search by postal code or store name.',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildSearchRow(theme),
          const SizedBox(height: 10),
          _buildUseLocationButton(theme),
          const SizedBox(height: 12),
          if (_hasSearched) _buildTabBar(theme),
          Expanded(child: _buildBody(theme, selectedId)),
        ],
      ),
    );
  }

  Widget _buildSearchRow(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(Icons.search,
                      size: 20,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _queryController,
                      textInputAction: TextInputAction.search,
                      onChanged: _onQueryChanged,
                      onSubmitted: (_) => _onSubmit(),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Postal code or store name',
                        hintStyle: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.35),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _queryController.clear();
                        _onQueryChanged('');
                      },
                      child: Icon(Icons.close,
                          size: 18,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _lime,
                foregroundColor: const Color(0xFF0A0A0A),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: Text(
                'Search',
                style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUseLocationButton(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: (_locating || _isLoading) ? null : () => _useMyLocation(),
          icon: _locating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location, size: 18),
          label: Text(
            _locating ? 'Locating…' : 'Use my location',
            style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w700, fontSize: 14),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurface,
            side: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    final count = _filteredStores.length;
    final mapCount = _mappableStores.length;
    return TabBar(
      controller: _tabController,
      indicatorColor: _lime,
      indicatorWeight: 3,
      labelColor: theme.colorScheme.onSurface,
      unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
      labelStyle:
          GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 14),
      tabs: [
        Tab(text: 'List ($count)'),
        Tab(text: 'Map ($mapCount)'),
      ],
    );
  }

  Widget _buildBody(ThemeData theme, int? selectedId) {
    if (_isLoading || _locating) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_hasSearched) {
      return _hint(theme,
          'Use your location or enter a postal code to find nearby stores.');
    }
    return TabBarView(
      controller: _tabController,
      children: [
        _buildListTab(theme, selectedId),
        _buildMapTab(theme, selectedId),
      ],
    );
  }

  Widget _buildListTab(ThemeData theme, int? selectedId) {
    if (_stores.isEmpty) {
      return _hint(theme, 'No grocery stores found for that postal code.');
    }
    final stores = _filteredStores;
    if (stores.isEmpty) {
      return _hint(theme, 'No stores match “$_nameFilter”.');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      itemCount: stores.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final store = stores[index];
        return _StoreTile(
          store: store,
          isSelected: store.merchant_id == selectedId,
          isSaving: store.merchant_id == _savingMerchantId,
          onTap: () => _select(store),
        );
      },
    );
  }

  Widget _buildMapTab(ThemeData theme, int? selectedId) {
    if (_center == null) {
      return _hint(theme, 'Search a postal code to see stores on the map.');
    }
    if (_mappableStores.isEmpty) {
      return _hint(
          theme,
          _nameFilter.isEmpty
              ? 'No mappable store locations nearby.'
              : 'No mapped stores match “$_nameFilter”.');
    }
    return StoreMap(
      center: _center!,
      stores: _mappableStores,
      selectedMerchantId: selectedId,
      onStoreTap: _select,
      height: null, // fill the tab
      borderRadius: 0,
    );
  }

  Widget _hint(ThemeData theme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

class _StoreTile extends StatelessWidget {
  const _StoreTile({
    required this.store,
    required this.isSelected,
    required this.isSaving,
    required this.onTap,
  });

  final GroceryStore store;
  final bool isSelected;
  final bool isSaving;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: isSaving ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFCAFF00)
                  : theme.colorScheme.outline.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1.5,
            ),
          ),
          child: Row(
            children: [
              _buildLogo(theme),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (store.distanceLabel != null ||
                        store.hasSpecificName) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (store.distanceLabel != null) ...[
                            Icon(Icons.place_outlined,
                                size: 13,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5)),
                            const SizedBox(width: 3),
                            Text(
                              store.distanceLabel!,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                          // Show the banner when the location name differs, so
                          // it's clear which chain's deals you'd get.
                          if (store.hasSpecificName) ...[
                            if (store.distanceLabel != null)
                              Text('  ·  ',
                                  style: GoogleFonts.spaceGrotesk(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.3))),
                            Flexible(
                              child: Text(
                                store.merchant,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.45),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (isSaving)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (isSelected)
                const Icon(Icons.check_circle, color: Color(0xFF0A0A0A))
              else
                Icon(Icons.chevron_right,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(ThemeData theme) {
    final placeholder = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.storefront_outlined,
          size: 22, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
    );
    if (store.logo_url == null || store.logo_url!.isEmpty) {
      return placeholder;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        store.logo_url!,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}

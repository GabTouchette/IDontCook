import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:i_cant_cook/api/grocery_api.dart';
import 'package:i_cant_cook/enums/toast_type.dart';
import 'package:i_cant_cook/models/grocery/grocery_models.dart';
import 'package:i_cant_cook/widgets/toasts/information_toast.dart';

/// Layer 3 — "Order" flow (iOS/Android only; web can't embed grocer sites).
///
/// Pick a grocer → its site loads in a WebView *behind* a native overlay →
/// the cart auto-fills from the Grocery Bag via the site's own API (injected
/// same-origin JS, passes Akamai) → "Review" reveals the site cart for checkout.
/// Only Maxi (Loblaw pcx-bff) is wired today; other grocers are placeholders
/// that will need their own adapters. See docs/plans/grocery-bag-implementation.md §10.
///
/// ToS-gray (personal use). `x-apikey` is a static public key captured from the
/// site; if calls start 401ing it rotated — re-capture.

const _kPcxApiKey = 'C1xujSegT5j3ap3yexJjqhOfELwGKYvz';
const _kPcxBase = 'https://api.pcexpress.ca/pcx-bff/api';

class _Grocer {
  final String id;
  final String name;
  final String url;
  final bool enabled;
  final Color color; // brand colour, used for the logo chip fallback
  final String? logo; // optional asset path (assets/grocers/<id>.png)
  const _Grocer({
    required this.id,
    required this.name,
    required this.color,
    this.url = '',
    this.enabled = false,
    this.logo,
  });
}

const _grocers = <_Grocer>[
  _Grocer(
      id: 'maxi',
      name: 'Maxi',
      url: 'https://www.maxi.ca/',
      enabled: true,
      color: Color(0xFF00A651),
      logo: 'assets/grocers/maxi.png'),
  _Grocer(id: 'superc', name: 'Super C', color: Color(0xFFE2001A),
      logo: 'assets/grocers/superc.png'),
  _Grocer(id: 'costco', name: 'Costco', color: Color(0xFF005DAA),
      logo: 'assets/grocers/costco.jpeg'),
  _Grocer(id: 'loblaws', name: 'Loblaws', color: Color(0xFFEF8200),
      logo: 'assets/grocers/loblaws.png'),
  _Grocer(id: 'iga', name: 'IGA', color: Color(0xFFE4002B),
      logo: 'assets/grocers/iga.jpeg'),
  _Grocer(id: 'metro', name: 'Metro', color: Color(0xFF009639),
      logo: 'assets/grocers/metro.png'),
];

enum _FillState { pending, searching, added, noMatch, error }

class _Candidate {
  final String code;
  final String title;
  final String? uom;
  final double? price;
  final String? packageSizing;
  final String? image;
  final double? perKg;

  _Candidate({
    required this.code,
    required this.title,
    this.uom,
    this.price,
    this.packageSizing,
    this.image,
    this.perKg,
  });

  factory _Candidate.fromJson(Map<String, dynamic> j) {
    final pkg = j['packageSizing'] as String?;
    return _Candidate(
      code: j['code'] as String,
      title: (j['title'] as String?) ?? j['code'] as String,
      uom: j['uom'] as String?,
      price: double.tryParse('${j['price']}'),
      packageSizing: pkg,
      image: j['image'] as String?,
      perKg: _parsePerKg(pkg),
    );
  }

  static double? _parsePerKg(String? s) {
    if (s == null) return null;
    final t = s.replaceAll(',', '.');
    final kg = RegExp(r'([\d.]+)\s*\$\s*/\s*1?\s*kg').firstMatch(t);
    if (kg != null) return double.tryParse(kg.group(1)!);
    final hg = RegExp(r'([\d.]+)\s*\$\s*/\s*100\s*g').firstMatch(t);
    if (hg != null) {
      final v = double.tryParse(hg.group(1)!);
      return v == null ? null : v * 10;
    }
    return null;
  }
}

class _ItemFill {
  final ShoppableLine line;
  _FillState state = _FillState.pending;
  List<_Candidate> candidates = [];
  _Candidate? selected;
  int quantity = 1;
  bool ambiguous = false; // matcher wasn't confident — flag for review
  _ItemFill(this.line);
}

class GroceryOrderWebViewPage extends StatefulWidget {
  final List<ShoppableLine> items;
  const GroceryOrderWebViewPage({super.key, this.items = const []});

  @override
  State<GroceryOrderWebViewPage> createState() =>
      _GroceryOrderWebViewPageState();
}

class _GroceryOrderWebViewPageState extends State<GroceryOrderWebViewPage> {
  InAppWebViewController? _controller;
  _Grocer? _grocer;
  String? _cartId;
  String? _storeId;

  bool _showBrowser = false;
  bool _filling = false;
  bool _filledOnce = false;
  bool _autoStarted = false;

  final GroceryApi _api = GroceryApi();

  late final List<_ItemFill> _items =
      widget.items.map((l) => _ItemFill(l)).toList();

  bool get _ready => _cartId != null;

  double get _subtotal =>
      _items.fold(0.0, (s, i) => s + (i.selected?.price ?? 0) * i.quantity);

  // --- harvest + auto-start ----------------------------------------------
  void _harvest(String? url, String? body) {
    if (url == null) return;
    var changed = false;
    final cart = RegExp(r'/carts/([0-9a-f-]{36})').firstMatch(url);
    if (cart != null && cart.group(1) != _cartId) {
      _cartId = cart.group(1);
      changed = true;
    }
    final store = RegExp(r'(?:sellerId|locationId)["=:\s]+"?(\d{3,5})')
        .firstMatch('$url ${body ?? ''}');
    if (store != null && store.group(1) != _storeId) {
      _storeId = store.group(1);
      changed = true;
    }
    if (changed) {
      setState(() {});
      _maybeAutoStart();
    }
  }

  void _maybeAutoStart() {
    if (_grocer != null && _ready && !_autoStarted) {
      _autoStarted = true;
      setState(() => _showBrowser = false);
      WidgetsBinding.instance.addPostFrameCallback((_) => _fillCart());
    }
  }

  /// The site we preload in the background while the user is on the picker —
  /// the first enabled grocer, so it's (close to) ready by the time they pick.
  String get _firstEnabledUrl =>
      _grocers.firstWhere((g) => g.enabled, orElse: () => _grocers.first).url;

  void _selectGrocer(_Grocer g) {
    final alreadyLoading = g.url == _firstEnabledUrl;
    setState(() => _grocer = g);
    if (alreadyLoading) {
      // The background preload is this grocer — fill now if it's already ready.
      _maybeAutoStart();
    } else {
      // A different grocer than the one we preloaded — load its site fresh.
      _cartId = null;
      _storeId = null;
      _autoStarted = false;
      _controller?.loadUrl(urlRequest: URLRequest(url: WebUri(g.url)));
    }
  }

  String? _bodyToString(dynamic body) {
    if (body == null) return null;
    if (body is String) return body;
    if (body is List) {
      try {
        return utf8.decode(body.cast<int>());
      } catch (_) {
        return body.toString();
      }
    }
    return body.toString();
  }

  // --- injected JS --------------------------------------------------------
  Future<void> _injectHelper() async {
    final controller = _controller;
    if (controller == null || _cartId == null) return;
    final storeId = _storeId ?? '3911';
    final js = '''
      window.__gb = {
        ctx: { cartId: "$_cartId", storeId: "$storeId", apikey: "$_kPcxApiKey", base: "$_kPcxBase" },
        headers: function () {
          return {
            "accept": "application/json, text/plain, */*",
            "accept-language": "fr",
            "content-type": "application/json",
            "basesiteid": "maxi",
            "site-banner": "maxi",
            "business-user-agent": "PCXWEB",
            "is-helios-account": "false",
            "is-iceberg-enabled": "true",
            "x-apikey": this.ctx.apikey,
            "x-application-type": "web",
            "x-channel": "web",
            "x-loblaw-tenant-id": "ONLINE_GROCERIES"
          };
        },
        _codeOf: function (o) {
          for (const k in o) {
            if (typeof o[k] === "string" && /^\\d+_(?:EA|KG)\$/.test(o[k])) return o[k];
          }
          return null;
        },
        search: async function (term) {
          try {
            const nd = window.__NEXT_DATA__ || {};
            const buildId = nd.buildId;
            const locale = nd.locale || "fr";
            if (!buildId) return JSON.stringify({ error: "no buildId" });
            const url = location.origin + "/_next/data/" + buildId + "/" + locale +
              "/search.json?search-bar=" + encodeURIComponent(term) +
              "&storeId=" + this.ctx.storeId + "&cartId=" + this.ctx.cartId;
            const r = await fetch(url, { headers: { "x-nextjs-data": "1" } });
            if (!r.ok) return JSON.stringify({ error: "search " + r.status });
            const data = await r.json();
            const self = this;
            // The real search grid is the `productTiles` array — each tile has
            // an `index` giving the site's relevance order (the same order you
            // see when searching in a browser). Target it by name; a flat walk
            // would mix in carousels/normalized caches and lose that order.
            let tiles = null;
            const findTiles = (o, d) => {
              if (tiles || d > 16 || o == null || typeof o !== "object") return;
              if (Array.isArray(o)) { for (const x of o) findTiles(x, d + 1); return; }
              if (Array.isArray(o.productTiles) && o.productTiles.length) {
                tiles = o.productTiles; return;
              }
              for (const k in o) { if (o[k] && typeof o[k] === "object") findTiles(o[k], d + 1); }
            };
            findTiles(data, 0);

            let list;
            if (tiles) {
              list = tiles.slice().sort((a, b) => (a.index || 0) - (b.index || 0));
            } else {
              // Fallback if the grid shape ever changes: flat walk, original order.
              list = [];
              const walk = (o, d) => {
                if (d > 14 || o == null || typeof o !== "object") return;
                if (Array.isArray(o)) { for (const x of o) walk(x, d + 1); return; }
                if (self._codeOf(o)) list.push(o);
                for (const k in o) { if (o[k] && typeof o[k] === "object") walk(o[k], d + 1); }
              };
              walk(data, 0);
            }
            // Skip sponsored tiles and anything out of stock.
            const prods = list.filter((p) =>
              !p.isSponsored &&
              !(p.inventoryIndicator && p.inventoryIndicator.indicatorId === "OUT"));
            const out = prods.slice(0, 10).map((p) => ({
              code: p.productId || self._codeOf(p),
              title: p.title,
              uom: p.uom,
              price: (p.pricing && p.pricing.price) || null,
              packageSizing: p.packageSizing || null,
              image: (p.productImage && p.productImage[0] && (p.productImage[0].smallUrl || p.productImage[0].thumbnailUrl)) || null,
            }));
            return JSON.stringify({ results: out });
          } catch (e) {
            return JSON.stringify({ error: String(e) });
          }
        },
        setQty: async function (code, qty) {
          try {
            const body = { entries: {} };
            body.entries[code] = { quantity: qty, fulfillmentMethod: "pickup", sellerId: this.ctx.storeId };
            const r = await fetch(this.ctx.base + "/v1/carts/" + this.ctx.cartId, {
              method: "POST", headers: this.headers(), body: JSON.stringify(body)
            });
            return JSON.stringify({ status: r.status });
          } catch (e) {
            return JSON.stringify({ error: String(e) });
          }
        }
      };
      return "ok";
    ''';
    await controller.evaluateJavascript(source: '(async () => { $js })();');
  }

  Future<Map<String, dynamic>?> _call(String expr) async {
    final controller = _controller;
    if (controller == null) return null;
    try {
      final res =
          await controller.callAsyncJavaScript(functionBody: 'return await $expr;');
      final v = res?.value;
      return v == null ? null : jsonDecode(v.toString()) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // --- matching + cart ----------------------------------------------------
  // The grocer ranks search by relevance, so within the top results we pick the
  // option that costs the least to cover what the recipe needs — e.g. 4 loose
  // peppers vs one bag, by weight/price. Ties prefer the individual item. When
  // we lack price/weight data we just prefer an individual item in order.
  // Returns the chosen candidate AND how many units to add.
  (_Candidate, int)? _pick(List<_Candidate> cands, ShoppableLine line) {
    if (cands.isEmpty) return null;
    final shortlist = cands.take(5).toList();
    final needCount =
        line.amount.dimension == 'count' && line.amount.value != null
            ? line.amount.value!.round().clamp(1, 99).toInt()
            : null;
    final needG =
        (line.approxG != null && line.approxG! > 0) ? line.approxG : null;

    _Candidate? best;
    var bestQty = 1;
    var bestCost = double.infinity;
    for (final c in shortlist) {
      final plan = _plan(c, needCount, needG);
      if (plan == null) continue;
      final (qty, cost) = plan;
      final better = cost < bestCost - 0.01 ||
          (cost <= bestCost + 0.01 &&
              best != null &&
              _isBulk(best) &&
              !_isBulk(c)); // tie → prefer the individual item
      if (better) {
        best = c;
        bestQty = qty;
        bestCost = cost;
      }
    }
    if (best != null) return (best, bestQty);

    // Not enough data to compare on price — prefer an individual item.
    final individual = shortlist.where((c) => !_isBulk(c)).toList();
    final pick = (individual.isNotEmpty ? individual : shortlist).first;
    return (pick, needCount ?? 1);
  }

  /// (units to add, total cost) to cover the need with [c], or null when we
  /// lack the price/weight to estimate.
  (int, double)? _plan(_Candidate c, int? needCount, double? needG) {
    final packG = _packGrams(c.packageSizing);
    if (packG != null && packG > 0) {
      // A fixed-size bag/pack: how many packs cover the needed weight?
      final packs =
          needG != null ? (needG / packG).ceil().clamp(1, 99).toInt() : 1;
      final unit = c.price ?? (c.perKg != null ? c.perKg! * packG / 1000 : null);
      if (unit == null) return null;
      return (packs, unit * packs);
    }
    // Loose / sold individually: buy one unit per item the recipe calls for.
    final qty = needCount ?? 1;
    if (c.price != null) return (qty, c.price! * qty);
    if (c.perKg != null && needG != null) return (qty, c.perKg! * needG / 1000);
    return null;
  }

  /// Heuristic: a bag / multipack rather than a single loose item.
  bool _isBulk(_Candidate c) {
    final t = c.title.toLowerCase();
    return t.contains('sac') ||
        t.contains('paquet') ||
        t.contains('pqt') ||
        t.contains('emball') ||
        RegExp(r'\bx\s*\d').hasMatch(t) ||
        RegExp(r'\d+\s*(lb|kg)\b').hasMatch(t);
  }

  /// Fixed pack weight in grams from a packageSizing like "1.36 kg, …" or
  /// "500 g, …". Null for loose items priced by weight ("5,49 $/1kg …").
  double? _packGrams(String? pkg) {
    if (pkg == null) return null;
    final m = RegExp(r'^\s*(\d+[.,]?\d*)\s*(kg|g)\b', caseSensitive: false)
        .firstMatch(pkg);
    if (m == null) return null;
    final v = double.tryParse(m.group(1)!.replaceAll(',', '.'));
    if (v == null) return null;
    return m.group(2)!.toLowerCase() == 'kg' ? v * 1000 : v;
  }

  /// Low confidence when the chosen product's title shares no word with the
  /// ingredient — i.e. the grocer's search likely returned something unrelated.
  bool _confident(_Candidate pick, ShoppableLine line) {
    final title = pick.title.toLowerCase();
    final tokens = line.name
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9à-ÿ]+'))
        .where((t) => t.length >= 3);
    return tokens.any(
        (t) => title.contains(t.length > 4 ? t.substring(0, 4) : t));
  }

  Future<void> _fillCart() async {
    if (_filling || !_ready) return;
    setState(() => _filling = true);
    await _injectHelper();
    final grocer = _grocer!.id;

    var pending = _items.where((i) => i.state != _FillState.added).toList();

    // 1. Cache hits (no LLM, no search): add the learned product directly.
    final cached =
        await _api.cachedMatches(grocer, pending.map((i) => i.line.key).toList());
    for (final item in pending) {
      final hit = cached[item.line.key];
      if (hit == null) continue;
      final pick = _Candidate(
        code: '${hit['code']}',
        title: '${hit['title']}'.isEmpty ? item.line.name : '${hit['title']}',
        uom: hit['uom'] as String?,
      );
      final ok = await _setQty(pick.code, item.quantity);
      setState(() {
        item.selected = pick;
        item.state = ok ? _FillState.added : _FillState.error;
      });
    }
    pending = pending.where((i) => i.state != _FillState.added).toList();

    // 2. Search each remaining ingredient in-page. The display name is already
    //    localized server-side (from the canonical), so it is the search term.
    for (final item in pending) {
      setState(() => item.state = _FillState.searching);
      final res = await _call('window.__gb.search(${jsonEncode(item.line.name)})');
      final raw = (res?['results'] as List?) ?? const [];
      item.candidates = raw
          .map((e) => _Candidate.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    }

    // 3. Pick client-side, trusting the grocer's relevance ranking, and add it.
    final learned = <Map<String, dynamic>>[];
    for (final item in pending) {
      final pick = _pick(item.candidates, item.line);
      if (pick == null) {
        setState(() {
          item.ambiguous = false;
          item.state = _FillState.noMatch;
        });
        continue;
      }
      final (cand, qty) = pick;
      final confident = _confident(cand, item.line);
      final ok = await _setQty(cand.code, qty);
      setState(() {
        item.selected = cand;
        item.quantity = qty;
        item.ambiguous = !confident;
        item.state = ok ? _FillState.added : _FillState.error;
      });
      if (ok && confident) {
        learned.add({
          'key': item.line.key,
          'code': cand.code,
          'title': cand.title,
          'uom': cand.uom,
        });
      }
    }

    // 4. Remember confident picks so the next fill reads them from cache.
    await _api.learnMatches(grocer, learned);

    if (mounted) {
      setState(() {
        _filling = false;
        _filledOnce = true;
      });
    }
  }

  /// Change an item's quantity (min 1) and sync it to the cart.
  Future<void> _changeQty(_ItemFill item, int delta) async {
    final next = (item.quantity + delta).clamp(1, 99);
    if (next == item.quantity) return;
    setState(() => item.quantity = next);
    final sel = item.selected;
    if (sel != null) await _setQty(sel.code, next);
  }

  Future<bool> _setQty(String code, int qty) async {
    final r = await _call('window.__gb.setQty(${jsonEncode(code)}, $qty)');
    return r?['status'] == 200;
  }

  Future<void> _replace(_ItemFill item, _Candidate cand) async {
    final prev = item.selected;
    // Optimistically show the new product with a spinner while it swaps.
    setState(() {
      item.selected = cand;
      item.state = _FillState.searching;
    });
    final ok = await _setQty(cand.code, item.quantity);
    if (ok && prev != null && prev.code != cand.code) {
      await _setQty(prev.code, 0);
    }
    setState(() {
      if (!ok) item.selected = prev;
      item.ambiguous = false; // user-chosen → no longer uncertain
      item.state = ok ? _FillState.added : _FillState.error;
    });
  }

  /// Remove entirely: drop it from the cart and from the list, with an Undo.
  void _removeEntirely(_ItemFill item) {
    final index = _items.indexOf(item);
    final sel = item.selected;
    setState(() => _items.remove(item));
    if (sel != null) _setQty(sel.code, 0);

    // NOTE: InformationToast.show() doesn't currently expose an action slot
    // (actionLabel/onAction), so this one keeps the raw SnackBar to preserve
    // the working Undo affordance rather than silently dropping it.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Removed ${item.line.name}'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            setState(() =>
                _items.insert(index.clamp(0, _items.length), item));
            if (sel != null) _setQty(sel.code, item.quantity);
          },
        ),
      ));
  }

  void _reviewCart() {
    setState(() => _showBrowser = true);
    _controller?.loadUrl(
      urlRequest: URLRequest(url: WebUri('https://www.maxi.ca/fr/cartReview')),
    );
  }

  // --- UI -----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return _webUnsupported(context);
    final theme = Theme.of(context);
    final targetUrl = _grocer?.url ?? _firstEnabledUrl;
    return PopScope(
      // In the browser, back returns to the Order list (to tweak the bag) rather
      // than popping the whole page back to the grocery bag.
      canPop: !_showBrowser,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _showBrowser) setState(() => _showBrowser = false);
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            padding: const EdgeInsets.only(left: 16.0),
            onPressed: () {
              if (_showBrowser) {
                setState(() => _showBrowser = false); // back to the Order list
              } else {
                Navigator.pop(context);
              }
            },
            icon: Icon(Icons.chevron_left,
                color: theme.colorScheme.primary, size: 32),
          ),
          title: Text(
            _showBrowser && _grocer != null
                ? _grocer!.name.toUpperCase()
                : 'ORDER',
            style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w700, fontSize: 20, letterSpacing: 2),
          ),
          actions: [
            if (_showBrowser)
              TextButton(
                onPressed: () => setState(() => _showBrowser = false),
                child: const Text('Done'),
              ),
          ],
        ),
        body: targetUrl.isEmpty
            ? _grocerPicker(context)
            : Stack(
                children: [
                  // Loads the grocer site in the background from page open, so
                  // it's ready (or nearly) by the time the user picks a grocer.
                  InAppWebView(
                    initialUrlRequest: URLRequest(url: WebUri(targetUrl)),
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      useShouldInterceptAjaxRequest: true,
                      useShouldInterceptFetchRequest: true,
                    ),
                    onWebViewCreated: (c) => _controller = c,
                    shouldInterceptAjaxRequest: (c, req) async {
                      _harvest(req.url?.toString(), _bodyToString(req.data));
                      return req;
                    },
                    shouldInterceptFetchRequest: (c, req) async {
                      _harvest(req.url?.toString(), _bodyToString(req.body));
                      return req;
                    },
                  ),
                  if (_grocer == null)
                    Positioned.fill(
                      child: Container(
                        color: theme.scaffoldBackgroundColor,
                        child: _grocerPicker(context),
                      ),
                    )
                  else if (!_showBrowser)
                    Positioned.fill(child: _overlay(context)),
                ],
              ),
      ),
    );
  }

  // Grocer picker --------------------------------------------------------
  Widget _grocerPicker(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose your grocer',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('We’ll fill your cart there automatically.',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
                children:
                    _grocers.map((g) => _grocerTile(context, g)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _grocerTile(BuildContext context, _Grocer g) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: g.enabled ? () => _selectGrocer(g) : null,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: g.enabled ? theme.colorScheme.secondary : theme.dividerColor,
            width: g.enabled ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _grocerLogo(g),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    g.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: g.enabled
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    g.enabled ? 'Available' : 'Coming soon',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: g.enabled
                          ? Colors.green
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Brand logo chip: the grocer's asset if present, else a coloured initial
  /// so the picker looks branded even before logo files are added.
  Widget _grocerLogo(_Grocer g) {
    final fallback = Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: g.color.withOpacity(g.enabled ? 1 : 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        g.name.characters.first.toUpperCase(),
        style: GoogleFonts.spaceGrotesk(
            fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
      ),
    );
    if (g.logo == null) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(
        g.logo!,
        width: 44,
        height: 44,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }

  // Overlay (connecting / filling / done) --------------------------------
  Widget _overlay(BuildContext context) {
    final theme = Theme.of(context);
    // Only show items that have been fetched — they pop in sequentially as each
    // one resolves. While filling, a "building the list" loader trails the end.
    final resolved = _items
        .where((i) =>
            i.state != _FillState.pending && i.state != _FillState.searching)
        .toList();
    final showLoader = _filling;
    final count = resolved.length + (showLoader ? 1 : 0);
    return Material(
      color: theme.scaffoldBackgroundColor,
      child: !_ready
          ? _connecting(context)
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: count,
                    separatorBuilder: (_, __) => Divider(
                        height: 1, color: theme.dividerColor.withOpacity(0.4)),
                    itemBuilder: (_, i) => i < resolved.length
                        ? _itemTile(context, resolved[i])
                        : const _BuildingLoader(),
                  ),
                ),
                _bottomArea(context),
              ],
            ),
    );
  }

  Widget _connecting(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text('Connecting to ${_grocer!.name}…',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _itemTile(BuildContext context, _ItemFill item) {
    final theme = Theme.of(context);
    final sel = item.selected;

    // Trailing: a loading spinner while searching, otherwise the line total
    // (unit price × quantity) with $/kg under it.
    Widget trailing;
    if (item.state == _FillState.searching) {
      trailing = const SizedBox(
          width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2));
    } else if (sel?.price != null) {
      trailing = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('\$${(sel!.price! * item.quantity).toStringAsFixed(2)}',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 20, fontWeight: FontWeight.w900)),
          if (sel.perKg != null)
            Text('\$${sel.perKg!.toStringAsFixed(2)}/kg',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
        ],
      );
    } else {
      trailing = const SizedBox.shrink();
    }

    return Dismissible(
      key: ValueKey(item.line.key),
      direction: DismissDirection.endToStart,
      background: Container(
        color: theme.colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _removeEntirely(item),
      child: InkWell(
        onTap: item.candidates.isEmpty ? null : () => _showOptions(context, item),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Image on top, the quantity stepper beneath it.
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _productImage(sel?.image, 64),
                  if (sel != null && item.state == _FillState.added) ...[
                    const SizedBox(height: 6),
                    _qtyStepper(item),
                  ],
                ],
              ),
              const SizedBox(width: 14),
              // Name (ingredient) then the matched product title.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.line.name,
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant)),
                    if (sel != null) ...[
                      const SizedBox(height: 2),
                      Text(sel.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                    ] else if (item.state == _FillState.noMatch)
                      Text('No match — tap to pick',
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  /// − N + stepper (minimum 1) with large, easy-to-tap targets.
  Widget _qtyStepper(_ItemFill item) {
    final theme = Theme.of(context);
    Widget btn(IconData icon, int delta, bool enabled) => InkResponse(
          onTap: enabled ? () => _changeQty(item, delta) : null,
          radius: 30,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon,
                size: 32,
                color: enabled
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
          ),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn(Icons.remove_circle_outline, -1, item.quantity > 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('${item.quantity}',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 19, fontWeight: FontWeight.w800)),
        ),
        btn(Icons.add_circle_outline, 1, true),
      ],
    );
  }

  Widget _productImage(String? url, double size) {
    final placeholder = Container(
      width: size,
      height: size,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(Icons.restaurant,
          color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
    if (url == null) return placeholder;
    return Image.network(url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder);
  }

  void _showOptions(BuildContext context, _ItemFill item) {
    final withPerKg = item.candidates.where((c) => c.perKg != null).toList();
    _Candidate? bestValue;
    if (withPerKg.length > 1) {
      withPerKg.sort((a, b) => a.perKg!.compareTo(b.perKg!));
      bestValue = withPerKg.first;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (_, scroll) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Pick for "${item.line.name}"',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  if (item.selected != null)
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _removeEntirely(item);
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Remove'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scroll,
                itemCount: item.candidates.length,
                itemBuilder: (_, i) {
                  final c = item.candidates[i];
                  final isSel = item.selected?.code == c.code;
                  final isBest = bestValue?.code == c.code;
                  return InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _replace(item, c);
                    },
                    child: Container(
                      color: isSel
                          ? Theme.of(context).colorScheme.secondary.withOpacity(0.12)
                          : Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          _productImage(c.image, 72),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.spaceGrotesk(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700)),
                                if (c.packageSizing != null)
                                  Text(c.packageSizing!,
                                      style: GoogleFonts.spaceGrotesk(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant)),
                                if (isBest)
                                  Text('★ best value / kg',
                                      style: GoogleFonts.spaceGrotesk(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.green)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (c.price != null)
                                Text('\$${c.price!.toStringAsFixed(2)}',
                                    style: GoogleFonts.spaceGrotesk(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900)),
                              if (isSel)
                                const Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Icon(Icons.check,
                                      color: Colors.green, size: 20),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomArea(BuildContext context) {
    final added = _items.where((i) => i.state == _FillState.added).length;
    if (_filling) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(
                value: _items.isEmpty ? null : added / _items.length,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: 10),
              Text('Filling your cart… $added/${_items.length}',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }
    if (_filledOnce) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 60,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _reviewCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
                shape:
                    const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: Text('Total: \$${_subtotal.toStringAsFixed(2)}  •  REVIEW CART',
                  style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: 0.5)),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _webUnsupported(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Order')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.phone_iphone,
                  size: 56, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text('Open this on a phone',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                "Online ordering uses the native in-app browser, which isn't "
                "available on web. Run the app on iOS or Android.",
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Trailing "building the list" row: a food icon that cross-fades through
/// different foods/colours on a gently pulsing ring, shown while the cart fills.
class _BuildingLoader extends StatefulWidget {
  const _BuildingLoader();

  @override
  State<_BuildingLoader> createState() => _BuildingLoaderState();
}

class _BuildingLoaderState extends State<_BuildingLoader>
    with SingleTickerProviderStateMixin {
  static const _foods = <(IconData, Color)>[
    (Icons.lunch_dining, Color(0xFFF57C00)),
    (Icons.local_pizza, Color(0xFFE53935)),
    (Icons.set_meal, Color(0xFF1E88E5)),
    (Icons.eco, Color(0xFF43A047)),
    (Icons.bakery_dining, Color(0xFF8D6E63)),
    (Icons.egg_alt, Color(0xFFFBC02D)),
    (Icons.icecream, Color(0xFFEC407A)),
  ];

  int _i = 0;
  Timer? _timer;
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 650), (_) {
      if (mounted) setState(() => _i = (_i + 1) % _foods.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _foods[_i];
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Center(
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, child) {
                  final t = _pulse.value;
                  return Container(
                    width: 50 + 10 * t,
                    height: 50 + 10 * t,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.12 + 0.10 * t),
                    ),
                    child: child,
                  );
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (c, a) =>
                      ScaleTransition(scale: a, child: FadeTransition(opacity: a, child: c)),
                  child: Icon(icon, key: ValueKey(_i), size: 30, color: color),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Building your list…',
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Finding the best match & price',
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

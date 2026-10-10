import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _apiBaseUrlDefine =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');
  static const String _iosLocalDefault = 'http://127.0.0.1:8000';
  static const String _androidEmulatorDefault = 'http://10.0.2.2:8000';
  static const String _webProductionDefault = 'https://web-production-853e.up.railway.app';

  static String get origin {
    if (_apiBaseUrlDefine.isNotEmpty) {
      return _normalizeBaseUrl(_apiBaseUrlDefine);
    }

    if (kReleaseMode) {
      throw UnsupportedError(
        'API_BASE_URL must be provided for release builds.',
      );
    }

    if (kIsWeb) {
      return _webProductionDefault;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return _androidEmulatorDefault;
    }

    return _iosLocalDefault;
  }

  static String get apiBaseUrl => '${origin}/api';

  // Scraped-image hosts that serve NO `Access-Control-Allow-Origin` header. On
  // Flutter web the CanvasKit renderer paints network images onto a <canvas>,
  // and the browser refuses to read cross-origin images without CORS headers
  // (tainted canvas) — so these fail to render silently, with no console error.
  // We route only these hosts through the backend image proxy. Hosts that
  // already send CORS (images.immediate.co.uk, ucarecdn.com) and our own
  // GCS/media URLs are left untouched. Keep this in sync with the backend
  // ALLOWED_IMAGE_HOSTS allowlist in api/api/image_proxy.py.
  static const Set<String> _proxyImageHosts = {
    'www.allrecipes.com',
    'images.allrecipes.com',
    'images.ricardocuisine.com',
    'food.fnr.sndimg.com',
    'www.seriouseats.com',
    'www.simplyrecipes.com',
  };

  /// Returns a browser-loadable image URL. On Flutter web, URLs from hosts that
  /// lack CORS headers are rewritten through the backend image proxy so the
  /// CanvasKit renderer can paint them; all other URLs (and every URL on native
  /// iOS/Android, where CORS does not apply) are returned unchanged.
  static String resolveImageUrl(String? url) {
    final raw = url ?? '';
    if (!kIsWeb || raw.isEmpty) {
      return raw;
    }
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        !(uri.scheme == 'http' || uri.scheme == 'https') ||
        !_proxyImageHosts.contains(uri.host)) {
      return raw;
    }
    return '$origin/api/images/proxy/?url=${Uri.encodeComponent(raw)}';
  }

  static Uri buildApiUri(
    String endpoint, {
    Map<String, String>? queryParameters,
  }) {
    final normalizedEndpoint =
        endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;

    return Uri.parse('$apiBaseUrl/$normalizedEndpoint').replace(
      queryParameters: queryParameters,
    );
  }

  static String _normalizeBaseUrl(String rawUrl) {
    var normalizedUrl = rawUrl.trim();

    while (normalizedUrl.endsWith('/')) {
      normalizedUrl = normalizedUrl.substring(0, normalizedUrl.length - 1);
    }

    return normalizedUrl;
  }
}

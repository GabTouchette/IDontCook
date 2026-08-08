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

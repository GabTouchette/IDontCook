/// Pure helpers for recognising Instagram links that arrive from the OS share
/// sheet. Shares usually arrive as free text with the URL embedded (Instagram
/// often prepends caption text), so we extract the URL substring first, then
/// validate the host and path kind.
class InstagramShare {
  InstagramShare._();

  static final RegExp _urlPattern = RegExp(
    r'https?:\/\/[^\s]+',
    caseSensitive: false,
  );

  static const Set<String> _hosts = {
    'instagram.com',
    'instagr.am',
  };

  /// Post/reel path kinds we can import. Instagram uses both `/reel/<id>` and
  /// `/<user>/reel/<id>` shapes.
  static const Set<String> _kinds = {'reel', 'reels', 'p', 'tv'};

  /// Returns a cleaned Instagram post/reel URL found in [raw], or null when
  /// [raw] contains no importable Instagram link (non-Instagram host, or an
  /// Instagram profile/home link with no post id).
  static String? extractInstagramUrl(String raw) {
    for (final match in _urlPattern.allMatches(raw)) {
      final candidate = _stripTrailingPunctuation(match.group(0)!);
      final uri = Uri.tryParse(candidate);
      if (uri == null) continue;

      final host = uri.host.toLowerCase();
      final isInstagram =
          _hosts.contains(host) || _hosts.any((h) => host.endsWith('.$h'));
      if (!isInstagram) continue;

      final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segs.isEmpty) continue;

      final hasKind = _kinds.contains(segs.first.toLowerCase()) ||
          (segs.length >= 2 && _kinds.contains(segs[1].toLowerCase()));
      if (!hasKind) continue;

      return _canonicalize(uri);
    }
    return null;
  }

  /// True when [raw] contains at least one importable Instagram link.
  static bool isInstagramShare(String raw) => extractInstagramUrl(raw) != null;

  /// Drop tracking query params (e.g. `?igsh=...`, `?utm_*`) and any fragment so
  /// the backend sees a canonical post URL.
  static String _canonicalize(Uri uri) {
    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      path: uri.path,
    ).toString();
  }

  /// Share payloads sometimes glue trailing punctuation onto the URL
  /// (e.g. a closing paren or period from surrounding caption text).
  static String _stripTrailingPunctuation(String url) {
    return url.replaceAll(RegExp(r'[)\].,!?"”]+$'), '');
  }
}

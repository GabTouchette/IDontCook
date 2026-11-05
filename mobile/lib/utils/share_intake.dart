import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/auth_api.dart';
import 'package:i_cant_cook/utils/instagram_share.dart';
import 'package:i_cant_cook/widgets/toasts/information_toast.dart';

/// Whether this platform can receive OS share-sheet intents. Only iOS and
/// Android have a `receive_sharing_intent` implementation; desktop (macOS) and
/// web have no OS share-sheet that targets the app, so the feature is absent
/// there. Gating on this prevents a `MissingPluginException` at startup when the
/// plugin's platform channel has no handler.
bool get kSupportsShareIntake =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android);

/// Global navigator key so OS share events (which fire outside any widget's
/// BuildContext) can navigate. Handed to [MaterialApp.navigatorKey].
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// URL stashed when a share arrives before the user is authenticated. Replayed
/// by the first authenticated screen via [consumePendingSharedImport].
String? pendingSharedImportUrl;

/// Handle a text/URL payload delivered by the OS share sheet. Extracts an
/// importable Instagram link, then either navigates to the import screen (when
/// authenticated) or stashes it for post-login replay. Non-Instagram shares are
/// rejected with a lightweight message and no navigation.
Future<void> handleSharedText(String raw) async {
  final url = InstagramShare.extractInstagramUrl(raw);
  final nav = rootNavigatorKey.currentState;

  if (url == null) {
    final ctx = nav?.context;
    if (ctx != null) {
      InformationToast.warning(
        ctx,
        'Only Instagram reels and posts can be imported right now.',
      );
    }
    return;
  }

  final user = await AuthApi.getUser();
  if (user == null) {
    // Not signed in yet — replay once the user reaches the app.
    pendingSharedImportUrl = url;
    return;
  }

  nav?.pushNamed('/import-share', arguments: url);
}

/// Called by the app's first authenticated screen (the dashboard) to replay a
/// share that arrived while signed out.
void consumePendingSharedImport() {
  final url = pendingSharedImportUrl;
  if (url == null) return;
  pendingSharedImportUrl = null;
  rootNavigatorKey.currentState?.pushNamed('/import-share', arguments: url);
}

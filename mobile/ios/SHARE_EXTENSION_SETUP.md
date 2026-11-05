# iOS Share Extension setup — "Share to IDontCook"

This wires the iOS side of the Instagram-import feature: an iOS **Share Extension**
so IDontCook appears in Instagram's share sheet, using `receive_sharing_intent`
(already in `pubspec.yaml`). The Dart side (`lib/main.dart` listeners,
`/import-share` route, `lib/utils/share_intake.dart`) and Android are already done;
this is the remaining native-iOS work, which must be done in **Xcode** (it edits the
`.xcodeproj` in ways that shouldn't be hand-authored).

Bundle IDs: release `com.icantcook.app`, dev flavor `com.icantcook.dev`
(`Runner.xcodeproj/project.pbxproj`). Deployment target: iOS 13.0.

---

## ⚠️ STEP 0 — SceneDelegate compatibility spike (do this FIRST; it gates everything)

This project uses Flutter's **new UISceneDelegate lifecycle**:
- `Runner/Info.plist` declares `UIApplicationSceneManifest` → `FlutterSceneDelegate`.
- `Runner/AppDelegate.swift` is `FlutterAppDelegate, FlutterImplicitEngineDelegate`.

`receive_sharing_intent` historically delivers the extension→app handoff through
`FlutterAppDelegate.application(_:open:options:)`. Under the SceneDelegate lifecycle,
URL opens are routed to **scene** callbacks (`scene(_:openURLContexts:)`) instead, so
the plugin's warm- and cold-share delivery can **silently no-op**.

**Before building the extension, verify** on a real device whether the pinned plugin
version (`^1.8.1`) delivers shares under this lifecycle. If it does NOT, pick one:
- **(a)** pin a plugin version that supports UISceneDelegate, or
- **(b)** remove the `UIApplicationSceneManifest` block from `Info.plist` and revert
  `AppDelegate.swift` to the classic `application(didFinishLaunchingWithOptions:)` +
  plugin-registrant lifecycle (drop `FlutterImplicitEngineDelegate`), or
- **(c)** switch the Dart side to `share_handler` instead of `receive_sharing_intent`
  (same `handleSharedText(raw)` entry point in `lib/utils/share_intake.dart`).

Do not proceed until shares actually arrive in `_ICantCookState._onShared`.

---

## STEP 1 — App Group (shared container app ↔ extension)

Per flavor (cleaner than one shared id given the two bundle IDs):
- `com.icantcook.app`  → App Group `group.com.icantcook.app`
- `com.icantcook.dev`  → App Group `group.com.icantcook.dev`

In Xcode → target **Runner** → Signing & Capabilities → **+ App Groups** → add the
group id(s). This creates `Runner/Runner.entitlements` (none exists today). Wire the
group id per build config via an xcconfig/build setting if you keep both flavors.

## STEP 2 — Create the Share Extension target

Xcode → File → New → Target → **Share Extension**. Name it e.g. `ShareExtension`.
- Set its deployment target ≤ 13.0.
- Give it the **same App Group** capability/entitlement as Runner
  (`ShareExtension/ShareExtension.entitlements`). **Mismatched group id = the extension
  writes but the app reads nothing (silent failure).**
- Replace the generated `ShareViewController.swift` with the one from the
  `receive_sharing_intent` iOS install guide for the pinned version (it serializes the
  shared payload into the App Group and re-opens the host app).

## STEP 3 — Activation rule (only show for links/text, not images)

In `ShareExtension/Info.plist`, set `NSExtension` → `NSExtensionActivationRule`:

```xml
<key>NSExtensionActivationRule</key>
<dict>
    <key>NSExtensionActivationSupportsText</key>
    <true/>
    <key>NSExtensionActivationSupportsWebURLWithMaxCount</key>
    <integer>1</integer>
</dict>
```

Instagram's iOS share sheet passes the reel/post as a URL and/or text — support both.
(`TRUEPREDICATE` also works but is broad; the dict keeps IDontCook out of image shares.)

## STEP 4 — Custom URL scheme (append, don't replace)

`Runner/Info.plist` already has one `CFBundleURLTypes` entry (Google Sign-In's
reversed-client-id). **Add a second dict** for the plugin's re-open scheme — do not
overwrite the existing one:

```xml
<dict>
    <key>CFBundleURLSchemes</key>
    <array>
        <string>ShareMedia-$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    </array>
</dict>
```

This resolves to `ShareMedia-com.icantcook.app` / `ShareMedia-com.icantcook.dev`.

## STEP 5 — Podfile (only if the plugin guide requires it)

`ios/Podfile` defines only `target 'Runner'`. The plugin's app-side pod links via
Flutter automatically. Add a minimal `target 'ShareExtension'` block **only** if the
pinned version's install doc says the shared Swift file needs a pod. (Note the repo is
partway to Swift Package Manager — follow whichever integration the project settles on.)

---

## Verify (real device — share sheet doesn't work in the simulator for third-party apps)

1. `flutter run --flavor dev -d <device>` (or your dev run config).
2. Open Instagram → a public recipe **reel** → Share → **IDontCook**.
3. Confirm the app opens on the "Reading the recipe…" screen (`/import-share`), then
   lands on the prefilled create form. This exercises `handleSharedText` →
   `/import-share` → `ImportSharePage` → `CreateRecipePage(prefillData:)`.
4. Repeat with the app already foregrounded (warm share) and fully killed (cold share).
5. Share a non-Instagram link → confirm the "Only Instagram reels and posts…" toast and
   no navigation.
6. Signed-out cold-start share → confirm the URL replays after login (dashboard's
   `consumePendingSharedImport`).

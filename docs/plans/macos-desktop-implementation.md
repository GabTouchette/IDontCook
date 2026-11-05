# macOS Desktop App — Implementation Plan

**Status:** Decisions locked — ready to implement
**Goal:** Run ICantCook as a native desktop app on Mac.

## Locked decisions
1. **Google Sign-In:** Browser-based OAuth, **integrated (embedded) browser preferred** — see Phase 2 for the caveat that Google may force a fallback to the system browser.
2. **Distribution:** Personal / single Mac only. **Unsigned local build** — no notarization, no Apple Developer account (Phase 4 skipped for now).
3. **Share-import:** Omitted on macOS (no desktop share-sheet equivalent).

## TL;DR — Flutter macOS, not Electron

The ask was "Electron or something like that." We should **not** use Electron. This
is a Flutter app, and Flutter 3.44 (our pinned version) compiles the existing Dart
codebase to a **native macOS app** out of the box. The `mobile/macos/` target is
already scaffolded in the repo.

| Option | What it means here | Verdict |
|---|---|---|
| **Flutter macOS** (recommended) | `flutter run -d macos` builds the current `lib/` as a native Cocoa app. Zero UI rewrite. | ✅ Use this |
| Electron | Rewrite the entire UI in HTML/JS/React, or wrap Flutter Web in a Chromium shell (heavy, laggy, CanvasKit + CORS issues we already hit on web). | ❌ Wrong tool for a Flutter codebase |
| Flutter Web in a shell (Tauri/Electron) | Reuses the web build but inherits the web CORS/image problems documented in memory, plus packaging overhead. | ❌ Only if a browser build were the goal |

The real work is **not** porting a framework. It's: (1) fixing macOS sandbox
entitlements, (2) guarding/replacing a handful of mobile-only plugins, (3)
distribution (signing/notarization) if we want a shareable `.app`.

---

## Current state (verified)

- `mobile/macos/` exists — default `flutter create` scaffold (bundle id still
  `com.example.mobile`, deployment target macOS 10.15).
- Flutter 3.44.0 stable, all six platform folders present.
- **Entitlements are the #1 blocker.** `macos/Runner/*.entitlements` grant
  `app-sandbox` + `network.server` but **not `network.client`** — a sandboxed
  macOS app cannot make outbound HTTP without it, so nothing reaches
  `https://api.idontcook.app`. This is the first thing to fix.

### Plugin compatibility audit

| Plugin | Used in | macOS status | Action |
|---|---|---|---|
| http, provider, shared_preferences, path_provider, google_fonts, flutter_markdown, flutter_map, latlong2, flutter_animate, flutter_slidable, font_awesome, freezed/json, dotted_border, mime | app-wide | ✅ Full support | None |
| **receive_sharing_intent** | `main.dart` (startup), `dashboard_page.dart`, `utils/share_intake.dart` | ❌ **iOS/Android only — no macOS impl** | Guard behind `Platform.isIOS\|\|isAndroid`. Called in `initState` with **no guard today** → risks `MissingPluginException` at launch. The OS share-sheet flow doesn't exist on macOS anyway. |
| **google_sign_in** | `auth_provider.dart`, `onboarding/onboarding_page.dart` | ⚠️ **No official macOS federated impl** | Needs a desktop auth path — **decision required** (see Open Questions). Auth is critical-path. |
| speech_to_text | 1 file (voice chat) | ⚠️ Version/entitlement dependent | Add mic + speech entitlements; feature-detect and hide the mic button if `initialize()` fails. |
| geolocator + geocoding | 1 file (deals/map location) | ⚠️ Apple impl supports macOS | Add location entitlement; graceful fallback to manual location if denied/unavailable. |
| image_picker | 2 files (recipe photos) | ⚠️ Uses file-selector on desktop | Verify picking + upload works; add files-read entitlement. |

---

## Phased plan

### Phase 0 — Boot it (half day)
1. Set bundle id (`com.idontcook.app` or similar) and app display name in the
   macOS target; replace default `com.example.mobile`.
2. Add `com.apple.security.network.client` to **both** `DebugProfile.entitlements`
   and `Release.entitlements`. **This alone is the difference between a working
   and a dead app.**
3. `cd mobile && flutter run -d macos` with the prod `--dart-define API_BASE_URL=https://api.idontcook.app`.
   Expect it to either launch or crash in `_initShareIntake` — that tells us
   whether Phase 1 guard is needed before first boot (it is).

**Exit criteria:** app window opens, reaches the API, login screen renders.

### Phase 1 — Make it not crash: guard mobile-only plugins (1 day)
1. **receive_sharing_intent** — wrap all three call sites so the share stream is
   only initialized on iOS/Android. On macOS the import-from-share feature is
   simply absent (no OS share sheet targets a desktop app the same way). Add a
   `kSupportsShareIntake` capability flag in `utils/share_intake.dart` and have
   `main.dart`/`dashboard_page.dart` respect it.
2. Audit `speech_to_text`, `geolocator`, `image_picker` for unguarded
   platform-channel calls that fire at startup; make each feature-detect.

**Exit criteria:** full navigation without a plugin crash; degraded features hide
cleanly instead of throwing.

### Phase 2 — Google Sign-In on desktop via browser OAuth (1–2 days)

**How it works today (verified):** `auth_provider.signInWithGoogle()` uses the
`google_sign_in` native SDK to get an `idToken`, then POSTs it to
`/api/accounts/google-auth/`. The backend ([api/accounts/views.py:145](../../api/accounts/views.py#L145))
verifies it with `id_token.verify_oauth2_token(token, req, GOOGLE_OAUTH_CLIENT_ID)`
— i.e. the token's `aud` **must equal the single server-configured client ID.**

**Plan — reuse the existing backend endpoint, swap only the client token source
on macOS:**

1. **New Google OAuth client** of type *Desktop app* (or *Web* with a loopback
   redirect) in the Google Cloud console. Its client ID becomes the `aud` of the
   id_token minted on desktop.
2. **Client (integrated browser preferred):** use `desktop_webview_auth` to open
   an **embedded WKWebView** OAuth window, configured with the desktop client ID
   + redirect + `openid email profile` scope. It returns an `idToken` we feed
   into the **unchanged** `googleAuthWithIdToken(idToken)` path.
   - ⚠️ **Honest caveat:** Google's anti-phishing policy can reject OAuth inside
     *embedded* webviews (`403 disallowed_useragent`). Whether it blocks our
     flow depends on Google's current enforcement — I can't promise the embedded
     browser will work until tested. **Fallback:** system browser + loopback
     redirect (PKCE) via `url_launcher` + a tiny local `HttpServer`, or
     `flutter_web_auth_2`. Still a smooth in-app round-trip, just not embedded.
     I'll attempt embedded first and fall back only if Google blocks it.
3. **Backend — accept the desktop audience.** `verify_oauth2_token` takes a
   single audience, so the desktop client ID won't verify against the current
   `GOOGLE_OAUTH_CLIENT_ID`. Change the view to accept a **set** of allowed
   client IDs (add `GOOGLE_OAUTH_CLIENT_IDS` env, verify `aud` ∈ allowed). Small,
   backward-compatible change; keeps mobile working unchanged.
4. Keep **email/password** token auth as the always-works baseline (no native
   SDK), so desktop login is never fully blocked while the Google path is tuned.
5. Add the `network.client` entitlement (already in Phase 0) — required for the
   webview and the token POST.

**Exit criteria:** user signs in on macOS via Google (embedded or system-browser
fallback) *and* via email/password; token persists via `shared_preferences`;
mobile Google login still works.

### Phase 3 — Desktop UX polish (1–2 days, optional for v1)
- Window sizing/min-size, resizable layout sanity on a wide window (the UI is
  phone-width today; verify it doesn't look broken maximized — may want a
  max-content-width wrapper).
- Native menu bar (Cmd+Q, Cmd+W), keyboard shortcuts.
- App icon (`macos/Runner/Assets.xcassets/AppIcon`).

### Phase 4 — Distribution — **DEFERRED** (personal use only)
Out of scope for now (locked decision #2). For personal use, run via
`flutter run -d macos` or build an **unsigned** `.app` locally. Gatekeeper will
warn on first open (right-click → Open to bypass), which is fine on your own Mac.
Revisit this phase only if the app needs to run on someone else's machine — that
would add code signing + notarization + an Apple Developer account ($99/yr).

---

## Implementation status (2026-10-27)

All code phases implemented in the working tree (not committed). Files touched:

**macOS native (Phase 0 + 3):**
- `mobile/macos/Runner/DebugProfile.entitlements`, `Release.entitlements` — added
  `network.client` (+ server, mic, location, user-selected files).
- `mobile/macos/Runner/Info.plist` — mic/speech/location usage strings.
- `mobile/macos/Runner/Configs/AppInfo.xcconfig` — name `ICantCook`, bundle id
  `com.idontcook.app`.
- `mobile/macos/Runner/MainFlutterWindow.swift` — 480×900 default, 380×600 min.
- macOS app icon generated via `dart run flutter_launcher_icons`.

**Dart (Phase 1 + 2):**
- `mobile/lib/utils/share_intake.dart` — `kSupportsShareIntake` flag (iOS/Android only).
- `mobile/lib/main.dart` — `_initShareIntake()` no-ops on macOS.
- `mobile/lib/providers/auth_provider.dart` — Google sign-in branches to an
  embedded `desktop_webview_auth` webview on desktop; mobile unchanged.
- `mobile/pubspec.yaml` — added `desktop_webview_auth: ^0.0.16`, macos icon config.

**Backend (Phase 2):**
- `api/api/settings.py` — `GOOGLE_OAUTH_CLIENT_IDS` (list; primary id always included).
- `api/accounts/views.py` — verifies id_token then checks `aud` ∈ allowed set.

### Setup for Google sign-in on macOS

**Done:**
- Desktop OAuth client created:
  `42379090918-kbqmdopvg7q3lrk201tdeq8an54v2cp1.apps.googleusercontent.com`.
- Backend accepts it — baked into `settings.GOOGLE_OAUTH_DESKTOP_CLIENT_ID`
  (client IDs are public, not secrets), so **no Coolify/env change is needed**;
  it ships with the next code deploy. `verify_oauth2_token` needs only Google's
  public keys + the client id — **no client secret anywhere in this flow.**

**You still need to:**
1. In the Google console, on that OAuth client (type *Web application*), add an
   **Authorized redirect URI** — recommended: `https://api.idontcook.app/auth/google/callback`.
   The page doesn't need to serve anything (the webview intercepts the redirect
   and reads the `#id_token=…` fragment), but Google requires it to be registered.
2. Run the app:
   ```bash
   cd mobile
   flutter run -d macos \
     --dart-define API_BASE_URL=https://api.idontcook.app \
     --dart-define GOOGLE_DESKTOP_OAUTH_CLIENT_ID=42379090918-kbqmdopvg7q3lrk201tdeq8an54v2cp1.apps.googleusercontent.com \
     --dart-define GOOGLE_DESKTOP_OAUTH_REDIRECT=https://api.idontcook.app/auth/google/callback
   ```
   Without the two Google defines the button self-disables
   (`AuthProvider.isGoogleSignInAvailable`); email/password always works.

### Not yet verified / honest caveats
- **Embedded-webview Google OAuth is untested** — I have no OAuth client to drive
  it, and Google may reject OAuth in an embedded webview (`disallowed_useragent`).
  If it's blocked, the fallback is system-browser + loopback. Email/password is
  the guaranteed path meanwhile.
- The onboarding UI still always shows the Google button; wiring it to
  `isGoogleSignInAvailable` to hide it on an unconfigured desktop build is a small
  follow-up (left as-is so nothing silently disappears).

## Risk notes
- Entitlements (network.client) is the single highest-leverage fix — trivial but
  total-blocker.
- `receive_sharing_intent` at startup is the most likely first-launch crash.
- **Embedded-browser Google OAuth may be blocked by Google** (`disallowed_useragent`);
  system-browser loopback is the proven fallback. Email/password covers us either way.
- Backend audience change is required for desktop Google tokens to verify — small,
  backward-compatible, but don't forget it or desktop Google login returns 400.

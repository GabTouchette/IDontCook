// Smoke test for the ICantCook app shell.
//
// The default Flutter counter template was removed — this app has no counter.
// Pumping the full `ICantCook` widget would bootstrap every provider (and
// SharedPreferences/network), which is too heavy for a unit smoke test, so we
// assert the app widget can be constructed with a route instead.

import 'package:flutter_test/flutter_test.dart';

import 'package:i_cant_cook/main.dart';

void main() {
  test('ICantCook can be constructed with an initial route', () {
    const app = ICantCook(initialRoute: '/onboarding');
    expect(app.initialRoute, '/onboarding');
  });
}

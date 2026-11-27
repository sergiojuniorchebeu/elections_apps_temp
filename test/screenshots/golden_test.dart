@Tags(['golden'])
library;

import 'package:elections_app/app/router/routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';

/// Key screens, light and dark, at a fixed time. Regenerate after a
/// visual change: `flutter test --update-goldens test/screenshots`.
/// Goldens are rendered on macOS; other platforms may differ by a few
/// pixels (run with `--exclude-tags golden` there).
void main() {
  setUpAll(loadAppFonts);
  final fixed = DateTime(2026, 10, 28, 9, 41);

  final screens = <(String, String, bool)>[
    ('home', Routes.home, true),
    ('digital_id', Routes.digitalId, true),
    ('activity', Routes.activity, true),
    ('profile', Routes.profile, true),
    ('landing', Routes.welcome, false),
    ('sign_in', Routes.signIn, false),
  ];

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final (name, route, signedIn) in screens) {
      testWidgets('$name ${mode.name}', (tester) async {
        final app = await pumpApp(
          tester,
          location: route,
          signedIn: signedIn,
          themeMode: mode,
          clock: () => fixed,
          devPanel: false,
          size: const Size(430, 932),
        );
        // PNG icons decode outside the fake clock: load them for real.
        await tester.runAsync(() async {
          for (final e in find.byType(Image).evaluate()) {
            await precacheImage((e.widget as Image).image, e);
          }
        });
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/${name}_${mode.name}.png'),
        );
        await app.dispose();
      });
    }
  }
}

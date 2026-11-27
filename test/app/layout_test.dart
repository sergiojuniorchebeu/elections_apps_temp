import 'package:elections_app/app/router/routes.dart';
import 'package:elections_app/design_system/design_system.dart';
import 'package:elections_app/features/identity/identity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';

/// Every main screen at the reference sizes: no overflow, no exception.
/// (An overflow is a FlutterError, which fails the test by itself.)
void main() {
  const signedInRoutes = [
    Routes.home,
    Routes.digitalId,
    Routes.activity,
    Routes.profile,
    Routes.notifications,
    Routes.personalDetails,
    Routes.elections,
    '/elections/el_city',
    Routes.petitions,
    '/petitions/pt_crossings',
    Routes.documents,
    '/documents/doc_misc',
    Routes.services,
    '/services/sv_marriage',
    Routes.search,
  ];
  const signedOutRoutes = [
    Routes.welcome,
    Routes.signIn,
    Routes.signUp,
    Routes.forgotPassword,
  ];

  final configs = <(String, Size, double)>[
    ('320x568 @130%', TestSizes.small, 1.3),
    ('430x932', TestSizes.phone, 1),
    ('430x932 @200%', TestSizes.phone, 2),
    ('tablet 820x1180', TestSizes.tablet, 1),
  ];

  for (final (name, size, scale) in configs) {
    group(name, () {
      for (final route in signedInRoutes) {
        testWidgets(route, (tester) async {
          final app = await pumpApp(tester, size: size, textScale: scale, location: route);
          expect(tester.takeException(), isNull);
          await app.dispose();
        });
      }
      for (final route in signedOutRoutes) {
        testWidgets('$route (signed out)', (tester) async {
          final app = await pumpApp(
            tester,
            size: size,
            textScale: scale,
            signedIn: false,
            location: route,
          );
          expect(tester.takeException(), isNull);
          await app.dispose();
        });
      }
    });
  }

  testWidgets('tablet: content is centered at most 640 wide', (tester) async {
    final app = await pumpApp(tester, size: TestSizes.tablet);
    final card = tester.getSize(find.byType(CitizenCard));
    expect(card.width, lessThanOrEqualTo(AppSizes.maxContentWidth));
    final left = tester.getTopLeft(find.byType(CitizenCard)).dx;
    expect(left, greaterThan((TestSizes.tablet.width - AppSizes.maxContentWidth) / 2 - 1));
    await app.dispose();
  });

  testWidgets('phone: content uses the full width', (tester) async {
    final app = await pumpApp(tester, size: TestSizes.phone);
    final card = tester.getSize(find.byType(CitizenCard));
    expect(card.width, TestSizes.phone.width - 2 * AppSpacing.gutter);
    await app.dispose();
  });

  group('touch targets', () {
    for (final route in [Routes.home, Routes.digitalId, Routes.profile, Routes.notifications]) {
      testWidgets('$route meets Android and iOS guidelines', (tester) async {
        final handle = tester.ensureSemantics();
        final app = await pumpApp(tester, location: route);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await app.dispose();
        handle.dispose();
      });
    }
  });
}

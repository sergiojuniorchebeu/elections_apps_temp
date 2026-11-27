import 'package:elections_app/core/storage/preferences.dart';
import 'package:elections_app/features/auth/application/auth_providers.dart';
import 'package:elections_app/features/auth/application/session_controller.dart';
import 'package:elections_app/features/home/application/home_providers.dart';
import 'package:elections_app/l10n/strings.dart';
import 'package:elections_app/mock/mock_accounts.dart';
import 'package:elections_app/mock/scenario.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('home opens on its offline copy when the network is down', (tester) async {
    final app = await pumpApp(tester);
    expect(find.text('Alex Morgan'), findsWidgets);

    app.scenario = MockScenario.offline;
    app.container.invalidate(homeFeedProvider);
    await tester.pumpAndSettle();

    expect(find.text('Alex Morgan'), findsWidgets);
    expect(find.text(HomeStrings.community), findsOneWidget);
    expect(find.text(CommonStrings.offlineTitle), findsOneWidget);
    await app.dispose();
  });

  testWidgets('switching account never shows the previous account, even one frame', (tester) async {
    final app = await pumpApp(tester);
    expect(find.text('Alex Morgan'), findsWidgets);

    await app.container.read(sessionControllerProvider.notifier).signOut();
    await tester.pumpAndSettle();
    final result = await app.container.read(authRepositoryProvider).signIn(
      email: MockAccounts.secondEmail,
      password: MockAccounts.demoPassword,
    );
    await app.container.read(sessionControllerProvider.notifier).establish(result);
    await tester.pump();
    expect(find.text('Alex Morgan'), findsNothing);

    await tester.pumpAndSettle();
    expect(find.text('Sam Lee'), findsWidgets);
    expect(find.text('Alex Morgan'), findsNothing);
    await app.dispose();
  });

  testWidgets('app lock: covers the app until biometrics succeed', (tester) async {
    final auth = FakeAuthenticator(approve: false);
    final app = await pumpApp(
      tester,
      authenticator: auth,
      preferences: MemoryPreferences({PrefKeys.appLockEnabled: true}),
    );
    expect(find.text(LockStrings.title), findsOneWidget);
    expect(auth.calls, 1);

    auth.approve = true;
    await tester.tap(find.text(LockStrings.unlockWith('Face ID')));
    await tester.pumpAndSettle();
    expect(find.text(LockStrings.title), findsNothing);
    expect(find.text(HomeStrings.community), findsOneWidget);
    await app.dispose();
  });

  testWidgets('show code asks for biometrics when protection is on', (tester) async {
    final auth = FakeAuthenticator(approve: false);
    final app = await pumpApp(tester, authenticator: auth, location: '/id');
    await tester.tap(find.text(IdStrings.showCode));
    await tester.pumpAndSettle();
    expect(auth.calls, 1);
    expect(find.text(IdStrings.codeTitle), findsNothing);

    auth.approve = true;
    await tester.tap(find.text(IdStrings.showCode));
    await tester.pumpAndSettle();
    expect(find.text(IdStrings.codeTitle), findsOneWidget);
    await app.dispose();
  });
}

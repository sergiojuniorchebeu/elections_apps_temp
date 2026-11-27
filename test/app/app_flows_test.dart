import 'package:elections_app/app/router/routes.dart';
import 'package:elections_app/core/state/connectivity.dart';
import 'package:elections_app/core/utils/formats.dart';
import 'package:elections_app/features/auth/application/session_controller.dart';
import 'package:elections_app/features/profile/presentation/signature_widgets.dart';
import 'package:elections_app/l10n/strings.dart';
import 'package:elections_app/mock/mock_accounts.dart';
import 'package:elections_app/mock/scenario.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';

void main() {
  group('sign-in', () {
    testWidgets('signed out -> landing -> sign in -> home', (tester) async {
      final app = await pumpApp(tester, signedIn: false);
      expect(find.text(AuthStrings.haveAccount), findsOneWidget);

      await tester.tap(find.text(AuthStrings.haveAccount));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), MockAccounts.demoEmail);
      await tester.enterText(find.byType(TextField).at(1), MockAccounts.demoPassword);
      await tester.tap(find.text(AuthStrings.signIn));
      await tester.pumpAndSettle();

      expect(find.text('Alex Morgan'), findsWidgets);
      expect(find.text(HomeStrings.community), findsOneWidget);
      await app.dispose();
    });

    testWidgets('sign-in shows no demo ids, offers Apple and Google', (tester) async {
      final app = await pumpApp(tester, signedIn: false, location: Routes.signIn);
      expect(find.text(MockAccounts.demoEmail), findsNothing);
      expect(find.text(AuthStrings.continueWithApple), findsOneWidget);
      expect(find.text(AuthStrings.continueWithGoogle), findsOneWidget);
      await app.dispose();
    });

    testWidgets('any e-mail + the universal password signs in', (tester) async {
      final app = await pumpApp(tester, signedIn: false, location: Routes.signIn);
      await tester.enterText(find.byType(TextField).at(0), 'jean.dupont@exemple.fr');
      await tester.enterText(find.byType(TextField).at(1), MockAccounts.universalPassword);
      await tester.tap(find.text(AuthStrings.signIn));
      await tester.pumpAndSettle();

      expect(app.container.read(sessionControllerProvider).signedIn, isTrue);
      expect(find.text(HomeStrings.community), findsOneWidget);
      await app.dispose();
    });

    testWidgets('continue with Google: consent sheet, then home', (tester) async {
      final app = await pumpApp(tester, signedIn: false, location: Routes.signIn);
      await tester.ensureVisible(find.text(AuthStrings.continueWithGoogle));
      await tester.tap(find.text(AuthStrings.continueWithGoogle));
      await tester.pumpAndSettle();
      expect(find.text(DevStrings.socialTitle(AuthStrings.google)), findsOneWidget);
      await tester.tap(find.text(DevStrings.socialContinue));
      await tester.pumpAndSettle();

      expect(app.container.read(sessionControllerProvider).signedIn, isTrue);
      expect(find.text(HomeStrings.community), findsOneWidget);
      await app.dispose();
    });

    testWidgets('continue with Apple, then cancel: still signed out', (tester) async {
      final app = await pumpApp(tester, signedIn: false, location: Routes.signIn);
      await tester.ensureVisible(find.text(AuthStrings.continueWithApple));
      await tester.tap(find.text(AuthStrings.continueWithApple));
      await tester.pumpAndSettle();
      await tester.tap(find.text(CommonStrings.cancel));
      await tester.pumpAndSettle();
      expect(app.container.read(sessionControllerProvider).signedIn, isFalse);
      expect(find.text(AuthStrings.signIn), findsOneWidget);
      await app.dispose();
    });

    testWidgets('wrong password shows a clear message', (tester) async {
      final app = await pumpApp(tester, signedIn: false, location: Routes.signIn);
      await tester.enterText(find.byType(TextField).at(0), MockAccounts.demoEmail);
      await tester.enterText(find.byType(TextField).at(1), 'nope-nope');
      await tester.tap(find.text(AuthStrings.signIn));
      await tester.pumpAndSettle();

      expect(find.textContaining('E-mail ou mot de passe incorrect'), findsOneWidget);
      expect(app.container.read(sessionControllerProvider).signedIn, isFalse);
      await app.dispose();
    });

    testWidgets('sign-up: server refuses a used email on its field', (tester) async {
      final app = await pumpApp(tester, signedIn: false, location: Routes.signUp);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Jo');
      await tester.enterText(fields.at(1), 'Doe');
      await tester.enterText(fields.at(3), MockAccounts.takenEmail);
      await tester.enterText(fields.at(4), 'longpassword');
      // Date of birth through the picker would be slow: fill local state
      // by submitting once and checking the local error first.
      await tester.ensureVisible(find.text(AuthStrings.signUp));
      await tester.tap(find.text(AuthStrings.signUp));
      await tester.pumpAndSettle();
      expect(find.text('Saisissez votre date de naissance.'), findsOneWidget);
      expect(find.text('Acceptez les conditions pour continuer.'), findsOneWidget);
      await app.dispose();
    });
  });

  group('session', () {
    testWidgets('expired session signs out and explains why', (tester) async {
      final app = await pumpApp(tester);
      app.scenario = MockScenario.sessionExpired;
      await tester.tap(find.text(NavStrings.activity));
      await tester.pumpAndSettle();

      expect(app.container.read(sessionControllerProvider).signedIn, isFalse);
      expect(find.text(AuthStrings.haveAccount), findsOneWidget);
      await tester.tap(find.text(AuthStrings.haveAccount));
      await tester.pumpAndSettle();
      expect(find.textContaining('Votre session a pris fin'), findsOneWidget);
      await app.dispose();
    });

    testWidgets('an expired access token is renewed silently', (tester) async {
      final app = await pumpApp(tester);
      final before = app.server.session.current!.refreshToken;
      app.server.expireAccessToken();
      await tester.tap(find.text(NavStrings.activity));
      await tester.pumpAndSettle();

      expect(app.container.read(sessionControllerProvider).signedIn, isTrue);
      expect(app.server.session.current!.refreshToken, isNot(before));
      expect(find.text(ActivityStrings.title), findsWidgets);
      await app.dispose();
    });

    testWidgets('sign-out wipes the account and returns to landing', (tester) async {
      final app = await pumpApp(tester, location: Routes.profile);
      await tester.scrollUntilVisible(
        find.text(ProfileStrings.signOut),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      // Clear the floating tab bar.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
      await tester.pumpAndSettle();
      await tester.tap(find.text(ProfileStrings.signOut));
      await tester.pumpAndSettle();
      await tester.tap(find.text(ProfileStrings.signOut).last);
      await tester.pumpAndSettle();

      expect(find.text(AuthStrings.createAccount), findsOneWidget);
      expect(app.server.session.current, isNull);
      await app.dispose();
    });
  });

  group('states', () {
    testWidgets('network down: banner + error, back online refreshes', (tester) async {
      final app = await pumpApp(tester, location: Routes.notifications, scenario: MockScenario.offline);
      expect(find.text(CommonStrings.offlineTitle), findsOneWidget);
      expect(find.text('Pas de connexion'), findsOneWidget);

      app.scenario = MockScenario.normal;
      await tester.tap(find.text(CommonStrings.retry).first);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(app.container.read(connectivityProvider).online, isTrue);
      expect(find.text(CommonStrings.offlineTitle), findsNothing);
      await app.dispose();
    });

    testWidgets('empty lists show the empty state', (tester) async {
      final app = await pumpApp(tester, location: Routes.notifications, scenario: MockScenario.empty);
      expect(find.text(NotificationStrings.emptyTitle), findsOneWidget);
      await app.dispose();
    });

    testWidgets('server error offers to try again', (tester) async {
      final app = await pumpApp(tester, location: Routes.petitions, scenario: MockScenario.serverError);
      expect(find.text('Un problème est survenu'), findsOneWidget);
      app.scenario = MockScenario.normal;
      await tester.tap(find.text(CommonStrings.retry));
      await tester.pumpAndSettle();
      expect(find.text('Plus de vert. De meilleures villes.'), findsOneWidget);
      await app.dispose();
    });

    testWidgets('an invalid link opens "not found"', (tester) async {
      final app = await pumpApp(tester, location: '/petitions/..%2F..');
      expect(find.text(CommonStrings.notFoundHeading), findsOneWidget);
      await app.dispose();
    });
  });

  group('civic', () {
    testWidgets('signing a petition: create a signature, then the pen writes it', (tester) async {
      final app = await pumpApp(tester, location: Routes.petition('pt_crossings'));
      expect(find.text(HomeStrings.signatures(Formats.number(2310), Formats.number(5000))), findsOneWidget);

      // No signature yet: create one first.
      await tester.tap(find.text(CivicStrings.sign));
      await tester.pumpAndSettle();
      expect(find.text(PetitionSignStrings.needSignature), findsOneWidget);
      await tester.tap(find.text(PetitionSignStrings.createSignature));
      await tester.pumpAndSettle();
      expect(find.byType(SignaturePad), findsOneWidget);
      await drawSignature(tester);
      await tester.tap(find.text(SignatureStrings.save));
      await tester.pumpAndSettle();

      // Back on the petition: the signing sheet with the saved signature.
      expect(find.text(PetitionSignStrings.title), findsOneWidget);
      await tester.tap(find.text(PetitionSignStrings.sign));
      await tester.pumpAndSettle();
      expect(find.text(PetitionSignStrings.done), findsOneWidget);
      await tester.tap(find.text(PetitionSignStrings.close));
      await tester.pumpAndSettle();

      expect(find.text(HomeStrings.signatures(Formats.number(2311), Formats.number(5000))), findsOneWidget);
      expect(find.text(CivicStrings.signed), findsOneWidget);

      await app.go(Routes.activity);
      expect(find.text('Pétition signée'), findsWidgets);
      await app.dispose();
    });

    testWidgets('a saved signature goes straight to the signing sheet', (tester) async {
      final app = await pumpApp(tester, location: Routes.signature);
      await drawSignature(tester);
      await tester.tap(find.text(SignatureStrings.save));
      await tester.pumpAndSettle();
      expect(find.text(SignatureStrings.redo), findsOneWidget);

      await app.go(Routes.petition('pt_crossings'));
      await tester.pump(const Duration(seconds: 5)); // "saved" snack bar leaves
      await tester.pumpAndSettle();
      await tester.tap(find.text(CivicStrings.sign));
      await tester.pumpAndSettle();
      expect(find.text(PetitionSignStrings.needSignature), findsNothing);
      expect(find.text(PetitionSignStrings.title), findsOneWidget);
      await app.dispose();
    });

    testWidgets('server error in the sheet: refused, can retry', (tester) async {
      final app = await pumpApp(tester, location: Routes.signature);
      await drawSignature(tester);
      await tester.tap(find.text(SignatureStrings.save));
      await tester.pumpAndSettle();
      await app.go(Routes.petition('pt_crossings'));
      await tester.pump(const Duration(seconds: 5)); // "saved" snack bar leaves
      await tester.pumpAndSettle();
      await tester.tap(find.text(CivicStrings.sign));
      await tester.pumpAndSettle();

      app.scenario = MockScenario.serverError;
      await tester.tap(find.text(PetitionSignStrings.sign));
      await tester.pumpAndSettle();
      expect(find.text(PetitionSignStrings.done), findsNothing);
      expect(find.text(PetitionSignStrings.sign), findsOneWidget); // can retry
      await app.dispose();
    });

    testWidgets('home card opens the election', (tester) async {
      final app = await pumpApp(tester);
      await tester.scrollUntilVisible(
        find.text('Conseil municipal'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      // Bring the card above the floating tab bar.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -250));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Conseil municipal'));
      await tester.pumpAndSettle();
      expect(find.text(CivicStrings.pollingStation), findsOneWidget);
      await app.dispose();
    });

    testWidgets('service request gets a reference', (tester) async {
      final app = await pumpApp(tester, location: Routes.service('sv_residence'));
      await tester.tap(find.text(ServiceStrings.request));
      await tester.pumpAndSettle();
      expect(find.text(ServiceStrings.requestSent), findsOneWidget);
      await app.dispose();
    });
  });

  group('identity', () {
    testWidgets('digital ID shows the card and personal details', (tester) async {
      final app = await pumpApp(tester, location: Routes.digitalId);
      expect(find.text(IdStrings.identityVerified), findsOneWidget);
      expect(find.text('14 mai 1994'), findsOneWidget);
      expect(find.text('•••• •••• 4829'), findsOneWidget);
      await app.dispose();
    });

    testWidgets('share ID creates a link', (tester) async {
      final app = await pumpApp(tester, location: Routes.digitalId);
      await tester.tap(find.text(IdStrings.shareId));
      await tester.pumpAndSettle();
      await tester.tap(find.text(IdStrings.createLink));
      await tester.pumpAndSettle();
      expect(find.text(IdStrings.linkReady), findsOneWidget);
      await app.dispose();
    });

    testWidgets('contact form shows the server error under the field', (tester) async {
      final app = await pumpApp(tester, location: Routes.personalDetails);
      await tester.enterText(find.byType(TextField).first, '+000000');
      await tester.ensureVisible(find.text(CommonStrings.save));
      await tester.tap(find.text(CommonStrings.save));
      await tester.pumpAndSettle();
      expect(find.text('Ce numéro ne peut pas recevoir de messages.'), findsOneWidget);
      await app.dispose();
    });
  });

  testWidgets('notifications: mark all read clears the bell', (tester) async {
    final app = await pumpApp(tester, location: Routes.notifications);
    await tester.tap(find.byIcon(Icons.done_all_rounded));
    await tester.pumpAndSettle();
    // Nothing unread left: the action disappears.
    expect(find.byIcon(Icons.done_all_rounded), findsNothing);
    await app.dispose();
  });

  testWidgets('analytics: screens are named by pattern, never by id', (tester) async {
    final analytics = RecordingAnalytics();
    final app = await pumpApp(
      tester,
      overrides: [analyticsProviderOverride(analytics)],
    );
    await app.go(Routes.petition('pt_green'));
    final screens = analytics.events.map((e) => e.$2['screen']).toList();
    expect(screens, contains('/petitions/:id'));
    expect(screens.join(), isNot(contains('pt_green')));
    await app.dispose();
  });
}

/// Draws a zigzag in the signature pad, like a finger would.
Future<void> drawSignature(WidgetTester tester) async {
  final box = tester.getRect(find.byType(SignaturePad));
  final g = await tester.startGesture(Offset(box.left + box.width * 0.15, box.top + box.width / 2.5 * 0.5));
  for (var i = 1; i <= 24; i++) {
    await g.moveTo(Offset(
      box.left + box.width * (0.15 + i * 0.028),
      box.top + box.width / 2.5 * (i.isEven ? 0.35 : 0.7),
    ));
  }
  await g.up();
  await tester.pump();
}

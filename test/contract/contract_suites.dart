import 'package:elections_app/core/error/failure.dart';
import 'package:elections_app/core/session/session.dart';
import 'package:elections_app/features/auth/domain/auth_repository.dart';
import 'package:elections_app/mock/mock_accounts.dart';
import 'package:flutter_test/flutter_test.dart';

import 'contract_env.dart';

/// The behaviour every implementation must have for the screens to work
/// unchanged. Run it against yours: see docs/BACKEND.md.
void runContractSuites(ContractEnv Function() create) {
  final probe = create();
  group('[${probe.name}] auth', () {
    test('signs in a known account', () async {
      final env = create();
      final r = await env.auth.signIn(
        email: MockAccounts.demoEmail,
        password: MockAccounts.demoPassword,
      );
      expect(r.user.email, MockAccounts.demoEmail);
      expect(r.session.accessToken, isNotEmpty);
      expect(r.session.refreshToken, isNotEmpty);
      expect(r.session.expiresAt.isAfter(DateTime.now()), isTrue);
    });

    test('wrong password -> AuthFailure(invalidCredentials)', () async {
      final env = create();
      await expectLater(
        env.auth.signIn(email: MockAccounts.demoEmail, password: 'wrong-one'),
        throwsA(isA<AuthFailure>().having(
          (f) => f.reason,
          'reason',
          AuthFailureReason.invalidCredentials,
        )),
      );
    });

    test('refused renewal -> AuthFailure(sessionEnded)', () async {
      final env = create();
      await expectLater(
        env.auth.renew(Session(
          userId: 'u_alex',
          accessToken: 'x',
          refreshToken: 'not-a-token',
          expiresAt: DateTime(2000),
        )),
        throwsA(isA<AuthFailure>().having((f) => f.sessionEnded, 'ended', isTrue)),
      );
    });

    test('renewal gives new tokens, old refresh token is single-use', () async {
      final env = create();
      await env.signIn();
      final first = env.session.current!;
      final next = await env.auth.renew(first);
      expect(next.accessToken, isNot(first.accessToken));
      await expectLater(env.auth.renew(first), throwsA(isA<AuthFailure>()));
    });

    test('expired access token is renewed transparently', () async {
      final env = create();
      await env.signIn();
      await env.expireAccess();
      final user = await env.auth.currentUser();
      expect(user.email, MockAccounts.demoEmail);
    });

    test('a field error comes back keyed by field', () async {
      final env = create();
      try {
        await env.auth.signIn(email: 'not-an-email', password: '');
        fail('should throw');
      } on ValidationFailure catch (f) {
        expect(f.fieldErrors.keys, contains(AuthFields.email));
      } on UnimplementedError {
        // Sign-up / field errors not served by this env.
      }
    });
  });

  group('[${probe.name}] petitions', () {
    test('cursor pagination walks every item once', () async {
      final env = create();
      await env.signIn();
      final ids = <String>[];
      String? cursor;
      var pages = 0;
      do {
        final page = await env.petitions.list(cursor: cursor);
        ids.addAll(page.items.map((p) => p.id));
        cursor = page.nextCursor;
        pages++;
      } while (cursor != null && pages < 20);
      expect(pages, greaterThan(1));
      expect(ids.toSet().length, ids.length);
    });

    test('unknown id -> NotFoundFailure', () async {
      final env = create();
      await env.signIn();
      await expectLater(env.petitions.get('nope'), throwsA(isA<NotFoundFailure>()));
    });

    test('signing counts once, even when replayed with the same key', () async {
      final env = create();
      await env.signIn();
      final before = await env.petitions.get('pt_crossings');
      final a = await env.petitions.sign('pt_crossings', idempotencyKey: 'k-1');
      final b = await env.petitions.sign('pt_crossings', idempotencyKey: 'k-1');
      expect(a.signatures, before.signatures + 1);
      expect(b.signatures, a.signatures);
      expect(a.signedByMe, isTrue);
      await expectLater(
        env.petitions.sign('pt_crossings', idempotencyKey: 'k-2'),
        throwsA(isA<ConflictFailure>()),
      );
    });

    test('closed petition -> ConflictFailure', () async {
      final env = create();
      await env.signIn();
      await expectLater(
        env.petitions.sign('pt_closed', idempotencyKey: 'k-3'),
        throwsA(isA<ConflictFailure>()),
      );
    });

    test('not signed in -> AuthFailure', () async {
      final env = create();
      await expectLater(env.petitions.list(), throwsA(isA<AuthFailure>()));
    });
  });

  group('[${probe.name}] notifications', () {
    test('mark all read brings the unread count to 0', () async {
      final env = create();
      await env.signIn();
      final first = await env.notifications.list();
      expect(first.items, isNotEmpty);
      expect(await env.notifications.unreadCount(), greaterThan(0));
      await env.notifications.markAllRead();
      expect(await env.notifications.unreadCount(), 0);
    });
  });
}

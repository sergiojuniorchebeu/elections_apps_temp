import 'package:elections_app/core/error/failure.dart';
import 'package:elections_app/core/session/session.dart';
import 'package:elections_app/core/session/session_holder.dart';
import 'package:elections_app/core/storage/secure_store.dart';
import 'package:elections_app/core/storage/session_store.dart';
import 'package:flutter_test/flutter_test.dart';

Session _s(String rt) => Session(
  userId: 'u',
  accessToken: 'at-$rt',
  refreshToken: rt,
  expiresAt: DateTime.now().add(const Duration(minutes: 5)),
);

void main() {
  late SessionHolder holder;
  setUp(() => holder = SessionHolder(SessionStore(MemorySecureStore())));

  test('concurrent renewals are merged into one', () async {
    var calls = 0;
    holder.renewer = (s) async {
      calls++;
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return _s('rt2');
    };
    await holder.set(_s('rt1'));
    final results = await Future.wait([holder.renew(), holder.renew(), holder.renew()]);
    expect(calls, 1);
    expect(results.map((s) => s.refreshToken).toSet(), {'rt2'});
  });

  test('a network error during renewal never signs out', () async {
    holder.renewer = (_) async => throw const NetworkFailure();
    await holder.set(_s('rt1'));
    var ended = false;
    holder.onEnded.listen((_) => ended = true);
    await expectLater(holder.renew(), throwsA(isA<NetworkFailure>()));
    await Future<void>.delayed(Duration.zero);
    expect(holder.current, isNotNull);
    expect(ended, isFalse);
  });

  test('a refused renewal ends the session', () async {
    holder.renewer = (_) async => throw const AuthFailure(sessionEnded: true);
    await holder.set(_s('rt1'));
    final ended = holder.onEnded.first;
    await expectLater(holder.renew(), throwsA(isA<AuthFailure>()));
    await ended;
    expect(holder.current, isNull);
  });

  test('persists and restores', () async {
    final store = SessionStore(MemorySecureStore());
    await SessionHolder(store).set(_s('rt9'));
    expect((await SessionHolder(store).restore())!.refreshToken, 'rt9');
  });
}

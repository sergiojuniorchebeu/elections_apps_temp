import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core_providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/security/app_lock.dart';
import '../../../core/state/action_controller.dart';
import '../../../core/state/session_scope.dart';
import '../../../core/storage/preferences.dart';
import '../domain/auth_repository.dart';
import '../domain/user.dart';
import 'auth_providers.dart';

/// Signed in or not. The router redirects on it; nothing else decides.
final class SessionState {
  const SessionState({required this.signedIn, this.endedNotice});

  final bool signedIn;

  /// Why the user was signed out without asking (shown on sign-in).
  final Failure? endedNotice;
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() {
    final holder = ref.watch(sessionHolderProvider);
    final sub = holder.onEnded.listen(
      (_) => _clearLocal(notice: const AuthFailure(sessionEnded: true)),
    );
    ref.onDispose(sub.cancel);
    return SessionState(signedIn: holder.current != null);
  }

  /// Called after a successful sign-in / sign-up.
  Future<void> establish(AuthResult result) async {
    await ref.read(sessionHolderProvider).set(result.session);
    ref.read(sessionScopeProvider.notifier).bump();
    state = const SessionState(signedIn: true);
  }

  /// User-initiated sign-out: revokes on the server (best effort), then
  /// wipes everything tied to the account.
  Future<void> signOut() async {
    try {
      await ref
          .read(authRepositoryProvider)
          .signOut()
          .timeout(const Duration(seconds: 5));
    } on Object {
      // Local sign-out must always work.
    }
    await _clearLocal();
  }

  Future<void> _clearLocal({Failure? notice}) async {
    await ref.read(sessionHolderProvider).clear();
    await ref.read(offlineStoreProvider).clear();
    final prefs = ref.read(preferencesProvider);
    for (final key in PrefKeys.accountScoped) {
      await prefs.remove(key);
    }
    ref.read(appLockProvider.notifier).reset();
    ref.read(sessionScopeProvider.notifier).bump();
    state = SessionState(signedIn: false, endedNotice: notice);
  }

  void dismissNotice() {
    if (state.endedNotice != null) state = SessionState(signedIn: state.signedIn);
  }
}

/// The signed-in user (name in Profile...). Reloads on account change.
final currentUserProvider = FutureProvider.autoDispose<User>((ref) {
  ref.watch(sessionScopeProvider);
  return ref.watch(authRepositoryProvider).currentUser();
});

final signInControllerProvider =
    NotifierProvider.autoDispose<SignInController, ActionState<AuthResult>>(
      SignInController.new,
    );

class SignInController extends ActionController<AuthResult> {
  Future<bool> submit(String email, String password) async {
    final result = await run(
      (_) => ref
          .read(authRepositoryProvider)
          .signIn(email: email.trim(), password: password),
    );
    if (result == null) return false;
    await ref.read(sessionControllerProvider.notifier).establish(result);
    return true;
  }
}

final signUpControllerProvider =
    NotifierProvider.autoDispose<SignUpController, ActionState<AuthResult>>(
      SignUpController.new,
    );

class SignUpController extends ActionController<AuthResult> {
  Future<bool> submit(SignUpRequest request) async {
    final result = await run(
      (_) => ref.read(authRepositoryProvider).signUp(request),
    );
    if (result == null) return false;
    await ref.read(sessionControllerProvider.notifier).establish(result);
    return true;
  }
}

final passwordResetControllerProvider =
    NotifierProvider.autoDispose<PasswordResetController, ActionState<void>>(
      PasswordResetController.new,
    );

class PasswordResetController extends ActionController<void> {
  Future<void> submit(String email) => run(
    (_) => ref.read(authRepositoryProvider).requestPasswordReset(email.trim()),
  );
}

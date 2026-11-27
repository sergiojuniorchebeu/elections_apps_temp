import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/action_controller.dart';
import '../../../core/state/cache_for.dart';
import '../../../core/state/connectivity.dart';
import '../../../core/state/session_scope.dart';
import '../domain/signature.dart';

/// Implemented in `backend.dart` (overrides).
final signatureRepositoryProvider = Provider<SignatureRepository>(
  (_) => throw UnimplementedError('Provided by backend.dart'),
);

/// The member's saved signature (null: none yet).
final signatureProvider = AsyncNotifierProvider.autoDispose<SignatureNotifier, Signature?>(
  SignatureNotifier.new,
);

class SignatureNotifier extends AsyncNotifier<Signature?> {
  @override
  Future<Signature?> build() {
    ref.watch(sessionScopeProvider);
    ref.cacheFor(const Duration(minutes: 10));
    return guard(ref, () => ref.read(signatureRepositoryProvider).get());
  }

  void set(Signature? value) => state = AsyncData(value);
}

final saveSignatureControllerProvider =
    NotifierProvider.autoDispose<SaveSignatureController, ActionState<Signature>>(
      SaveSignatureController.new,
    );

class SaveSignatureController extends ActionController<Signature> {
  Future<Signature?> save(Signature signature) async {
    final saved = await run(
      (_) => ref.read(signatureRepositoryProvider).save(signature),
    );
    if (saved != null) ref.read(signatureProvider.notifier).set(saved);
    return saved;
  }

  Future<bool> delete() async {
    final done = await run((_) async {
      await ref.read(signatureRepositoryProvider).delete();
      return const Signature(strokes: []);
    });
    if (done == null) return false;
    ref.read(signatureProvider.notifier).set(null);
    return true;
  }
}

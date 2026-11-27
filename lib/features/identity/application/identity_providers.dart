import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/action_controller.dart';
import '../../../core/state/connectivity.dart';
import '../../../core/state/offline_first.dart';
import '../domain/citizen_id.dart';
import '../domain/identity_repository.dart';

final identityRepositoryProvider = Provider<IdentityRepository>(
  (_) => throw UnimplementedError('Provided by backend.dart'),
);

final citizenIdProvider = AsyncNotifierProvider<CitizenIdNotifier, CitizenId>(
  CitizenIdNotifier.new,
);

class CitizenIdNotifier extends OfflineFirstNotifier<CitizenId> {
  @override
  Future<CitizenId?> peek() => ref.read(identityRepositoryProvider).peek();
  @override
  Future<CitizenId> fetch() => ref.read(identityRepositoryProvider).citizenId();
}

/// A fresh code every time the sheet opens; never cached.
final presentationCodeProvider = FutureProvider.autoDispose<PresentationCode>(
  (ref) => guard(ref, () => ref.read(identityRepositoryProvider).presentationCode()),
);

final shareControllerProvider =
    NotifierProvider.autoDispose<ShareController, ActionState<ShareLink>>(
      ShareController.new,
    );

class ShareController extends ActionController<ShareLink> {
  Future<ShareLink?> submit(Set<SharedField> fields) => run(
    (key) => ref.read(identityRepositoryProvider).share(fields, idempotencyKey: key),
  );
}

final verifyControllerProvider =
    NotifierProvider.autoDispose<VerifyController, ActionState<VerificationResult>>(
      VerifyController.new,
    );

class VerifyController extends ActionController<VerificationResult> {
  Future<VerificationResult?> submit(String code) =>
      run((_) => ref.read(identityRepositoryProvider).verify(code));
}

final contactControllerProvider =
    NotifierProvider.autoDispose<ContactController, ActionState<CitizenId>>(
      ContactController.new,
    );

class ContactController extends ActionController<CitizenId> {
  Future<CitizenId?> submit(ContactUpdate update) async {
    final id = await run(
      (key) => ref
          .read(identityRepositoryProvider)
          .updateContact(update, idempotencyKey: key),
    );
    if (id != null) ref.read(citizenIdProvider.notifier).set(id);
    return id;
  }
}

final biometricProtectionControllerProvider = NotifierProvider.autoDispose<
  BiometricProtectionController,
  ActionState<CitizenId>
>(BiometricProtectionController.new);

class BiometricProtectionController extends ActionController<CitizenId> {
  Future<CitizenId?> submit(bool enabled) async {
    final id = await run(
      (_) => ref.read(identityRepositoryProvider).setBiometricProtection(enabled),
    );
    if (id != null) ref.read(citizenIdProvider.notifier).set(id);
    return id;
  }
}

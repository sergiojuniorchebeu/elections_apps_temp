/// "Continue with Apple / Google".
///
/// Two steps, two owners:
/// 1. the device obtains a proof of identity from the provider (native
///    SDK: `sign_in_with_apple`, `google_sign_in`...) -> [SocialSignIn];
/// 2. the back-end checks that proof and opens a session ->
///    `AuthRepository.signInWithProvider`.
///
/// Default: no provider (buttons hidden). Demo mode: a simulated consent
/// sheet. Plug the SDKs by implementing [SocialSignIn].
library;

enum SocialProvider { apple, google }

/// What the provider returned on the device.
final class SocialCredential {
  const SocialCredential({
    required this.provider,
    required this.idToken,
    this.email,
    this.firstName,
    this.lastName,
  });

  final SocialProvider provider;

  /// Signed token the back-end verifies with the provider's public keys.
  final String idToken;

  /// Given by the provider the first time only (Apple), may be null.
  final String? email;
  final String? firstName;
  final String? lastName;
}

abstract interface class SocialSignIn {
  /// Providers offered on this device (buttons shown in this order).
  List<SocialProvider> get providers;

  /// Asks the provider. Null when the user cancelled.
  Future<SocialCredential?> obtain(SocialProvider provider);
}

final class NoSocialSignIn implements SocialSignIn {
  const NoSocialSignIn();
  @override
  List<SocialProvider> get providers => const [];
  @override
  Future<SocialCredential?> obtain(SocialProvider provider) async => null;
}

/// Demo mode: [decide] shows a consent sheet and returns the credential
/// the "provider" would give, or null when cancelled.
final class SimulatedSocialSignIn implements SocialSignIn {
  const SimulatedSocialSignIn({required this.decide});

  final Future<SocialCredential?> Function(SocialProvider provider) decide;

  @override
  List<SocialProvider> get providers => SocialProvider.values;

  @override
  Future<SocialCredential?> obtain(SocialProvider provider) => decide(provider);
}

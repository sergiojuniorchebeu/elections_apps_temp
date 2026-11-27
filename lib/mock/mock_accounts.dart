/// Demo accounts (README "Demo mode").
///
/// Magic values:
/// * any e-mail + [universalPassword] -> signed in (unknown e-mails get a
///   verified account on the fly);
/// * a demo account also accepts [demoPassword];
/// * any other password -> wrong credentials;
/// * [lockedEmail] -> "Too many attempts" (rate limit);
/// * sign-up with [takenEmail] -> "already used" on the email field.
abstract final class MockAccounts {
  static const demoEmail = 'alex.morgan@example.org';
  static const secondEmail = 'sam.lee@example.org';
  static const demoPassword = 'demo1234';
  static const universalPassword = 'password';
  static const lockedEmail = 'locked@example.org';
  static const takenEmail = 'taken@example.org';
}

/// A simulated user account.
final class MockAccount {
  MockAccount({
    required this.id,
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.citizenNumber,
    this.phone,
    this.address,
    this.verified = true,
  });

  final String id;
  String email;
  String password;
  String firstName;
  String lastName;
  DateTime dateOfBirth;

  /// 12 digits; the app only ever shows the last 4.
  final String citizenNumber;
  String? phone;
  String? address;
  bool verified;
  bool biometricProtection = true;
}

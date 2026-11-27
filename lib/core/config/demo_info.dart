import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the sign-in screen shows in demo mode. Provided by the simulator
/// in `backend.dart`; null with a real back-end.
final class DemoInfo {
  const DemoInfo({required this.accounts, required this.password, required this.hints});

  final List<String> accounts;
  final String password;

  /// Documented magic values ("wrong password -> refused"...).
  final List<String> hints;
}

final demoInfoProvider = Provider<DemoInfo?>((_) => null);

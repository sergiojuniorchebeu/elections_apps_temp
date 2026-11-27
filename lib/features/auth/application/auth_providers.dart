import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_repository.dart';

/// Implemented in `backend.dart` (overrides).
final authRepositoryProvider = Provider<AuthRepository>(
  (_) => throw UnimplementedError('Provided by backend.dart'),
);

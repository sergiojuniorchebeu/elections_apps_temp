import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_config.dart';
import 'device/device_identity.dart';
import 'network/reachability.dart';
import 'session/session_holder.dart';
import 'storage/offline_store.dart';
import 'storage/preferences.dart';
import 'storage/secure_store.dart';
import 'storage/session_store.dart';

/// Technical singletons. `bootstrap.dart` overrides the ones that need
/// async setup; tests override them with in-memory versions.
final appConfigProvider = Provider<AppConfig>((_) => const AppConfig());

final preferencesProvider = Provider<Preferences>(
  (_) => throw UnimplementedError('Overridden in bootstrap / pumpApp'),
);

final secureStoreProvider = Provider<SecureStore>((_) => KeychainStore());

final sessionHolderProvider = Provider<SessionHolder>((ref) {
  final holder = SessionHolder(SessionStore(ref.watch(secureStoreProvider)));
  ref.onDispose(holder.dispose);
  return holder;
});

final offlineStoreProvider = Provider<OfflineStore>(
  (ref) => OfflineStore(ref.watch(secureStoreProvider)),
);

final deviceIdentityProvider = Provider<DeviceIdentity>(
  (ref) => DeviceIdentity(ref.watch(preferencesProvider)),
);

/// Current time. Tests and screenshots pin it.
final clockProvider = Provider<DateTime Function()>((_) => DateTime.now);

/// Provided by `backend.dart`.
final reachabilityProvider = Provider<Reachability>(
  (_) => throw UnimplementedError('Provided by backend.dart'),
);

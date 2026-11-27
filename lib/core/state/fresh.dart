import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import 'session_scope.dart';

/// Remembers, for each provider, in which session scope its last data
/// arrived. Lets [WatchFresh.watchFresh] hide data of a previous account.
final class FreshnessObserver extends ProviderObserver {
  final Map<ProviderBase<Object?>, int> _scopeOfData = {};

  int? scopeOf(ProviderBase<Object?> provider) => _scopeOfData[provider];

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    if (newValue is AsyncData) {
      _scopeOfData[context.provider] = context.container.read(
        sessionScopeProvider,
      );
    }
  }

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    if (value is AsyncData) {
      _scopeOfData[context.provider] = context.container.read(
        sessionScopeProvider,
      );
    }
  }

  @override
  void didDisposeProvider(ProviderObserverContext context) =>
      _scopeOfData.remove(context.provider);
}

/// The single observer instance (one per container is enough).
final freshnessObserverProvider = Provider<FreshnessObserver>(
  (_) => throw UnimplementedError('Overridden in bootstrap / pumpApp'),
);

extension WatchFresh on WidgetRef {
  /// Like `watch`, but while a provider reloads after an account change,
  /// returns a plain loading state: the screen shows its skeleton, never
  /// the previous account's data, even for one frame.
  AsyncValue<T> watchFresh<T>(ProviderListenable<AsyncValue<T>> provider) {
    final value = watch(provider);
    final Object base = provider;
    if (base is! ProviderBase<Object?>) return value;
    final scope = watch(sessionScopeProvider);
    final dataScope = read(freshnessObserverProvider).scopeOf(base);
    if (value.hasValue && dataScope != null && dataScope != scope) {
      return AsyncLoading<T>();
    }
    return value;
  }
}

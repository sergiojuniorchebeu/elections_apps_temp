import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/connectivity.dart';
import '../../../core/state/session_scope.dart';
import '../domain/search_result.dart';

final searchRepositoryProvider = Provider<SearchRepository>(
  (_) => throw UnimplementedError('Provided by backend.dart'),
);

final searchQueryProvider = NotifierProvider.autoDispose<SearchQuery, String>(
  SearchQuery.new,
);

class SearchQuery extends Notifier<String> {
  @override
  String build() => '';
  void set(String q) => state = q;
}

/// Results for the current query, after a short pause in typing.
final searchResultsProvider = FutureProvider.autoDispose<List<SearchResult>>((
  ref,
) async {
  ref.watch(sessionScopeProvider);
  final q = ref.watch(searchQueryProvider).trim();
  if (q.isEmpty) return const [];
  var cancelled = false;
  ref.onDispose(() => cancelled = true);
  await Future<void>.delayed(const Duration(milliseconds: 300));
  if (cancelled) return const [];
  return guard(ref, () => ref.read(searchRepositoryProvider).search(q));
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/failure.dart';
import '../pagination/page.dart';
import 'app_resume.dart';
import 'connectivity.dart';
import 'session_scope.dart';

/// State of a cursor-paginated list.
final class PagedState<T> {
  const PagedState({
    this.items = const [],
    this.cursor,
    this.hasMore = true,
    this.loadingFirst = true,
    this.loadingMore = false,
    this.refreshing = false,
    this.error,
    this.moreError,
  });

  final List<T> items;
  final String? cursor;
  final bool hasMore;

  /// First page in flight, nothing to show yet: skeleton.
  final bool loadingFirst;
  final bool loadingMore;
  final bool refreshing;

  /// The first page failed (full-screen error) or a refresh failed (the
  /// list stays, a snack bar tells it).
  final Failure? error;

  /// Loading the next page failed: a "Retry" row at the bottom.
  final Failure? moreError;

  bool get isEmpty => !loadingFirst && error == null && items.isEmpty;
  bool get isBlockingError => items.isEmpty && error != null && !loadingFirst;

  PagedState<T> copyWith({
    List<T>? items,
    String? cursor,
    bool clearCursor = false,
    bool? hasMore,
    bool? loadingFirst,
    bool? loadingMore,
    bool? refreshing,
    Failure? error,
    bool clearError = false,
    Failure? moreError,
    bool clearMoreError = false,
  }) => PagedState(
    items: items ?? this.items,
    cursor: clearCursor ? null : cursor ?? this.cursor,
    hasMore: hasMore ?? this.hasMore,
    loadingFirst: loadingFirst ?? this.loadingFirst,
    loadingMore: loadingMore ?? this.loadingMore,
    refreshing: refreshing ?? this.refreshing,
    error: clearError ? null : error ?? this.error,
    moreError: clearMoreError ? null : moreError ?? this.moreError,
  );
}

/// Base for every list: first page, next pages, pull-to-refresh that keeps
/// the list when it fails, a generation number so a late answer never
/// overwrites a newer one, and optimistic updates.
///
/// ```dart
/// class NotificationsNotifier extends PaginatedNotifier<AppNotification> {
///   @override
///   Future<Page<AppNotification>> fetchPage(String? cursor) =>
///       ref.read(notificationsRepositoryProvider).list(cursor: cursor);
/// }
/// ```
abstract class PaginatedNotifier<T> extends Notifier<PagedState<T>> {
  int _generation = 0;

  Future<Page<T>> fetchPage(String? cursor);

  /// Key identifying an item for [replaceWhere] / [removeWhere].
  bool sameItem(T a, T b) => a == b;

  @override
  PagedState<T> build() {
    ref.watch(sessionScopeProvider);
    ref.listen(appResumeProvider, (_, _) => refresh());
    ref.listen(connectivityProvider, (prev, next) {
      if (prev != null && !prev.online && next.online && state.error != null) {
        refresh();
      }
    });
    _generation++;
    Future.microtask(_loadFirst);
    return PagedState<T>();
  }

  Future<void> _loadFirst() async {
    final gen = _generation;
    try {
      final page = await guard(ref, () => fetchPage(null));
      if (!ref.mounted || gen != _generation) return;
      state = PagedState(
        items: page.items,
        cursor: page.nextCursor,
        hasMore: page.hasMore,
        loadingFirst: false,
      );
    } on Failure catch (f) {
      if (!ref.mounted || gen != _generation) return;
      state = state.copyWith(loadingFirst: false, error: f);
    }
  }

  /// Pull-to-refresh / Retry. On failure the current items stay and the
  /// failure is returned so the screen can show a snack bar.
  Future<Failure?> refresh() async {
    final gen = ++_generation;
    final hadItems = state.items.isNotEmpty;
    state = hadItems
        ? state.copyWith(refreshing: true, clearError: true)
        : state.copyWith(loadingFirst: true, clearError: true);
    try {
      final page = await guard(ref, () => fetchPage(null));
      if (!ref.mounted || gen != _generation) return null;
      state = PagedState(
        items: page.items,
        cursor: page.nextCursor,
        hasMore: page.hasMore,
        loadingFirst: false,
      );
      return null;
    } on Failure catch (f) {
      if (!ref.mounted || gen != _generation) return f;
      state = state.copyWith(
        refreshing: false,
        loadingFirst: false,
        error: hadItems ? null : f,
      );
      return f;
    }
  }

  /// Called when the end of the list becomes visible.
  Future<void> loadMore() async {
    final s = state;
    if (!s.hasMore || s.loadingMore || s.loadingFirst || s.cursor == null) {
      return;
    }
    final gen = _generation;
    state = s.copyWith(loadingMore: true, clearMoreError: true);
    try {
      final page = await guard(ref, () => fetchPage(s.cursor));
      if (!ref.mounted || gen != _generation) return;
      state = state.copyWith(
        items: [...state.items, ...page.items],
        cursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
        hasMore: page.hasMore,
        loadingMore: false,
      );
    } on Failure catch (f) {
      if (!ref.mounted || gen != _generation) return;
      state = state.copyWith(loadingMore: false, moreError: f);
    }
  }

  /// Optimistic update: applies [update] now, restores the previous list
  /// if [commit] fails, then rethrows.
  Future<R> optimistic<R>(
    List<T> Function(List<T> items) update,
    Future<R> Function() commit,
  ) async {
    final before = state.items;
    state = state.copyWith(items: update(before));
    try {
      return await guard(ref, commit);
    } on Failure {
      if (ref.mounted) state = state.copyWith(items: before);
      rethrow;
    }
  }

  void replaceWhere(T item) => state = state.copyWith(
    items: [for (final i in state.items) sameItem(i, item) ? item : i],
  );
}

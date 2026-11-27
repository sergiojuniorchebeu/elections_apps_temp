import 'dart:async';

import 'package:dio/dio.dart';

/// Product analytics, back-end agnostic. Events never carry personal data:
/// screens are named by route pattern (`/petitions/:id`), never by id.
abstract interface class Analytics {
  void track(String event, [Map<String, Object> properties = const {}]);
  Future<void> flush();
}

/// Default: nothing leaves the device.
final class NoopAnalytics implements Analytics {
  const NoopAnalytics();
  @override
  void track(String event, [Map<String, Object> properties = const {}]) {}
  @override
  Future<void> flush() async {}
}

/// Example: batches events and posts them to `POST {endpoint}` as
/// `{"events":[{"name","at","props"}]}`. Plug it in `bootstrap.dart`.
final class BatchingApiAnalytics implements Analytics {
  BatchingApiAnalytics({
    required this.endpoint,
    Dio? dio,
    this.batchSize = 20,
    this.isEnabled = _always,
  }) : _dio = dio ?? Dio();

  static bool _always() => true;

  final Uri endpoint;
  final Dio _dio;
  final int batchSize;

  /// The user can turn analytics off in Profile.
  final bool Function() isEnabled;
  final List<Map<String, Object>> _queue = [];

  @override
  void track(String event, [Map<String, Object> properties = const {}]) {
    if (!isEnabled()) return;
    _queue.add({
      'name': event,
      'at': DateTime.now().toUtc().toIso8601String(),
      'props': properties,
    });
    if (_queue.length >= batchSize) unawaited(flush());
  }

  @override
  Future<void> flush() async {
    if (_queue.isEmpty) return;
    final batch = List.of(_queue);
    _queue.clear();
    try {
      await _dio.postUri<void>(endpoint, data: {'events': batch});
    } on Object {
      // Analytics never bother the user; the batch is dropped.
    }
  }
}

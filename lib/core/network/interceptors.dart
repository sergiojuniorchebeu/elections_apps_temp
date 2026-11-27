import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../error/failure.dart';
import '../session/session_holder.dart';
import '../storage/offline_store.dart';
import 'failure_mapper.dart';

/// `RequestOptions.extra` keys understood by the interceptors.
abstract final class ApiExtra {
  /// false = anonymous call (sign-in, refresh...).
  static const auth = 'auth';
  static const replayed = 'replayed';
  static const attempt = 'attempt';

  /// Save the answer as the offline copy under this key.
  static const offlineKey = 'offline_key';
}

/// Header carrying the idempotency key of sensitive writes.
const idempotencyHeader = 'Idempotency-Key';

/// 1. Session: adds the bearer token; on 401, renews once (single-flight
/// in [SessionHolder]) and replays. A network error during renewal never
/// signs out: the request fails with a [NetworkFailure].
final class SessionInterceptor extends Interceptor {
  SessionInterceptor(this._holder, this._dio);

  final SessionHolder _holder;
  final Dio _dio;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _holder.current?.accessToken;
    if (options.extra[ApiExtra.auth] != false && token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        options.extra[ApiExtra.auth] == false ||
        options.extra[ApiExtra.replayed] == true) {
      return handler.next(err);
    }
    try {
      final session = await _holder.renew();
      options
        ..headers['Authorization'] = 'Bearer ${session.accessToken}'
        ..extra[ApiExtra.replayed] = true;
      handler.resolve(await _dio.fetch<Object?>(options));
    } on Failure catch (f) {
      handler.next(err.copyWith(error: f));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}

/// 2. Retries: at most [maxRetries], only on connection errors, timeouts
/// and 5xx, with growing jittered delays, honouring `Retry-After`. Never
/// retries a write that has no idempotency key.
final class RetryInterceptor extends Interceptor {
  RetryInterceptor(this._dio, {this.maxRetries = 2, Random? random})
    : _random = random ?? Random();

  final Dio _dio;
  final int maxRetries;
  final Random _random;

  static bool _safe(RequestOptions o) =>
      o.method == 'GET' ||
      o.method == 'HEAD' ||
      o.headers.containsKey(idempotencyHeader);

  static bool _transient(DioException e) =>
      switch (e.type) {
        DioExceptionType.connectionError ||
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout => true,
        DioExceptionType.badResponse => (e.response?.statusCode ?? 0) >= 500,
        _ => false,
      };

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final o = err.requestOptions;
    final attempt = (o.extra[ApiExtra.attempt] as int?) ?? 0;
    if (attempt >= maxRetries || !_safe(o) || !_transient(err)) {
      return handler.next(err);
    }
    final retryAfter = err.response == null
        ? null
        : FailureMapper.retryAfter(err.response!.headers);
    final base = Duration(milliseconds: 400 * pow(2, attempt).toInt());
    final jitter = Duration(milliseconds: _random.nextInt(250));
    final wait = retryAfter ?? base + jitter;
    if (wait > const Duration(seconds: 10)) return handler.next(err);
    await Future<void>.delayed(wait);
    o.extra[ApiExtra.attempt] = attempt + 1;
    try {
      handler.resolve(await _dio.fetch<Object?>(o));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}

/// 3. Offline copies: saves the last answer of requests tagged with
/// [ApiExtra.offlineKey] (main screens).
final class OfflineCopyInterceptor extends Interceptor {
  OfflineCopyInterceptor(this._store);
  final OfflineStore _store;

  @override
  void onResponse(Response<Object?> response, ResponseInterceptorHandler handler) {
    final key = response.requestOptions.extra[ApiExtra.offlineKey] as String?;
    if (key != null) unawaited(_store.write(key, response.data));
    handler.next(response);
  }
}

/// 4. Log, debug builds only: method, path, status, duration. Never
/// headers, bodies or query parameters.
final class DebugLogInterceptor extends Interceptor {
  static const _start = 'log_start';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_start] = DateTime.now();
    handler.next(options);
  }

  @override
  void onResponse(Response<Object?> response, ResponseInterceptorHandler handler) {
    _log(response.requestOptions, response.statusCode);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log(err.requestOptions, err.response?.statusCode ?? err.type.name);
    handler.next(err);
  }

  void _log(RequestOptions o, Object? status) {
    if (!kDebugMode) return;
    final start = o.extra[_start] as DateTime?;
    final ms = start == null
        ? '?'
        : DateTime.now().difference(start).inMilliseconds.toString();
    debugPrint('[api] ${o.method} ${o.uri.path} -> $status (${ms}ms)');
  }
}

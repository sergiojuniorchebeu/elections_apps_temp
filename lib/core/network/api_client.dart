import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'dart:io';

import '../error/failure.dart';
import '../session/session_holder.dart';
import '../storage/offline_store.dart';
import 'failure_mapper.dart';
import 'interceptors.dart';

typedef Decode<T> = T Function(Object? json);

/// Thin wrapper over Dio for the reference REST implementation. Every
/// call returns a domain object or throws a [Failure].
final class ApiClient {
  ApiClient(this.dio);

  /// Production setup: timeouts, idle connections closed after 5 s (avoids
  /// dead sockets on iOS after a network switch), interceptors in order.
  factory ApiClient.create({
    required String baseUrl,
    required SessionHolder session,
    required OfflineStore offline,
    HttpClientAdapter? adapter,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Accept': 'application/json'},
      ),
    );
    dio.httpClientAdapter =
        adapter ??
        IOHttpClientAdapter(
          createHttpClient: () =>
              HttpClient()..idleTimeout = const Duration(seconds: 5),
        );
    dio.interceptors.addAll([
      SessionInterceptor(session, dio),
      RetryInterceptor(dio),
      OfflineCopyInterceptor(offline),
      DebugLogInterceptor(),
    ]);
    return ApiClient(dio);
  }

  final Dio dio;

  Future<T> get<T>(
    String path, {
    required Decode<T> decode,
    Map<String, Object?>? query,
    bool auth = true,
    String? offlineKey,
  }) => _send(
    () => dio.get<Object?>(
      path,
      queryParameters: query == null ? null : _clean(query),
      options: _options(auth: auth, offlineKey: offlineKey),
    ),
    decode,
  );

  Future<T> post<T>(
    String path, {
    required Decode<T> decode,
    Object? body,
    bool auth = true,
    String? idempotencyKey,
  }) => _send(
    () => dio.post<Object?>(
      path,
      data: body,
      options: _options(auth: auth, idempotencyKey: idempotencyKey),
    ),
    decode,
  );

  Future<T> patch<T>(
    String path, {
    required Decode<T> decode,
    Object? body,
    String? idempotencyKey,
  }) => _send(
    () => dio.patch<Object?>(
      path,
      data: body,
      options: _options(idempotencyKey: idempotencyKey),
    ),
    decode,
  );

  Future<T> delete<T>(String path, {required Decode<T> decode}) =>
      _send(() => dio.delete<Object?>(path, options: _options()), decode);

  Options _options({
    bool auth = true,
    String? idempotencyKey,
    String? offlineKey,
  }) => Options(
    extra: {ApiExtra.auth: auth, ApiExtra.offlineKey: ?offlineKey},
    headers: {idempotencyHeader: ?idempotencyKey},
  );

  static Map<String, Object?> _clean(Map<String, Object?> q) => {
    for (final e in q.entries)
      if (e.value != null) e.key: e.value,
  };

  Future<T> _send<T>(
    Future<Response<Object?>> Function() call,
    Decode<T> decode,
  ) async {
    final Response<Object?> response;
    try {
      response = await call();
    } on DioException catch (e) {
      throw FailureMapper.fromDio(e);
    }
    try {
      return decode(response.data);
    } on Failure {
      rethrow;
    } on Object catch (e) {
      // The server answered something the contract does not describe.
      throw UnknownFailure(
        cause: e,
        requestId: response.headers.value('x-request-id'),
      );
    }
  }
}

/// JSON helpers for DTO decoding: fail loudly on a broken contract.
extension JsonRead on Map<String, Object?> {
  String str(String key) => this[key]! as String;
  String? strOrNull(String key) => this[key] as String?;
  int integer(String key) => (this[key]! as num).toInt();
  bool boolean(String key) => this[key] as bool? ?? false;
  DateTime date(String key) => DateTime.parse(str(key)).toLocal();
  DateTime? dateOrNull(String key) =>
      this[key] == null ? null : DateTime.parse(str(key)).toLocal();
  List<Map<String, Object?>> list(String key) => [
    for (final e in (this[key] as List? ?? const []))
      (e as Map).cast<String, Object?>(),
  ];
}

Map<String, Object?> asMap(Object? json) =>
    (json! as Map).cast<String, Object?>();

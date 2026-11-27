import 'package:dio/dio.dart';

import '../error/failure.dart';

/// Translates the REST contract's errors into [Failure]s
/// (docs/api_contract.yaml, `Error` schema):
///
/// ```json
/// {"error": {"code": "validation_failed", "message": "...",
///            "fields": {"email": "This email is already used."}}}
/// ```
abstract final class FailureMapper {
  static Failure fromDio(DioException e) {
    if (e.error is Failure) return e.error! as Failure;
    final requestId = e.response?.headers.value('x-request-id');
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return TimeoutFailure(requestId: requestId);
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.cancel:
        return const CancelledFailure();
      case DioExceptionType.badCertificate:
        return ServerFailure(requestId: requestId);
      case DioExceptionType.unknown:
        return e.response == null
            ? const NetworkFailure()
            : UnknownFailure(cause: e.error, requestId: requestId);
      case DioExceptionType.badResponse:
        return fromResponse(e.response!);
    }
  }

  static Failure fromResponse(Response<Object?> response) {
    final status = response.statusCode ?? 0;
    final requestId = response.headers.value('x-request-id');
    final body = response.data;
    final error = body is Map ? body['error'] : null;
    final code = error is Map ? error['code'] as String? : null;
    final message = error is Map ? error['message'] as String? : null;
    final fields = <String, String>{
      if (error is Map && error['fields'] is Map)
        for (final e in (error['fields'] as Map).entries)
          '${e.key}': '${e.value}',
    };
    switch (status) {
      case 400 || 422:
        return ValidationFailure(
          fieldErrors: fields,
          message: message,
          requestId: requestId,
        );
      case 401:
        return AuthFailure(
          sessionEnded: code == 'session_ended',
          reason: code == 'invalid_credentials'
              ? AuthFailureReason.invalidCredentials
              : code == 'account_locked'
              ? AuthFailureReason.accountLocked
              : AuthFailureReason.unknown,
          requestId: requestId,
        );
      case 403:
        return AuthFailure(requestId: requestId);
      case 404:
        return NotFoundFailure(requestId: requestId);
      case 409:
        return ConflictFailure(message: message, requestId: requestId);
      case 429:
        return RateLimitFailure(
          retryAfter: retryAfter(response.headers),
          requestId: requestId,
        );
      case >= 500:
        return ServerFailure(statusCode: status, requestId: requestId);
      default:
        return UnknownFailure(requestId: requestId);
    }
  }

  /// `Retry-After` in seconds (HTTP dates are rare from APIs: ignored).
  static Duration? retryAfter(Headers headers) {
    final raw = headers.value('retry-after');
    final s = raw == null ? null : int.tryParse(raw.trim());
    return s == null ? null : Duration(seconds: s);
  }
}

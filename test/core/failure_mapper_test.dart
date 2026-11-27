import 'package:dio/dio.dart';
import 'package:elections_app/core/error/failure.dart';
import 'package:elections_app/core/network/failure_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

Response<Object?> _res(int status, [Object? body, Map<String, List<String>> headers = const {}]) =>
    Response(
      requestOptions: RequestOptions(),
      statusCode: status,
      data: body,
      headers: Headers.fromMap({'x-request-id': ['req_1'], ...headers}),
    );

void main() {
  test('422 -> ValidationFailure with field errors', () {
    final f = FailureMapper.fromResponse(_res(422, {
      'error': {'code': 'validation_failed', 'fields': {'email': 'Taken'}},
    }));
    expect(f, isA<ValidationFailure>());
    expect((f as ValidationFailure).errorFor('email'), 'Taken');
    expect(f.requestId, 'req_1');
  });

  test('401 codes', () {
    expect(
      (FailureMapper.fromResponse(_res(401, {'error': {'code': 'session_ended'}})) as AuthFailure).sessionEnded,
      isTrue,
    );
    expect(
      (FailureMapper.fromResponse(_res(401, {'error': {'code': 'invalid_credentials'}})) as AuthFailure).reason,
      AuthFailureReason.invalidCredentials,
    );
  });

  test('429 honours Retry-After', () {
    final f = FailureMapper.fromResponse(_res(429, null, {'retry-after': ['12']}));
    expect((f as RateLimitFailure).retryAfter, const Duration(seconds: 12));
  });

  test('statuses', () {
    expect(FailureMapper.fromResponse(_res(404)), isA<NotFoundFailure>());
    expect(FailureMapper.fromResponse(_res(409)), isA<ConflictFailure>());
    expect(FailureMapper.fromResponse(_res(503)), isA<ServerFailure>());
    expect(FailureMapper.fromResponse(_res(418)), isA<UnknownFailure>());
  });

  test('transport errors', () {
    DioException e(DioExceptionType t) => DioException(requestOptions: RequestOptions(), type: t);
    expect(FailureMapper.fromDio(e(DioExceptionType.connectionError)), isA<NetworkFailure>());
    expect(FailureMapper.fromDio(e(DioExceptionType.receiveTimeout)), isA<TimeoutFailure>());
    expect(FailureMapper.fromDio(e(DioExceptionType.cancel)), isA<CancelledFailure>());
  });

  test('every failure has a readable title and message', () {
    const all = <Failure>[
      NetworkFailure(), TimeoutFailure(), AuthFailure(), AuthFailure(sessionEnded: true),
      ValidationFailure(), RateLimitFailure(), NotFoundFailure(), ConflictFailure(),
      ServerFailure(), CancelledFailure(), UnknownFailure(),
    ];
    for (final f in all) {
      expect(f.title, isNotEmpty);
      expect(f.message, isNotEmpty);
      expect(f.message, isNot(contains('Exception')));
    }
  });
}

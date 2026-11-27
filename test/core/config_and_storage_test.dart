import 'package:dio/dio.dart';
import 'package:elections_app/app/router/routes.dart';
import 'package:elections_app/core/config/app_config.dart';
import 'package:elections_app/core/network/interceptors.dart';
import 'package:elections_app/core/storage/offline_store.dart';
import 'package:elections_app/core/storage/secure_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HTTPS is mandatory except on localhost', () {
    expect(AppConfig.isAllowedUrl(Uri.parse('https://api.example.org')), isTrue);
    expect(AppConfig.isAllowedUrl(Uri.parse('http://localhost:8080')), isTrue);
    expect(AppConfig.isAllowedUrl(Uri.parse('http://api.example.org')), isFalse);
    expect(
      () => const AppConfig(backend: BackendKind.rest, apiBaseUrl: 'http://evil.org').validate(),
      throwsStateError,
    );
  });

  test('offline copies expire after their max age', () async {
    final store = OfflineStore(MemorySecureStore(), maxAge: const Duration(days: 7));
    var now = DateTime(2026, 1, 1);
    store.clock = () => now;
    await store.write('k', {'a': 1});
    expect((await store.read('k'))!.data, {'a': 1});
    now = now.add(const Duration(days: 8));
    expect(await store.read('k'), isNull);
  });

  test('sign-out wipes every offline copy', () async {
    final secure = MemorySecureStore()..values['session.v1'] = 'x';
    final store = OfflineStore(secure);
    await store.write('a', 1);
    await store.write('b', 2);
    await store.clear();
    expect(secure.values.keys, ['session.v1']);
  });

  test('ids from links are checked', () {
    expect(Routes.isValidId('pt_green'), isTrue);
    expect(Routes.isValidId('../etc'), isFalse);
    expect(Routes.isValidId(''), isFalse);
    expect(Routes.isValidId('a' * 65), isFalse);
  });

  test('a write without idempotency key is never retried', () async {
    var calls = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://x.test'));
    dio.httpClientAdapter = _CountingAdapter(() => calls++);
    dio.interceptors.add(RetryInterceptor(dio));
    await expectLater(dio.post<Object?>('/a'), throwsA(isA<DioException>()));
    expect(calls, 1);
    calls = 0;
    await expectLater(dio.get<Object?>('/a'), throwsA(isA<DioException>()));
    expect(calls, 3);
  });
}

class _CountingAdapter implements HttpClientAdapter {
  _CountingAdapter(this.onFetch);
  final void Function() onFetch;
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<dynamic>? s, Future<void>? c) async {
    onFetch();
    return ResponseBody.fromString('{}', 503);
  }
}

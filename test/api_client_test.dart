import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ferreteriabimetalica/core/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'API requests preserve the configured base path and use bearer auth',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/'));
      final client = ApiClient.forTesting(
        dio: dio,
        readToken: () async => 'test-token',
        removeToken: () async {},
      );
      RequestOptions? sent;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            sent = options;
            handler.resolve(Response(requestOptions: options, data: const []));
          },
        ),
      );

      await client.dio.get('/productos');

      final prefix = Uri.parse(apiBaseUrl).path.replaceAll(RegExp(r'/+$'), '');
      expect(sent?.path, '$prefix/productos');
      expect(sent?.headers['Authorization'], 'Bearer test-token');
    },
  );

  test('login requests do not forward a previously saved token', () async {
    var tokenReads = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/'));
    final client = ApiClient.forTesting(
      dio: dio,
      readToken: () async {
        tokenReads++;
        return 'stale-token';
      },
      removeToken: () async {},
    );
    RequestOptions? sent;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          sent = options;
          handler.resolve(Response(requestOptions: options, data: const {}));
        },
      ),
    );

    await client.dio.post('/auth/login');

    expect(tokenReads, 0);
    expect(sent?.headers.containsKey('Authorization'), isFalse);
  });

  test(
    'an authenticated 401 clears the token and notifies the app once',
    () async {
      var cleared = false;
      var notified = 0;
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/'));
      final client = ApiClient.forTesting(
        dio: dio,
        readToken: () async => 'expired-token',
        removeToken: () async {
          cleared = true;
        },
      )..onUnauthorized = () => notified++;
      dio.httpClientAdapter = _StatusAdapter(401);

      await expectLater(
        client.dio.get('/pedidos'),
        throwsA(isA<DioException>()),
      );

      expect(cleared, isTrue);
      expect(notified, 1);
    },
  );
}

class _StatusAdapter implements HttpClientAdapter {
  _StatusAdapter(this.statusCode);

  final int statusCode;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    '{"detail":"expired"}',
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

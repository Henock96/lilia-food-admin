import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:lilia_admin/core/network/interceptors/app_version_interceptor.dart';

/// Audit du 28/10/2026 — l'app vendeurs annonce qui elle est et sa version.
void main() {
  Future<Map<String, dynamic>> sentHeaders(
    AppVersionInterceptor interceptor,
  ) async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
    late Map<String, dynamic> captured;
    dio.interceptors.add(interceptor);
    dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
      captured = Map.of(o.headers);
      h.next(o);
    }));
    DioAdapter(dio: dio).onGet('/x', (s) => s.reply(200, {}));
    await dio.get('/x');
    return captured;
  }

  test('pose l’application et la version', () async {
    final headers = await sentHeaders(
      AppVersionInterceptor(readVersion: () async => '1.0.6+7'),
    );
    expect(headers['X-Lilia-App'], 'vendor');
    expect(headers['X-Lilia-App-Version'], '1.0.6+7');
  });

  test('lot 3 — annonce la capacité « accepter puis payer »', () async {
    final headers = await sentHeaders(
      AppVersionInterceptor(readVersion: () async => null),
    );
    expect(headers['X-Lilia-Order-Flow'], 'accept-first');
  });

  test('version illisible : la requête part, sans en-tête de version', () async {
    final headers = await sentHeaders(
      AppVersionInterceptor(readVersion: () async => null),
    );
    expect(headers['X-Lilia-App'], 'vendor');
    expect(headers.containsKey('X-Lilia-App-Version'), isFalse);
  });

  test('la version n’est lue qu’une fois', () async {
    var reads = 0;
    final interceptor = AppVersionInterceptor(readVersion: () async {
      reads++;
      return '1.0.6';
    });
    await sentHeaders(interceptor);
    await sentHeaders(interceptor);
    expect(reads, 1);
  });
}

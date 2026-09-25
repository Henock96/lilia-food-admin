import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/core/network/api_exception.dart';
import 'package:lilia_admin/core/network/interceptors/error_interceptor.dart';

ApiException _mapResponse(int status, dynamic body) {
  final interceptor = ErrorInterceptor();
  ApiException? captured;
  final handler = _CaptureRejectHandler((e) => captured = e.error as ApiException);
  final dioError = DioException(
    requestOptions: RequestOptions(path: '/x', method: 'GET'),
    response: Response(
      requestOptions: RequestOptions(path: '/x'),
      statusCode: status,
      data: body,
    ),
    type: DioExceptionType.badResponse,
  );
  interceptor.onError(dioError, handler);
  return captured!;
}

void main() {
  test('message String depuis {message}', () {
    final e = _mapResponse(400, {'message': 'Stock insuffisant'});
    expect(e.message, 'Stock insuffisant');
    expect(e.statusCode, 400);
    expect(e.kind, ApiErrorKind.client);
  });

  test('message List joint par ". "', () {
    final e = _mapResponse(400, {'message': ['Champ A requis', 'Champ B invalide']});
    expect(e.message, 'Champ A requis. Champ B invalide');
  });

  test('5xx => kind server', () {
    final e = _mapResponse(503, {'message': 'Indispo'});
    expect(e.kind, ApiErrorKind.server);
  });

  test('401 => kind unauthorized', () {
    final e = _mapResponse(401, {'message': 'Non autorisé'});
    expect(e.kind, ApiErrorKind.unauthorized);
  });

  group('F3-08 — gestes réservés à l’admin web (double authentification)', () {
    for (final entry in {
      'MFA_REQUIRED': 403,
      'MFA_STEP_UP_REQUIRED': 401,
    }.entries) {
      test('${entry.key} : on renvoie vers l’admin web, code conservé', () {
        final e = _mapResponse(entry.value, {
          'message': 'Confirmez votre identité avec votre code pour ce geste.',
          'error': {'code': entry.key},
        });
        expect(e.message, mfaWebOnlyMessage);
        expect(e.code, entry.key);
      });
    }

    test('un autre refus garde le message du serveur', () {
      final e = _mapResponse(403, {
        'message': 'Capacité manquante',
        'error': {'code': 'CAPABILITY_REQUIRED'},
      });
      expect(e.message, 'Capacité manquante');
    });
  });

  test('timeout => kind timeout + message fallback', () {
    final interceptor = ErrorInterceptor();
    ApiException? captured;
    final handler = _CaptureRejectHandler((e) => captured = e.error as ApiException);
    interceptor.onError(
      DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.receiveTimeout,
      ),
      handler,
    );
    expect(captured!.kind, ApiErrorKind.timeout);
    expect(captured!.message, isNotEmpty);
  });
}

class _CaptureRejectHandler extends ErrorInterceptorHandler {
  final void Function(DioException) onReject;
  _CaptureRejectHandler(this.onReject);
  @override
  void reject(DioException error, [bool callFollowingErrorInterceptor = false]) {
    onReject(error);
  }
}

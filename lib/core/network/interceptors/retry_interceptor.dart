import 'dart:math';
import 'package:dio/dio.dart';

/// Rejoue les requêtes échouées sur 5xx / timeout / erreur réseau, avec
/// backoff exponentiel + jitter. Ne rejoue JAMAIS les 4xx.
///
/// Seules les **lectures** (`GET`, `HEAD`) sont rejouées d'office. Une écriture
/// — `POST`, mais aussi `PUT`, `PATCH`, `DELETE` — ne l'est que si elle porte
/// un header `Idempotency-Key` : le serveur a pu la commiter avant le 5xx ou
/// le timeout, et la rejouer sans clé la ferait deux fois. Le cas qui l'a
/// montré : `PATCH /products/:id/stock` `RESTOCK` ajoute N au stock — rejoué,
/// il en ajoutait 2N (audit du 13/10/2026, ADM-01).
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration baseDelay;
  final Random _rng = Random();

  RetryInterceptor(
    this.dio, {
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 400),
  });

  static const _attemptKey = 'retry_attempt';

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final attempt = (err.requestOptions.extra[_attemptKey] as int?) ?? 0;

    if (!_shouldRetry(err) || attempt >= maxRetries) {
      return handler.next(err);
    }

    final delay = _backoff(attempt);
    await Future<void>.delayed(delay);

    final options = err.requestOptions;
    options.extra[_attemptKey] = attempt + 1;
    try {
      final response = await dio.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  Duration _backoff(int attempt) {
    final base = baseDelay.inMilliseconds * pow(2, attempt).toInt();
    final jitter = (base * 0.2 * (_rng.nextDouble() * 2 - 1)).toInt();
    return Duration(milliseconds: max(0, base + jitter));
  }

  bool _shouldRetry(DioException err) {
    final method = err.requestOptions.method.toUpperCase();
    final isRead = method == 'GET' || method == 'HEAD';
    final hasIdempotencyKey =
        err.requestOptions.headers.containsKey('Idempotency-Key');
    if (!isRead && !hasIdempotencyKey) return false;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final status = err.response?.statusCode ?? 0;
        return status >= 500;
      default:
        return false;
    }
  }
}

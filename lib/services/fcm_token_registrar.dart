import 'package:flutter/foundation.dart';
import 'package:lilia_admin/core/network/api_client.dart';

/// Cycle de vie du token FCM d'une session vendeur / admin.
///
/// Isolé de [NotificationService] parce que ce dernier touche
/// `FirebaseMessaging.instance` dès sa construction et n'est donc pas
/// instanciable en test unitaire. Ici il n'y a que de l'HTTP : le contrat
/// avec le backend est vérifiable directement.
class FcmTokenRegistrar {
  FcmTokenRegistrar(this._api, {Duration Function(int attempt)? backoff})
      : _backoff = backoff ?? _defaultBackoff;

  final ApiClient _api;

  /// Attente entre deux tentatives d'enregistrement. Injectable pour que les
  /// tests n'attendent pas les paliers de production.
  final Duration Function(int attempt) _backoff;

  static Duration _defaultBackoff(int attempt) =>
      Duration(seconds: attempt * 15);

  String? _token;

  /// Token actuellement enregistré côté serveur, `null` si aucun.
  String? get token => _token;

  /// Enregistre [token] auprès du backend, avec [maxRetries] tentatives.
  /// N'échoue jamais bruyamment : une notification perdue ne doit pas casser
  /// le flux de connexion. Le token n'est mémorisé qu'en cas de succès, pour
  /// ne pas tenter plus tard de supprimer un token que le serveur ignore.
  Future<void> register(String token, {int maxRetries = 3}) async {
    for (var attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        await _api.postJson(
          '/notifications/register-token',
          body: {'token': token},
        );
        _token = token;
        debugPrint('[ADMIN NOTIF] Token FCM enregistré sur le serveur');
        return;
      } catch (e) {
        debugPrint(
          '[ADMIN NOTIF] Erreur enregistrement token '
          '(tentative $attempt/$maxRetries): $e',
        );
        if (attempt == maxRetries) {
          debugPrint('[ADMIN NOTIF] Nombre max de tentatives atteint');
          return;
        }
        await Future<void>.delayed(_backoff(attempt));
      }
    }
  }

  /// Supprime le token côté serveur (logout).
  ///
  /// Sans cet appel, un appareil déconnecté reste rattaché au compte et
  /// continue de recevoir les pushs de commandes — montant et nombre
  /// d'articles inclus.
  ///
  /// L'état local est purgé même si l'appel échoue (typiquement un token
  /// Firebase déjà expiré au moment du logout) : garder un token mort
  /// empêcherait le prochain enregistrement.
  Future<void> remove() async {
    final current = _token;
    if (current == null) return;
    try {
      await _api.deleteJson('/notifications/token', body: {'token': current});
      debugPrint('[ADMIN NOTIF] Token FCM supprimé du serveur');
    } catch (e) {
      debugPrint('[ADMIN NOTIF] Erreur suppression token: $e');
    } finally {
      _token = null;
    }
  }
}

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/interceptors/error_interceptor.dart';
import '../../../core/network/network_observer.dart';
import '../controller/auth_controller.dart';
import '../repository/firebase_auth_repository.dart';

part 'session_guard.g.dart';

/// Lot 4 (ADM-24) — ce qu'il advient d'une session que le serveur refuse.
///
/// Avant : un compte banni ou supprimé recevait 403 `ACCOUNT_REVOKED` sur
/// chaque appel, et restait connecté devant des écrans en erreur ; rien ne lui
/// disait pourquoi. Même trou pour un 401 qui survit au rafraîchissement du
/// jeton (`AuthInterceptor` le tente une fois).
///
/// Seuls ces deux cas déconnectent. Un autre 403 (droit manquant, MFA web
/// exigée…) ne touche jamais à la session : un vendeur en plein service ne
/// doit pas être éjecté par erreur.
///
/// Modèle repris de `lilia-app` (`SessionGuard`, éprouvé) :
/// - drapeau posé avant le premier `await` : trois requêtes qui échouent
///   ensemble ne déclenchent qu'une déconnexion ;
/// - `signOut()` appelle lui-même le serveur (DELETE du jeton FCM), qui peut
///   répondre 401 à son tour : le drapeau absorbe ce second passage ;
/// - le drapeau ne couvre que la déconnexion en cours, puis se réarme.

/// Messages affichés sur l'écran de connexion.
const kSessionRevokedNotice =
    'Votre compte a été suspendu. Contactez le support Lilia Food.';
const kSessionExpiredNotice = 'Votre session a expiré. Reconnectez-vous.';

/// Vrai si l'erreur doit mettre fin à la session, avec le message à afficher.
String? sessionEndNoticeFor(Object error) {
  if (error is! ApiException) return null;
  if (error.statusCode == 403 && error.code == 'ACCOUNT_REVOKED') {
    return kSessionRevokedNotice;
  }
  // Un 401 `MFA_STEP_UP_REQUIRED` (geste financier, connexion de plus de
  // 15 min) n'est pas une session morte : l'app affiche « faites-le depuis
  // l'admin web ». Le déconnecter ferait perdre sa session à un ADMIN en
  // service pour un simple refus de geste.
  if (error.kind == ApiErrorKind.unauthorized &&
      !mfaWebOnlyCodes.contains(error.code)) {
    return kSessionExpiredNotice;
  }
  return null;
}

/// Message laissé pour l'écran de connexion après une déconnexion forcée.
@Riverpod(keepAlive: true)
class SessionEndNotice extends _$SessionEndNotice {
  @override
  String? build() => null;

  void announce(String message) => state = message;

  void clear() => state = null;
}

/// Une session Firebase est-elle ouverte ? Surchargeable en test.
@Riverpod(keepAlive: true)
bool Function() hasFirebaseSession(Ref ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return () => auth.currentUser != null;
}

/// Déconnexion complète (jeton FCM, Firebase, données). Surchargeable en test.
@Riverpod(keepAlive: true)
Future<bool> Function() sessionSignOut(Ref ref) =>
    () => ref.read(authControllerProvider.notifier).signOut();

@Riverpod(keepAlive: true)
class SessionGuard extends _$SessionGuard {
  bool _deconnexionEnCours = false;

  @override
  void build() {}

  /// À appeler sur **toute** erreur d'API.
  Future<void> handle(Object error) async {
    if (_deconnexionEnCours) return;
    final notice = sessionEndNoticeFor(error);
    if (notice == null) return;
    // Plus de session (déjà déconnecté, route publique) : rien à fermer, et
    // aucun message à un utilisateur qui n'a rien demandé.
    if (!ref.read(hasFirebaseSessionProvider)()) return;

    _deconnexionEnCours = true;
    try {
      ref.read(sessionEndNoticeProvider.notifier).announce(notice);
      await ref.read(sessionSignOutProvider)();
    } finally {
      _deconnexionEnCours = false;
    }
  }
}

/// Relie toutes les erreurs d'API à la garde de session : `ApiClient` notifie
/// son observateur pour chaque erreur, quel que soit l'écran à l'origine.
class SessionAwareNetworkObserver implements NetworkObserver {
  const SessionAwareNetworkObserver(this._delegate, this._guard);

  final NetworkObserver _delegate;
  final SessionGuard _guard;

  @override
  void onRequest(RequestSnapshot r) => _delegate.onRequest(r);

  @override
  void onError(ApiException e, RequestSnapshot r) {
    _delegate.onError(e, r);
    // Non attendu : l'erreur remonte à l'appelant sans délai ; un échec de
    // déconnexion ne doit pas masquer l'erreur d'origine.
    unawaited(_guard.handle(e).catchError((Object _) {}));
  }
}

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// État de la permission de notifier, réduit à ce que l'écran doit décider.
enum NotificationPermission { granted, denied, notDetermined, unknown }

/// Traduction pure du statut Firebase (testée sans plateforme).
NotificationPermission permissionFromStatus(AuthorizationStatus status) {
  switch (status) {
    case AuthorizationStatus.authorized:
    case AuthorizationStatus.provisional:
      return NotificationPermission.granted;
    case AuthorizationStatus.denied:
    case AuthorizationStatus.deniedPermanently:
      return NotificationPermission.denied;
    case AuthorizationStatus.notDetermined:
      return NotificationPermission.notDetermined;
  }
}

/// Le bandeau s'affiche-t-il ?
///
/// Audit du 28/10/2026 (F-03) : une permission refusée n'était que journalisée
/// (`debugPrint`). Le vendeur ne recevait plus aucune commande sans le savoir.
/// On avertit dès que l'app ne peut PAS afficher une notification ; un état
/// illisible (`unknown`) n'avertit pas — mieux vaut se taire que d'accuser à
/// tort un téléphone qui fonctionne.
bool shouldWarnAboutNotifications(NotificationPermission permission) =>
    permission == NotificationPermission.denied ||
    permission == NotificationPermission.notDetermined;

/// Lecture de la permission courante. Relue au retour au premier plan
/// (l'écran invalide ce provider) : le vendeur a pu la changer dans Réglages.
final notificationPermissionProvider =
    FutureProvider.autoDispose<NotificationPermission>((ref) async {
  try {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    return permissionFromStatus(settings.authorizationStatus);
  } catch (_) {
    return NotificationPermission.unknown;
  }
});

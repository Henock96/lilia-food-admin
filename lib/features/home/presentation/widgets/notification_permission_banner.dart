import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../application/notification_permission.dart';

/// Bandeau rouge « Notifications désactivées » (audit du 28/10/2026, F-03).
///
/// Sans permission, aucune commande ne sonne : le vendeur la découvrait en
/// constatant qu'il ne recevait plus rien. Le bandeau reste affiché tant que
/// la permission manque — il ne se ferme pas, c'est voulu.
class NotificationPermissionBanner extends ConsumerWidget {
  const NotificationPermissionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permission = ref.watch(notificationPermissionProvider).value;
    if (permission == null || !shouldWarnAboutNotifications(permission)) {
      return const SizedBox.shrink();
    }
    return NotificationPermissionWarning(
      onEnable: () => _enable(context, ref),
    );
  }

  Future<void> _enable(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    ref.invalidate(notificationPermissionProvider);
    if (permissionFromStatus(settings.authorizationStatus) ==
        NotificationPermission.granted) {
      return;
    }
    // Refus définitif : le système ne repose plus la question. Sur iPhone,
    // on ouvre les réglages de l'app ; Android n'offre pas de lien standard.
    if (!kIsWeb && Platform.isIOS) {
      await launchUrl(Uri.parse('app-settings:'));
      return;
    }
    messenger.showSnackBar(
      const SnackBar(
        duration: Duration(seconds: 8),
        content: Text(
          'Ouvrez Paramètres › Applications › Lilia Admin › Notifications, '
          'puis autorisez-les.',
        ),
      ),
    );
  }
}

/// Partie visuelle, sans plateforme (testable en widget test).
class NotificationPermissionWarning extends StatelessWidget {
  const NotificationPermissionWarning({super.key, required this.onEnable});

  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          children: [
            Icon(Icons.notifications_off_outlined,
                color: scheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Notifications désactivées : vous ne serez pas prévenu des '
                'nouvelles commandes.',
                style: TextStyle(
                  color: scheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: onEnable,
              child: const Text('Activer'),
            ),
          ],
        ),
      ),
    );
  }
}

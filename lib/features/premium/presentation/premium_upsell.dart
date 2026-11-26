import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../constants/app_constants.dart';

/// Premium S1 (25/11/2026) — l'app vendeurs ne vend pas Premium : la
/// souscription et son paiement Mobile Money (pawaPay) se font sur l'espace
/// web. Ici, on dit seulement **où** aller, là où Premium manque.
///
/// Le prix n'est jamais écrit dans l'app : il est fixé par le serveur et
/// affiché sur la page web.
Uri premiumWebUri() => Uri.parse(AppConstants.premiumWebUrl);

/// Ouvre l'espace Premium dans le navigateur. Sans navigateur (ou refus du
/// système), l'adresse est affichée pour être saisie ailleurs.
///
/// `launcher` : remplaçable en test (le greffon n'y est pas branché).
Future<void> openPremiumWeb(
  BuildContext context, {
  @visibleForTesting Future<bool> Function(Uri uri)? launcher,
}) async {
  final uri = premiumWebUri();
  var opened = false;
  try {
    opened =
        await (launcher ??
            (u) => launchUrl(u, mode: LaunchMode.externalApplication))(uri);
  } catch (_) {
    opened = false;
  }
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ouvrez $uri dans votre navigateur pour souscrire.'),
      ),
    );
  }
}

/// Bouton « Souscrire sur l'espace web ».
class PremiumSubscribeButton extends StatelessWidget {
  const PremiumSubscribeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      key: const Key('premium-subscribe-web'),
      onPressed: () => openPremiumWeb(context),
      icon: const Icon(Icons.open_in_new, size: 18),
      label: const Text('Souscrire sur l’espace web'),
    );
  }
}

/// Carte du tableau de bord à la place des statistiques réservées, pour un
/// vendeur Standard (verdict du serveur, `premiumRequired`).
class PremiumStatsUpsellCard extends StatelessWidget {
  const PremiumStatsUpsellCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      key: Key('premium-stats-upsell'),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.workspace_premium_outlined),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Statistiques avancées',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Produits les plus vendus et heures de pointe sont réservés aux '
              'restaurants Premium, comme la réservation de tables. '
              'Souscrivez depuis votre espace web Lilia : paiement Mobile '
              'Money, activation dès la confirmation de l’opérateur.',
            ),
            SizedBox(height: 4),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: PremiumSubscribeButton(),
            ),
          ],
        ),
      ),
    );
  }
}

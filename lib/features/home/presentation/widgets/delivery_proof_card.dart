import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../models/order.dart';

/// Comment la remise d'une commande est prouvée (F3-07), et ce que cela
/// change pour le paiement du restaurant.
///
/// « Livrée » ne suffit plus à dire si le vendeur peut être payé : une remise
/// que le restaurant déclare seul, ou une course conclue sans code, ne prouvent
/// pas que le client a reçu son repas. Le vendeur doit le lire, sinon il ne
/// comprend pas pourquoi son paiement attend.
class DeliveryProofCard extends StatelessWidget {
  const DeliveryProofCard({super.key, required this.order});

  final Order order;

  static bool isRelevant(Order order) =>
      order.status == OrderStatus.livrer && order.deliveryProof != null;

  @override
  Widget build(BuildContext context) {
    final look = deliveryProofLook(order);
    if (look == null) return const SizedBox.shrink();
    final fmt = DateFormat('dd/MM à HH:mm', 'fr_FR');
    final due = order.payoutDueAt;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: look.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: look.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(look.icon, color: look.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  look.title,
                  key: const Key('delivery-proof-title'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (order.customerConfirmedAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Confirmé par le client le '
                    '${fmt.format(order.customerConfirmedAt!.toLocal())}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  due != null
                      ? 'Paiement du restaurant possible à partir du '
                            '${fmt.format(due.toLocal())}.'
                      : look.whyNoPayout!,
                  key: const Key('delivery-proof-payout'),
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Libellé de chaque preuve. `whyNoPayout` n'est lu que pour les preuves qui
/// n'ouvrent pas le paiement automatique.
({String title, IconData icon, Color color, String? whyNoPayout})?
    deliveryProofLook(Order order) => switch (order.deliveryProof) {
          'PICKUP_CODE' => (
              title: 'Remise prouvée par le code du client',
              icon: Icons.verified,
              color: Colors.teal,
              whyNoPayout: null,
            ),
          'PICKUP_CUSTOMER_CONFIRMED' => (
              title: 'Retrait confirmé par le client',
              icon: Icons.verified,
              color: Colors.teal,
              whyNoPayout: null,
            ),
          'PICKUP_VENDOR_DECLARED' => (
              title: 'Remise déclarée par le restaurant',
              icon: Icons.hourglass_bottom,
              color: Colors.orange,
              whyNoPayout:
                  'En attente de la confirmation du client : le paiement '
                  'partira dès qu’il aura confirmé le retrait.',
            ),
          'PICKUP_ADMIN_OVERRIDE' || 'DELIVERY_ADMIN_OVERRIDE' => (
              title: 'Remise validée par Lilia Food',
              icon: Icons.admin_panel_settings,
              color: Colors.blueGrey,
              whyNoPayout: null,
            ),
          'DELIVERY_CODE' => (
              title: 'Livrée — code du client saisi par le livreur',
              icon: Icons.verified,
              color: Colors.teal,
              whyNoPayout: null,
            ),
          'DELIVERY_UNVERIFIED' => (
              title: 'Livrée sans code du client',
              icon: Icons.info_outline,
              color: Colors.orange,
              whyNoPayout:
                  'Sans code, le paiement n’est pas automatique : Lilia Food '
                  'le valide.',
            ),
          _ => null,
        };

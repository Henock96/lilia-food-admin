import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Lot 4 (4C, F-6) — une commande liée à une réservation n'est pas un simple
/// retrait : c'est la précommande d'une table. Le badge le dit, et ouvre la
/// réservation, qui porte l'annulation, la table et l'absence.
///
/// [linkToReservation] : faux pour l'ADMIN, l'agenda (`/vendors/me/…`) étant
/// celui du restaurateur.
class ReservationOrderBadge extends StatelessWidget {
  const ReservationOrderBadge({
    super.key,
    required this.reservationId,
    this.linkToReservation = true,
  });

  final String reservationId;
  final bool linkToReservation;

  @override
  Widget build(BuildContext context) {
    final color = Colors.indigo.shade700;
    final badge = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.table_restaurant_outlined, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Réservation de table — précommande',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (linkToReservation) ...[
            Text(
              'Voir',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: color),
          ],
        ],
      ),
    );
    if (!linkToReservation) return badge;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.pushNamed(
        'reservation-detail',
        pathParameters: {'id': reservationId},
      ),
      child: badge,
    );
  }
}

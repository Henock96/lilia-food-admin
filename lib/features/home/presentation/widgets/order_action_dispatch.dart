import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/order.dart';
import '../../../../models/order_actions.dart';
import '../../data/order_controller.dart';
import 'order_actions_panel.dart';

/// Exécute une demande née d'[OrderActionsPanel] et en rend compte.
///
/// Partagé par la liste et le détail : un seul endroit sait quel geste part
/// sur quelle route (`/accept`, `/reject`, ou la route de statut).
Future<void> performOrderAction(
  BuildContext context,
  WidgetRef ref,
  Order order,
  OrderActionRequest request,
) async {
  final controller = ref.read(restaurantOrdersProvider(null, '').notifier);
  final messenger = ScaffoldMessenger.of(context);
  try {
    switch (request.action) {
      case OrderAction.accept:
        await controller.acceptOrder(order.id, prepMinutes: request.prepMinutes!);
      case OrderAction.reject:
        await controller.rejectOrder(
          order.id,
          reason: request.reason!,
          note: request.note,
          outOfStockProductIds: request.outOfStockProductIds,
        );
      case OrderAction.handOver when request.pickupCode != null:
        await controller.handOverPickupWithCode(order.id, request.pickupCode!);
      case OrderAction.startPreparation:
      case OrderAction.markReady:
      case OrderAction.handOver:
      case OrderAction.cancel:
        await controller.updateOrderStatus(order.id, request.action.targetStatus!);
    }
    ref.invalidate(restaurantOrdersProvider);
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(_successMessage(request))),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('Erreur : $e')),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

String _successMessage(OrderActionRequest request) => switch (request.action) {
      OrderAction.accept =>
        'Commande acceptée — prête dans ${request.prepMinutes} min',
      OrderAction.reject => 'Commande refusée — le client est remboursé',
      OrderAction.startPreparation => 'Commande en préparation',
      OrderAction.markReady => 'Commande prête',
      OrderAction.handOver when request.pickupCode != null =>
        'Commande remise — le code du client prouve la remise',
      OrderAction.handOver => 'Commande remise au client',
      OrderAction.cancel => 'Commande annulée',
    };

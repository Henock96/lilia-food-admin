import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../routing/app_router.dart';
import '../../application/new_order_alerts.dart';

/// Alerte plein écran « nouvelle commande » (sonnerie vendeur, Phase 3 F3-01).
///
/// Montée au-dessus du routeur (`MaterialApp.router(builder:)`) : elle
/// recouvre n'importe quel écran, parce qu'une commande payée non acceptée
/// est annulée et remboursée au bout de quelques minutes. La sonnerie
/// (notification insistante) s'arrête quand le vendeur ferme l'alerte.
class NewOrderAlertHost extends ConsumerWidget {
  const NewOrderAlertHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(newOrderAlertsProvider);
    if (queue.isEmpty) return child;

    final orderId = queue.first;
    final others = queue.length - 1;
    final alerts = ref.read(newOrderAlertsProvider.notifier);
    final reference = orderId.length > 6
        ? orderId.substring(orderId.length - 6).toUpperCase()
        : orderId.toUpperCase();

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: Material(
            color: Colors.black.withValues(alpha: 0.6),
            child: SafeArea(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.notifications_active, size: 56, color: Colors.green),
                      const SizedBox(height: 12),
                      const Text(
                        'Nouvelle commande à accepter',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text('Commande #$reference', style: TextStyle(color: Colors.grey[700])),
                      if (others > 0) ...[
                        const SizedBox(height: 6),
                        Text(
                          '+ $others autre${others > 1 ? 's' : ''} commande${others > 1 ? 's' : ''} en attente',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () async {
                            await alerts.dismiss(orderId);
                            ref.read(routerProvider).pushNamed(
                              'order-detail',
                              pathParameters: {'id': orderId},
                            );
                          },
                          icon: const Icon(Icons.visibility),
                          label: const Text('Voir la commande'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => alerts.dismiss(orderId),
                        child: const Text('Plus tard'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

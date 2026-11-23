import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lilia_admin/features/home/data/order_controller.dart';
import 'package:lilia_admin/features/home/presentation/screens/order_detail_screen.dart';

/// Fiche commande ouverte **par son identifiant** (alerte « Nouvelle
/// commande », lien direct) : relit la commande, puis affiche la fiche
/// habituelle. L'alerte n'envoyait que l'id et tombait sur « Commande
/// indisponible » (constaté le 22/11/2026).
///
/// Ordre des cas, piège Riverpod 3 :
/// - une valeur, même suivie d'une relecture ratée, garde la fiche à l'écran :
///   la fiche signale elle-même son retard (`staffOrderIsStale`) ; un échec
///   de relecture ne doit pas la démonter avec ses dialogues et sa saisie ;
/// - une erreur **sans** valeur montre l'erreur : entre deux relances
///   automatiques, le fournisseur est « en chargement » avec son erreur, et
///   un `when` afficherait le spinner une quarantaine de secondes ;
/// - le chargement garde une barre avec retour : personne n'est bloqué.
class OrderByIdScreen extends ConsumerWidget {
  const OrderByIdScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(staffOrderProvider(orderId));
    final order = state.value;
    if (order != null) return OrderDetailScreen(order: order);
    if (state.hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Commande')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Impossible de charger cette commande.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(staffOrderProvider(orderId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
                TextButton(
                  onPressed: () => context.goNamed('commandes'),
                  child: const Text('Voir les commandes'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Commande')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

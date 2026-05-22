import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lilia_admin/features/zones/data/zones_service.dart';
import 'package:lilia_admin/features/zones/presentation/providers/zones_provider.dart';

/// Référentiel en lecture seule des quartiers couverts par la plateforme.
/// La configuration des zones de livraison et de leurs tarifs se fait au
/// niveau de chaque restaurant (écran « Zones de livraison » restaurateur).
class QuartiersScreen extends ConsumerWidget {
  const QuartiersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quartiersAsync = ref.watch(allQuartiersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zones'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: () => ref.invalidate(allQuartiersProvider),
          ),
        ],
      ),
      body: quartiersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Impossible de charger les quartiers',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(allQuartiersProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (quartiers) {
          if (quartiers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text('Aucun quartier',
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
                child: Text(
                  'Référentiel des quartiers couverts. La configuration des '
                  'zones de livraison et de leurs tarifs se fait au niveau de '
                  'chaque restaurant.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ),
              Text(
                'Quartiers (${quartiers.length})',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  childAspectRatio: 3.4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: quartiers.length,
                itemBuilder: (context, index) {
                  final Quartier q = quartiers[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.place_outlined,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(q.nom,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

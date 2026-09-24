import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lilia_admin/core/network/api_exception.dart';
import 'package:lilia_admin/features/ops/data/ops_queue_service.dart';

/// « À traiter » (F3-04), version téléphone : les files calculées par le
/// serveur, en lecture. Utile la nuit, loin d'un poste. Les incidents
/// s'ouvrent ; les autres cartes se traitent depuis l'écran concerné.
class OpsQueueScreen extends ConsumerWidget {
  const OpsQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(opsQueueProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('À traiter'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(opsQueueProvider),
          ),
        ],
      ),
      body: queue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  e is ApiException
                      ? e.message
                      : 'Impossible de charger la file « À traiter ».',
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: () => ref.invalidate(opsQueueProvider),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (q) => RefreshIndicator(
          onRefresh: () => ref.refresh(opsQueueProvider.future),
          child: q.active.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 120),
                    Icon(Icons.check_circle, color: Colors.green, size: 48),
                    SizedBox(height: 12),
                    Center(child: Text('Rien à traiter.')),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (final bucket in q.active) _BucketCard(bucket: bucket),
                  ],
                ),
        ),
      ),
    );
  }
}

class _BucketCard extends StatelessWidget {
  final OpsBucket bucket;
  const _BucketCard({required this.bucket});

  @override
  Widget build(BuildContext context) {
    final color = bucket.isHigh ? Colors.red : Colors.orange;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(Icons.circle, size: 12, color: color),
            title: Text(
              bucket.label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: Chip(label: Text('${bucket.count}')),
          ),
          for (final item in bucket.items)
            ListTile(
              dense: true,
              title: Text(item.title),
              subtitle: item.detail == null ? null : Text(item.detail!),
              trailing: Text(
                ageLabel(item.since),
                style: const TextStyle(fontSize: 12),
              ),
              onTap: bucket.key == 'incidents_open'
                  ? () => context.pushNamed(
                      'incident-detail',
                      pathParameters: {'id': item.id},
                    )
                  : null,
            ),
          if (bucket.count > bucket.items.length)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'et ${bucket.count - bucket.items.length} de plus.',
                style: const TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

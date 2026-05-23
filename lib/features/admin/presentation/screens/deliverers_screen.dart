import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lilia_admin/features/admin/presentation/providers/admin_operations_provider.dart';
import 'package:lilia_admin/models/admin_deliverer.dart';

class DeliverersScreen extends ConsumerStatefulWidget {
  const DeliverersScreen({super.key});

  @override
  ConsumerState<DeliverersScreen> createState() => _DeliverersScreenState();
}

class _DeliverersScreenState extends ConsumerState<DeliverersScreen> {
  int _page = 1;

  @override
  Widget build(BuildContext context) {
    final deliverersAsync = ref.watch(adminDeliverersProvider(page: _page));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Livreurs'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: () => ref.invalidate(adminDeliverersProvider),
          ),
        ],
      ),
      body: deliverersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _errorView(error),
        data: (result) {
          if (result.deliverers.isEmpty) {
            return _emptyView();
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  itemCount: result.deliverers.length,
                  itemBuilder: (context, index) =>
                      _delivererCard(result.deliverers[index]),
                ),
              ),
              _buildPagination(result.total, result.totalPages),
            ],
          );
        },
      ),
    );
  }

  Widget _delivererCard(AdminDeliverer deliverer) {
    final theme = Theme.of(context);
    final name = deliverer.nom ?? deliverer.email ?? 'Livreur';
    final lastDelivery = deliverer.recentDeliveries.isNotEmpty
        ? deliverer.recentDeliveries.first
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/deliverers/${deliverer.id}'),
        child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: deliverer.imageUrl != null
                  ? NetworkImage(deliverer.imageUrl!)
                  : null,
              child: deliverer.imageUrl == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(deliverer.nom ?? '—',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  if (deliverer.email != null)
                    Row(
                      children: [
                        Icon(Icons.email_outlined,
                            size: 13, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(deliverer.email!,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  if (deliverer.phone != null)
                    Row(
                      children: [
                        Icon(Icons.phone_outlined,
                            size: 13, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(deliverer.phone!,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_shipping_outlined,
                        size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${deliverer.totalDeliveries}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  lastDelivery != null
                      ? 'Dernière : ${DateFormat('dd/MM/yyyy').format(lastDelivery.createdAt)}'
                      : 'Aucune livraison',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildPagination(int total, int totalPages) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$total livreur${total > 1 ? 's' : ''} · page $_page/$totalPages',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Page précédente',
                onPressed: _page > 1 ? () => setState(() => _page--) : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Page suivante',
                onPressed:
                    _page < totalPages ? () => setState(() => _page++) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delivery_dining_outlined,
              size: 64, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text('Aucun livreur', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _errorView(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur de chargement',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(error.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(adminDeliverersProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lilia_admin/features/admin/presentation/providers/admin_operations_provider.dart';
import 'package:lilia_admin/models/admin_deliverer.dart';

/// Strings UI groupées en `_Strings` privée — cohérent avec le pattern adopté
/// dans `DelivererDetailScreen` (LIL-87) et `DeliveryTrackingScreen` (LIL-86).
class _Strings {
  static const title = 'Livreurs';
  static const refreshTooltip = 'Actualiser';
  static const fallbackName = 'Livreur';
  static const fallbackNoName = '—';
  static const lastDeliveryPrefix = 'Dernière : ';
  static const noDelivery = 'Aucune livraison';
  static const prevPageTooltip = 'Page précédente';
  static const nextPageTooltip = 'Page suivante';
  static const emptyTitle = 'Aucun livreur';
  static const errorTitle = 'Erreur de chargement';
  static const retry = 'Réessayer';
}

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
        title: const Text(_Strings.title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: _Strings.refreshTooltip,
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
    final scheme = theme.colorScheme;
    final name = deliverer.nom ?? deliverer.email ?? _Strings.fallbackName;
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
              backgroundColor: scheme.primaryContainer,
              backgroundImage: deliverer.imageUrl != null
                  ? NetworkImage(deliverer.imageUrl!)
                  : null,
              child: deliverer.imageUrl == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: scheme.onPrimaryContainer,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(deliverer.nom ?? _Strings.fallbackNoName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  if (deliverer.email != null)
                    Row(
                      children: [
                        Icon(Icons.email_outlined,
                            size: 13, color: scheme.outline),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(deliverer.email!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  if (deliverer.phone != null)
                    Row(
                      children: [
                        Icon(Icons.phone_outlined,
                            size: 13, color: scheme.outline),
                        const SizedBox(width: 4),
                        Text(deliverer.phone!,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant)),
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
                        size: 14, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('${deliverer.totalDeliveries}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  lastDelivery != null
                      ? '${_Strings.lastDeliveryPrefix}${DateFormat('dd/MM/yyyy').format(lastDelivery.createdAt)}'
                      : _Strings.noDelivery,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: scheme.outline),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$total livreur${total > 1 ? 's' : ''} · page $_page/$totalPages',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: _Strings.prevPageTooltip,
                onPressed: _page > 1 ? () => setState(() => _page--) : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: _Strings.nextPageTooltip,
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delivery_dining_outlined,
              size: 64, color: scheme.outlineVariant),
          const SizedBox(height: 12),
          Text(_Strings.emptyTitle,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _errorView(Object error) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: scheme.error),
            const SizedBox(height: 16),
            Text(_Strings.errorTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(error.toString(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(adminDeliverersProvider),
              icon: const Icon(Icons.refresh),
              label: const Text(_Strings.retry),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lilia_admin/features/clients/presentation/providers/user_orders_provider.dart';
import 'package:lilia_admin/features/clients/presentation/providers/clients_provider.dart';
import 'package:lilia_admin/features/home/presentation/screens/restaurant_orders_screen.dart';
import 'package:lilia_admin/models/app_user.dart';
import 'package:lilia_admin/models/order.dart';

class ClientDetailScreen extends ConsumerWidget {
  final AppUser client;

  const ClientDetailScreen({super.key, required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientId = client.id;
    if (clientId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(client.nom ?? 'Détail Client')),
        body: const Center(child: Text('ID client non disponible')),
      );
    }

    final userOrdersAsync = ref.watch(userOrdersProvider(clientId));

    return Scaffold(
      appBar: AppBar(
        title: Text(client.nom ?? 'Détail Client'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(userOrdersProvider(clientId)),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildClientHeader(context),
          const Divider(height: 1),
          // Stats résumé
          userOrdersAsync.whenOrNull(
                data: (orders) => _buildOrderStats(context, orders),
              ) ??
              const SizedBox.shrink(),
          const Divider(height: 1),
          _buildLoyaltySection(context, ref, clientId),
          const Divider(height: 1),
          // Titre section commandes
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Icon(Icons.receipt_long, color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Historique des commandes',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: userOrdersAsync.when(
              data: (orders) {
                if (orders.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'Ce client n\'a passé aucune commande.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(userOrdersProvider(clientId).future),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      return OrderCard(order: orders[index]);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(
                        'Erreur de chargement:\n$error',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => ref.invalidate(userOrdersProvider(clientId)),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage:
                    client.imageUrl != null ? NetworkImage(client.imageUrl!) : null,
                child: client.imageUrl == null
                    ? Text(
                        client.initials,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.nom ?? 'Client',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    if (client.email.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.email_outlined, size: 16, color: Colors.grey[500]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              client.email,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey[600]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    if (client.phone != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined, size: 16, color: Colors.grey[500]),
                          const SizedBox(width: 6),
                          Text(
                            client.phone!,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 6),
                        Text(
                          'Inscrit le ${DateFormat('dd/MM/yyyy').format(client.createdAt)}',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Boutons d'action
          Row(
            children: [
              if (client.phone != null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _launchPhone(client.phone!),
                    icon: Icon(Icons.call, color: Colors.green[600], size: 18),
                    label: Text('Appeler', style: TextStyle(color: Colors.green[600])),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.green[300]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _launchSms(client.phone!),
                    icon: Icon(Icons.sms, color: Colors.blue[600], size: 18),
                    label: Text('SMS', style: TextStyle(color: Colors.blue[600])),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.blue[300]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final text = client.phone ?? client.email;
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Contact copié'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: Icon(Icons.copy, color: Colors.grey[600], size: 18),
                  label: Text('Copier', style: TextStyle(color: Colors.grey[600])),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStats(BuildContext context, List<Order> orders) {
    final totalSpent = orders.fold<double>(0, (sum, o) => sum + o.total);
    final completedOrders = orders.where((o) => o.status == OrderStatus.livrer).length;
    final cancelledOrders = orders.where((o) => o.status == OrderStatus.annuler).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _statItem(
            context,
            '${orders.length}',
            'Commandes',
            Icons.receipt,
            Colors.blue,
          ),
          _statItem(
            context,
            '$completedOrders',
            'Livrées',
            Icons.check_circle,
            Colors.green,
          ),
          _statItem(
            context,
            '$cancelledOrders',
            'Annulées',
            Icons.cancel,
            Colors.red,
          ),
          _statItem(
            context,
            '${totalSpent.toStringAsFixed(0)}F',
            'Dépensé',
            Icons.monetization_on,
            Colors.amber[700]!,
          ),
        ],
      ),
    );
  }

  Widget _buildLoyaltySection(BuildContext context, WidgetRef ref, String clientId) {
    final loyaltyAsync = ref.watch(clientLoyaltyProvider(clientId));
    return loyaltyAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Fidélité indisponible', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      ),
      data: (loyalty) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.stars, color: Colors.amber[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  '${loyalty.balance} point${loyalty.balance > 1 ? 's' : ''} de fidélité',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.amber[800]),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 28, top: 2),
              child: Text(
                '≈ ${loyalty.balance * 5} FCFA de réduction disponible',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
            if (loyalty.transactions.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...loyalty.transactions.take(5).map((t) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.reason, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                              Text(
                                DateFormat('dd/MM/yyyy').format(t.createdAt),
                                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${t.points >= 0 ? '+' : ''}${t.points}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: t.points >= 0 ? Colors.green[600] : Colors.red[600],
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statItem(
      BuildContext context, String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchSms(String phone) async {
    final uri = Uri(scheme: 'sms', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../models/order.dart';
import '../../data/order_controller.dart';

class OrderDetailScreen extends ConsumerWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Écouter les mises à jour de la commande en temps réel
    final ordersState = ref.watch(restaurantOrdersProvider);
    final currentOrder = ordersState.whenOrNull(
          data: (orders) {
            try {
              return orders.firstWhere((o) => o.id == order.id);
            } catch (_) {
              return null;
            }
          },
        ) ??
        order;

    final statusInfo = _getStatusInfo(currentOrder.status);

    return Scaffold(
      appBar: AppBar(
        title: Text('Commande #${currentOrder.id.substring(0, 8).toUpperCase()}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(restaurantOrdersProvider.future),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bannière statut
            _buildStatusBanner(context, currentOrder, statusInfo),
            const SizedBox(height: 16),

            // Infos client
            _buildCustomerSection(context, currentOrder),
            const SizedBox(height: 16),

            // Adresse livraison
            if (currentOrder.deliveryAddress.isNotEmpty &&
                currentOrder.deliveryAddress != 'Adresse non spécifiée')
              _buildDeliverySection(context, currentOrder),
            if (currentOrder.deliveryAddress.isNotEmpty &&
                currentOrder.deliveryAddress != 'Adresse non spécifiée')
              const SizedBox(height: 16),

            // Notes
            if (currentOrder.notes != null && currentOrder.notes!.isNotEmpty)
              _buildNotesSection(context, currentOrder),
            if (currentOrder.notes != null && currentOrder.notes!.isNotEmpty)
              const SizedBox(height: 16),

            // Articles
            _buildItemsSection(context, currentOrder),
            const SizedBox(height: 16),

            // Récapitulatif prix
            _buildPriceSummary(context, currentOrder),
            const SizedBox(height: 16),

            // Infos paiement
            _buildPaymentInfo(context, currentOrder),
            const SizedBox(height: 24),

            // Actions statut
            _buildStatusActions(context, ref, currentOrder),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context, Order order, _StatusInfo info) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: info.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(info.icon, color: info.color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.label,
                  style: TextStyle(
                    color: info.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd/MM/yyyy à HH:mm').format(order.createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          if (order.restaurantName != null)
            Chip(
              avatar: Icon(Icons.restaurant, size: 16, color: Colors.purple[700]),
              label: Text(
                order.restaurantName!,
                style: TextStyle(fontSize: 12, color: Colors.purple[700]),
              ),
              backgroundColor: Colors.purple.shade50,
              side: BorderSide.none,
            ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection(BuildContext context, Order order) {
    final theme = Theme.of(context);
    final hasCustomerInfo = order.customerName != null || order.customerPhone != null;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Client',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            if (!hasCustomerInfo)
              Text(
                'Informations client non disponibles',
                style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
              )
            else ...[
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    backgroundImage: order.customerImageUrl != null
                        ? NetworkImage(order.customerImageUrl!)
                        : null,
                    child: order.customerImageUrl == null
                        ? Text(
                            _getInitials(order.customerName),
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
                        Text(
                          order.customerName ?? 'Client',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (order.customerEmail != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            order.customerEmail!,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (order.customerPhone != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.phone, size: 18, color: Colors.green[600]),
                    const SizedBox(width: 8),
                    Text(
                      order.customerPhone!,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    // Bouton appeler
                    IconButton(
                      icon: Icon(Icons.call, color: Colors.green[600]),
                      tooltip: 'Appeler',
                      onPressed: () => _launchPhone(order.customerPhone!),
                    ),
                    // Bouton copier
                    IconButton(
                      icon: Icon(Icons.copy, color: Colors.grey[600]),
                      tooltip: 'Copier le numéro',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: order.customerPhone!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Numéro copié'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeliverySection(BuildContext context, Order order) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  order.isDelivery ? Icons.delivery_dining : Icons.store,
                  color: Colors.blue[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  order.isDelivery ? 'Livraison' : 'Retrait au restaurant',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, color: Colors.grey[500], size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.deliveryAddress,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.copy, size: 18, color: Colors.grey[500]),
                  tooltip: 'Copier l\'adresse',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: order.deliveryAddress));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Adresse copiée'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context, Order order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.note_alt, size: 20, color: Colors.amber[700]),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notes du client',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[800],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order.notes!,
                  style: TextStyle(color: Colors.amber[900], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(BuildContext context, Order order) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_bag, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Articles (${order.items.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...order.items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${item.quantite}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (item.variant != null && item.variant != 'Standard')
                            Text(
                              item.variant!,
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '${(item.prix * item.quantite).toStringAsFixed(0)} FCFA',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummary(BuildContext context, Order order) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _priceRow('Sous-total', '${order.subTotal.toStringAsFixed(0)} FCFA'),
            const SizedBox(height: 8),
            _priceRow(
              order.isDelivery ? 'Frais de livraison' : 'Retrait (gratuit)',
              '${order.deliveryFee.toStringAsFixed(0)} FCFA',
            ),
            if (order.serviceFee > 0) ...[
              const SizedBox(height: 8),
              _priceRow(
                'Frais de service (10%)',
                '${order.serviceFee.toStringAsFixed(0)} FCFA',
              ),
            ],
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${order.total.toStringAsFixed(0)} FCFA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600])),
        Text(value, style: TextStyle(color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildPaymentInfo(BuildContext context, Order order) {
    String paymentLabel;
    IconData paymentIcon;
    Color paymentColor;

    switch (order.paymentMethod) {
      case 'MTN_MOMO':
        paymentLabel = 'MTN Mobile Money';
        paymentIcon = Icons.phone_android;
        paymentColor = Colors.amber[700]!;
        break;
      case 'AIRTEL_MONEY':
        paymentLabel = 'Airtel Money';
        paymentIcon = Icons.phone_android;
        paymentColor = Colors.red[600]!;
        break;
      case 'CASH':
        paymentLabel = 'Paiement à la livraison';
        paymentIcon = Icons.money;
        paymentColor = Colors.green[600]!;
        break;
      default:
        paymentLabel = order.paymentMethod ?? 'Non spécifié';
        paymentIcon = Icons.payment;
        paymentColor = Colors.grey[600]!;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: paymentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: paymentColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(paymentIcon, color: paymentColor, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mode de paiement',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              Text(
                paymentLabel,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: paymentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusActions(BuildContext context, WidgetRef ref, Order order) {
    if (order.status == OrderStatus.livrer || order.status == OrderStatus.annuler) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              order.status == OrderStatus.livrer ? Icons.check_circle : Icons.cancel,
              color: order.status == OrderStatus.livrer ? Colors.green : Colors.red,
              size: 28,
            ),
            const SizedBox(width: 10),
            Text(
              order.status == OrderStatus.livrer
                  ? 'Commande livrée avec succès'
                  : 'Commande annulée',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    final availableStatuses = _getAvailableStatuses(order.status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Changer le statut',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        ...availableStatuses.map((status) {
          final info = _getStatusInfo(status);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _updateStatus(context, ref, order, status),
                style: ElevatedButton.styleFrom(
                  backgroundColor: info.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: Icon(info.icon),
                label: Text(
                  info.label,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _updateStatus(
      BuildContext context, WidgetRef ref, Order order, OrderStatus status) async {
    if (status == OrderStatus.annuler) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Annuler la commande ?'),
          content: const Text('Cette action est irréversible. Le client sera notifié.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Non'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Oui, annuler'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    try {
      await ref.read(restaurantOrdersProvider.notifier).updateOrderStatus(order.id, status);

      if (context.mounted) {
        final info = _getStatusInfo(status);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Statut mis à jour: ${info.label}'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        ref.refresh(restaurantOrdersProvider.future);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Erreur: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  List<OrderStatus> _getAvailableStatuses(OrderStatus current) {
    switch (current) {
      case OrderStatus.enattente:
        return [OrderStatus.enpreparation, OrderStatus.payer, OrderStatus.annuler];
      case OrderStatus.payer:
        return [OrderStatus.enpreparation, OrderStatus.annuler];
      case OrderStatus.enpreparation:
        return [OrderStatus.pret, OrderStatus.annuler];
      case OrderStatus.pret:
        return [OrderStatus.livrer, OrderStatus.annuler];
      default:
        return [];
    }
  }

  _StatusInfo _getStatusInfo(OrderStatus status) {
    switch (status) {
      case OrderStatus.enattente:
        return _StatusInfo(label: 'En attente', color: Colors.orange, icon: Icons.hourglass_empty);
      case OrderStatus.payer:
        return _StatusInfo(label: 'Payée', color: Colors.blue, icon: Icons.payment);
      case OrderStatus.enpreparation:
        return _StatusInfo(
            label: 'En préparation', color: Colors.indigo, icon: Icons.restaurant);
      case OrderStatus.pret:
        return _StatusInfo(label: 'Prête', color: Colors.green, icon: Icons.check_circle);
      case OrderStatus.livrer:
        return _StatusInfo(label: 'Livrée', color: Colors.teal, icon: Icons.local_shipping);
      case OrderStatus.annuler:
        return _StatusInfo(label: 'Annuler', color: Colors.red, icon: Icons.cancel);
      default:
        return _StatusInfo(label: 'Inconnu', color: Colors.grey, icon: Icons.help_outline);
    }
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '??';
    final parts = name.split(' ');
    if (parts.length > 1 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : name.length).toUpperCase();
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  final IconData icon;

  _StatusInfo({required this.label, required this.color, required this.icon});
}

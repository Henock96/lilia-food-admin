import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lilia_admin/features/admin/presentation/providers/admin_operations_provider.dart';
import 'package:lilia_admin/models/admin_payment.dart';

/// Statuts de paiement (ordre des filtres) et leurs libellés français.
const _paymentStatuses = ['PENDING', 'SUCCESS', 'FAILED', 'CANCELLED'];
const _paymentStatusLabels = <String, String>{
  'PENDING': 'En attente',
  'SUCCESS': 'Confirmé',
  'FAILED': 'Échoué',
  'CANCELLED': 'Annulé',
};

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  String _status = 'PENDING';
  int _page = 1;
  String? _confirmingId;

  Future<void> _confirmPayment(AdminPayment payment) async {
    setState(() => _confirmingId = payment.id);
    try {
      await ref
          .read(adminOperationsRepositoryProvider)
          .confirmPayment(payment.id);
      if (!mounted) return;
      ref.invalidate(adminPaymentsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paiement confirmé'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _confirmingId = null);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'SUCCESS':
        return Colors.green;
      case 'FAILED':
        return Colors.red;
      case 'CANCELLED':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentsAsync =
        ref.watch(adminPaymentsProvider(page: _page, status: _status));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiements'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: () => ref.invalidate(adminPaymentsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusFilter(),
          Expanded(
            child: paymentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _errorView(error),
              data: (result) {
                if (result.payments.isEmpty) {
                  return _emptyView(
                    'Aucun paiement « ${_paymentStatusLabels[_status]} »',
                  );
                }
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        itemCount: result.payments.length,
                        itemBuilder: (context, index) =>
                            _paymentCard(result.payments[index]),
                      ),
                    ),
                    _buildPagination(result.total, result.totalPages),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: _paymentStatuses.map((s) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_paymentStatusLabels[s] ?? s),
              selected: s == _status,
              onSelected: (_) {
                setState(() {
                  _status = s;
                  _page = 1;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _paymentCard(AdminPayment payment) {
    final order = payment.order;
    final orderId = order?.id ?? '';
    final orderRef = orderId.length >= 6
        ? '#${orderId.substring(orderId.length - 6).toUpperCase()}'
        : (orderId.isEmpty ? '—' : '#${orderId.toUpperCase()}');
    final color = _statusColor(payment.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(orderRef,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _paymentStatusLabels[payment.status] ?? payment.status,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
                Text(
                  '${payment.amount.toStringAsFixed(0)} ${payment.currency}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              order?.clientNom ?? '—',
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.phone_outlined, size: 13, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(payment.phoneNumber,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(width: 10),
                Text(payment.provider,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(payment.createdAt),
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (payment.status == 'PENDING') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _confirmingId == null
                      ? () => _confirmPayment(payment)
                      : null,
                  icon: _confirmingId == payment.id
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: const Text('Confirmer le paiement'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
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
            '$total paiement${total > 1 ? 's' : ''} · page $_page/$totalPages',
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

  Widget _emptyView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payments_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.grey[600])),
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
              onPressed: () => ref.invalidate(adminPaymentsProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

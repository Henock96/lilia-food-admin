import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lilia_admin/features/admin/presentation/providers/admin_operations_provider.dart';
import 'package:lilia_admin/models/admin_payment.dart';
import 'package:lilia_admin/models/payments_stats.dart';

/// Statuts de paiement (ordre des filtres) et leurs libellés français.
/// La valeur '' = vue "Tous statuts confondus" (pas de filtre serveur).
const _paymentFilters = <({String value, String label})>[
  (value: '', label: 'Tous'),
  (value: 'PENDING', label: 'En attente'),
  (value: 'SUCCESS', label: 'Confirmé'),
  (value: 'FAILED', label: 'Échoué'),
  (value: 'CANCELLED', label: 'Annulé'),
];
const _paymentStatusLabels = <String, String>{
  'PENDING': 'En attente',
  'SUCCESS': 'Confirmé',
  'FAILED': 'Échoué',
  'CANCELLED': 'Annulé',
};

const _paymentMethodLabels = <String, String>{
  'MTN_MOMO': 'MTN Mobile Money',
  'AIRTEL_MONEY': 'Airtel Money',
  'CASH_ON_DELIVERY': 'À la livraison',
};

// Couleurs d'identité des opérateurs de paiement externes — intentionnellement
// HORS du design system Lilia (`lilia_tokens.dart`) : ce sont les couleurs de
// marque MTN / Airtel, pas des tokens de marque Lilia (cf. A19).
const _paymentMethodColors = <String, Color>{
  'MTN_MOMO': Color(0xFFFACC15),     // jaune marque MTN
  'AIRTEL_MONEY': Color(0xFFEF4444), // rouge marque Airtel
  'CASH_ON_DELIVERY': Color(0xFF9CA3AF), // gris neutre (espèces)
};

/// LIL-132 : emoji par vendorType — local au payments screen pour éviter
/// d'importer le model VendorType (qui n'existe pas encore côté admin)
/// et garder l'aperçu auto-contenu.
String _vendorEmoji(String? vendorType) {
  switch (vendorType) {
    case 'RESTAURANT':
      return '🍽️';
    case 'HOME_COOK':
      return '🍲';
    case 'BAKERY':
      return '🥐';
    case 'BEVERAGE_SHOP':
      return '🥤';
    case 'GROCERY':
      return '🛒';
    default:
      return '🏬';
  }
}

final _xafFormatter = NumberFormat.decimalPattern('fr_FR');

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  // '' = "Tous statuts" par défaut — l'admin voit l'historique complet et peut
  // ensuite filtrer sur PENDING pour traiter les confirmations à faire.
  String _status = '';
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
      ref.invalidate(adminPaymentsStatsProvider);
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
    final statsAsync = ref.watch(adminPaymentsStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiements'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: () {
              ref.invalidate(adminPaymentsProvider);
              ref.invalidate(adminPaymentsStatsProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsCards(statsAsync),
          _buildStatusFilter(),
          Expanded(
            child: paymentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _errorView(error),
              data: (result) {
                if (result.payments.isEmpty) {
                  final currentLabel = _paymentFilters
                      .firstWhere((f) => f.value == _status,
                          orElse: () => (value: '', label: 'Tous'))
                      .label;
                  return _emptyView(
                    _status.isEmpty
                        ? 'Aucun paiement enregistré'
                        : 'Aucun paiement « $currentLabel »',
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

  Widget _buildStatsCards(AsyncValue<PaymentsStats> statsAsync) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: SizedBox(
        height: 88,
        child: statsAsync.when(
          loading: () => _statsSkeleton(),
          error: (_, _) => const SizedBox.shrink(),
          data: (stats) => Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.schedule,
                  iconColor: Colors.amber.shade700,
                  label: 'À confirmer',
                  value: _xafFormatter.format(stats.pending.totalXaf),
                  unit: 'XAF',
                  sub: '${stats.pending.count} paiement'
                      '${stats.pending.count > 1 ? 's' : ''}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  icon: Icons.calendar_month_outlined,
                  iconColor: Colors.green.shade700,
                  label: 'Ce mois',
                  value: _xafFormatter.format(stats.monthSuccess.totalXaf),
                  unit: 'XAF',
                  sub: '${stats.monthSuccess.count} encaissé'
                      '${stats.monthSuccess.count > 1 ? 's' : ''}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  icon: Icons.trending_up,
                  iconColor: Colors.blue.shade700,
                  label: '7 derniers j.',
                  value: _xafFormatter.format(stats.last7DaysSuccess.totalXaf),
                  unit: 'XAF',
                  sub: '${stats.last7DaysSuccess.count} encaissé'
                      '${stats.last7DaysSuccess.count > 1 ? 's' : ''}',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statsSkeleton() {
    return Row(
      children: List.generate(
        3,
        (_) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: _paymentFilters.map((f) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f.label),
              selected: f.value == _status,
              onSelected: (_) {
                setState(() {
                  _status = f.value;
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
    final method = order?.paymentMethod;
    final methodLabel = method != null ? _paymentMethodLabels[method] : null;
    final methodColor = method != null ? _paymentMethodColors[method] : null;

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
                if (orderId.isNotEmpty)
                  // Tap → liste des commandes (filtrable). Le deep link direct
                  // vers `/commandes/:id` nécessite que la route order-detail
                  // accepte un fetch par id (à faire en suivi LIL-105).
                  GestureDetector(
                    onTap: () => context.goNamed('commandes'),
                    child: Text(
                      orderRef,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                else
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
                if (methodLabel != null && methodColor != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: methodColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: methodColor.withValues(alpha: 0.5), width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: methodColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          methodLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  '${payment.amount.toStringAsFixed(0)} ${payment.currency}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // LIL-132 : identité du vendeur — emoji + nom — pour distinguer
            // les paiements multi-vendeurs sans devoir cliquer sur la commande.
            if (order?.restaurantNom != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _vendorEmoji(order?.vendorType),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        order!.restaurantNom!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ],
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
                Text(
                  payment.provider == 'MANUAL'
                      ? 'Virement manuel'
                      : payment.provider == 'MTN_MOMO'
                          ? 'MTN auto'
                          : payment.provider,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(payment.createdAt),
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

/// KPI card de la rangée d'en-tête (à confirmer / ce mois / 7 derniers jours).
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.unit,
    required this.sub,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String unit;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 3),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lilia_admin/core/utils/currency.dart';
import 'package:lilia_admin/core/utils/date_format.dart';
import 'package:lilia_admin/features/earnings/data/earnings_repository.dart';
import 'package:lilia_admin/features/earnings/presentation/earnings_providers.dart';

/// « Mes gains » (F3-07) — ce qui va être versé, ce qui a été versé, et ce
/// que le vendeur doit éventuellement.
///
/// Quatre questions, dans l'ordre où il se les pose : quand serai-je payé ?
/// qu'est-ce qui attend encore ? qu'ai-je reçu ? est-ce que je dois quelque
/// chose ? Les montants à venir sont des ESTIMATIONS : une retenue (réclamation,
/// dette) n'est connue qu'au moment du versement.
class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(vendorEarningsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes gains')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(vendorEarningsProvider.future),
        // Riverpod 3 relance un provider en échec et repasse en chargement EN
        // GARDANT son erreur : un `switch` sur `AsyncError` seul tombait dans
        // le spinner pendant chaque relance — sans fin, sans « Réessayer ».
        // L'erreur se lit donc sur `hasError`, pas sur le type de l'état.
        child: async.hasValue
            ? _Body(earnings: async.requireValue)
            : async.hasError
                ? _Error(
                    message: async.error.toString(),
                    onRetry: () => ref.invalidate(vendorEarningsProvider),
                  )
                : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.earnings});

  final VendorEarnings earnings;

  @override
  Widget build(BuildContext context) {
    final e = earnings;
    if (e.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Icon(Icons.account_balance_wallet_outlined, size: 56, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'Aucun versement pour l’instant.\nChaque commande remise vous est '
            'versée automatiquement une heure après la remise.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Summary(earnings: e),
        if (e.debtXaf > 0) ...[
          const SizedBox(height: 12),
          _DebtBanner(debtXaf: e.debtXaf),
        ],
        if (e.awaitingProofCount > 0) ...[
          const SizedBox(height: 12),
          _AwaitingProof(count: e.awaitingProofCount),
        ],
        if (e.upcoming.isNotEmpty) ...[
          const _SectionTitle('À venir'),
          for (final u in e.upcoming) _UpcomingTile(item: u),
        ],
        if (e.payouts.isNotEmpty) ...[
          const _SectionTitle('Versements'),
          for (final p in e.payouts) _PayoutTile(payout: p),
        ],
        if (e.debtEntries.isNotEmpty) ...[
          const _SectionTitle('Mouvements de la dette'),
          for (final d in e.debtEntries) _DebtTile(entry: d),
        ],
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.earnings});

  final VendorEarnings earnings;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget cell(String label, int amount, {Key? key}) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(
                formatXaf(amount),
                key: key,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(children: [
              cell('À venir (estimé)', earnings.upcomingXaf,
                  key: const Key('earnings-upcoming')),
              cell('En cours', earnings.pendingXaf),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              cell('Reçu sur 30 jours', earnings.paidLast30DaysXaf,
                  key: const Key('earnings-paid-30d')),
              const Expanded(child: SizedBox.shrink()),
            ]),
          ],
        ),
      ),
    );
  }
}

class _DebtBanner extends StatelessWidget {
  const _DebtBanner({required this.debtXaf});

  final int debtXaf;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('earnings-debt'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Text(
        'Vous devez ${formatXaf(debtXaf)} : des clients ont été remboursés '
        'après le versement de leur commande. Ce montant sera retenu sur vos '
        'prochains versements.',
      ),
    );
  }
}

class _AwaitingProof extends StatelessWidget {
  const _AwaitingProof({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('earnings-awaiting-proof'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count commande${count > 1 ? 's' : ''} remise${count > 1 ? 's' : ''} '
        'sans preuve : le paiement part dès que le client confirme le retrait. '
        'Demandez le code du client au comptoir pour être payé sans attendre.',
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      );
}

class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({required this.item});

  final UpcomingPayout item;

  @override
  Widget build(BuildContext context) {
    final due = item.payoutDueAt;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.schedule),
      title: Text('Commande #${item.orderRef}'),
      subtitle: Text(
        due == null ? 'Date à venir' : 'Prévu le ${formatBrazzavilleDateTime(due)}',
      ),
      trailing: Text(
        '≈ ${formatXaf(item.estimatedXaf)}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _PayoutTile extends StatelessWidget {
  const _PayoutTile({required this.payout});

  final PayoutLine payout;

  @override
  Widget build(BuildContext context) {
    final p = payout;
    final at = p.completedAt ?? p.requestedAt;
    final retenues = [
      if (p.commissionAmount > 0) 'commission ${formatXaf(p.commissionAmount)}',
      if (p.deliverySubsidyAmount > 0)
        'livraison offerte ${formatXaf(p.deliverySubsidyAmount)}',
      if (p.refundDeductionAmount > 0)
        'remboursement ${formatXaf(p.refundDeductionAmount)}',
      if (p.debtDeductionAmount > 0) 'dette ${formatXaf(p.debtDeductionAmount)}',
    ];
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      leading: Icon(
        p.status == 'SUCCESS'
            ? Icons.check_circle
            : p.status == 'FAILED'
                ? Icons.error_outline
                : Icons.hourglass_bottom,
        color: p.status == 'SUCCESS'
            ? Colors.teal
            : p.status == 'FAILED'
                ? Colors.orange
                : Colors.blueGrey,
      ),
      title: Text('Commande #${p.orderRef}'),
      subtitle: Text(
        '${p.statusLabel}${at != null ? ' · ${formatBrazzavilleDateTime(at)}' : ''}',
      ),
      trailing: Text(
        formatXaf(p.amount),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 56, bottom: 12),
            child: Text(
              'Commande ${formatXaf(p.grossAmount)}'
              '${retenues.isEmpty ? '' : ' − ${retenues.join(' − ')}'}'
              ' = ${formatXaf(p.amount)}',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}

class _DebtTile extends StatelessWidget {
  const _DebtTile({required this.entry});

  final DebtEntry entry;

  @override
  Widget build(BuildContext context) {
    final at = entry.createdAt;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(entry.label),
      subtitle: at == null ? null : Text(formatBrazzavilleDateTime(at)),
      trailing: Text(
        '${entry.amountXaf > 0 ? '+' : '−'} ${formatXaf(entry.amountXaf.abs())}',
        style: TextStyle(
          color: entry.amountXaf < 0 ? Colors.orange[800] : Colors.teal,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListView(
        children: [
          const SizedBox(height: 120),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Center(
            child: FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
          ),
        ],
      );
}

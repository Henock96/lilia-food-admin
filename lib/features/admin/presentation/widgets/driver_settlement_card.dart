import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lilia_admin/features/admin/presentation/providers/admin_operations_provider.dart';
import 'package:lilia_admin/features/admin/presentation/providers/deliverer_detail_provider.dart';
import 'package:lilia_admin/models/driver_settlement.dart';
import 'package:lilia_admin/core/utils/currency.dart';

/// Règlement d'un livreur — ce qu'on lui doit, ce qu'on lui a versé.
///
/// ## Ce que cet écran n'est pas
///
/// Un bouton « payer ». Aucun virement n'est déclenché : l'argent est remis
/// hors application. Cette carte **enregistre** un versement déjà fait, et son
/// libellé le dit — « J'ai versé ce montant », pas « Payer ». Un bouton qui
/// semble payer serait cliqué en croyant payer.
///
/// ## Le piège que `coveredUntil` ferme
///
/// Le montant dû est une lecture prise à un instant. Entre son affichage et le
/// clic, le livreur peut terminer une course : si l'enregistrement couvrait
/// « tout ce qui est non réglé maintenant », elle serait absorbée dans un
/// montant déjà convenu et déjà remis, et le livreur sous-payé sans que rien
/// ne le signale.
///
/// On renvoie donc la coupure **de l'aperçu affiché**. C'est la seule chose de
/// ce fichier à ne surtout pas « simplifier » en `DateTime.now()`.
class DriverSettlementCard extends ConsumerStatefulWidget {
  const DriverSettlementCard({super.key, required this.driverId});

  final String driverId;

  @override
  ConsumerState<DriverSettlementCard> createState() =>
      _DriverSettlementCardState();
}

class _DriverSettlementCardState extends ConsumerState<DriverSettlementCard> {
  bool _saving = false;

  Future<void> _record(DriverOutstanding due) async {
    final method = await showDialog<SettlementMethod>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Comment avez-vous versé ?'),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(
              'Cette action n’envoie aucun argent : elle enregistre un '
              'versement que vous avez déjà effectué.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          ...SettlementMethod.values.map(
            (m) => SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(m),
              child: Text(m.label),
            ),
          ),
        ],
      ),
    );
    if (method == null || !mounted) return;

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(adminOperationsRepositoryProvider).recordDriverSettlement(
            driverId: widget.driverId,
            // ⚠️ Celui de l'aperçu, jamais `DateTime.now()`.
            coveredUntil: due.coveredUntil,
            method: method,
          );
      ref.invalidate(driverOutstandingProvider(widget.driverId));
      ref.invalidate(driverSettlementsProvider(widget.driverId));
      ref.invalidate(delivererStatsProvider(widget.driverId));
      messenger.showSnackBar(
        const SnackBar(content: Text('Règlement enregistré')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final outstanding = ref.watch(driverOutstandingProvider(widget.driverId));
    final settlements = ref.watch(driverSettlementsProvider(widget.driverId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Règlement du livreur',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            outstanding.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(
                'Décompte indisponible : $e',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
              data: (due) => _DueBlock(
                due: due,
                saving: _saving,
                onRecord: () => _record(due),
              ),
            ),
            const Divider(height: 24),
            const Text(
              'Versements enregistrés',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            settlements.when(
              loading: () => const SizedBox(
                height: 32,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('$e',
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
              data: (list) => list.isEmpty
                  ? const Text('Aucun versement enregistré.',
                      style: TextStyle(fontSize: 12, color: Colors.grey))
                  : Column(
                      children: list.map((s) => _SettlementRow(s: s)).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DueBlock extends StatelessWidget {
  const _DueBlock({
    required this.due,
    required this.saving,
    required this.onRecord,
  });

  final DriverOutstanding due;
  final bool saving;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    final nothing = due.courseCount == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Reste dû',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          formatXaf(due.amountXaf),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          nothing
              ? 'Aucune course à régler. Les courses antérieures au 18/09/2026 '
                    'n’ont pas de rémunération enregistrée.'
              : '${due.courseCount} course(s), arrêté au '
                    '${DateFormat('d MMM HH:mm', 'fr').format(due.coveredUntil)}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        if (!nothing) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: saving ? null : onRecord,
              icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
              // « J'ai versé » et non « Payer » : rien ne part d'ici.
              label: Text(
                saving ? 'Enregistrement…' : 'J’ai versé ce montant',
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SettlementRow extends StatelessWidget {
  const _SettlementRow({required this.s});

  final DriverSettlement s;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Icon(
          s.cancelled ? Icons.cancel_outlined : Icons.check_circle_outline,
          size: 16,
          color: s.cancelled ? Colors.grey : Colors.green,
        ),
        const SizedBox(width: 6),
        Text(
          formatXaf(s.amountXaf),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            // Barré plutôt que masqué : un versement qui disparaîtrait de
            // l'historique inquiéterait à raison.
            decoration: s.cancelled ? TextDecoration.lineThrough : null,
            color: s.cancelled ? Colors.grey : null,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${s.courseCount} course(s) · ${s.method.label} · '
            '${DateFormat('d MMM', 'fr').format(s.paidAt)}'
            '${s.cancelled ? ' · annulé' : ''}',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

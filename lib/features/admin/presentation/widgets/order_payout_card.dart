import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lilia_admin/core/network/api_exception.dart';
import 'package:lilia_admin/core/utils/currency.dart';
import 'package:lilia_admin/features/admin/presentation/providers/admin_operations_provider.dart';
import 'package:lilia_admin/models/order_financials.dart';

/// Carte « Payer le restaurant » du détail d'une commande.
///
/// Trois principes de conception :
///
///  1. **Le serveur décide.** Le bouton s'active d'après `eligibility.eligible`,
///     et le backend rejoue toutes ses vérifications au clic. Afficher le bouton
///     n'autorise rien — un écran resté ouvert dix minutes peut proposer une
///     action devenue impossible, et c'est le 409 qui fait foi.
///
///  2. **Aucun montant n'est recalculé ici.** Commission, net à reverser et
///     total client viennent du serveur. Recalculer localement produirait tôt
///     ou tard un chiffre différent de celui qui part réellement.
///
///  3. **Une confirmation explicite avant tout virement.** Envoyer de l'argent
///     à un tiers ne doit pas tenir à un tap : la modale récapitule le
///     bénéficiaire, le montant net et le numéro masqué.
class OrderPayoutCard extends ConsumerStatefulWidget {
  const OrderPayoutCard({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderPayoutCard> createState() => _OrderPayoutCardState();
}

class _OrderPayoutCardState extends ConsumerState<OrderPayoutCard> {
  /// Verrou local : empêche un second tap pendant l'appel réseau. Ce n'est
  /// qu'un confort d'interface — la vraie garantie contre le double paiement est
  /// la contrainte d'unicité en base, côté serveur.
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(orderFinancialsProvider(orderId: widget.orderId));

    return async.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  error is ApiException
                      ? error.message
                      : 'Récapitulatif financier indisponible.',
                ),
              ),
              TextButton(
                onPressed: () => ref.invalidate(
                  orderFinancialsProvider(orderId: widget.orderId),
                ),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
      data: (financials) => _buildCard(context, financials),
    );
  }

  Widget _buildCard(BuildContext context, OrderFinancials f) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Paiement du restaurant',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _PayoutStatusChip(financials: f),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Commande #${f.orderRef} · ${f.restaurantName}',
              style: theme.textTheme.bodySmall?.copyWith(color: cs.outline),
            ),
            const Divider(height: 24),

            // ─── Ce que paie le client ────────────────────────────────────────
            _SectionTitle('Client'),
            _Row(label: 'Produits', value: formatXaf(f.subTotal)),
            if (f.deliveryFee > 0)
              _Row(label: 'Livraison', value: formatXaf(f.deliveryFee)),
            _Row(label: 'Frais de service', value: formatXaf(f.serviceFee)),
            if (f.discountAmount > 0)
              _Row(
                label: 'Remise',
                value: '− ${formatXaf(f.discountAmount)}',
                valueColor: Colors.green.shade700,
              ),
            _Row(
              label: 'Total payé',
              value: formatXaf(f.totalPaid),
              bold: true,
            ),
            if (f.collection != null)
              _Row(
                label: 'Encaissement',
                value: f.collection!.isPaid
                    ? 'Confirmé'
                    : (f.collection!.failureMessage ?? f.collection!.status),
                valueColor: f.collection!.isPaid
                    ? Colors.green.shade700
                    : cs.error,
              ),

            const SizedBox(height: 16),

            // ─── Ce que touche le vendeur ─────────────────────────────────────
            _SectionTitle('Restaurant'),
            _Row(label: 'Montant produits', value: formatXaf(f.grossAmount)),
            _Row(
              label: 'Commission (${_formatPercent(f.commissionPercent)} %)',
              value: '− ${formatXaf(f.commissionAmount)}',
            ),
            _Row(
              label: 'Montant à payer',
              value: formatXaf(f.payoutAmount),
              bold: true,
              valueColor: cs.primary,
            ),
            if (f.payoutAccount.configured)
              _Row(
                label: 'Compte Mobile Money',
                value:
                    '${f.payoutAccount.phoneNumber ?? '—'} · ${_providerLabel(f.payoutAccount.provider)}',
              ),

            const SizedBox(height: 16),

            // ─── Ce que garde Lilia Food ──────────────────────────────────────
            _SectionTitle('Lilia Food'),
            _Row(
              label: 'Frais de service client',
              value: formatXaf(f.margin.serviceFee),
            ),
            _Row(
              label: 'Commission restaurant',
              value: formatXaf(f.margin.restaurantCommission),
            ),
            // Les frais du prestataire sont des CHARGES de Lilia Food — jamais
            // déduites du vendeur. Affichés séparément pour que ça se voie.
            _Row(
              label: 'Frais encaissement',
              value: f.margin.collectionFee == null
                  ? 'non communiqué'
                  : '− ${formatXaf(f.margin.collectionFee!)}',
              muted: f.margin.collectionFee == null,
            ),
            _Row(
              label: 'Frais reversement',
              value: f.margin.payoutFee == null
                  ? 'non communiqué'
                  : '− ${formatXaf(f.margin.payoutFee!)}',
              muted: f.margin.payoutFee == null,
            ),
            if (f.margin.netMargin != null)
              _Row(
                label: 'Marge nette',
                value: formatXaf(f.margin.netMargin!),
                bold: true,
              ),

            const SizedBox(height: 20),
            _buildAction(context, f),
          ],
        ),
      ),
    );
  }

  Widget _buildAction(BuildContext context, OrderFinancials f) {
    final cs = Theme.of(context).colorScheme;

    // Un reversement réussi est terminal : il ne reste rien à faire.
    if (f.restaurantPaid) {
      return _Banner(
        icon: Icons.check_circle,
        color: Colors.green.shade700,
        title: 'Restaurant payé',
        message: f.payout?.completedAt != null
            ? '${formatXaf(f.payout!.amount)} versés le ${_formatDate(f.payout!.completedAt!)}.'
            : '${formatXaf(f.payoutAmount)} versés.',
      );
    }

    final payout = f.payout;

    if (payout?.status == PayoutStatus.pending) {
      return _Banner(
        icon: Icons.hourglass_top,
        color: cs.tertiary,
        title: 'Paiement du restaurant en cours',
        message:
            'Le prestataire traite le virement. Le statut se mettra à jour '
            'automatiquement — ne relancez pas.',
      );
    }

    if (payout?.status == PayoutStatus.failed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Banner(
            icon: Icons.error_outline,
            color: cs.error,
            title: 'Paiement échoué',
            message: payout?.failureMessage ??
                payout?.failureCode ??
                'Le prestataire a refusé le virement.',
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _submitting ? null : () => _confirmAndSend(f, retry: true),
            icon: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            label: const Text('Réessayer le paiement'),
          ),
        ],
      );
    }

    if (!f.eligibility.eligible) {
      final missingAccount = f.eligibility.code ==
          PayoutIneligibility.vendorPayoutAccountMissing;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Banner(
            icon: missingAccount ? Icons.phone_disabled : Icons.info_outline,
            color: missingAccount ? cs.error : cs.outline,
            title: 'Paiement impossible pour l’instant',
            // Le message vient du serveur : il porte l'action à mener.
            message: f.eligibility.reason ??
                'Cette commande n’est pas encore éligible au paiement du restaurant.',
          ),
          if (missingAccount) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _showPayoutAccountSheet(f),
              icon: const Icon(Icons.edit),
              label: const Text('Configurer le compte Mobile Money'),
            ),
          ],
        ],
      );
    }

    return FilledButton.icon(
      onPressed: _submitting ? null : () => _confirmAndSend(f),
      icon: _submitting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.send),
      label: Text('Payer le restaurant · ${formatXaf(f.payoutAmount)}'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  /// Confirmation explicite avant d'envoyer de l'argent.
  Future<void> _confirmAndSend(
    OrderFinancials f, {
    bool retry = false,
  }) async {
    final noteController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(retry ? 'Réessayer le paiement' : 'Payer le restaurant'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vous allez envoyer ${formatXaf(f.payoutAmount)} à '
              '${f.restaurantName}.',
              style: Theme.of(dialogContext).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            _Row(
              label: 'Numéro',
              value:
                  '${f.payoutAccount.phoneNumber ?? '—'} · ${_providerLabel(f.payoutAccount.provider)}',
            ),
            _Row(
              label: 'Commission retenue',
              value:
                  '${formatXaf(f.commissionAmount)} (${_formatPercent(f.commissionPercent)} %)',
            ),
            const SizedBox(height: 12),
            Text(
              'Cette opération est irréversible : un virement Mobile Money ne '
              'peut pas être annulé.',
              style: Theme.of(dialogContext).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLength: 300,
              decoration: const InputDecoration(
                labelText: 'Note (facultatif)',
                helperText: 'Tracée dans le journal d’audit',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirmer le paiement'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);
    final repo = ref.read(adminOperationsRepositoryProvider);
    final note = noteController.text.trim();

    try {
      if (retry) {
        await repo.retryPayout(widget.orderId, note: note.isEmpty ? null : note);
      } else {
        await repo.requestPayout(widget.orderId, note: note.isEmpty ? null : note);
      }
      if (!mounted) return;
      _snack('Paiement envoyé — le statut se mettra à jour automatiquement.');
    } on ApiException catch (e) {
      if (!mounted) return;
      // Le backend a refusé : son message porte le motif exact (déjà payé,
      // compte manquant, commande annulée…). On l'affiche tel quel.
      _snack(e.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      _snack('Le paiement n’a pas pu être envoyé.', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
      // On relit l'état réel plutôt que de le supposer : un échec côté
      // prestataire a pu créer une ligne FAILED.
      ref.invalidate(orderFinancialsProvider(orderId: widget.orderId));
    }
  }

  /// Saisie du compte Mobile Money de reversement du vendeur.
  Future<void> _showPayoutAccountSheet(OrderFinancials f) async {
    final phoneController = TextEditingController();
    final nameController = TextEditingController();
    var provider = 'MTN_MOMO';
    final formKey = GlobalKey<FormState>();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
        ),
        child: StatefulBuilder(
          builder: (innerContext, setSheetState) => Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compte de reversement — ${f.restaurantName}',
                  style: Theme.of(innerContext).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Distinct du numéro de contact du commerce : c’est le compte '
                  'sur lequel l’argent sera envoyé.',
                  style: Theme.of(innerContext).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Numéro Mobile Money',
                    hintText: '06 123 45 67',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
                    // Miroir du contrôle serveur : 242 optionnel + 0 + [456] + 7.
                    final ok = RegExp(r'^(242)?0?[456]\d{7}$').hasMatch(digits);
                    return ok ? null : 'Numéro congolais invalide';
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: provider,
                  decoration: const InputDecoration(
                    labelText: 'Opérateur',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'MTN_MOMO',
                      child: Text('MTN Mobile Money'),
                    ),
                    DropdownMenuItem(
                      value: 'AIRTEL_MONEY',
                      child: Text('Airtel Money'),
                    ),
                  ],
                  onChanged: (value) =>
                      setSheetState(() => provider = value ?? 'MTN_MOMO'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Titulaire du compte (facultatif)',
                    helperText: 'Pour vérification avant envoi',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.of(sheetContext).pop(true);
                    }
                  },
                  child: const Text('Enregistrer'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );

    if (saved != true || !mounted) return;

    try {
      await ref.read(adminOperationsRepositoryProvider).updateVendorPayoutAccount(
            restaurantId: f.restaurantId,
            phoneNumber: phoneController.text.trim(),
            provider: provider,
            accountName: nameController.text.trim(),
          );
      if (!mounted) return;
      _snack('Compte de reversement enregistré.');
    } on ApiException catch (e) {
      if (!mounted) return;
      _snack(e.message, isError: true);
    } finally {
      ref.invalidate(orderFinancialsProvider(orderId: widget.orderId));
    }
  }

  void _snack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Présentation
// ════════════════════════════════════════════════════════════════════════════

class _PayoutStatusChip extends StatelessWidget {
  const _PayoutStatusChip({required this.financials});

  final OrderFinancials financials;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (label, color) = switch (financials.payout?.status) {
      PayoutStatus.success => ('Payé', Colors.green.shade700),
      PayoutStatus.pending => ('En cours', cs.tertiary),
      PayoutStatus.failed => ('Échec', cs.error),
      PayoutStatus.cancelled => ('Annulé', cs.outline),
      null => ('Non payé', cs.outline),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.bold = false,
    this.muted = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool bold;
  final bool muted;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = (bold ? theme.textTheme.bodyLarge : theme.textTheme.bodyMedium)
        ?.copyWith(
      fontWeight: bold ? FontWeight.w700 : null,
      color: valueColor ??
          (muted ? theme.colorScheme.outline : null),
      fontStyle: muted ? FontStyle.italic : null,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(value, style: style, textAlign: TextAlign.end),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w600, color: color),
                ),
                const SizedBox(height: 2),
                Text(message, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatPercent(double value) =>
    value == value.roundToDouble() ? value.round().toString() : value.toString();

String _providerLabel(String? code) => switch (code) {
      'MTN_MOMO' => 'MTN MoMo',
      'AIRTEL_MONEY' => 'Airtel Money',
      _ => '—',
    };

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
    'à ${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}';

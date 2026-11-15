import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lilia_admin/theme/lilia_tokens.dart';

import '../../../../models/delivery_arbitration.dart';
import '../../../../models/order.dart';
import '../../data/order_controller.dart';

/// Ce que l'ADMIN a décidé dans [DeliveryArbitrationDialog].
typedef DeliveryArbitrationRequest = ({
  DeliveryArbitrationReason reason,
  String? note,
  int? voucherAmountXaf,
});

/// 15/11/2026 — clôture d'une livraison par l'ADMIN, sans le livreur.
///
/// La commande passe « livrée », le versement du vendeur s'ouvre, le client
/// n'est pas remboursé et ne gagne pas de points : le dialogue le dit, exige
/// un motif (liste fermée du serveur) et propose un avoir facultatif.
class DeliveryArbitrationDialog extends StatefulWidget {
  const DeliveryArbitrationDialog({super.key, required this.orderTotal});

  /// Plafond de l'avoir : le serveur refuse au-delà du total payé.
  final num orderTotal;

  @override
  State<DeliveryArbitrationDialog> createState() =>
      _DeliveryArbitrationDialogState();
}

class _DeliveryArbitrationDialogState extends State<DeliveryArbitrationDialog> {
  DeliveryArbitrationReason? _reason;
  final _note = TextEditingController();
  final _voucher = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    _voucher.dispose();
    super.dispose();
  }

  ({bool ok, int? amount}) get _voucherAmount =>
      parseVoucherAmount(_voucher.text, widget.orderTotal);

  bool get _complete =>
      _reason != null && _reason!.acceptsNote(_note.text) && _voucherAmount.ok;

  @override
  Widget build(BuildContext context) {
    final voucherInvalid = !_voucherAmount.ok;
    return AlertDialog(
      title: const Text('Clôturer la livraison ?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'La commande passera « livrée » sans le livreur. Le client '
              'n’est pas remboursé et ne gagne pas de points ; le versement '
              'du vendeur sera ouvert. Le motif est journalisé.',
            ),
            const SizedBox(height: 8),
            RadioGroup<DeliveryArbitrationReason>(
              groupValue: _reason,
              onChanged: (value) => setState(() => _reason = value),
              child: Column(
                children: DeliveryArbitrationReason.values
                    .map(
                      (r) => RadioListTile<DeliveryArbitrationReason>(
                        value: r,
                        title: Text(r.label),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    )
                    .toList(),
              ),
            ),
            TextField(
              key: const Key('delivery-arbitration-note'),
              controller: _note,
              maxLength: 300,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: _reason == DeliveryArbitrationReason.other
                    ? 'Précision (obligatoire)'
                    : 'Précision (facultatif)',
              ),
            ),
            TextField(
              key: const Key('delivery-arbitration-voucher'),
              controller: _voucher,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Avoir offert au client (FCFA, facultatif)',
                errorText: voucherInvalid
                    ? 'Entre $voucherMinXaf et $voucherMaxXaf FCFA, '
                        'sans dépasser le total payé.'
                    : null,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Retour'),
        ),
        FilledButton(
          key: const Key('delivery-arbitration-confirm'),
          onPressed: _complete
              ? () {
                  final note = _note.text.trim();
                  Navigator.pop<DeliveryArbitrationRequest>(context, (
                    reason: _reason!,
                    note: note.isEmpty ? null : note,
                    voucherAmountXaf: _voucherAmount.amount,
                  ));
                }
              : null,
          child: const Text('Clôturer'),
        ),
      ],
    );
  }
}

/// Ouvre le dialogue, exécute la clôture et en rend compte. Le code de
/// l'avoir s'affiche dans un dialogue (copiable) : le push au client peut ne
/// pas arriver, l'opérateur le dicte alors au téléphone.
Future<void> runDeliveryArbitration(
  BuildContext context,
  WidgetRef ref,
  Order order,
) async {
  final request = await showDialog<DeliveryArbitrationRequest>(
    context: context,
    builder: (_) => DeliveryArbitrationDialog(orderTotal: order.total),
  );
  if (request == null || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  try {
    final voucher = await ref
        .read(restaurantOrdersProvider(null, '').notifier)
        .arbitrateDelivery(
          order.id,
          reason: request.reason,
          note: request.note,
          voucherAmountXaf: request.voucherAmountXaf,
        );
    ref.invalidate(restaurantOrdersProvider);
    ref.invalidate(staffOrderProvider(order.id));
    if (voucher != null && context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Livraison clôturée'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Avoir de ${voucher.amountXaf} FCFA offert au client :'),
              const SizedBox(height: 8),
              SelectableText(
                voucher.code,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Clipboard.setData(ClipboardData(text: voucher.code)),
              child: const Text('Copier le code'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Livraison clôturée — versement du vendeur ouvert'),
          backgroundColor: LiliaColors.green700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (e) {
    // Un échec ne dit pas que rien n'a été écrit (timeout après commit) :
    // la liste et la fiche se relisent sur le serveur.
    ref.invalidate(restaurantOrdersProvider);
    ref.invalidate(staffOrderProvider(order.id));
    messenger.showSnackBar(
      SnackBar(
        content: Text('Erreur : $e'),
        backgroundColor: LiliaColors.red500,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

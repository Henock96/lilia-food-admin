import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../models/admin_payment.dart';

final _xaf = NumberFormat.decimalPattern('fr_FR');

/// Lot 3 (ADM-10) — confirmer un virement manuel n'est plus un seul appui.
///
/// Confirmer déclare la commande payée et lance sa préparation : un appui
/// égaré sur la mauvaise ligne valait un faux encaissement. Le dialogue
/// remet sous les yeux le montant, le numéro et la commande, et exige une
/// case cochée — « j'ai retrouvé ce virement » — avant d'activer le bouton.
///
/// Rend `true` si l'administrateur confirme.
Future<bool> confirmManualPaymentDialog(
  BuildContext context,
  AdminPayment payment,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => _ManualPaymentConfirmDialog(payment: payment),
  );
  return confirmed ?? false;
}

class _ManualPaymentConfirmDialog extends StatefulWidget {
  const _ManualPaymentConfirmDialog({required this.payment});

  final AdminPayment payment;

  @override
  State<_ManualPaymentConfirmDialog> createState() =>
      _ManualPaymentConfirmDialogState();
}

class _ManualPaymentConfirmDialogState
    extends State<_ManualPaymentConfirmDialog> {
  bool _found = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.payment;
    final amount = '${_xaf.format(p.amount)} FCFA';
    final order = p.order;
    return AlertDialog(
      title: const Text('Confirmer l’encaissement ?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(amount, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Depuis le ${p.phoneNumber}'),
          if (order != null) ...[
            if (order.clientNom != null) Text('Client : ${order.clientNom}'),
            if (order.restaurantNom != null)
              Text('Vendeur : ${order.restaurantNom}'),
          ],
          const SizedBox(height: 12),
          const Text(
            'La commande sera déclarée payée et partira en préparation. '
            'Ce geste ne s’annule pas.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _found,
            onChanged: (v) => setState(() => _found = v ?? false),
            title: Text(
              'J’ai retrouvé un virement de $amount depuis ce numéro.',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _found ? () => Navigator.of(context).pop(true) : null,
          child: Text('Confirmer $amount'),
        ),
      ],
    );
  }
}

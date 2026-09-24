import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../models/order.dart';
import '../../../../models/order_actions.dart';
import '../../../../models/role.dart';
import '../../../../models/vendor_rejection_reason.dart';

/// Demande née d'un geste, avec ce que ce geste exige.
class OrderActionRequest {
  const OrderActionRequest(
    this.action, {
    this.prepMinutes,
    this.reason,
    this.note,
  });

  final OrderAction action;

  /// Accepter : temps de préparation annoncé au client.
  final int? prepMinutes;

  /// Refuser : motif en liste fermée, précision facultative.
  final VendorRejectionReason? reason;
  final String? note;
}

/// Gestes possibles sur une commande (Phase 3, F3-01 — règle R1).
///
/// Partagé par la liste et le détail : deux écrans qui portaient chacun leur
/// copie de la matrice de transitions, et qui avaient divergé. Il n'affiche
/// QUE ce que le serveur publie (`resolveOrderActions`), recueille ce que le
/// geste exige (temps de préparation, motif, confirmation) et rend une
/// [OrderActionRequest] — il ne parle pas au réseau lui-même.
class OrderActionsPanel extends StatelessWidget {
  const OrderActionsPanel({
    super.key,
    required this.order,
    required this.role,
    required this.onAction,
    this.compact = false,
  });

  final Order order;
  final Role role;
  final Future<void> Function(OrderActionRequest request) onAction;

  /// Liste : boutons en ligne. Détail : boutons pleine largeur.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final actions = resolveOrderActions(order, role);
    if (actions.isEmpty) return const SizedBox.shrink();

    final buttons = actions.map((action) {
      final look = orderActionLook(action);
      final button = ElevatedButton.icon(
        onPressed: () => _handle(context, action),
        style: ElevatedButton.styleFrom(
          backgroundColor: look.color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            vertical: compact ? 8 : 14,
            horizontal: compact ? 12 : 16,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: Icon(look.icon, size: compact ? 18 : 22),
        label: Text(
          look.label,
          style: TextStyle(fontSize: compact ? 13 : 15, fontWeight: FontWeight.w600),
        ),
      );
      return compact
          ? button
          : Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(width: double.infinity, child: button),
            );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (order.status == OrderStatus.payer && order.acceptDeadlineAt != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AcceptDeadlineBadge(deadline: order.acceptDeadlineAt!),
          ),
        if (compact)
          Wrap(spacing: 8, runSpacing: 8, children: buttons)
        else
          ...buttons,
      ],
    );
  }

  Future<void> _handle(BuildContext context, OrderAction action) async {
    switch (action) {
      case OrderAction.accept:
        final minutes = await showDialog<int>(
          context: context,
          builder: (_) => const PrepTimeDialog(),
        );
        if (minutes != null) {
          await onAction(OrderActionRequest(action, prepMinutes: minutes));
        }
      case OrderAction.reject:
        final rejection = await showDialog<OrderActionRequest>(
          context: context,
          builder: (_) => const RejectOrderDialog(),
        );
        if (rejection != null) await onAction(rejection);
      case OrderAction.cancel:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Annuler la commande ?'),
            content: const Text(
              'Cette action est irréversible. Le client sera notifié.',
            ),
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
        if (confirmed == true) await onAction(OrderActionRequest(action));
      case OrderAction.startPreparation:
      case OrderAction.markReady:
      case OrderAction.handOver:
        await onAction(OrderActionRequest(action));
    }
  }
}

/// Libellé, icône et couleur d'un geste — partagés par les deux écrans.
({String label, IconData icon, Color color}) orderActionLook(OrderAction action) =>
    switch (action) {
      OrderAction.accept => (label: 'Accepter', icon: Icons.check, color: Colors.green),
      OrderAction.reject => (label: 'Refuser', icon: Icons.close, color: Colors.red),
      OrderAction.startPreparation =>
        (label: 'En préparation', icon: Icons.restaurant, color: Colors.indigo),
      OrderAction.markReady =>
        (label: 'Prête', icon: Icons.check_circle, color: Colors.green),
      OrderAction.handOver =>
        (label: 'Remise au client', icon: Icons.shopping_bag, color: Colors.teal),
      OrderAction.cancel => (label: 'Annuler', icon: Icons.cancel, color: Colors.red),
    };

/// Choix du temps de préparation annoncé au client.
class PrepTimeDialog extends StatefulWidget {
  const PrepTimeDialog({super.key});

  /// Bornes serveur : 5 à 120 minutes.
  static const choices = [10, 20, 30, 45];

  @override
  State<PrepTimeDialog> createState() => _PrepTimeDialogState();
}

class _PrepTimeDialogState extends State<PrepTimeDialog> {
  int _minutes = 20;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Temps de préparation'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Le client verra l’heure à laquelle sa commande sera prête.'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: PrepTimeDialog.choices
                .map(
                  (m) => ChoiceChip(
                    label: Text('$m min'),
                    selected: _minutes == m,
                    onSelected: (_) => setState(() => _minutes = m),
                  ),
                )
                .toList(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Retour')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _minutes),
          child: const Text('Accepter la commande'),
        ),
      ],
    );
  }
}

/// Refus motivé : motif obligatoire (liste fermée), précision facultative.
class RejectOrderDialog extends StatefulWidget {
  const RejectOrderDialog({super.key});

  @override
  State<RejectOrderDialog> createState() => _RejectOrderDialogState();
}

class _RejectOrderDialogState extends State<RejectOrderDialog> {
  VendorRejectionReason? _reason;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Refuser la commande ?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Le client sera remboursé automatiquement.'),
            const SizedBox(height: 8),
            RadioGroup<VendorRejectionReason>(
              groupValue: _reason,
              onChanged: (value) => setState(() => _reason = value),
              child: Column(
                children: VendorRejectionReason.values
                    .map(
                      (r) => RadioListTile<VendorRejectionReason>(
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
              controller: _note,
              maxLength: 200,
              decoration: const InputDecoration(labelText: 'Précision (facultatif)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Retour')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: _reason == null
              ? null
              : () => Navigator.pop(
                    context,
                    OrderActionRequest(
                      OrderAction.reject,
                      reason: _reason,
                      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
                    ),
                  ),
          child: const Text('Refuser la commande'),
        ),
      ],
    );
  }
}

/// « À accepter avant 12:08 — 5 min » : l'échéance après laquelle la commande
/// est annulée et le client remboursé. Rafraîchi toutes les 15 s.
class AcceptDeadlineBadge extends StatefulWidget {
  const AcceptDeadlineBadge({super.key, required this.deadline, this.now});

  final DateTime deadline;

  /// Horloge injectable pour les tests.
  final DateTime Function()? now;

  @override
  State<AcceptDeadlineBadge> createState() => _AcceptDeadlineBadgeState();
}

class _AcceptDeadlineBadgeState extends State<AcceptDeadlineBadge> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = (widget.now ?? DateTime.now)();
    final left = widget.deadline.difference(now);
    final local = widget.deadline.toLocal();
    final hhmm =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    final expired = left.isNegative;
    final urgent = left.inMinutes < 3;
    final color = expired || urgent ? Colors.red : Colors.orange;
    final text = expired
        ? 'Délai dépassé — la commande va être annulée'
        : 'À accepter avant $hhmm — ${left.inMinutes < 1 ? 'moins d’1 min' : '${left.inMinutes} min'}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

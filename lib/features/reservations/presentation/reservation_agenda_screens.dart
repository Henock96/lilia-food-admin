import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:lilia_admin/core/network/api_exception.dart';
import 'package:lilia_admin/core/utils/date_format.dart';
import 'package:lilia_admin/features/home/data/order_controller.dart';
import 'package:lilia_admin/features/reservations/data/reservation_agenda_repository.dart';
import 'package:lilia_admin/features/reservations/data/reservation_settings_repository.dart';
import 'package:lilia_admin/features/reservations/presentation/reservation_agenda_providers.dart';
import 'package:lilia_admin/features/reservations/presentation/reservation_settings_providers.dart';

final _day = DateFormat('EEEE d MMMM', 'fr_FR');
final _hour = DateFormat('HH:mm', 'fr_FR');
final _dayHour = DateFormat('d MMM, HH:mm', 'fr_FR');
final _xaf = NumberFormat.decimalPattern('fr_FR');
final _isoDay = DateFormat('yyyy-MM-dd');

String _money(int v) => '${_xaf.format(v)} FCFA';

/// Heure et jour **de Brazzaville**, quel que soit le fuseau du téléphone.
String _h(DateTime instant) => _hour.format(toBrazzaville(instant));
String _dayOf(DateTime instant) =>
    _capitalize(_day.format(toBrazzaville(instant)));

/// Jour civil envoyé au serveur (`AAAA-MM-JJ`). [day] est déjà un jour de
/// Brazzaville (voir `_brazzavilleToday`).
String agendaDateKey(DateTime day) => _isoDay.format(day);

/// Aujourd'hui à Brazzaville, comme jour civil (minuit).
DateTime _brazzavilleToday() {
  final t = toBrazzaville(DateTime.now());
  return DateTime(t.year, t.month, t.day);
}

String _capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

String _errorText(Object error) =>
    error is ApiException ? reservationErrorMessage(error) : '$error';

Color _statusColor(String status) => switch (status) {
  'PENDING' => Colors.orange.shade700,
  'AWAITING_PAYMENT' => Colors.blue.shade700,
  'CONFIRMED' => Colors.green.shade700,
  'HONORED' => Colors.teal.shade700,
  'NO_SHOW' => Colors.red.shade700,
  _ => Colors.grey.shade600,
};

/// Lot 4 (4C) — agenda des réservations du restaurant : un jour à la fois,
/// et en tête les demandes à traiter, tous jours confondus (elles expirent
/// sans réponse : c'est ce que le vendeur ne doit pas manquer).
class ReservationAgendaScreen extends ConsumerStatefulWidget {
  const ReservationAgendaScreen({super.key, this.initialDay});

  final DateTime? initialDay;

  @override
  ConsumerState<ReservationAgendaScreen> createState() =>
      _ReservationAgendaScreenState();
}

class _ReservationAgendaScreenState
    extends ConsumerState<ReservationAgendaScreen> {
  late DateTime _selected = _dateOnly(widget.initialDay ?? _brazzavilleToday());

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  void _shift(int days) => setState(
    () => _selected = _dateOnly(_selected.add(Duration(days: days))),
  );

  Future<void> _pickDay() async {
    final today = _brazzavilleToday();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selected,
      firstDate: today.subtract(const Duration(days: 60)),
      lastDate: today.add(const Duration(days: 120)),
    );
    if (picked != null) setState(() => _selected = _dateOnly(picked));
  }

  Future<void> _refresh() {
    ref.invalidate(pendingReservationsProvider);
    return ref.refresh(
      reservationAgendaProvider(agendaDateKey(_selected)).future,
    );
  }

  @override
  Widget build(BuildContext context) {
    final agenda = ref.watch(reservationAgendaProvider(agendaDateKey(_selected)));
    final pending = ref.watch(pendingReservationsProvider);
    final isToday = _selected == _brazzavilleToday();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Réservations'),
        actions: [
          IconButton(
            tooltip: 'Configurer les réservations',
            icon: const Icon(Icons.tune),
            onPressed: () => context.pushNamed('reservation-settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            if (pending.value case final p? when p.items.isNotEmpty)
              _PendingBanner(page: p),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Jour précédent',
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _shift(-1),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: _pickDay,
                      child: Text(
                        isToday
                            ? 'Aujourd’hui'
                            : _capitalize(_day.format(_selected)),
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Jour suivant',
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _shift(1),
                  ),
                ],
              ),
            ),
            if (!isToday)
              Center(
                child: TextButton(
                  onPressed: () =>
                      setState(() => _selected = _brazzavilleToday()),
                  child: const Text('Revenir à aujourd’hui'),
                ),
              ),
            switch (agenda) {
              // L'erreur d'abord : la relance automatique de Riverpod
              // laisserait sinon la roue tourner indéfiniment.
              AsyncValue(hasError: true, hasValue: false, :final error?) =>
                _Message(text: _errorText(error), icon: Icons.error_outline),
              AsyncValue(:final value?) when value.items.isEmpty =>
                const _Message(
                  text: 'Aucune réservation ce jour-là.',
                  icon: Icons.event_available_outlined,
                ),
              AsyncValue(:final value?) => Column(
                children: [
                  for (final r in value.items) _ReservationTile(r: r),
                  if (value.total > value.items.length)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        '${value.total - value.items.length} réservation(s) '
                        'de plus ce jour-là ne sont pas affichées.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
              _ => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            },
          ],
        ),
      ),
    );
  }
}

class _PendingBanner extends StatelessWidget {
  const _PendingBanner({required this.page});

  final ReservationAgendaPage page;

  @override
  Widget build(BuildContext context) {
    final n = page.total;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      color: Colors.orange.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              n > 1 ? '$n demandes à traiter' : '1 demande à traiter',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.orange.shade900,
              ),
            ),
          ),
          for (final r in page.items) _ReservationTile(r: r, showDay: true),
        ],
      ),
    );
  }
}

class _ReservationTile extends StatelessWidget {
  const _ReservationTile({required this.r, this.showDay = false});

  final VendorReservation r;
  final bool showDay;

  @override
  Widget build(BuildContext context) {
    final who = r.customer.nom ?? r.customer.phone ?? 'Client';
    final when = showDay
        ? _dayHour.format(toBrazzaville(r.arrivalAt))
        : _h(r.arrivalAt);
    final color = _statusColor(r.status);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Text(
          '${r.partySize}',
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ),
      title: Text('$when · ${r.space.label}'),
      subtitle: Text(
        '$who\n${reservationStatusLabel(r.status)}'
        '${r.items.isEmpty ? '' : ' · précommande'}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.pushNamed(
        'reservation-detail',
        pathParameters: {'id': r.id},
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      children: [
        Icon(icon, size: 40, color: Colors.grey),
        const SizedBox(height: 12),
        Text(text, textAlign: TextAlign.center),
      ],
    ),
  );
}

/// Fiche d'une réservation : client, table, précommande, paiement, échéances
/// et les seuls gestes que le serveur publie (`allowedActions`).
class ReservationDetailScreen extends ConsumerStatefulWidget {
  const ReservationDetailScreen({super.key, required this.reservationId});

  final String reservationId;

  @override
  ConsumerState<ReservationDetailScreen> createState() =>
      _ReservationDetailScreenState();
}

class _ReservationDetailScreenState
    extends ConsumerState<ReservationDetailScreen> {
  bool _busy = false;

  ReservationAgendaRepository get _repo =>
      ref.read(reservationAgendaRepositoryProvider);

  /// Exécute un geste. Quelle qu'en soit l'issue, la fiche et l'agenda sont
  /// relus : un refus (409, la réservation a changé entre-temps) montre
  /// ainsi l'état réel au lieu d'un bouton qui ne marchera plus.
  Future<void> _run(
    Future<VendorReservation> Function() gesture,
    String done,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await gesture();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(_errorText(e))));
    } finally {
      ref.invalidate(vendorReservationProvider(widget.reservationId));
      ref.invalidate(reservationAgendaProvider);
      ref.invalidate(pendingReservationsProvider);
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decline(VendorReservation r) async {
    final reason = await _pickReason(
      context,
      title: 'Refuser la demande',
      reasons: reservationDeclineReasons,
    );
    if (reason == null) return;
    await _run(() => _repo.decline(r.id, reason), 'Demande refusée.');
  }

  Future<void> _cancel(VendorReservation r) async {
    final reason = await _pickReason(
      context,
      title: 'Annuler la réservation',
      reasons: reservationVendorCancelReasons,
      warning: r.payment != null
          ? 'Le client sera intégralement remboursé.'
          : null,
    );
    if (reason == null) return;
    await _run(() => _repo.cancel(r.id, reason), 'Réservation annulée.');
  }

  Future<void> _noShow(VendorReservation r) async {
    final ok = await _confirm(
      context,
      title: 'Client absent ?',
      body:
          'À déclarer seulement si le client n’est pas venu. Vous pourrez '
          'retirer cette absence pendant 6 heures en cas d’erreur.',
      action: 'Déclarer absent',
    );
    if (!ok) return;
    await _run(() => _repo.markNoShow(r.id), 'Absence enregistrée.');
  }

  Future<void> _reassign(VendorReservation r) async {
    final ReservationState settings;
    try {
      settings = await ref.read(myReservationSettingsProvider.future);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tables indisponibles : ${_errorText(e)}')),
        );
      }
      return;
    }
    final spaces = [
      for (final s in settings.config?.spaces ?? const <ReservationSpace>[])
        if (s.archivedAt == null &&
            s.kind == r.space.kind &&
            s.id != r.space.id)
          s,
    ];
    if (!mounted) return;
    if (spaces.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune autre table de ce type.')),
      );
      return;
    }
    final spaceId = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Déplacer vers…')),
            for (final s in spaces)
              ListTile(
                leading: const Icon(Icons.table_restaurant_outlined),
                title: Text(s.label),
                subtitle: s.maxGuests != null
                    ? Text('${s.minGuests ?? 1} à ${s.maxGuests} personnes')
                    : null,
                onTap: () => Navigator.of(context).pop(s.id),
              ),
          ],
        ),
      ),
    );
    if (spaceId == null) return;
    await _run(
      () => _repo.reassign(r.id, spaceId),
      'Table changée ; le client est prévenu.',
    );
  }

  /// La commande liée porte la préparation et la remise par code : relue,
  /// elle s'ouvre dans la fiche commande existante (qui exige l'objet).
  Future<void> _openOrder(String orderId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final order = await ref.read(staffOrderProvider(orderId).future);
      if (!mounted) return;
      await context.pushNamed(
        'reservation-order',
        pathParameters: {'id': widget.reservationId, 'orderId': orderId},
        extra: order,
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(_errorText(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vendorReservationProvider(widget.reservationId));
    return Scaffold(
      appBar: AppBar(title: const Text('Réservation')),
      body: switch (state) {
        AsyncValue(hasError: true, hasValue: false, :final error?) =>
          _Message(text: _errorText(error), icon: Icons.error_outline),
        AsyncValue(:final value?) => RefreshIndicator(
          onRefresh: () => ref.refresh(
            vendorReservationProvider(widget.reservationId).future,
          ),
          child: ReservationDetailView(
            r: value,
            busy: _busy,
            onAccept: () =>
                _run(() => _repo.accept(value.id), 'Demande acceptée.'),
            onDecline: () => _decline(value),
            onCancel: () => _cancel(value),
            onNoShow: () => _noShow(value),
            onUndoNoShow: () =>
                _run(() => _repo.undoNoShow(value.id), 'Absence retirée.'),
            onReassign: () => _reassign(value),
            onOpenOrder: _openOrder,
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// Contenu de la fiche, sans état : testable seul (gestes = verdict serveur).
class ReservationDetailView extends StatelessWidget {
  const ReservationDetailView({
    super.key,
    required this.r,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
    required this.onCancel,
    required this.onNoShow,
    required this.onUndoNoShow,
    required this.onReassign,
    required this.onOpenOrder,
  });

  final VendorReservation r;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onCancel;
  final VoidCallback onNoShow;
  final VoidCallback onUndoNoShow;
  final VoidCallback onReassign;
  final void Function(String orderId) onOpenOrder;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = _statusColor(r.status);
    final reason = r.declineReason ?? r.cancelReason;
    final payment = r.payment;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reservationStatusLabel(r.status),
                style: text.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (r.status == 'PENDING' && r.responseDeadlineAt != null)
                Text(
                  'Répondez avant ${_h(r.responseDeadlineAt!)} : '
                  'sans réponse, la demande expire.',
                ),
              if (r.status == 'AWAITING_PAYMENT' &&
                  r.paymentDeadlineAt != null)
                Text(
                  'Le client doit payer avant '
                  '${_h(r.paymentDeadlineAt!)}.',
                ),
              if (r.status == 'CONFIRMED')
                const Text(
                  'À l’arrivée du client, ouvrez la commande liée : '
                  'préparez-la, marquez-la prête, puis saisissez le code '
                  'que le client vous montre.',
                ),
              if (reason != null)
                Text('Motif : ${reservationReasonLabel(reason)}'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Line(
          icon: Icons.event,
          text:
              '${_dayOf(r.arrivalAt)} à ${_h(r.arrivalAt)}'
              '${r.endsAt != null ? ' (jusqu’à ${_h(r.endsAt!)})' : ''}',
        ),
        _Line(
          icon: Icons.group_outlined,
          text: '${r.partySize} personne${r.partySize > 1 ? 's' : ''}',
        ),
        _Line(icon: Icons.table_restaurant_outlined, text: r.space.label),
        const Divider(height: 32),
        Text('Client', style: text.titleSmall),
        if (r.customer.hidden)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('Coordonnées masquées pour cette réservation.'),
          )
        else ...[
          if (r.customer.nom != null)
            _Line(icon: Icons.person_outline, text: r.customer.nom!),
          if (r.customer.phone != null)
            _Line(
              icon: Icons.phone_outlined,
              text: r.customer.phone!,
              onTap: () {
                Clipboard.setData(ClipboardData(text: r.customer.phone!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Numéro copié.')),
                );
              },
            ),
        ],
        if (r.note != null) ...[
          const SizedBox(height: 8),
          Text('Note du client', style: text.titleSmall),
          Text(r.note!),
        ],
        const Divider(height: 32),
        Text('Précommande', style: text.titleSmall),
        if (r.items.isEmpty)
          const Text('Aucun plat précommandé.')
        else
          for (final i in r.items)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_itemLine(i)),
            ),
        if (payment != null) ...[
          const SizedBox(height: 12),
          _Amount(label: 'Plats', value: payment.subTotal),
          _Amount(label: 'Frais de service', value: payment.serviceFee),
          _Amount(
            label: 'Total payé par le client',
            value: payment.total,
            bold: true,
          ),
          if (payment.priceChanged && payment.indicativeSubTotal != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Le prix des plats a changé depuis la demande '
                '(${_money(payment.indicativeSubTotal!)} annoncés).',
                style: TextStyle(color: Colors.orange.shade800),
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => onOpenOrder(payment.orderId),
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('Ouvrir la commande (préparation, code)'),
          ),
        ],
        const SizedBox(height: 24),
        if (busy) const LinearProgressIndicator(),
        _gesture(VendorReservationAction.accept, 'Accepter', onAccept,
            primary: true),
        _gesture(VendorReservationAction.decline, 'Refuser', onDecline,
            danger: true),
        _gesture(
          VendorReservationAction.reassign,
          'Changer de table',
          onReassign,
        ),
        _gesture(VendorReservationAction.noShow, 'Client absent', onNoShow,
            danger: true),
        _gesture(
          VendorReservationAction.undoNoShow,
          'Retirer l’absence',
          onUndoNoShow,
        ),
        _gesture(
          VendorReservationAction.cancel,
          'Annuler la réservation',
          onCancel,
          danger: true,
        ),
      ],
    );
  }

  static String _itemLine(ReservationItem i) {
    final variant = i.variantLabel != null ? ' (${i.variantLabel})' : '';
    final options = i.options.isEmpty
        ? ''
        : '\n   + ${i.options.map((o) => o.quantity > 1 ? '${o.quantity} × ${o.name}' : o.name).join(', ')}';
    return '${i.quantity} × ${i.name}$variant$options';
  }

  /// Un geste n'apparaît que si le serveur l'a publié.
  Widget _gesture(
    VendorReservationAction action,
    String label,
    VoidCallback onPressed, {
    bool primary = false,
    bool danger = false,
  }) {
    if (!r.can(action)) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: primary
          ? FilledButton(
              onPressed: busy ? null : onPressed,
              child: Text(label),
            )
          : OutlinedButton(
              style: danger
                  ? OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                    )
                  : null,
              onPressed: busy ? null : onPressed,
              child: Text(label),
            ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text, this.onTap});

  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
          if (onTap != null)
            Icon(Icons.copy, size: 16, color: Colors.grey.shade500),
        ],
      ),
    ),
  );
}

class _Amount extends StatelessWidget {
  const _Amount({required this.label, required this.value, this.bold = false});

  final String label;
  final int value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold ? const TextStyle(fontWeight: FontWeight.w700) : null;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(_money(value), style: style),
        ],
      ),
    );
  }
}

Future<String?> _pickReason(
  BuildContext context, {
  required String title,
  required Map<String, String> reasons,
  String? warning,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  builder: (context) => SafeArea(
    child: ListView(
      shrinkWrap: true,
      children: [
        ListTile(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            [?warning, 'Le client est prévenu du motif.'].join('\n'),
          ),
        ),
        for (final e in reasons.entries)
          ListTile(
            title: Text(e.value),
            onTap: () => Navigator.of(context).pop(e.key),
          ),
      ],
    ),
  ),
);

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Retour'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

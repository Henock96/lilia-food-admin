import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lilia_admin/core/network/api_exception.dart';
import 'package:lilia_admin/features/closures/data/vendor_opening_service.dart';

const _pauses = <(int, String)>[
  (30, '30 min'),
  (60, '1 h'),
  (120, '2 h'),
  (24 * 60, '24 h'),
];

/// Onglet « Fermetures » (F3-03) : pause qui se lève seule, congés datés,
/// jours fériés. Remplace l'interrupteur « Ouvert / Fermé » permanent qu'un
/// vendeur oubliait de relâcher.
class ClosuresTab extends ConsumerWidget {
  final String vendorId;
  const ClosuresTab({super.key, required this.vendorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vendorOpeningProvider(vendorId));
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              e is ApiException
                  ? e.message
                  : 'Impossible de charger les fermetures.',
            ),
            TextButton(
              onPressed: () => ref.invalidate(vendorOpeningProvider(vendorId)),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
      data: (s) => RefreshIndicator(
        onRefresh: () => ref.refresh(vendorOpeningProvider(vendorId).future),
        child: _ClosuresBody(vendorId: vendorId, state: s),
      ),
    );
  }
}

class _ClosuresBody extends ConsumerStatefulWidget {
  final String vendorId;
  final VendorOpeningState state;
  const _ClosuresBody({required this.vendorId, required this.state});

  @override
  ConsumerState<_ClosuresBody> createState() => _ClosuresBodyState();
}

class _ClosuresBodyState extends ConsumerState<_ClosuresBody> {
  bool _busy = false;

  VendorOpeningService get _service => ref.read(vendorOpeningServiceProvider);

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _run(Future<String?> Function() action) async {
    setState(() => _busy = true);
    try {
      final message = await action();
      if (mounted && message != null) _snack(message);
    } on ApiException catch (e) {
      if (mounted) _snack(e.message, error: true);
    } finally {
      ref.invalidate(vendorOpeningProvider(widget.vendorId));
      if (mounted) setState(() => _busy = false);
    }
  }

  String _inFlight(int n) => n == 0
      ? ''
      : ' — $n commande${n > 1 ? 's' : ''} en cours, toujours à servir';

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    // Saisie en heure de Brazzaville (UTC+1), quel que soit le fuseau du
    // téléphone : on construit l'instant UTC correspondant.
    return DateTime.utc(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    ).subtract(const Duration(hours: 1));
  }

  Future<void> _addClosure() async {
    final start = await _pickDateTime(DateTime.now());
    if (start == null) return;
    final end = await _pickDateTime(
      toBrazzaville(start).add(const Duration(days: 1)),
    );
    if (end == null) return;
    await _run(() async {
      final n = await _service.addClosure(
        widget.vendorId,
        startsAt: start,
        endsAt: end,
      );
      return 'Congé enregistré${_inFlight(n)}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  openingSummary(s),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: s.isOpen ? Colors.green.shade700 : cs.onSurface,
                  ),
                ),
                if (s.pausedUntil != null) ...[
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _run(() async {
                            await _service.resume(widget.vendorId);
                            return 'Pause levée';
                          }),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Rouvrir maintenant'),
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Mettre en pause — la boutique rouvre seule à l’échéance.',
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final (minutes, label) in _pauses)
                      OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () => _run(() async {
                                final n = await _service.pause(
                                  widget.vendorId,
                                  minutes,
                                );
                                return 'Boutique en pause${_inFlight(n)}';
                              }),
                        child: Text(label),
                      ),
                  ],
                ),
                const Divider(height: 32),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fermé les jours fériés'),
                  value: s.closedOnHolidays,
                  onChanged: _busy
                      ? null
                      : (v) => _run(() async {
                          await _service.setClosedOnHolidays(
                            widget.vendorId,
                            v,
                          );
                          return null;
                        }),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Congés',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (s.closures.isEmpty)
                  Text(
                    'Aucun congé prévu.',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                for (final c in s.closures)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_busy),
                    title: Text(
                      'Du ${formatBrazzaville(c.startsAt)} au ${formatBrazzaville(c.endsAt)}',
                    ),
                    subtitle: c.reason == null ? null : Text(c.reason!),
                    trailing: IconButton(
                      tooltip: 'Supprimer',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                              await _service.removeClosure(
                                widget.vendorId,
                                c.id,
                              );
                              return 'Congé supprimé';
                            }),
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _addClosure,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un congé'),
                ),
                const SizedBox(height: 4),
                Text(
                  'Heures de Brazzaville. 90 jours au plus par congé.',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

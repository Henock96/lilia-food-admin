import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lilia_admin/features/admin/data/refunds_service.dart';
import 'package:lilia_admin/models/refund.dart';

/// File des remboursements dus aux clients.
///
/// Quand une commande **déjà payée** est annulée, le backend ouvre
/// automatiquement une ligne `Refund` pour le montant réellement encaissé.
/// Avant cet écran, ces lignes n'étaient visibles nulle part : la plateforme
/// savait qu'elle devait de l'argent, et personne ne pouvait le traiter.
///
/// L'ordre est volontairement chronologique croissant (le backend trie ainsi) :
/// c'est une file d'attente, le client qui patiente depuis le plus longtemps
/// passe en premier.
class RefundsScreen extends ConsumerStatefulWidget {
  const RefundsScreen({super.key});

  @override
  ConsumerState<RefundsScreen> createState() => _RefundsScreenState();
}

class _RefundsScreenState extends ConsumerState<RefundsScreen> {
  RefundStatus? _filter = RefundStatus.pending;

  /// Pages au-delà de la première, chargées à la demande.
  ///
  /// La première page reste servie par le provider (elle profite du cache et
  /// du `RefreshIndicator`) ; les suivantes s'accumulent ici. Un changement de
  /// filtre les remet à zéro — elles ne correspondraient plus à rien.
  final List<Refund> _extraPages = [];
  int _lastLoadedPage = 1;
  bool _loadingMore = false;

  void _changeFilter(RefundStatus? value) {
    setState(() {
      _filter = value;
      _extraPages.clear();
      _lastLoadedPage = 1;
    });
  }

  void _resetPagination() {
    _extraPages.clear();
    _lastLoadedPage = 1;
    ref.invalidate(refundsListProvider(_filter));
    ref.invalidate(pendingRefundsCountProvider);
  }

  Future<void> _loadMore() async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final next = await ref
          .read(refundsServiceProvider)
          .list(status: _filter, page: _lastLoadedPage + 1);
      if (!mounted) return;
      setState(() {
        _extraPages.addAll(next.items);
        _lastLoadedPage = next.page;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chargement impossible : $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final refundsAsync = ref.watch(refundsListProvider(_filter));

    return Scaffold(
      appBar: AppBar(title: const Text('Remboursements')),
      body: Column(
        children: [
          _FilterBar(selected: _filter, onChanged: _changeFilter),
          Expanded(
            child: refundsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorState(
                message: error.toString(),
                onRetry: () => ref.invalidate(refundsListProvider(_filter)),
              ),
              data: (page) {
                final refunds = [...page.items, ..._extraPages];
                if (refunds.isEmpty) {
                  return _EmptyState(filter: _filter);
                }

                final remaining = page.total - refunds.length;
                final hasMore = remaining > 0;

                return RefreshIndicator(
                  onRefresh: () async => _resetPagination(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    // +1 pour le pied de liste : il porte soit le bouton
                    // « charger la suite », soit le décompte total. Sans lui,
                    // rien n'indiquait que la file continuait au-delà de
                    // l'écran.
                    itemCount: refunds.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      if (i == refunds.length) {
                        return _ListFooter(
                          shown: refunds.length,
                          total: page.total,
                          hasMore: hasMore,
                          loading: _loadingMore,
                          onLoadMore: _loadMore,
                        );
                      }
                      return _RefundCard(
                        refund: refunds[i],
                        onChanged: _resetPagination,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Pied de liste : dit où l'on en est dans la file, et permet d'aller plus loin.
class _ListFooter extends StatelessWidget {
  const _ListFooter({
    required this.shown,
    required this.total,
    required this.hasMore,
    required this.loading,
    required this.onLoadMore,
  });

  final int shown;
  final int total;
  final bool hasMore;
  final bool loading;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(
            hasMore ? '$shown affichés sur $total' : '$total au total',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (hasMore) ...[
            const SizedBox(height: 8),
            loading
                ? const CircularProgressIndicator()
                : OutlinedButton(
                    onPressed: onLoadMore,
                    child: const Text('Charger la suite'),
                  ),
          ],
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});

  final RefundStatus? selected;
  final ValueChanged<RefundStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Tous'),
            selected: selected == null,
            onSelected: (_) => onChanged(null),
          ),
          const SizedBox(width: 8),
          ...RefundStatus.values.map(
            (s) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(s.label),
                selected: selected == s,
                onSelected: (_) => onChanged(s),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RefundCard extends ConsumerStatefulWidget {
  const _RefundCard({required this.refund, required this.onChanged});

  final Refund refund;
  final VoidCallback onChanged;

  @override
  ConsumerState<_RefundCard> createState() => _RefundCardState();
}

class _RefundCardState extends ConsumerState<_RefundCard> {
  bool _busy = false;

  Future<void> _apply(RefundStatus next) async {
    final notes = await _askNotes(next);
    // `null` = l'admin a fermé la boîte de dialogue. Une chaîne vide est une
    // réponse valide (pas de commentaire), il ne faut pas confondre les deux.
    if (notes == null) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(refundsServiceProvider)
          .updateStatus(widget.refund.id, next, notes: notes);
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Échec : $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Demande un commentaire. Obligatoire sur un refus : refuser un
  /// remboursement sans motif écrit rend le litige ingérable ensuite.
  Future<String?> _askNotes(RefundStatus next) async {
    final controller = TextEditingController();
    final required = next == RefundStatus.rejected;

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(next.label),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 500,
          autofocus: true,
          decoration: InputDecoration(
            hintText: required
                ? 'Motif du refus (obligatoire)'
                : 'Note interne (optionnel) — référence du virement…',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (required && controller.text.trim().isEmpty) return;
              Navigator.of(ctx).pop(controller.text);
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.refund;
    final cs = Theme.of(context).colorScheme;
    final money = NumberFormat.decimalPattern('fr');

    final (color, icon) = switch (r.status) {
      RefundStatus.pending => (Colors.orange, Icons.schedule),
      RefundStatus.processing => (Colors.blue, Icons.sync),
      RefundStatus.completed => (Colors.green, Icons.check_circle),
      RefundStatus.rejected => (Colors.red, Icons.cancel),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  r.status.label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '${money.format(r.amount)} FCFA',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Commande ${r.shortOrderRef}'
              '${r.restaurantNom != null ? ' · ${r.restaurantNom}' : ''}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (r.clientNom != null || r.clientPhone != null) ...[
              const SizedBox(height: 4),
              Text(
                [r.clientNom, r.clientPhone].whereType<String>().join(' · '),
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              '${r.reason} · ${DateFormat('dd/MM à HH:mm').format(r.createdAt.toLocal())}',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
            if (r.notes != null && r.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(r.notes!, style: const TextStyle(fontSize: 13)),
              ),
            ],
            if (r.status.nextStates.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: r.status.nextStates
                    .map(
                      (next) => OutlinedButton(
                        onPressed: _busy ? null : () => _apply(next),
                        child: Text(next.label),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});

  final RefundStatus? filter;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 48, color: cs.outline),
          const SizedBox(height: 12),
          Text(
            filter == RefundStatus.pending
                ? 'Aucun remboursement en attente'
                : 'Aucun remboursement',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}

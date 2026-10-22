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
          // Lot 3 (D-3) — le remboursement se fait sur le web.
          const MaterialBanner(
            key: Key('refunds-web-only-banner'),
            leading: Icon(Icons.info_outline),
            content: Text(
              'Les remboursements se traitent depuis l’admin web : virement '
              'au client, clôture et refus. Cet écran sert à suivre la file.',
            ),
            actions: [SizedBox.shrink()],
          ),
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
                      return _RefundCard(refund: refunds[i]);
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

/// Une ligne de la file, en consultation.
///
/// Lot 3 (ADM-14, décision D-3 du 22/10/2026) — le remboursement est réservé
/// à l'admin web : virement au client (`/execute`) comme clôture déclarative
/// (« Remboursé » / « Refusé »). L'app ne propose plus ces gestes ; marquer
/// « remboursé » depuis le téléphone sans virement, c'est précisément ce que
/// la décision renvoie au poste de travail.
class _RefundCard extends StatelessWidget {
  const _RefundCard({required this.refund});

  final Refund refund;

  @override
  Widget build(BuildContext context) {
    final r = refund;
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
              Row(
                children: [
                  Icon(Icons.computer, size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'À traiter depuis l’admin web.',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                    ),
                  ),
                ],
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

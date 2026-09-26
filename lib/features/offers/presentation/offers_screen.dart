import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lilia_admin/core/network/api_exception.dart';
import 'package:lilia_admin/core/utils/currency.dart';
import 'package:lilia_admin/core/utils/date_format.dart';
import 'package:lilia_admin/features/offers/data/offers_repository.dart';
import 'package:lilia_admin/features/offers/presentation/offer_form_screen.dart';
import 'package:lilia_admin/features/offers/presentation/offers_providers.dart';

/// « Mes offres » (F3-11) — la promotion que le vendeur offre, à ses frais.
///
/// Une seule offre en cours à la fois. Le vendeur voit ce qu'elle lui a coûté
/// jusqu'ici (budget consommé) et peut la mettre en pause ou la terminer. La
/// remise est retenue sur ses versements, commande par commande : c'est dit
/// ici, pour qu'aucun versement plus bas que prévu ne soit une surprise.
class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myOffersProvider);
    final canCreate = async.hasValue &&
        async.requireValue.enabled &&
        async.requireValue.current == null;

    return Scaffold(
      appBar: AppBar(title: const Text('Mes offres')),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              key: const Key('offers-new'),
              onPressed: () async {
                final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const OfferFormScreen()),
                );
                if (created == true) ref.invalidate(myOffersProvider);
              },
              icon: const Icon(Icons.local_offer_outlined),
              label: const Text('Nouvelle offre'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myOffersProvider.future),
        // Riverpod 3 garde l'erreur pendant la relance automatique : on lit
        // `hasError`, jamais le type de l'état (sinon spinner sans fin).
        child: async.hasValue
            ? _Body(offers: async.requireValue)
            : async.hasError
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Text(async.error.toString(), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      Center(
                        child: FilledButton(
                          onPressed: () => ref.invalidate(myOffersProvider),
                          child: const Text('Réessayer'),
                        ),
                      ),
                    ],
                  )
                : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.offers});

  final MyOffers offers;

  @override
  Widget build(BuildContext context) {
    final current = offers.current;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        if (!offers.enabled)
          const _Notice(
            key: Key('offers-disabled'),
            text: 'Les offres boutique ne sont pas encore ouvertes sur '
                'Lilia Food. Vous pourrez bientôt en publier ici.',
          ),
        if (current != null)
          _CurrentOffer(offer: current)
        else if (offers.enabled)
          const _Notice(
            key: Key('offers-empty'),
            text: 'Aucune offre en cours. Une offre attire les clients : '
                '« −10 % sur toute la boutique » s’affiche sur votre carte '
                'et s’applique d’elle-même au panier.',
          ),
        const SizedBox(height: 12),
        const _Notice(
          text: 'La remise est à votre charge : elle est retenue sur le '
              'versement de chaque commande concernée. La commission Lilia '
              'reste calculée sur le prix avant remise. La livraison offerte '
              'se règle à part, dans Paramètres › Livraison.',
        ),
        if (offers.past.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(top: 20, bottom: 8),
            child: Text(
              'Offres passées',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          for (final o in offers.past) _PastOffer(offer: o),
        ],
      ],
    );
  }
}

class _CurrentOffer extends ConsumerStatefulWidget {
  const _CurrentOffer({required this.offer});

  final VendorOffer offer;

  @override
  ConsumerState<_CurrentOffer> createState() => _CurrentOfferState();
}

class _CurrentOfferState extends ConsumerState<_CurrentOffer> {
  bool _busy = false;

  Future<void> _act(OfferAction action) async {
    if (action == OfferAction.end) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Terminer l’offre ?'),
          content: const Text(
            'Elle ne s’appliquera plus aux nouvelles commandes. Les commandes '
            'déjà passées gardent leur remise.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Terminer'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(offersRepositoryProvider).act(widget.offer.id, action);
      ref.invalidate(myOffersProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.offer;
    final cs = Theme.of(context).colorScheme;
    return Card(
      key: const Key('offers-current'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    o.label,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Chip(label: Text(o.statusLabel)),
              ],
            ),
            if (o.endsAt != null)
              Text(
                'Jusqu’au ${formatBrazzavilleDateTime(o.endsAt!)}',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              key: const Key('offers-budget-bar'),
              value: o.spentRatio,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              '${formatXaf(o.spentXaf)} offerts sur ${formatXaf(o.budgetXaf)} '
              '· ${o.ordersCount} commande${o.ordersCount > 1 ? 's' : ''}',
              key: const Key('offers-budget-text'),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                if (o.isActive)
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _act(OfferAction.pause),
                    icon: const Icon(Icons.pause),
                    label: const Text('Mettre en pause'),
                  ),
                if (o.isPaused)
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _act(OfferAction.resume),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Reprendre'),
                  ),
                TextButton(
                  onPressed: _busy ? null : () => _act(OfferAction.end),
                  child: const Text('Terminer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PastOffer extends StatelessWidget {
  const _PastOffer({required this.offer});

  final VendorOffer offer;

  @override
  Widget build(BuildContext context) {
    final o = offer;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.local_offer_outlined),
      title: Text(o.label),
      subtitle: Text(
        '${o.statusLabel} · ${formatXaf(o.spentXaf)} offerts · '
        '${o.ordersCount} commande${o.ordersCount > 1 ? 's' : ''}'
        '${o.stoppedReason != null ? '\nMotif : ${o.stoppedReason}' : ''}',
      ),
      isThreeLine: o.stoppedReason != null,
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blueGrey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text),
      );
}

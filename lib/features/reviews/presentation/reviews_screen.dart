import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lilia_admin/core/network/api_exception.dart';
import 'package:lilia_admin/core/utils/date_format.dart';
import 'package:lilia_admin/features/reviews/data/reviews_repository.dart';
import 'package:lilia_admin/features/reviews/presentation/reviews_providers.dart';

/// « Avis reçus » (lot B, 15/11/2026) — ce que les clients disent de la
/// boutique, et la réponse publique du vendeur.
///
/// L'auteur reste « Client » : le serveur n'envoie pas son identité. Une
/// réponse se modifie à volonté ; masquée par la modération, elle n'est plus
/// publique et ne se modifie plus d'ici.
class ReviewsScreen extends ConsumerWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(receivedReviewsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Avis reçus')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(receivedReviewsProvider.future),
        // Riverpod 3 garde l'erreur pendant la relance automatique : on lit
        // `hasError`, jamais le type de l'état (sinon spinner sans fin).
        child: async.hasValue
            ? _Body(data: async.requireValue)
            : async.hasError
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Text(async.error.toString(), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      Center(
                        child: FilledButton(
                          onPressed: () =>
                              ref.invalidate(receivedReviewsProvider),
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
  const _Body({required this.data});

  final ReceivedReviews data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _Summary(data: data),
        const SizedBox(height: 16),
        if (data.reviews.isEmpty)
          const Padding(
            key: Key('reviews-empty'),
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Text(
              'Aucun avis pour le moment. Les clients sont invités à noter '
              'chaque commande livrée.',
              textAlign: TextAlign.center,
            ),
          )
        else
          for (final r in data.reviews) _ReviewCard(review: r),
        if (data.totalPages > 1)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Les 20 avis les plus récents sont affichés.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$rating sur 5',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 1; i <= 5; i++)
              Icon(
                i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 16,
                color: Colors.amber.shade700,
              ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.data});

  final ReceivedReviews data;

  @override
  Widget build(BuildContext context) {
    final total = data.totalReviews;
    return Card(
      key: const Key('reviews-summary'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Column(
              children: [
                Text(
                  total == 0 ? '—' : data.averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                _Stars(rating: data.averageRating.round()),
                const SizedBox(height: 4),
                Text('$total avis', style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                children: [
                  for (var s = 5; s >= 1; s--)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          SizedBox(width: 14, child: Text('$s')),
                          const SizedBox(width: 6),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: total == 0
                                  ? 0
                                  : (data.distribution[s] ?? 0) / total,
                              minHeight: 6,
                              color: Colors.amber.shade700,
                              backgroundColor: Colors.grey.shade200,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends ConsumerWidget {
  const _ReviewCard({required this.review});

  final ReceivedReview review;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = [
      if (review.restaurantName != null) review.restaurantName!,
      review.orderRef != null ? 'Commande #${review.orderRef}' : 'Avis général',
      if (review.createdAt != null)
        formatBrazzavilleDateTime(review.createdAt!),
    ].join(' · ');

    return Card(
      key: Key('review-${review.id}'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Stars(rating: review.rating),
                const SizedBox(width: 8),
                const Text(
                  'Client',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(meta, style: const TextStyle(fontSize: 12)),
            if (review.comment != null) ...[
              const SizedBox(height: 8),
              Text(review.comment!),
            ],
            const SizedBox(height: 10),
            if (review.vendorReply != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.vendorReplyHidden
                          ? 'Votre réponse (masquée par la modération)'
                          : 'Votre réponse',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(review.vendorReply!),
                  ],
                ),
              ),
            if (!review.vendorReplyHidden)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: Key('review-reply-${review.id}'),
                  onPressed: () => _openReply(context, ref),
                  icon: const Icon(Icons.reply_outlined),
                  label: Text(
                    review.vendorReply == null ? 'Répondre' : 'Modifier',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openReply(BuildContext context, WidgetRef ref) async {
    final sent = await showDialog<bool>(
      context: context,
      builder: (_) => _ReplyDialog(review: review),
    );
    if (sent == true) ref.invalidate(receivedReviewsProvider);
  }
}

class _ReplyDialog extends ConsumerStatefulWidget {
  const _ReplyDialog({required this.review});

  final ReceivedReview review;

  @override
  ConsumerState<_ReplyDialog> createState() => _ReplyDialogState();
}

class _ReplyDialogState extends ConsumerState<_ReplyDialog> {
  late final TextEditingController _text =
      TextEditingController(text: widget.review.vendorReply ?? '');
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _valid => _text.text.trim().length >= 2;

  Future<void> _send() async {
    if (!_valid || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref
          .read(reviewsRepositoryProvider)
          .reply(widget.review.id, _text.text);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Réponse publique'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Visible de tous sous l’avis, au nom de la boutique.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('review-reply-field'),
            controller: _text,
            maxLength: 1000,
            minLines: 3,
            maxLines: 6,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Merci pour votre retour…',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null)
            Text(
              _error!,
              key: const Key('review-reply-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          key: const Key('review-reply-send'),
          onPressed: _valid && !_sending ? _send : null,
          child: Text(_sending ? 'Envoi…' : 'Publier'),
        ),
      ],
    );
  }
}

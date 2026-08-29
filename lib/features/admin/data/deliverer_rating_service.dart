import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/utils/api_response.dart';

part 'deliverer_rating_service.g.dart';

/// Note moyenne d'un livreur, telle que les clients la donnent après livraison.
///
/// `averageRating` est **nullable** et ce n'est pas un détail : `null` signifie
/// « pas encore noté », `0` signifierait « très mal noté ». Afficher 0 pour un
/// nouveau livreur serait un jugement porté sur quelqu'un qui n'a rien fait.
class DelivererRating {
  final double? averageRating;
  final int totalReviews;
  final Map<int, int> distribution;

  const DelivererRating({
    required this.averageRating,
    required this.totalReviews,
    required this.distribution,
  });

  bool get hasRatings => totalReviews > 0 && averageRating != null;

  factory DelivererRating.fromJson(Map<String, dynamic> json) {
    final raw = json['ratingDistribution'] as Map<String, dynamic>? ?? {};
    return DelivererRating(
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
      distribution: {
        for (final entry in raw.entries)
          int.tryParse(entry.key) ?? 0: (entry.value as num?)?.toInt() ?? 0,
      },
    );
  }
}

/// `GET /delivery-reviews/deliverer/:id/stats` — authentifiée côté backend
/// (la note d'un livreur est une évaluation de personne, pas une vitrine).
/// (c'est une information d'affichage, sans identité de client ni détail de
/// course).
@riverpod
Future<DelivererRating> delivererRating(Ref ref, String delivererId) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.getJson('/delivery-reviews/deliverer/$delivererId/stats');
  return DelivererRating.fromJson(ApiResponse.mapOf(res.data));
}

import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/utils/api_response.dart';

/// « Avis reçus » (lot B, 15/11/2026) — les avis laissés sur les boutiques du
/// vendeur, et sa réponse publique.
///
/// `GET /vendors/me/reviews`, `PUT /vendors/me/reviews/:id/reply`. Le serveur
/// borne tout aux boutiques du compte et n'envoie jamais l'identité du client
/// (auteur « Client », commande désignée par sa référence courte). Les avis
/// masqués par la modération n'y figurent pas.
class ReviewsRepository {
  ReviewsRepository(this._api);

  final ApiClient _api;

  Future<ReceivedReviews> received({int page = 1}) async {
    final res = await _api.getJson(
      '/vendors/me/reviews',
      query: {'page': page, 'limit': 20},
    );
    return ReceivedReviews.fromJson(res.data);
  }

  /// Une réponse par avis, modifiable (2 à 1 000 caractères, vérifié par le
  /// serveur). 409 si la modération a masqué l'avis ou la réponse.
  Future<void> reply(String reviewId, String text) async {
    await _api.putJson(
      '/vendors/me/reviews/${Uri.encodeComponent(reviewId)}/reply',
      body: {'text': text.trim()},
    );
  }
}

int _i(Object? v) => v is num ? v.toInt() : 0;
String? _sOrNull(Object? v) => v is String && v.isNotEmpty ? v : null;
DateTime? _d(Object? v) => v is String ? DateTime.tryParse(v) : null;

class ReceivedReviews {
  const ReceivedReviews({
    required this.reviews,
    required this.averageRating,
    required this.totalReviews,
    required this.distribution,
    required this.totalPages,
  });

  /// La réponse porte `stats` en plus de `data`/`meta` : l'intercepteur la
  /// ré-enveloppe (`{ data: { data, stats, meta } }`). On lit les deux formes.
  factory ReceivedReviews.fromJson(dynamic decoded) {
    final body = decoded is Map<String, dynamic> &&
            decoded['data'] is Map<String, dynamic>
        ? decoded['data'] as Map<String, dynamic>
        : (decoded is Map<String, dynamic> ? decoded : <String, dynamic>{});
    final stats = body['stats'] is Map<String, dynamic>
        ? body['stats'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final dist = stats['ratingDistribution'] is Map
        ? stats['ratingDistribution'] as Map
        : const {};
    return ReceivedReviews(
      reviews: ApiResponse.listOf(body)
          .whereType<Map<String, dynamic>>()
          .map(ReceivedReview.fromJson)
          .toList(growable: false),
      averageRating: stats['averageRating'] is num
          ? (stats['averageRating'] as num).toDouble()
          : 0,
      totalReviews: _i(stats['totalReviews']),
      distribution: {for (var s = 1; s <= 5; s++) s: _i(dist['$s'])},
      totalPages: ApiResponse.totalPagesOf(decoded),
    );
  }

  final List<ReceivedReview> reviews;
  final double averageRating;
  final int totalReviews;

  /// Nombre d'avis par note, de 1 à 5.
  final Map<int, int> distribution;
  final int totalPages;
}

class ReceivedReview {
  const ReceivedReview({
    required this.id,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.restaurantName,
    required this.orderRef,
    required this.vendorReply,
    required this.vendorReplyHidden,
  });

  factory ReceivedReview.fromJson(Map<String, dynamic> j) => ReceivedReview(
        id: j['id'] is String ? j['id'] as String : '',
        rating: _i(j['rating']).clamp(0, 5),
        comment: _sOrNull(j['comment']),
        createdAt: _d(j['createdAt']),
        restaurantName: _sOrNull(j['restaurantName']),
        orderRef: _sOrNull(j['orderRef']),
        vendorReply: _sOrNull(j['vendorReply']),
        vendorReplyHidden: j['vendorReplyHidden'] == true,
      );

  final String id;
  final int rating;
  final String? comment;
  final DateTime? createdAt;
  final String? restaurantName;

  /// Référence courte de la commande (« A3F2B1 ») ; `null` pour un avis
  /// général laissé sans commande.
  final String? orderRef;
  final String? vendorReply;

  /// La modération a masqué la réponse : elle n'est plus publique et ne se
  /// modifie plus depuis l'app.
  final bool vendorReplyHidden;
}

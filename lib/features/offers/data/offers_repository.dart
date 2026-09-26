import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/utils/api_response.dart';

/// « Mes offres » (F3-11) — offres boutique financées par le vendeur.
///
/// `GET|POST /vendors/me/offers`, `PATCH /vendors/me/offers/:id`. Le serveur
/// borne tout à la boutique du vendeur connecté : l'app n'envoie aucun
/// identifiant de boutique. Les bornes (≤ 50 %, ≤ 30 jours, seuil ≥ 2 ×
/// remise) sont vérifiées par le serveur, qui répond un message en français :
/// le formulaire les rappelle, il ne les recopie pas.
class OffersRepository {
  OffersRepository(this._api);

  final ApiClient _api;

  Future<MyOffers> mine() async {
    final res = await _api.getJson('/vendors/me/offers');
    return MyOffers.fromJson(ApiResponse.mapOf(res.data));
  }

  Future<VendorOffer> create(NewOffer offer) async {
    final res = await _api.postJson('/vendors/me/offers', body: offer.toJson());
    return VendorOffer.fromJson(ApiResponse.mapOf(res.data));
  }

  /// `PAUSE`, `RESUME` ou `END` — les seuls gestes permis : les termes d'une
  /// offre ne se modifient pas, on la termine et on en publie une autre.
  Future<VendorOffer> act(String offerId, OfferAction action) async {
    final res = await _api.patchJson(
      '/vendors/me/offers/$offerId',
      body: {'action': action.wire},
    );
    return VendorOffer.fromJson(ApiResponse.mapOf(res.data));
  }
}

enum OfferAction {
  pause('PAUSE'),
  resume('RESUME'),
  end('END');

  const OfferAction(this.wire);
  final String wire;
}

enum OfferKind {
  percent('PERCENT'),
  fixedThreshold('FIXED_THRESHOLD');

  const OfferKind(this.wire);
  final String wire;

  static OfferKind parse(Object? v) =>
      v == 'FIXED_THRESHOLD' ? OfferKind.fixedThreshold : OfferKind.percent;
}

int _i(Object? v) => v is num ? v.toInt() : 0;
int? _iOrNull(Object? v) => v is num ? v.toInt() : null;
String _s(Object? v) => v is String ? v : '';
DateTime? _d(Object? v) => v is String ? DateTime.tryParse(v) : null;

class MyOffers {
  const MyOffers({required this.enabled, required this.offers});

  factory MyOffers.fromJson(Map<String, dynamic> json) => MyOffers(
        enabled: json['enabled'] == true,
        offers: json['offers'] is List
            ? (json['offers'] as List)
                .whereType<Map<String, dynamic>>()
                .map(VendorOffer.fromJson)
                .toList()
            : const [],
      );

  /// Interrupteur plateforme : éteint, le vendeur voit ses offres passées
  /// mais ne peut pas en publier.
  final bool enabled;
  final List<VendorOffer> offers;

  /// L'offre en cours (active ou en pause) — au plus une à la fois.
  VendorOffer? get current => offers
      .where((o) => o.status == 'ACTIVE' || o.status == 'PAUSED')
      .firstOrNull;

  List<VendorOffer> get past =>
      offers.where((o) => o != current).toList(growable: false);
}

class VendorOffer {
  const VendorOffer({
    required this.id,
    required this.kind,
    required this.value,
    required this.minSubTotalXaf,
    required this.maxDiscountXaf,
    required this.endsAt,
    required this.budgetXaf,
    required this.spentXaf,
    required this.status,
    required this.ordersCount,
    required this.label,
    required this.stoppedReason,
  });

  factory VendorOffer.fromJson(Map<String, dynamic> j) => VendorOffer(
        id: _s(j['id']),
        kind: OfferKind.parse(j['kind']),
        value: _i(j['value']),
        minSubTotalXaf: _i(j['minSubTotalXaf']),
        maxDiscountXaf: _iOrNull(j['maxDiscountXaf']),
        endsAt: _d(j['endsAt']),
        budgetXaf: _i(j['budgetXaf']),
        spentXaf: _i(j['spentXaf']),
        status: _s(j['status']),
        ordersCount: _i(j['ordersCount']),
        label: _s(j['label']),
        stoppedReason:
            j['stoppedReason'] is String ? j['stoppedReason'] as String : null,
      );

  final String id;
  final OfferKind kind;
  final int value;
  final int minSubTotalXaf;
  final int? maxDiscountXaf;
  final DateTime? endsAt;
  final int budgetXaf;
  final int spentXaf;
  final String status;
  final int ordersCount;

  /// Libellé écrit par le serveur (« −10 % sur toute la boutique »).
  final String label;
  final String? stoppedReason;

  int get remainingXaf => budgetXaf - spentXaf;

  /// Part du budget consommée, entre 0 et 1.
  double get spentRatio =>
      budgetXaf <= 0 ? 0 : (spentXaf / budgetXaf).clamp(0, 1).toDouble();

  bool get isActive => status == 'ACTIVE';
  bool get isPaused => status == 'PAUSED';

  String get statusLabel => switch (status) {
        'ACTIVE' => 'En cours',
        'PAUSED' => 'En pause',
        'EXHAUSTED' => 'Budget épuisé',
        'ENDED' => 'Terminée',
        'STOPPED_BY_ADMIN' => 'Arrêtée par Lilia Food',
        _ => status,
      };
}

/// Offre à publier.
class NewOffer {
  const NewOffer({
    required this.kind,
    required this.value,
    required this.budgetXaf,
    required this.endsAt,
    this.minSubTotalXaf = 0,
    this.maxDiscountXaf,
  });

  final OfferKind kind;
  final int value;
  final int minSubTotalXaf;
  final int? maxDiscountXaf;
  final int budgetXaf;
  final DateTime endsAt;

  Map<String, dynamic> toJson() => {
        'kind': kind.wire,
        'value': value,
        if (minSubTotalXaf > 0) 'minSubTotalXaf': minSubTotalXaf,
        if (kind == OfferKind.percent && maxDiscountXaf != null)
          'maxDiscountXaf': maxDiscountXaf,
        'budgetXaf': budgetXaf,
        'endsAt': endsAt.toUtc().toIso8601String(),
      };

  /// Remise sur un panier donné — sert UNIQUEMENT à l'aperçu « coût estimé »
  /// du formulaire. Le montant réellement appliqué est calculé par le serveur.
  int discountOn(int subTotalXaf) {
    if (subTotalXaf < minSubTotalXaf) return 0;
    var d = kind == OfferKind.percent
        ? (subTotalXaf * value / 100).round()
        : value;
    if (kind == OfferKind.percent && maxDiscountXaf != null) {
      d = d > maxDiscountXaf! ? maxDiscountXaf! : d;
    }
    return d > subTotalXaf ? subTotalXaf : d;
  }
}

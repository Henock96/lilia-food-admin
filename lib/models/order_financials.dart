/// Récapitulatif financier d'une commande, tel que le backend le calcule.
///
/// ⚠️ **Rien n'est recalculé côté application.** Ni la commission, ni le montant
/// à reverser, ni l'éligibilité. L'écran affiche ce que le serveur lui dit — et
/// le serveur rejoue toutes ses vérifications au moment du clic. Un décompte
/// recalculé localement finirait par diverger (taux de commission changé, arrondi
/// différent) et afficherait à l'administrateur un montant qui n'est pas celui
/// qui partira.
library;

int _asInt(Object? v, [int fallback = 0]) =>
    v is num ? v.round() : (v is String ? int.tryParse(v) ?? fallback : fallback);

double _asDouble(Object? v, [double fallback = 0]) =>
    v is num ? v.toDouble() : fallback;

String? _asString(Object? v) => v is String && v.isNotEmpty ? v : null;

DateTime? _asDate(Object? v) =>
    v is String ? DateTime.tryParse(v)?.toLocal() : null;

Map<String, dynamic> _asMap(Object? v) =>
    v is Map<String, dynamic> ? v : <String, dynamic>{};

/// Motifs pour lesquels un reversement est refusé, tels que définis par le
/// backend (`PayoutIneligibilityCode`).
enum PayoutIneligibility {
  orderNotFound,
  orderCancelled,
  orderNotReady,
  paymentNotCompleted,
  orderRefunded,
  vendorPayoutAccountMissing,
  payoutAlreadyCompleted,
  payoutInProgress,
  providerDoesNotSupportPayout,
  unknown,
}

PayoutIneligibility _parseIneligibility(String? code) {
  switch (code) {
    case 'ORDER_NOT_FOUND':
      return PayoutIneligibility.orderNotFound;
    case 'ORDER_CANCELLED':
      return PayoutIneligibility.orderCancelled;
    case 'ORDER_NOT_READY':
      return PayoutIneligibility.orderNotReady;
    case 'PAYMENT_NOT_COMPLETED':
      return PayoutIneligibility.paymentNotCompleted;
    case 'ORDER_REFUNDED':
      return PayoutIneligibility.orderRefunded;
    case 'VENDOR_PAYOUT_ACCOUNT_MISSING':
      return PayoutIneligibility.vendorPayoutAccountMissing;
    case 'PAYOUT_ALREADY_COMPLETED':
      return PayoutIneligibility.payoutAlreadyCompleted;
    case 'PAYOUT_IN_PROGRESS':
      return PayoutIneligibility.payoutInProgress;
    case 'PROVIDER_DOES_NOT_SUPPORT_PAYOUT':
      return PayoutIneligibility.providerDoesNotSupportPayout;
    default:
      return PayoutIneligibility.unknown;
  }
}

/// États d'un reversement. `success` est le **seul** où le vendeur est payé.
enum PayoutStatus { pending, success, failed, cancelled }

PayoutStatus _parsePayoutStatus(String? raw) {
  switch (raw) {
    case 'SUCCESS':
      return PayoutStatus.success;
    case 'FAILED':
      return PayoutStatus.failed;
    case 'CANCELLED':
      return PayoutStatus.cancelled;
    default:
      return PayoutStatus.pending;
  }
}

extension PayoutStatusLabel on PayoutStatus {
  String get label => switch (this) {
        PayoutStatus.pending => 'Paiement en cours',
        PayoutStatus.success => 'Restaurant payé',
        PayoutStatus.failed => 'Paiement échoué',
        PayoutStatus.cancelled => 'Paiement annulé',
      };
}

/// Encaissement du client.
class CollectionSummary {
  final String paymentId;
  final String status;
  final String provider;
  final String? method;
  final int amount;
  final DateTime? completedAt;
  final String? failureCode;
  final String? failureMessage;

  const CollectionSummary({
    required this.paymentId,
    required this.status,
    required this.provider,
    required this.amount,
    this.method,
    this.completedAt,
    this.failureCode,
    this.failureMessage,
  });

  bool get isPaid => status == 'SUCCESS';

  factory CollectionSummary.fromJson(Map<String, dynamic> json) {
    return CollectionSummary(
      paymentId: json['paymentId'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      provider: json['provider'] as String? ?? '',
      method: _asString(json['method']),
      amount: _asInt(json['amount']),
      completedAt: _asDate(json['completedAt']),
      failureCode: _asString(json['failureCode']),
      failureMessage: _asString(json['failureMessage']),
    );
  }
}

/// Reversement vendeur, quand il existe.
class PayoutSummary {
  final String id;
  final PayoutStatus status;
  final int amount;
  final String requestedBy;
  final DateTime? requestedAt;
  final DateTime? completedAt;
  final String? failureCode;
  final String? failureMessage;
  final String provider;

  const PayoutSummary({
    required this.id,
    required this.status,
    required this.amount,
    required this.requestedBy,
    required this.provider,
    this.requestedAt,
    this.completedAt,
    this.failureCode,
    this.failureMessage,
  });

  factory PayoutSummary.fromJson(Map<String, dynamic> json) {
    return PayoutSummary(
      id: json['id'] as String? ?? '',
      status: _parsePayoutStatus(json['status'] as String?),
      amount: _asInt(json['amount']),
      requestedBy: json['requestedBy'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      requestedAt: _asDate(json['requestedAt']),
      completedAt: _asDate(json['completedAt']),
      failureCode: _asString(json['failureCode']),
      failureMessage: _asString(json['failureMessage']),
    );
  }
}

/// Compte Mobile Money de reversement du vendeur.
class VendorPayoutAccount {
  /// Numéro **masqué** par le backend — l'écran n'a pas à afficher le numéro
  /// complet, et le journal d'audit ne le conserve pas non plus.
  final String? phoneNumber;
  final String? provider;
  final String? accountName;
  final bool configured;

  const VendorPayoutAccount({
    required this.configured,
    this.phoneNumber,
    this.provider,
    this.accountName,
  });

  factory VendorPayoutAccount.fromJson(Map<String, dynamic> json) {
    return VendorPayoutAccount(
      configured: json['configured'] as bool? ?? false,
      phoneNumber: _asString(json['phoneNumber']),
      provider: _asString(json['provider']),
      accountName: _asString(json['accountName']),
    );
  }
}

/// Éligibilité au reversement, décidée par le serveur.
class PayoutEligibility {
  final bool eligible;
  final PayoutIneligibility? code;

  /// Message prêt à afficher, rédigé par le backend. On ne le reformule pas :
  /// il porte l'action à mener (« renseignez le compte Mobile Money… »).
  final String? reason;

  const PayoutEligibility({required this.eligible, this.code, this.reason});

  factory PayoutEligibility.fromJson(Map<String, dynamic> json) {
    return PayoutEligibility(
      eligible: json['eligible'] as bool? ?? false,
      code: json['code'] == null
          ? null
          : _parseIneligibility(json['code'] as String?),
      reason: _asString(json['reason']),
    );
  }
}

/// Ce que Lilia Food garde sur la commande.
class PlatformMargin {
  final int serviceFee;
  final int restaurantCommission;

  /// Frais de livraison encaissés auprès du client. C'est un **revenu** de
  /// Lilia : le vendeur ne les reçoit pas (`grossAmount = subTotal`). Ce
  /// qu'ils coûtent réellement — la course — est `driverCost`, qui n'existe
  /// pas encore.
  final int deliveryFeeCollected;

  /// Remises offertes par Lilia (promo + fidélité). Un **coût**.
  final int discountGranted;

  /// Remboursement réellement versé. `0` tant qu'il n'est pas `COMPLETED` :
  /// un remboursement en cours est une dette, pas une sortie d'argent.
  final int refundPaid;

  /// Frais du prestataire — **charges de Lilia Food**, jamais déduites de ce
  /// que touche le vendeur. `null` tant que le prestataire ne les a pas
  /// communiqués.
  final int? collectionFee;
  final int? payoutFee;

  /// Rémunération due au livreur pour cette course, en XAF. Figée à
  /// l'acceptation, jamais recalculée à la lecture.
  ///
  /// ⚠️ `null` = **inconnu** : soit la course n'a pas d'économie gelée, soit
  /// elle n'existe pas (retrait au comptoir, ou livraison hors système).
  /// Ne jamais afficher `0` à la place.
  final int? driverCost;

  /// Part de Lilia sur la course : `driverBaseXaf − driverPayXaf`.
  final int? liliaDeliveryShare;

  /// Rend un [driverCost] de 0 lisible : au salaire, zéro est la bonne réponse.
  final String? driverCompensationModel;
  final String? driverEmploymentType;
  final double? driverSharePercent;

  /// Contribution **hors frais prestataire**.
  ///
  /// `collectionFee` et `payoutFee` ne sont jamais renseignés : nos types
  /// pawaPay n'en modélisent aucun et la production n'a jamais reçu un seul
  /// webhook. Attendre ces deux valeurs revient à n'afficher aucune marge,
  /// jamais. Ce nombre est exact dès que le coût livreur est connu.
  ///
  /// ⚠️ Il ne remplace PAS [contributionMargin] : l'écran doit dire lequel il
  /// montre, sans quoi il surestimerait le résultat du montant des frais.
  final int? contributionMarginBeforeProviderFees;

  /// Contribution réelle de la commande, ou `null` si un poste **obligatoire**
  /// est inconnu — `missingInputs` dit alors lesquels.
  final int? contributionMargin;

  /// Postes manquants qui empêchent de conclure. Aujourd'hui `driverCost` sur
  /// toute commande livrée : le coût d'une course n'existe nulle part dans le
  /// système.
  ///
  /// ⚠️ **Ne jamais le traiter comme un zéro.** Un `driverCost` absent
  /// remplacé par `0` transformerait « inconnu » en « gratuit » et produirait
  /// une marge surestimée avec l'air d'être exacte.
  final List<String> missingInputs;

  /// @deprecated Alias serveur de [contributionMargin], conservé le temps que
  /// les deux back-offices migrent. Ne plus l'afficher.
  final int? netMargin;

  const PlatformMargin({
    required this.serviceFee,
    required this.restaurantCommission,
    this.deliveryFeeCollected = 0,
    this.discountGranted = 0,
    this.refundPaid = 0,
    this.collectionFee,
    this.payoutFee,
    this.driverCost,
    this.liliaDeliveryShare,
    this.driverCompensationModel,
    this.driverEmploymentType,
    this.driverSharePercent,
    this.contributionMarginBeforeProviderFees,
    this.contributionMargin,
    this.missingInputs = const [],
    this.netMargin,
  });

  factory PlatformMargin.fromJson(Map<String, dynamic> json) {
    // `contributionMargin` est le champ courant ; `netMargin` en est l'alias
    // déprécié. On lit le premier et on retombe sur le second, pour qu'une app
    // à jour reste lisible contre un backend qui n'a pas encore été déployé.
    final contribution = json['contributionMargin'] ?? json['netMargin'];

    return PlatformMargin(
      serviceFee: _asInt(json['serviceFee']),
      restaurantCommission: _asInt(json['restaurantCommission']),
      deliveryFeeCollected: _asInt(json['deliveryFeeCollected']),
      discountGranted: _asInt(json['discountGranted']),
      refundPaid: _asInt(json['refundPaid']),
      collectionFee:
          json['collectionFee'] == null ? null : _asInt(json['collectionFee']),
      payoutFee: json['payoutFee'] == null ? null : _asInt(json['payoutFee']),
      driverCost:
          json['driverCost'] == null ? null : _asInt(json['driverCost']),
      liliaDeliveryShare: json['liliaDeliveryShare'] == null
          ? null
          : _asInt(json['liliaDeliveryShare']),
      driverCompensationModel: _asString(json['driverCompensationModel']),
      driverEmploymentType: _asString(json['driverEmploymentType']),
      driverSharePercent: json['driverSharePercent'] == null
          ? null
          : _asDouble(json['driverSharePercent']),
      contributionMarginBeforeProviderFees:
          json['contributionMarginBeforeProviderFees'] == null
          ? null
          : _asInt(json['contributionMarginBeforeProviderFees']),
      contributionMargin: contribution == null ? null : _asInt(contribution),
      // Un backend antérieur ne porte pas ce champ : liste vide, et la marge
      // s'affiche alors sans explication — c'est le comportement d'avant.
      missingInputs: (json['missingInputs'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
      netMargin: json['netMargin'] == null ? null : _asInt(json['netMargin']),
    );
  }

  /// Libellés lisibles des postes manquants, dans l'ordre rendu par le serveur.
  ///
  /// Un poste inconnu du front est rendu tel quel plutôt que masqué : mieux
  /// vaut un identifiant technique à l'écran qu'une explication tronquée.
  List<String> get missingInputLabels => missingInputs
      .map((key) => switch (key) {
            'driverCost' => 'le coût du livreur',
            'collectionFee' => 'les frais d’encaissement',
            'payoutFee' => 'les frais de reversement',
            _ => key,
          })
      .toList(growable: false);
}

class OrderFinancials {
  final String orderId;
  final String orderRef;
  final String orderStatus;

  // ─── Client ────────────────────────────────────────────────────────────────
  final int subTotal;
  final int deliveryFee;
  final int serviceFee;
  final int discountAmount;
  final int totalPaid;
  final CollectionSummary? collection;

  // ─── Vendeur ───────────────────────────────────────────────────────────────
  final String restaurantId;
  final String restaurantName;
  final int grossAmount;
  final double commissionPercent;
  final int commissionAmount;
  final int payoutAmount;
  final VendorPayoutAccount payoutAccount;
  final PayoutSummary? payout;

  /// ⚠️ `true` **uniquement** si le reversement est `SUCCESS`. Un reversement
  /// en cours n'est pas de l'argent reçu.
  final bool restaurantPaid;

  // ─── Plateforme ────────────────────────────────────────────────────────────
  final PlatformMargin margin;

  final PayoutEligibility eligibility;

  const OrderFinancials({
    required this.orderId,
    required this.orderRef,
    required this.orderStatus,
    required this.subTotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.discountAmount,
    required this.totalPaid,
    required this.restaurantId,
    required this.restaurantName,
    required this.grossAmount,
    required this.commissionPercent,
    required this.commissionAmount,
    required this.payoutAmount,
    required this.payoutAccount,
    required this.restaurantPaid,
    required this.margin,
    required this.eligibility,
    this.collection,
    this.payout,
  });

  factory OrderFinancials.fromJson(Map<String, dynamic> json) {
    final client = _asMap(json['client']);
    final restaurant = _asMap(json['restaurant']);
    final lilia = _asMap(json['liliaFood']);

    return OrderFinancials(
      orderId: json['orderId'] as String? ?? '',
      orderRef: json['orderRef'] as String? ?? '',
      orderStatus: json['orderStatus'] as String? ?? '',
      subTotal: _asInt(client['subTotal']),
      deliveryFee: _asInt(client['deliveryFee']),
      serviceFee: _asInt(client['serviceFee']),
      discountAmount: _asInt(client['discountAmount']),
      totalPaid: _asInt(client['totalPaid']),
      collection: client['collection'] == null
          ? null
          : CollectionSummary.fromJson(_asMap(client['collection'])),
      restaurantId: restaurant['id'] as String? ?? '',
      restaurantName: restaurant['nom'] as String? ?? '',
      grossAmount: _asInt(restaurant['grossAmount']),
      commissionPercent: _asDouble(restaurant['commissionPercent']),
      commissionAmount: _asInt(restaurant['commissionAmount']),
      payoutAmount: _asInt(restaurant['payoutAmount']),
      payoutAccount:
          VendorPayoutAccount.fromJson(_asMap(restaurant['payoutAccount'])),
      payout: restaurant['payout'] == null
          ? null
          : PayoutSummary.fromJson(_asMap(restaurant['payout'])),
      restaurantPaid: restaurant['paid'] as bool? ?? false,
      margin: PlatformMargin.fromJson(lilia),
      eligibility: PayoutEligibility.fromJson(_asMap(json['eligibility'])),
    );
  }
}

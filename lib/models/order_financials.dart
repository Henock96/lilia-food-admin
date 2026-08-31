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

  /// Frais du prestataire — **charges de Lilia Food**, jamais déduites de ce
  /// que touche le vendeur. `null` tant que le prestataire ne les a pas
  /// communiqués.
  final int? collectionFee;
  final int? payoutFee;
  final int? netMargin;

  const PlatformMargin({
    required this.serviceFee,
    required this.restaurantCommission,
    this.collectionFee,
    this.payoutFee,
    this.netMargin,
  });

  factory PlatformMargin.fromJson(Map<String, dynamic> json) {
    return PlatformMargin(
      serviceFee: _asInt(json['serviceFee']),
      restaurantCommission: _asInt(json['restaurantCommission']),
      collectionFee:
          json['collectionFee'] == null ? null : _asInt(json['collectionFee']),
      payoutFee: json['payoutFee'] == null ? null : _asInt(json['payoutFee']),
      netMargin: json['netMargin'] == null ? null : _asInt(json['netMargin']),
    );
  }
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

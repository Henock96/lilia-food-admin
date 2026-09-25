import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/utils/api_response.dart';

/// « Mes gains » du vendeur (F3-07) — `GET /vendors/me/earnings`.
///
/// Un versement par commande, envoyé seul une heure après la remise : c'est
/// l'argument de confiance, à condition que le vendeur VOIE ce qui arrive. Le
/// serveur borne la réponse à SES boutiques ; l'app n'envoie aucun
/// identifiant de boutique.
class EarningsRepository {
  EarningsRepository(this._api);

  final ApiClient _api;

  Future<VendorEarnings> mine({int page = 1}) async {
    final res = await _api.getJson(
      '/vendors/me/earnings',
      query: {'page': '$page', 'limit': '20'},
    );
    final body = res.data;
    final data = ApiResponse.mapOf(body);
    final meta = body is Map<String, dynamic> && body['meta'] is Map
        ? body['meta'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return VendorEarnings.fromJson(data, meta);
  }
}

int _i(Object? v) => v is num ? v.toInt() : 0;
String _s(Object? v) => v is String ? v : '';
DateTime? _d(Object? v) => v is String ? DateTime.tryParse(v) : null;
List<Map<String, dynamic>> _list(Object? v) =>
    v is List ? v.whereType<Map<String, dynamic>>().toList() : const [];

class VendorEarnings {
  const VendorEarnings({
    required this.upcomingXaf,
    required this.upcomingCount,
    required this.awaitingProofCount,
    required this.pendingXaf,
    required this.paidLast30DaysXaf,
    required this.debtXaf,
    required this.upcoming,
    required this.payouts,
    required this.debtEntries,
    required this.total,
  });

  factory VendorEarnings.fromJson(
    Map<String, dynamic> json,
    Map<String, dynamic> meta,
  ) {
    final summary = json['summary'] is Map<String, dynamic>
        ? json['summary'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return VendorEarnings(
      upcomingXaf: _i(summary['upcomingXaf']),
      upcomingCount: _i(summary['upcomingCount']),
      awaitingProofCount: _i(summary['awaitingProofCount']),
      pendingXaf: _i(summary['pendingXaf']),
      paidLast30DaysXaf: _i(summary['paidLast30DaysXaf']),
      debtXaf: _i(summary['debtXaf']),
      upcoming: _list(json['upcoming']).map(UpcomingPayout.fromJson).toList(),
      payouts: _list(json['payouts']).map(PayoutLine.fromJson).toList(),
      debtEntries: _list(json['debtEntries']).map(DebtEntry.fromJson).toList(),
      total: _i(meta['total']),
    );
  }

  /// Estimation : les retenues ne sont connues qu'au versement.
  final int upcomingXaf;
  final int upcomingCount;

  /// Commandes remises sans preuve (remise déclarée seule, sans code).
  final int awaitingProofCount;
  final int pendingXaf;
  final int paidLast30DaysXaf;
  final int debtXaf;
  final List<UpcomingPayout> upcoming;
  final List<PayoutLine> payouts;
  final List<DebtEntry> debtEntries;
  final int total;

  bool get isEmpty =>
      upcoming.isEmpty &&
      payouts.isEmpty &&
      awaitingProofCount == 0 &&
      debtXaf == 0;
}

class UpcomingPayout {
  const UpcomingPayout({
    required this.orderRef,
    required this.payoutDueAt,
    required this.estimatedXaf,
  });

  factory UpcomingPayout.fromJson(Map<String, dynamic> j) => UpcomingPayout(
        orderRef: _s(j['orderRef']),
        payoutDueAt: _d(j['payoutDueAt']),
        estimatedXaf: _i(j['estimatedXaf']),
      );

  final String orderRef;
  final DateTime? payoutDueAt;
  final int estimatedXaf;
}

class PayoutLine {
  const PayoutLine({
    required this.id,
    required this.orderRef,
    required this.status,
    required this.provider,
    required this.grossAmount,
    required this.commissionAmount,
    required this.deliverySubsidyAmount,
    required this.refundDeductionAmount,
    required this.debtDeductionAmount,
    required this.amount,
    required this.requestedAt,
    required this.completedAt,
  });

  factory PayoutLine.fromJson(Map<String, dynamic> j) => PayoutLine(
        id: _s(j['id']),
        orderRef: _s(j['orderRef']),
        status: _s(j['status']),
        provider: _s(j['provider']),
        grossAmount: _i(j['grossAmount']),
        commissionAmount: _i(j['commissionAmount']),
        deliverySubsidyAmount: _i(j['deliverySubsidyAmount']),
        refundDeductionAmount: _i(j['refundDeductionAmount']),
        debtDeductionAmount: _i(j['debtDeductionAmount']),
        amount: _i(j['amount']),
        requestedAt: _d(j['requestedAt']),
        completedAt: _d(j['completedAt']),
      );

  final String id;
  final String orderRef;
  final String status;
  final String provider;
  final int grossAmount;
  final int commissionAmount;
  final int deliverySubsidyAmount;
  final int refundDeductionAmount;
  final int debtDeductionAmount;
  final int amount;
  final DateTime? requestedAt;
  final DateTime? completedAt;

  /// Entièrement absorbé par une dette : aucun virement n'est parti.
  bool get isNetting => provider == 'NETTING';

  String get statusLabel => switch (status) {
        'SUCCESS' => isNetting ? 'Retenu sur dette' : 'Versé',
        'PENDING' => 'En cours',
        'FAILED' => 'En attente — Lilia relance',
        _ => status,
      };
}

class DebtEntry {
  const DebtEntry({
    required this.kind,
    required this.amountXaf,
    required this.note,
    required this.createdAt,
  });

  factory DebtEntry.fromJson(Map<String, dynamic> j) => DebtEntry(
        kind: _s(j['kind']),
        amountXaf: _i(j['amountXaf']),
        note: j['note'] is String ? j['note'] as String : null,
        createdAt: _d(j['createdAt']),
      );

  final String kind;

  /// Signé : négatif = dette qui naît, positif = dette réglée.
  final int amountXaf;
  final String? note;
  final DateTime? createdAt;

  String get label => switch (kind) {
        'REFUND_CLAWBACK' => 'Remboursement client après versement',
        'DEBT_SETTLED' => 'Retenu sur un versement',
        'DEBT_RESTORED' => 'Versement en échec : retenue annulée',
        'ADJUSTMENT' => 'Correction Lilia Food',
        _ => kind,
      };
}

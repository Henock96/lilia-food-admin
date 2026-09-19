/// Règlement d'un livreur — ce que Lilia Food lui a versé.
///
/// ⚠️ **Aucun virement n'est déclenché par l'application.** L'argent est remis
/// hors système (espèces, Mobile Money passé à la main) ; ces objets en
/// tiennent la comptabilité. Toute interface construite dessus doit le dire :
/// un bouton qui semble payer sera cliqué en croyant payer.
library;

enum SettlementMethod { cash, mobileMoney, bankTransfer, other }

extension SettlementMethodX on SettlementMethod {
  static SettlementMethod fromApi(String? raw) => switch (raw) {
    'CASH' => SettlementMethod.cash,
    'MOBILE_MONEY' => SettlementMethod.mobileMoney,
    'BANK_TRANSFER' => SettlementMethod.bankTransfer,
    _ => SettlementMethod.other,
  };

  String get apiValue => switch (this) {
    SettlementMethod.cash => 'CASH',
    SettlementMethod.mobileMoney => 'MOBILE_MONEY',
    SettlementMethod.bankTransfer => 'BANK_TRANSFER',
    SettlementMethod.other => 'OTHER',
  };

  String get label => switch (this) {
    SettlementMethod.cash => 'Espèces',
    SettlementMethod.mobileMoney => 'Mobile Money',
    SettlementMethod.bankTransfer => 'Virement bancaire',
    SettlementMethod.other => 'Autre',
  };
}

/// Ce qui reste dû à un livreur, à l'instant de la consultation.
///
/// ⚠️ [coveredUntil] doit être **rejoué tel quel** à l'enregistrement du
/// versement. C'est lui qui garantit que le règlement couvre exactement les
/// courses affichées — et non celles terminées pendant qu'on allait payer, qui
/// seraient sinon absorbées dans un montant déjà remis.
class DriverOutstanding {
  final int amountXaf;
  final int courseCount;
  final DateTime? periodStart;
  final DateTime coveredUntil;

  const DriverOutstanding({
    required this.amountXaf,
    required this.courseCount,
    required this.coveredUntil,
    this.periodStart,
  });

  factory DriverOutstanding.fromJson(Map<String, dynamic> json) =>
      DriverOutstanding(
        amountXaf: (json['amountXaf'] as num?)?.toInt() ?? 0,
        courseCount: (json['courseCount'] as num?)?.toInt() ?? 0,
        periodStart: _date(json['periodStart']),
        coveredUntil: _date(json['coveredUntil']) ?? DateTime.now(),
      );
}

class DriverSettlement {
  final String id;
  final int amountXaf;
  final int courseCount;
  final DateTime paidAt;
  final SettlementMethod method;
  final String? reference;
  final bool cancelled;

  const DriverSettlement({
    required this.id,
    required this.amountXaf,
    required this.courseCount,
    required this.paidAt,
    required this.method,
    required this.cancelled,
    this.reference,
  });

  factory DriverSettlement.fromJson(Map<String, dynamic> json) =>
      DriverSettlement(
        id: json['id'] as String? ?? '',
        amountXaf: (json['amountXaf'] as num?)?.toInt() ?? 0,
        courseCount: (json['courseCount'] as num?)?.toInt() ?? 0,
        paidAt: _date(json['paidAt']) ?? DateTime.now(),
        method: SettlementMethodX.fromApi(json['method'] as String?),
        reference: json['reference'] as String?,
        cancelled: json['status'] == 'CANCELLED',
      );
}

DateTime? _date(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

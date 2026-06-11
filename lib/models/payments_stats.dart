// KPI agrégés paiements pour la carte stats admin (GET /admin/payments/stats).

class PaymentsStatsBucket {
  final int count;
  final double totalXaf;

  const PaymentsStatsBucket({required this.count, required this.totalXaf});

  factory PaymentsStatsBucket.fromJson(Map<String, dynamic> json) {
    return PaymentsStatsBucket(
      count: (json['count'] as num?)?.toInt() ?? 0,
      totalXaf: (json['totalXaf'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Délai moyen de validation paiement (PENDING → confirmation) sur 7j roulants.
/// `avgMinutes` null = pas assez de données sur la fenêtre (DoD LIL-78).
class ValidationDelay {
  final double? avgMinutes;
  final int sampleCount;

  const ValidationDelay({required this.avgMinutes, required this.sampleCount});

  factory ValidationDelay.fromJson(Map<String, dynamic> json) {
    return ValidationDelay(
      avgMinutes: (json['avgMinutes'] as num?)?.toDouble(),
      sampleCount: (json['sampleCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class PaymentsStats {
  final PaymentsStatsBucket pending;
  final PaymentsStatsBucket monthSuccess;
  final PaymentsStatsBucket last7DaysSuccess;
  final ValidationDelay validationDelay;

  const PaymentsStats({
    required this.pending,
    required this.monthSuccess,
    required this.last7DaysSuccess,
    required this.validationDelay,
  });

  factory PaymentsStats.fromJson(Map<String, dynamic> json) {
    return PaymentsStats(
      pending: PaymentsStatsBucket.fromJson(
          (json['pending'] as Map<String, dynamic>?) ?? const {}),
      monthSuccess: PaymentsStatsBucket.fromJson(
          (json['monthSuccess'] as Map<String, dynamic>?) ?? const {}),
      last7DaysSuccess: PaymentsStatsBucket.fromJson(
          (json['last7DaysSuccess'] as Map<String, dynamic>?) ?? const {}),
      validationDelay: ValidationDelay.fromJson(
          (json['validationDelay'] as Map<String, dynamic>?) ?? const {}),
    );
  }
}

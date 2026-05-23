/// Statistiques agrégées d'un livreur (route `GET /admin/deliverers/:id/stats`).
///
/// **Stub LIL-85** — sera écrasé / fusionné par LIL-84 au merge. L'API
/// publique (noms de champs et types) DOIT rester identique. Si LIL-84 livre
/// un design différent, voir la section "Points d'attention pour le merge".
class DelivererStats {
  final int totalDeliveries;
  final int deliveredCount;
  final int failedCount;
  final int inProgressCount;
  final double successRate;
  final int totalRevenueXAF;
  final double? avgDeliveryMinutes;
  final int last30dDeliveries;
  final DateTime? lastDeliveryAt;

  const DelivererStats({
    required this.totalDeliveries,
    required this.deliveredCount,
    required this.failedCount,
    required this.inProgressCount,
    required this.successRate,
    required this.totalRevenueXAF,
    required this.last30dDeliveries,
    this.avgDeliveryMinutes,
    this.lastDeliveryAt,
  });

  factory DelivererStats.fromJson(Map<String, dynamic> json) {
    return DelivererStats(
      totalDeliveries: (json['totalDeliveries'] as num?)?.toInt() ?? 0,
      deliveredCount: (json['deliveredCount'] as num?)?.toInt() ?? 0,
      failedCount: (json['failedCount'] as num?)?.toInt() ?? 0,
      inProgressCount: (json['inProgressCount'] as num?)?.toInt() ?? 0,
      successRate: (json['successRate'] as num?)?.toDouble() ?? 0.0,
      totalRevenueXAF: (json['totalRevenueXAF'] as num?)?.toInt() ?? 0,
      avgDeliveryMinutes: (json['avgDeliveryMinutes'] as num?)?.toDouble(),
      last30dDeliveries: (json['last30dDeliveries'] as num?)?.toInt() ?? 0,
      lastDeliveryAt: json['lastDeliveryAt'] != null
          ? DateTime.tryParse(json['lastDeliveryAt'] as String)
          : null,
    );
  }
}

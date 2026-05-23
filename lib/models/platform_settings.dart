/// Configuration globale de la plateforme (GET/PATCH /admin/platform-settings).
class PlatformSettings {
  final String id;
  final double serviceFeePercent;
  final int loyaltyPointsPer100Xaf;
  final int loyaltyPointValueXaf;
  final int loyaltyMinRedemption;
  final int referrerBonusPoints;
  final int referredBonusPoints;
  final bool maintenanceMode;
  final String? maintenanceMessage;
  final DateTime updatedAt;

  PlatformSettings({
    required this.id,
    required this.serviceFeePercent,
    required this.loyaltyPointsPer100Xaf,
    required this.loyaltyPointValueXaf,
    required this.loyaltyMinRedemption,
    required this.referrerBonusPoints,
    required this.referredBonusPoints,
    required this.maintenanceMode,
    this.maintenanceMessage,
    required this.updatedAt,
  });

  /// Parse l'objet `data` de la réponse.
  factory PlatformSettings.fromJson(Map<String, dynamic> json) {
    return PlatformSettings(
      id: json['id'] as String? ?? 'singleton',
      serviceFeePercent: (json['serviceFeePercent'] as num?)?.toDouble() ?? 8,
      loyaltyPointsPer100Xaf: json['loyaltyPointsPer100Xaf'] as int? ?? 1,
      loyaltyPointValueXaf: json['loyaltyPointValueXaf'] as int? ?? 5,
      loyaltyMinRedemption: json['loyaltyMinRedemption'] as int? ?? 100,
      referrerBonusPoints: json['referrerBonusPoints'] as int? ?? 500,
      referredBonusPoints: json['referredBonusPoints'] as int? ?? 200,
      maintenanceMode: json['maintenanceMode'] as bool? ?? false,
      maintenanceMessage: json['maintenanceMessage'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }
}

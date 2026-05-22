/// Statistiques de parrainage d'un client (GET /admin/clients/:id/referral).
class ClientReferral {
  final String? referralCode;
  final String? referredByCode;
  final int totalReferrals;
  final int convertedReferrals;
  final int referralBonusEarned;

  ClientReferral({
    this.referralCode,
    this.referredByCode,
    required this.totalReferrals,
    required this.convertedReferrals,
    required this.referralBonusEarned,
  });

  /// Parse l'objet `data` de la réponse.
  factory ClientReferral.fromJson(Map<String, dynamic> json) {
    return ClientReferral(
      referralCode: json['referralCode'] as String?,
      referredByCode: json['referredByCode'] as String?,
      totalReferrals: json['totalReferrals'] as int? ?? 0,
      convertedReferrals: json['convertedReferrals'] as int? ?? 0,
      referralBonusEarned: json['referralBonusEarned'] as int? ?? 0,
    );
  }
}

/// Configuration globale de la plateforme (GET/PATCH /admin/platform-settings).
class PlatformSettings {
  final String id;
  final double serviceFeePercent;

  /// Forfait de points gagné par commande **livrée**.
  ///
  /// A remplacé `loyaltyPointsPer100Xaf` : le gain n'est plus proportionnel au
  /// montant, une commande de 1 000 et une de 20 000 FCFA rapportent la même
  /// chose. L'ancien champ n'a pas été détourné — un nom qui ne décrit plus le
  /// calcul est un piège pour qui reprend le code.
  final int loyaltyPointsPerOrder;

  /// Valeur d'un point, en FCFA.
  ///
  /// ⚠️ **Réglage le plus lourd de conséquences de l'écran.** Il est lu au
  /// moment de la dépense, jamais figé à l'acquisition : le modifier
  /// revalorise instantanément tout le passif déjà distribué. Ne jamais le
  /// changer sans exécuter d'abord `scripts/db/redenominate-loyalty.js`
  /// (procédure : `docs/LOYALTY.md` côté backend).
  final int loyaltyPointValueXaf;

  final int loyaltyMinRedemption;

  /// Points versés au parrain à la première commande **livrée** de son filleul.
  /// Le bonus de bienvenue du filleul a été supprimé du programme : il payait
  /// une inscription, pas un achat.
  final int referrerBonusPoints;

  final bool maintenanceMode;
  final String? maintenanceMessage;
  final DateTime updatedAt;

  PlatformSettings({
    required this.id,
    required this.serviceFeePercent,
    required this.loyaltyPointsPerOrder,
    required this.loyaltyPointValueXaf,
    required this.loyaltyMinRedemption,
    required this.referrerBonusPoints,
    required this.maintenanceMode,
    this.maintenanceMessage,
    required this.updatedAt,
  });

  /// Convertit un nombre de points en FCFA. Point de passage **unique** de
  /// l'application d'administration : aucun écran ne doit multiplier des points
  /// par une constante.
  int pointsToXaf(int points) => points * loyaltyPointValueXaf;

  /// Parse l'objet `data` de la réponse. Les valeurs de repli reprennent les
  /// `@default` du modèle Prisma, jamais une constante inventée côté client.
  factory PlatformSettings.fromJson(Map<String, dynamic> json) {
    return PlatformSettings(
      id: json['id'] as String? ?? 'singleton',
      serviceFeePercent: (json['serviceFeePercent'] as num?)?.toDouble() ?? 8,
      loyaltyPointsPerOrder: json['loyaltyPointsPerOrder'] as int? ?? 1,
      loyaltyPointValueXaf: json['loyaltyPointValueXaf'] as int? ?? 50,
      loyaltyMinRedemption: json['loyaltyMinRedemption'] as int? ?? 1,
      referrerBonusPoints: json['referrerBonusPoints'] as int? ?? 1,
      maintenanceMode: json['maintenanceMode'] as bool? ?? false,
      maintenanceMessage: json['maintenanceMessage'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }
}

/// Statistiques agrégées d'un livreur — réponse `GET /admin/deliverers/:id/stats`.
///
/// Champs JSON conformes au backend (LIL-81) :
/// ```
/// {
///   "totalDeliveries": int,
///   "deliveredCount": int,
///   "failedCount": int,
///   "inProgressCount": int,
///   "successRate": double,          // 0..100, 2 décimales
///   "totalRevenueXAF": int,
///   "avgDeliveryMinutes": double?,  // null si pas mesurable
///   "last30dDeliveries": int,
///   "lastDeliveryAt": String?       // ISO 8601, null possible
/// }
/// ```
class DelivererStats {
  /// Nombre total de livraisons (tous statuts confondus).
  final int totalDeliveries;

  /// Nombre de livraisons terminées avec succès (statut LIVRER).
  final int deliveredCount;

  /// Nombre de livraisons échouées (statut ECHEC).
  final int failedCount;

  /// Nombre de livraisons en cours (ASSIGNER + EN_TRANSIT).
  final int inProgressCount;

  /// Taux de réussite en pourcentage (0..100, 2 décimales),
  /// calculé sur `deliveredCount / (deliveredCount + failedCount)`.
  final double successRate;

  /// Valeur des commandes que ce livreur a portées, en XAF (entiers).
  ///
  /// ⚠️ **Ce n'est le revenu de personne**, et surtout pas le sien : c'est la
  /// somme des `Order.total`, donc ce que les CLIENTS ont payé, dont le gros
  /// va au vendeur. Le champ s'appelait `totalRevenueXAF` côté serveur — un
  /// nom qui, sur la fiche d'une personne, se lit « ce qu'elle a gagné ».
  final int handledOrderValueXaf;

  /// @Deprecated Alias serveur de [handledOrderValueXaf], le temps que les
  /// back-offices migrent. Ne plus l'utiliser pour de l'affichage.
  final int totalRevenueXAF;

  /// Ce que le livreur a réellement touché sur ces courses.
  ///
  /// `null` = **inconnu** : le coût d'une course n'existe nulle part dans le
  /// système (ni colonne, ni table, ni règle métier). Ne jamais afficher `0` à
  /// la place — cela transformerait « on ne sait pas » en « il n'a rien
  /// coûté », et produirait une marge surestimée avec l'air d'être exacte.
  final int? driverPayXaf;

  /// Courses livrées sans économie connue — toutes celles antérieures au
  /// 18/09/2026, aucun backfill n'ayant été fait. Sans ce compteur,
  /// [driverPayXaf] se lirait comme un cumul exhaustif.
  final int coursesWithoutEconomics;

  /// Durée moyenne de livraison (entre `pickedUpAt` et `deliveredAt`),
  /// en minutes (2 décimales). `null` si aucune livraison ne fournit
  /// les deux timestamps.
  final double? avgDeliveryMinutes;

  /// Nombre de livraisons créées dans les 30 derniers jours.
  final int last30dDeliveries;

  /// Date de la dernière livraison réussie (LIVRER), ou `null`.
  final DateTime? lastDeliveryAt;

  const DelivererStats({
    required this.totalDeliveries,
    required this.deliveredCount,
    required this.failedCount,
    required this.inProgressCount,
    required this.successRate,
    required this.handledOrderValueXaf,
    required this.totalRevenueXAF,
    this.driverPayXaf,
    this.coursesWithoutEconomics = 0,
    required this.avgDeliveryMinutes,
    required this.last30dDeliveries,
    required this.lastDeliveryAt,
  });

  factory DelivererStats.fromJson(Map<String, dynamic> json) {
    return DelivererStats(
      totalDeliveries: (json['totalDeliveries'] as num?)?.toInt() ?? 0,
      deliveredCount: (json['deliveredCount'] as num?)?.toInt() ?? 0,
      failedCount: (json['failedCount'] as num?)?.toInt() ?? 0,
      inProgressCount: (json['inProgressCount'] as num?)?.toInt() ?? 0,
      successRate: (json['successRate'] as num?)?.toDouble() ?? 0.0,
      // On lit le nom courant et on retombe sur l'ancien : une app à jour reste
      // lisible contre un backend pas encore redéployé.
      handledOrderValueXaf:
          (json['handledOrderValueXaf'] as num?)?.toInt() ??
              (json['totalRevenueXAF'] as num?)?.toInt() ??
              0,
      totalRevenueXAF: (json['totalRevenueXAF'] as num?)?.toInt() ?? 0,
      driverPayXaf: (json['driverPayXaf'] as num?)?.toInt(),
      coursesWithoutEconomics:
          (json['coursesWithoutEconomics'] as num?)?.toInt() ?? 0,
      avgDeliveryMinutes: (json['avgDeliveryMinutes'] as num?)?.toDouble(),
      last30dDeliveries: (json['last30dDeliveries'] as num?)?.toInt() ?? 0,
      lastDeliveryAt: _parseDate(json['lastDeliveryAt']),
    );
  }

  /// État neutre — utile comme placeholder ou état d'erreur côté UI.
  static const DelivererStats empty = DelivererStats(
    totalDeliveries: 0,
    deliveredCount: 0,
    failedCount: 0,
    inProgressCount: 0,
    successRate: 0.0,
    handledOrderValueXaf: 0,
    totalRevenueXAF: 0,
    // `null`, pas `0` : sans course, on ne sait pas — on n'affirme pas.
    driverPayXaf: null,
    coursesWithoutEconomics: 0,
    avgDeliveryMinutes: null,
    last30dDeliveries: 0,
    lastDeliveryAt: null,
  );

  static DateTime? _parseDate(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

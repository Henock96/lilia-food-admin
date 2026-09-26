// ignore_for_file: constant_identifier_names

import 'stock_mode.dart';

/// F3-10 — comment le stock d'un produit se renouvelle (backend `StockPolicy`).
///
/// Remplace `StockMode` (« journalier / permanent ») et le « champ vide =
/// illimité » implicite : trois choix explicites, dits dans les mots du
/// vendeur.
enum StockPolicy {
  UNLIMITED,
  DAILY_QUOTA,
  INVENTORY;

  String get label => switch (this) {
    StockPolicy.UNLIMITED => 'Toujours disponible',
    StockPolicy.DAILY_QUOTA => 'Quantité du jour',
    StockPolicy.INVENTORY => 'Stock réel',
  };

  String get help => switch (this) {
    StockPolicy.UNLIMITED =>
      'Pas de limite : vous pouvez toujours en préparer.',
    StockPolicy.DAILY_QUOTA =>
      'Vous en préparez un nombre fixe chaque jour. Le compteur revient '
          'à ce nombre chaque matin à 5 h.',
    StockPolicy.INVENTORY =>
      'Le stock baisse à chaque vente et ne remonte que quand vous '
          'réapprovisionnez.',
  };

  /// Libellé du champ quantité pour cette politique (`null` = pas de champ).
  String? get quantityLabel => switch (this) {
    StockPolicy.UNLIMITED => null,
    StockPolicy.DAILY_QUOTA => 'Quantité préparée chaque jour',
    StockPolicy.INVENTORY => 'Unités en stock',
  };

  /// `stockMode` envoyé en double : un serveur antérieur à F3-10 ignore
  /// `stockPolicy` et relit l'ancien contrat.
  StockMode get legacyMode =>
      this == StockPolicy.INVENTORY ? StockMode.PERMANENT : StockMode.DAILY;

  /// Lit la politique ; un serveur antérieur à F3-10 ne l'envoie pas, on la
  /// déduit alors de l'ancien contrat (exactement comme la migration).
  static StockPolicy fromJson(
    String? value, {
    String? stockMode,
    int? stockRestant,
  }) {
    for (final policy in StockPolicy.values) {
      if (policy.name == value) return policy;
    }
    if (stockRestant == null) return StockPolicy.UNLIMITED;
    return stockMode == 'PERMANENT'
        ? StockPolicy.INVENTORY
        : StockPolicy.DAILY_QUOTA;
  }
}

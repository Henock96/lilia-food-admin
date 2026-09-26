// ignore_for_file: constant_identifier_names

/// F3-10 — ce que compte le stock d'un produit (backend `StockUnit`).
///
/// Libellé seulement : la vérité est le nombre. C'est pourtant la parade au
/// premier risque humain du modèle — saisir « 10 » (cartons) là où le système
/// compte 60 (bouteilles). L'unité est donc affichée partout où un nombre de
/// stock l'est.
enum StockUnit {
  PIECE('unité', 'unités'),
  PORTION('portion', 'portions'),
  BOTTLE('bouteille', 'bouteilles'),
  CAN('canette', 'canettes'),
  CUP('gobelet', 'gobelets'),
  BAG('sachet', 'sachets');

  const StockUnit(this.singular, this.plural);

  final String singular;
  final String plural;

  /// « 6 bouteilles », « 1 portion ».
  String format(int units) => '$units ${units > 1 ? plural : singular}';

  /// Nom de liste : « Bouteilles ».
  String get title => plural[0].toUpperCase() + plural.substring(1);

  static StockUnit fromJson(String? value) => StockUnit.values.firstWhere(
    (u) => u.name == value,
    orElse: () => StockUnit.PIECE,
  );
}

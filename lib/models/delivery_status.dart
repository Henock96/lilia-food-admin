/// Enum aligné sur les statuts backend `DeliveryStatus`.
///
/// Backend Prisma enum :
/// `EN_ATTENTE | ASSIGNER | EN_TRANSIT | LIVRER | ECHEC`
///
/// Stubé pour LIL-85 — sera remplacé / fusionné avec la version produite par
/// LIL-84 au merge. Garde la même API publique (valeurs identiques, helpers
/// `wireValue` / `fromWire`).
enum DeliveryStatus {
  enAttente,
  assigner,
  enTransit,
  livrer,
  echec;

  /// Valeur sérialisée backend (clé Prisma).
  String get wireValue {
    switch (this) {
      case DeliveryStatus.enAttente:
        return 'EN_ATTENTE';
      case DeliveryStatus.assigner:
        return 'ASSIGNER';
      case DeliveryStatus.enTransit:
        return 'EN_TRANSIT';
      case DeliveryStatus.livrer:
        return 'LIVRER';
      case DeliveryStatus.echec:
        return 'ECHEC';
    }
  }

  /// Parse une valeur backend `DeliveryStatus`. Retourne [DeliveryStatus.enAttente]
  /// si la valeur est inconnue ou nulle (fallback safe pour ne pas crasher l'UI).
  static DeliveryStatus fromWire(String? value) {
    switch (value) {
      case 'EN_ATTENTE':
        return DeliveryStatus.enAttente;
      case 'ASSIGNER':
        return DeliveryStatus.assigner;
      case 'EN_TRANSIT':
        return DeliveryStatus.enTransit;
      case 'LIVRER':
        return DeliveryStatus.livrer;
      case 'ECHEC':
        return DeliveryStatus.echec;
      default:
        return DeliveryStatus.enAttente;
    }
  }
}

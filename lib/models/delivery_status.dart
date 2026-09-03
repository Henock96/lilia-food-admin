import 'dart:developer' as developer;

/// Statuts d'une livraison — miroir de l'enum Prisma `DeliveryStatus`.
///
/// ⚠️ `accepter` a été ajouté côté backend le 29/08/2026 et manquait ici :
/// `fromWire('ACCEPTER')` retombait sur `enAttente`, et l'écran de suivi en
/// déduisait « pas en livraison ». La carte de toute course acceptée mais non
/// encore récupérée était donc invisible pour l'admin — un « Maps ne marche
/// pas » qui n'avait rien à voir avec Maps.
///
/// Le repli silencieux du `default:` masquait la divergence : il est conservé
/// (une valeur inconnue ne doit pas casser l'écran) mais il journalise
/// désormais, pour qu'un futur écart se voie au lieu de se taire.
enum DeliveryStatus {
  enAttente,
  assigner,
  accepter,
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
      case DeliveryStatus.accepter:
        return 'ACCEPTER';
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
      case 'ACCEPTER':
        return DeliveryStatus.accepter;
      case 'EN_TRANSIT':
        return DeliveryStatus.enTransit;
      case 'LIVRER':
        return DeliveryStatus.livrer;
      case 'ECHEC':
        return DeliveryStatus.echec;
      default:
        // Une valeur que cette version de l'app ne connaît pas. On ne casse
        // pas l'écran, mais on le dit : c'est exactement ce silence qui a
        // laissé passer l'ajout d'`ACCEPTER` pendant plusieurs jours.
        assert(
          value == null,
          'DeliveryStatus inconnu reçu du backend : "$value" — '
          "l'enum de l'admin est en retard sur Prisma.",
        );
        if (value != null) {
          developer.log(
            'DeliveryStatus inconnu : $value',
            name: 'lilia.admin.delivery',
          );
        }
        return DeliveryStatus.enAttente;
    }
  }
}

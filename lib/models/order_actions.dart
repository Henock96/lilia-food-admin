import 'order.dart';
import 'role.dart';

/// Geste qu'une interface peut proposer sur une commande (Phase 3, F3-01).
///
/// Le serveur publie la liste dans `allowedActions` (règle R1) : c'est lui
/// qui sait ce qu'il acceptera. L'application ne fait que l'afficher.
enum OrderAction {
  accept('ACCEPT'),
  reject('REJECT'),
  startPreparation('START_PREPARATION'),
  markReady('MARK_READY'),
  handOver('HAND_OVER'),
  cancel('CANCEL');

  const OrderAction(this.wire);
  final String wire;

  static OrderAction? fromWire(Object? raw) {
    for (final action in values) {
      if (action.wire == raw) return action;
    }
    return null;
  }

  /// `null` si le champ est absent ; les gestes inconnus de cette version sont
  /// ignorés plutôt que devinés.
  static List<OrderAction>? listFromWire(Object? raw) {
    if (raw is! List) return null;
    return raw.map(fromWire).whereType<OrderAction>().toList();
  }

  /// Statut visé par la route de statut ; `null` pour Accepter et Refuser,
  /// qui ont leur propre route (temps de préparation, motif).
  OrderStatus? get targetStatus => switch (this) {
        OrderAction.startPreparation => OrderStatus.enpreparation,
        OrderAction.markReady => OrderStatus.pret,
        OrderAction.handOver => OrderStatus.livrer,
        OrderAction.cancel => OrderStatus.annuler,
        OrderAction.accept || OrderAction.reject => null,
      };
}

/// Gestes à proposer : ceux que publie le serveur, rien d'autre.
///
/// Lot 5 (ADM-17, règle 4) — l'ancien repli recalculait les gestes à partir
/// d'une copie locale de la matrice de transitions (`order_transitions.dart`)
/// quand le serveur ne publiait pas `allowedActions`. Tous les serveurs en
/// service la publient depuis la Phase 3 ; la copie, elle, pouvait diverger.
/// Sans `allowedActions`, aucun geste : mieux vaut ne rien proposer que
/// deviner. [role] reste dans la signature pour les appelants.
List<OrderAction> resolveOrderActions(Order order, Role role) =>
    order.allowedActions ?? const [];

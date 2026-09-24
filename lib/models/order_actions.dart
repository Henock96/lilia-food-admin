import 'order.dart';
import 'order_transitions.dart';
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

/// Gestes à proposer : ceux du serveur, sinon l'ancienne logique locale.
///
/// Le repli ne sert que face à un serveur antérieur à la Phase 3, qui ne
/// publie pas `allowedActions` — et qui n'a donc ni `/accept` ni `/reject` :
/// il ne les propose jamais. À supprimer, avec `order_transitions.dart`, une
/// fois ce serveur-là disparu.
List<OrderAction> resolveOrderActions(Order order, Role role) {
  final published = order.allowedActions;
  if (published != null) return published;

  return availableOrderTransitions(
    current: order.status,
    role: role,
    isDelivery: order.isDelivery,
  ).map((status) => switch (status) {
        OrderStatus.enpreparation => OrderAction.startPreparation,
        OrderStatus.pret => OrderAction.markReady,
        OrderStatus.livrer => OrderAction.handOver,
        OrderStatus.annuler => OrderAction.cancel,
        _ => null,
      }).whereType<OrderAction>().toList();
}

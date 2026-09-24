import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/models/order.dart';
import 'package:lilia_admin/models/order_actions.dart';
import 'package:lilia_admin/models/role.dart';

/// Gestes proposés sur une commande (Phase 3, F3-01 — règle R1).
///
/// Le serveur publie `allowedActions` : l'application n'a plus à recopier la
/// matrice de transitions, copie qui avait divergé (audit du 22/09/2026). Le
/// repli sur l'ancienne logique ne sert que face à un serveur antérieur, qui ne
/// publie rien — et qui ne connaît donc pas `/accept` ni `/reject`.
Order _order({
  String status = 'PAYER',
  bool isDelivery = true,
  Object? allowedActions,
  String? acceptDeadlineAt,
  String? estimatedReadyAt,
}) =>
    Order.fromJson({
      'id': 'o-1',
      'total': 6750,
      'createdAt': '2026-09-24T12:00:00.000Z',
      'status': status,
      'isDelivery': isDelivery,
      'items': [],
      'allowedActions': ?allowedActions,
      'acceptDeadlineAt': ?acceptDeadlineAt,
      'estimatedReadyAt': ?estimatedReadyAt,
    });

void main() {
  group('statuts', () {
    test('ACCEPTEE et ECHEC_LIVRAISON sont reconnus, pas rangés en « inconnu »', () {
      expect(Order.statusFromWire('ACCEPTEE'), OrderStatus.acceptee);
      expect(Order.statusFromWire('ECHEC_LIVRAISON'), OrderStatus.echecLivraison);
    });

    test('aller-retour : tout statut connu se réécrit à l’identique', () {
      for (final status in OrderStatus.values.where((s) => s != OrderStatus.unknown)) {
        expect(Order.statusFromWire(status.toWire()), status, reason: status.name);
      }
    });
  });

  group('lecture de la commande', () {
    test('lit les gestes publiés, l’échéance et l’heure de fin annoncée', () {
      final order = _order(
        allowedActions: ['ACCEPT', 'REJECT'],
        acceptDeadlineAt: '2026-09-24T12:08:00.000Z',
        estimatedReadyAt: '2026-09-24T12:20:00.000Z',
      );
      expect(order.allowedActions, [OrderAction.accept, OrderAction.reject]);
      expect(order.acceptDeadlineAt, DateTime.utc(2026, 9, 24, 12, 8));
      expect(order.estimatedReadyAt, DateTime.utc(2026, 9, 24, 12, 20));
    });

    test('un geste inconnu de cette version est ignoré, pas deviné', () {
      final order = _order(allowedActions: ['ACCEPT', 'TELEPORT']);
      expect(order.allowedActions, [OrderAction.accept]);
    });

    test('champ absent (serveur antérieur) : null, pas une liste vide', () {
      // Une liste vide voudrait dire « aucun geste permis » ; l'absence veut
      // dire « le serveur ne le dit pas », et déclenche le repli.
      expect(_order().allowedActions, isNull);
    });

    test('copyWith conserve gestes et échéance', () {
      final order = _order(allowedActions: ['ACCEPT'], acceptDeadlineAt: '2026-09-24T12:08:00.000Z');
      final copy = order.copyWith(status: OrderStatus.acceptee);
      expect(copy.allowedActions, [OrderAction.accept]);
      expect(copy.acceptDeadlineAt, order.acceptDeadlineAt);
    });
  });

  group('resolveOrderActions', () {
    test('le serveur fait foi quand il publie', () {
      final order = _order(allowedActions: ['ACCEPT', 'REJECT']);
      expect(
        resolveOrderActions(order, Role.restaurateur),
        [OrderAction.accept, OrderAction.reject],
      );
    });

    test('liste vide publiée : aucun geste (le serveur a tranché)', () {
      final order = _order(status: 'LIVRER', allowedActions: <String>[]);
      expect(resolveOrderActions(order, Role.admin), isEmpty);
    });

    test('serveur antérieur : repli sur l’ancienne logique, sans Accepter ni Refuser', () {
      // Ces deux routes n'existent pas sur un serveur qui ne publie pas les
      // gestes : les proposer produirait un 404.
      final actions = resolveOrderActions(_order(status: 'PAYER'), Role.restaurateur);
      expect(actions, [OrderAction.startPreparation, OrderAction.cancel]);
    });

    test('repli : retrait au comptoir seulement pour une commande à emporter', () {
      expect(
        resolveOrderActions(_order(status: 'PRET', isDelivery: false), Role.restaurateur),
        contains(OrderAction.handOver),
      );
      expect(
        resolveOrderActions(_order(status: 'PRET', isDelivery: true), Role.restaurateur),
        isNot(contains(OrderAction.handOver)),
      );
    });
  });

  group('OrderAction', () {
    test('chaque geste de changement de statut vise le bon statut', () {
      expect(OrderAction.startPreparation.targetStatus, OrderStatus.enpreparation);
      expect(OrderAction.markReady.targetStatus, OrderStatus.pret);
      expect(OrderAction.handOver.targetStatus, OrderStatus.livrer);
      expect(OrderAction.cancel.targetStatus, OrderStatus.annuler);
    });

    test('Accepter et Refuser ne passent pas par la route de statut', () {
      expect(OrderAction.accept.targetStatus, isNull);
      expect(OrderAction.reject.targetStatus, isNull);
    });
  });
}

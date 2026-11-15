import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/features/deliveries/data/delivery_service.dart';

/// Verdict serveur du dispatch FCFS (`GET /deliveries/by-order/:id/dispatch`).
/// Le bouton d'affectation suit `manualAssignmentAllowed` ; l'app ne déduit
/// rien de l'interrupteur elle-même.
void main() {
  Map<String, dynamic> payload({
    String mode = 'AUTOMATIC',
    bool manual = false,
    bool redispatch = false,
    String state = 'SEARCHING',
    Map<String, dynamic>? deliverer,
  }) => {
    'orderId': 'o-1',
    'isDelivery': true,
    'mode': mode,
    'manualAssignmentAllowed': manual,
    'redispatchAllowed': redispatch,
    'maxRounds': 5,
    'roundIntervalSeconds': 180,
    'deliveryId': 'd-1',
    'deliveryStatus': 'EN_ATTENTE',
    'state': state,
    'startedAt': '2026-11-10T12:00:00.000Z',
    'nextRoundAt': '2026-11-10T12:03:00.000Z',
    'endedAt': null,
    'outcome': null,
    'endReason': null,
    'round': 2,
    'notifiedCount': 7,
    'waitingSeconds': 95,
    'acceptedAt': null,
    'deliverer': deliverer,
  };

  test('recherche en cours : libellé, compteurs, aucune affectation', () {
    final v = OrderDispatchView.fromJson(payload());
    expect(v.isAutomatic, isTrue);
    expect(v.isSearching, isTrue);
    expect(v.label, 'Recherche d’un livreur en cours');
    expect(v.notifiedCount, 7);
    expect(v.round, 2);
    expect(v.maxRounds, 5);
    expect(v.waitingSeconds, 95);
    expect(v.startedAt, DateTime.utc(2026, 11, 10, 12).toLocal());
    expect(v.manualAssignmentAllowed, isFalse);
    expect(v.redispatchAllowed, isFalse);
  });

  test('attribuée : « Livreur attribué : Nom »', () {
    final v = OrderDispatchView.fromJson(
      payload(state: 'ASSIGNED', deliverer: {'id': 'u1', 'nom': 'Awa'}),
    );
    expect(v.isAssigned, isTrue);
    expect(v.label, 'Livreur attribué : Awa');
  });

  test('épuisée : relance possible pour l’admin (verdict serveur)', () {
    final v = OrderDispatchView.fromJson(
      payload(state: 'EXHAUSTED', redispatch: true),
    );
    expect(v.isExhausted, isTrue);
    expect(v.redispatchAllowed, isTrue);
    expect(v.label, contains('relance'));
  });

  test('mode manuel (interrupteur éteint) : l’affectation reste permise', () {
    final v = OrderDispatchView.fromJson(
      payload(mode: 'MANUAL', manual: true, state: 'NONE'),
    );
    expect(v.isAutomatic, isFalse);
    expect(v.manualAssignmentAllowed, isTrue);
    expect(v.label, 'Aucune recherche automatique');
  });

  test('champs absents : valeurs sûres, jamais d’exception', () {
    final v = OrderDispatchView.fromJson(const {});
    expect(v.mode, 'MANUAL');
    expect(v.state, 'NONE');
    expect(v.manualAssignmentAllowed, isFalse);
    expect(v.round, 0);
    expect(v.notifiedCount, 0);
    expect(v.delivererName, isNull);
  });
}

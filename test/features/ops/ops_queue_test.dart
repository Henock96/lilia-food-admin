import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/features/ops/data/ops_queue_service.dart';
import 'package:lilia_admin/models/incident.dart';

/// Cockpit ops (F3-04), app admin.
void main() {
  test('files lues telles que le serveur les calcule', () {
    final q = OpsQueue.fromJson({
      'total': 3,
      'buckets': [
        {
          'key': 'acceptance_late',
          'label': 'Payées, pas encore prises en charge',
          'severity': 'HIGH',
          'count': 3,
          'items': [
            {
              'id': 'o1',
              'orderId': 'o1',
              'title': 'Commande #ABCDEF — Chez Lili',
              'detail': null,
              'since': '2026-09-28T11:00:00.000Z',
            },
          ],
        },
        {
          'key': 'refunds_pending',
          'label': 'Remboursements',
          'severity': 'MEDIUM',
          'count': 0,
          'items': [],
        },
      ],
    });
    expect(q.total, 3);
    expect(q.active.map((b) => b.key), ['acceptance_late']);
    expect(q.active.single.isHigh, isTrue);
    expect(q.active.single.items.single.orderId, 'o1');
  });

  test('ancienneté lisible', () {
    final now = DateTime.utc(2026, 9, 28, 12);
    expect(
      ageLabel(DateTime.utc(2026, 9, 28, 11, 48), now: now),
      'il y a 12 min',
    );
    expect(ageLabel(DateTime.utc(2026, 9, 28, 9), now: now), 'il y a 3 h');
    expect(ageLabel(DateTime.utc(2026, 9, 25, 12), now: now), 'il y a 3 j');
  });

  test('les incidents ouverts par le système ont leur type', () {
    expect(IncidentType.fromWire('OPS_SLA_BREACH'), IncidentType.opsSlaBreach);
    expect(IncidentType.metricAnomaly.wireValue, 'METRIC_ANOMALY');
  });
}

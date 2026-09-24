import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/features/closures/data/vendor_opening_service.dart';

/// Fermetures datées (F3-03), vue vendeur.
void main() {
  final now = DateTime.utc(2026, 9, 28, 10); // 11h00 à Brazzaville

  test('heure de Brazzaville, jour même : l’heure seule', () {
    expect(
      formatBrazzaville(DateTime.utc(2026, 9, 28, 13, 30), now: now),
      '14h30',
    );
  });

  test('autre jour : la date et l’heure', () {
    expect(
      formatBrazzaville(DateTime.utc(2026, 10, 2, 7), now: now),
      '02/10 à 08h00',
    );
  });

  test('état décidé par le serveur, lu tel quel', () {
    final s = VendorOpeningState.fromJson({
      'isOpen': false,
      'reason': 'PAUSED',
      'until': '2026-09-28T13:30:00.000Z',
      'pausedUntil': '2026-09-28T13:30:00.000Z',
      'closedOnHolidays': true,
      'closures': [
        {
          'id': 'c1',
          'startsAt': '2026-12-24T07:00:00.000Z',
          'endsAt': '2026-12-31T07:00:00.000Z',
          'reason': null,
        },
      ],
    });
    expect(openingSummary(s, now: now), 'En pause jusqu’à 14h30');
    expect(s.closures.single.id, 'c1');
  });

  test('raison inconnue d’un serveur plus récent : fermée, sans planter', () {
    final s = VendorOpeningState.fromJson({'isOpen': false, 'reason': 'NEW'});
    expect(openingSummary(s), 'Fermée (hors horaires)');
  });
}

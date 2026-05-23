import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/core/utils/geo.dart';

void main() {
  group('haversineKm', () {
    test('returns 0 for identical coordinates', () {
      expect(haversineKm(-4.2634, 15.2429, -4.2634, 15.2429), 0);
    });

    test('Brazzaville-Pointe-Noire (~390 km vol d\'oiseau)', () {
      // Brazzaville (-4.2634, 15.2429) → Pointe-Noire (-4.7980, 11.8636)
      final d = haversineKm(-4.2634, 15.2429, -4.7980, 11.8636);
      expect(d, greaterThan(370));
      expect(d, lessThan(410));
    });

    test('Brazzaville-Kinshasa (~5-12 km traversée fleuve)', () {
      // Centre Brazzaville → centre Kinshasa
      final d = haversineKm(-4.2634, 15.2429, -4.3253, 15.3120);
      expect(d, greaterThan(7));
      expect(d, lessThan(12));
    });
  });

  group('etaMinutes', () {
    test('5 km à 25 km/h = 12 min', () {
      // 5 / 25 * 60 = 12.0
      expect(etaMinutes(5), 12);
    });

    test('rounds correctly (1 km à 25 km/h = 2.4 min → 2)', () {
      expect(etaMinutes(1), 2);
    });

    test('handles custom avgKmh (5 km à 50 km/h = 6 min)', () {
      expect(etaMinutes(5, avgKmh: 50), 6);
    });

    test('0 distance = 0 min', () {
      expect(etaMinutes(0), 0);
    });

    test('negative distance returns 0 (defensive)', () {
      expect(etaMinutes(-3), 0);
    });

    test('0 avgKmh returns 0 (defensive — avoid division by zero)', () {
      expect(etaMinutes(5, avgKmh: 0), 0);
    });
  });
}

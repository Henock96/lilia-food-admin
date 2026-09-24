import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/features/delivery_pricing/data/delivery_pricing_service.dart';
import 'package:lilia_admin/models/restaurant.dart';

/// F3-02 — grille plateforme et part offerte, vue vendeur.
void main() {
  group('CurrentDeliveryTariff', () {
    test('mode plateforme : tranches triées par distance', () {
      final t = CurrentDeliveryTariff.fromJson({
        'mode': 'PLATFORM',
        'tariff': {
          'version': 2,
          'bands': [
            {'maxKm': 6, 'feeXaf': 1500},
            {'maxKm': 3, 'feeXaf': 1000},
          ],
        },
      });
      expect(t.isPlatform, isTrue);
      expect(t.version, 2);
      expect(t.bands.map((b) => b.maxKm), [3, 6]);
    });

    test('mode vendeur sans grille', () {
      final t = CurrentDeliveryTariff.fromJson({
        'mode': 'VENDOR_LEGACY',
        'tariff': null,
      });
      expect(t.isPlatform, isFalse);
      expect(t.bands, isEmpty);
    });
  });

  group('DeliverySubsidySetting', () {
    test('seule la valeur du mode choisi part', () {
      expect(
        const DeliverySubsidySetting(
          mode: 'FIXED',
          amountXaf: 500,
          thresholdXaf: 9000,
        ).toJson(),
        {'mode': 'FIXED', 'amountXaf': 500},
      );
      expect(
        const DeliverySubsidySetting(
          mode: 'FREE_ABOVE',
          thresholdXaf: 9000,
        ).toQuery(),
        {'mode': 'FREE_ABOVE', 'thresholdXaf': '9000'},
      );
      expect(const DeliverySubsidySetting(mode: 'NONE').toJson(), {
        'mode': 'NONE',
      });
    });
  });

  group('Restaurant — réglage de subvention', () {
    test('lu depuis la vue gestionnaire et conservé par copyWith', () {
      final r = Restaurant.fromJson({
        'id': 'r1',
        'nom': 'Chez Lili',
        'deliverySubsidyMode': 'FIXED',
        'deliverySubsidyXaf': 300,
      });
      expect(r.deliverySubsidyMode, 'FIXED');
      final copy = r.copyWith(isOpen: false);
      expect(copy.deliverySubsidyMode, 'FIXED');
      expect(copy.deliverySubsidyXaf, 300);
    });

    test('serveur antérieur à F3-02 : aucune part offerte', () {
      final r = Restaurant.fromJson({'id': 'r1', 'nom': 'Chez Lili'});
      expect(r.deliverySubsidyMode, 'NONE');
      expect(r.deliverySubsidyXaf, isNull);
    });
  });
}

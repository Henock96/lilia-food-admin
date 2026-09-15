import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/models/platform_settings.dart';

void main() {
  group('PlatformSettings.fromJson — canal de mise à jour', () {
    test('lit les cinq champs quand ils sont présents', () {
      final s = PlatformSettings.fromJson({
        'id': 'singleton',
        'minAppVersion': '1.3.0',
        'latestAppVersion': '1.4.0+41',
        'updateUrlAndroid': 'https://play.google.com/store/apps/details?id=x',
        'updateUrlIos': 'https://apps.apple.com/app/id123',
        'updateMessage': 'Nouveautés du panier',
      });

      expect(s.minAppVersion, '1.3.0');
      expect(s.latestAppVersion, '1.4.0+41');
      expect(s.updateUrlAndroid,
          'https://play.google.com/store/apps/details?id=x');
      expect(s.updateUrlIos, 'https://apps.apple.com/app/id123');
      expect(s.updateMessage, 'Nouveautés du panier');
    });

    // C'est l'état réel de la production au 08/09/2026 : les colonnes
    // existent, aucune n'est renseignée. L'écran doit s'ouvrir dessus.
    test('rend null sur les cinq quand la réponse ne les porte pas', () {
      final s = PlatformSettings.fromJson({'id': 'singleton'});

      expect(s.minAppVersion, isNull);
      expect(s.latestAppVersion, isNull);
      expect(s.updateUrlAndroid, isNull);
      expect(s.updateUrlIos, isNull);
      expect(s.updateMessage, isNull);
    });

    // `as String?` sur un nombre lèverait ; une app à jour contre un backend
    // qui renverrait n'importe quoi ne doit pas planter l'écran de réglages.
    test('rend null plutôt que de lever sur une valeur non-chaîne', () {
      final s = PlatformSettings.fromJson({
        'id': 'singleton',
        'minAppVersion': 130,
      });

      expect(s.minAppVersion, isNull);
    });

    test('ne casse pas les champs existants', () {
      final s = PlatformSettings.fromJson({
        'id': 'singleton',
        'serviceFeePercent': 15,
        'loyaltyPointValueXaf': 50,
        'maintenanceMode': true,
      });

      expect(s.serviceFeePercent, 15);
      expect(s.loyaltyPointValueXaf, 50);
      expect(s.maintenanceMode, isTrue);
    });
  });
}

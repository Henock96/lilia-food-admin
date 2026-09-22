import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/features/admin/domain/platform_settings_form.dart';
import 'package:lilia_admin/models/platform_settings.dart';

/// Configuration de production au 22/09/2026.
PlatformSettings _prod({String? minAppVersion = '1.3.0', String? latest = '1.3.0'}) =>
    PlatformSettings(
      id: 'singleton',
      serviceFeePercent: 15,
      restaurantCommissionPercent: 10,
      loyaltyPointsPerOrder: 1,
      loyaltyPointValueXaf: 50,
      loyaltyMinRedemption: 1,
      referrerBonusPoints: 1,
      maintenanceMode: false,
      maintenanceMessage: '',
      minAppVersion: minAppVersion,
      latestAppVersion: latest,
      updateUrlAndroid:
          'https://play.google.com/store/apps/details?id=com.dreesis.lilia.lilia_app',
      updateUrlIos: null,
      updateMessage: 'Nouvelle mise à jour Lilia Food disponible !🥳',
      updatedAt: DateTime.utc(2026, 9, 22, 10),
      updatedAtRaw: '2026-09-22T10:00:00.000Z',
    );

SettingsFormValues _form(
  PlatformSettings s, {
  Map<String, String> numbers = const {},
  String? min,
  String? latest,
  String? urlIos,
  String? message,
  String? maintenanceMessage,
  String block = '',
}) =>
    SettingsFormValues(
      numbers: {
        'serviceFeePercent': '${s.serviceFeePercent}',
        'restaurantCommissionPercent': '${s.restaurantCommissionPercent}',
        'loyaltyPointsPerOrder': '${s.loyaltyPointsPerOrder}',
        'loyaltyPointValueXaf': '${s.loyaltyPointValueXaf}',
        'loyaltyMinRedemption': '${s.loyaltyMinRedemption}',
        'referrerBonusPoints': '${s.referrerBonusPoints}',
        ...numbers,
      },
      maintenanceMode: s.maintenanceMode,
      maintenanceMessage: maintenanceMessage ?? s.maintenanceMessage ?? '',
      minAppVersion: min ?? s.minAppVersion ?? '',
      latestAppVersion: latest ?? s.latestAppVersion ?? '',
      updateUrlAndroid: s.updateUrlAndroid ?? '',
      updateUrlIos: urlIos ?? s.updateUrlIos ?? '',
      updateMessage: message ?? s.updateMessage ?? '',
      blockConfirmation: block,
    );

void main() {
  group('saisie numérique stricte (SET-003)', () {
    const decimal = NumberFieldSpec('Frais de service', integer: false);
    const integer = NumberFieldSpec("Valeur d'un point", integer: true);

    for (final raw in ['12,5', 'abc', '12foo', '', '  ', '-5', '1e3']) {
      test('refuse « $raw »', () {
        expect(parseNumberField(raw, decimal).error, isNotNull);
      });
    }

    test('la virgule décimale est expliquée', () {
      expect(parseNumberField('12,5', decimal).error, contains('point'));
    });

    test('accepte décimal et entier', () {
      expect(parseNumberField('12.5', decimal).value, 12.5);
      expect(parseNumberField(' 50 ', integer).value, 50);
    });

    test('un entier attendu refuse un décimal', () {
      expect(parseNumberField('12.5', integer).error, isNotNull);
    });

    test('toute saisie invalide bloque le PATCH — plus de repli silencieux', () {
      final s = _prod();
      for (final key in numberFieldSpecs.keys) {
        final r = buildSettingsPatch(_form(s, numbers: {key: 'abc'}), s);
        expect(r.ok, isFalse, reason: '$key = abc a été accepté');
      }
    });
  });

  group('PATCH minimal + verrou (SET-001)', () {
    test('rien de modifié : seulement le verrou, changed = false', () {
      final s = _prod();
      final r = buildSettingsPatch(_form(s), s);
      expect(r.ok, isTrue);
      expect(r.changed, isFalse);
      expect(r.patch, {'expectedUpdatedAt': '2026-09-22T10:00:00.000Z'});
    });

    test('seul le champ modifié part — les réglages de mise à jour ne sont pas réécrits', () {
      final s = _prod();
      final r = buildSettingsPatch(
          _form(s, numbers: {'serviceFeePercent': '12.5'}), s);
      expect(r.patch, {
        'expectedUpdatedAt': '2026-09-22T10:00:00.000Z',
        'serviceFeePercent': 12.5,
      });
    });

    test('« 15 » face à 15.0 en base : pas un changement', () {
      final s = _prod();
      final r =
          buildSettingsPatch(_form(s, numbers: {'serviceFeePercent': '15'}), s);
      expect(r.changed, isFalse);
    });

    test('maintenanceMessage "" en base, vide à l\'écran : pas un changement', () {
      final s = _prod();
      expect(buildSettingsPatch(_form(s, maintenanceMessage: '  '), s).changed,
          isFalse);
    });
  });

  group('canal de mise à jour', () {
    test('lever le blocage : null, sans confirmation', () {
      final s = _prod();
      final r = buildSettingsPatch(_form(s, min: ''), s);
      expect(r.ok, isTrue);
      expect(r.patch['minAppVersion'], isNull);
      expect(r.patch.containsKey('minAppVersion'), isTrue);
    });

    test('poser un nouveau blocage sans BLOQUER : refusé', () {
      final s = _prod();
      final r = buildSettingsPatch(_form(s, min: '1.3.1', latest: '1.3.1'), s);
      expect(r.ok, isFalse);
    });

    test('avec BLOQUER : accepté, et le mot n\'est jamais envoyé', () {
      final s = _prod();
      final r = buildSettingsPatch(
          _form(s, min: '1.3.1', latest: '1.3.1', block: 'bloquer'), s);
      expect(r.ok, isTrue);
      expect(r.patch['minAppVersion'], '1.3.1');
      expect(r.patch.containsKey('blockConfirmation'), isFalse);
    });

    test('URL iOS de gabarit : refusée', () {
      final s = _prod();
      final r = buildSettingsPatch(
          _form(s,
              urlIos: 'https://apps.apple.com/app/lilia-food/id6740000000'),
          s);
      expect(r.ok, isFalse);
    });

    test('message de plus de 300 caractères : refusé', () {
      final s = _prod();
      expect(buildSettingsPatch(_form(s, message: 'x' * 301), s).ok, isFalse);
    });

    test('état hérité incohérent : bloque tout enregistrement jusqu\'à correction', () {
      final legacy = _prod(latest: null);
      final r = buildSettingsPatch(
          _form(legacy, numbers: {'serviceFeePercent': '12'}), legacy);
      expect(r.ok, isFalse);
    });
  });

  test('updatedAt inconnu : le verrou est omis plutôt qu\'inventé', () {
    final s = PlatformSettings.fromJson({'serviceFeePercent': 15});
    final r = buildSettingsPatch(_form(s), s);
    expect(r.patch.containsKey('expectedUpdatedAt'), isFalse);
  });
}

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
  String? min,
  String? latest,
  String? urlIos,
  String? message,
  String? maintenanceMessage,
  String block = '',
}) =>
    SettingsFormValues(
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
  /// R-09 — les réglages qui fixent de l'argent ne sont plus modifiables ici :
  /// ils se demandent depuis l'admin web et s'approuvent à deux.
  test('le PATCH ne porte jamais un réglage d’argent', () {
    final s = _prod();
    final r = buildSettingsPatch(_form(s, maintenanceMessage: 'Retour à 14 h'), s);
    const financial = {
      'serviceFeePercent',
      'groceryServiceFeeBps',
      'restaurantCommissionPercent',
      'loyaltyPointValueXaf',
      'loyaltyPointsPerOrder',
      'loyaltyMinRedemption',
      'referrerBonusPoints',
      'vendorPayoutAutoEnabled',
      'vendorPayoutDelayMinutes',
      'deliveryPricingMode',
    };
    expect(r.patch.keys.toSet().intersection(financial), isEmpty);
    expect(r.patch['maintenanceMessage'], 'Retour à 14 h');
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
      final r = buildSettingsPatch(_form(s, maintenanceMessage: 'Retour à 14 h'), s);
      expect(r.patch, {
        'expectedUpdatedAt': '2026-09-22T10:00:00.000Z',
        'maintenanceMessage': 'Retour à 14 h',
      });
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
          _form(legacy, maintenanceMessage: 'Retour à 14 h'), legacy);
      expect(r.ok, isFalse);
    });
  });

  test('updatedAt inconnu : le verrou est omis plutôt qu\'inventé', () {
    final s = PlatformSettings.fromJson({'serviceFeePercent': 15});
    final r = buildSettingsPatch(_form(s), s);
    expect(r.patch.containsKey('expectedUpdatedAt'), isFalse);
  });

  // D-4 (10/10/2026) — frais de service propres aux épiceries : saisis en %,
  // envoyés en points de base, vide = taux général.
  test('D-4 — affichage du taux épicerie : 500 bps → « 5 », null → vide', () {
    PlatformSettings d4({int? bps}) => PlatformSettings.fromJson({
          'id': 'singleton',
          'serviceFeePercent': 15,
          'groceryServiceFeeBps': bps,
          'updatedAt': '2026-10-10T10:00:00.000Z',
        });
    expect(groceryServiceFeeText(d4(bps: 500)), '5');
    expect(groceryServiceFeeText(d4(bps: 750)), '7.5');
    expect(groceryServiceFeeText(d4()), '');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/features/admin/domain/app_update_rules.dart';

void main() {
  group('AppVersionRef.tryParse', () {
    test('accepte major.minor.patch avec et sans build', () {
      expect(AppVersionRef.tryParse('1.3.0').toString(), '1.3.0');
      expect(AppVersionRef.tryParse('1.3.0+34').toString(), '1.3.0+34');
      expect(AppVersionRef.tryParse('  v1.3.0  ').toString(), '1.3.0');
    });

    // Une saisie approximative ne doit jamais devenir un seuil valide : ce
    // champ peut bloquer tout le parc.
    test('refuse tout le reste', () {
      expect(AppVersionRef.tryParse('1.2'), isNull);
      expect(AppVersionRef.tryParse('1.3.x'), isNull);
      expect(AppVersionRef.tryParse('v2 beta'), isNull);
      expect(AppVersionRef.tryParse('1.3.0-rc1'), isNull);
      expect(AppVersionRef.tryParse(''), isNull);
      expect(AppVersionRef.tryParse('   '), isNull);
      expect(AppVersionRef.tryParse(null), isNull);
    });
  });

  group('AppVersionRef.compareTo', () {
    test('ordonne numériquement, pas lexicographiquement', () {
      final v1_3_0 = AppVersionRef.tryParse('1.3.0')!;
      final v1_10_0 = AppVersionRef.tryParse('1.10.0')!;
      expect(v1_3_0 < v1_10_0, isTrue);
      expect(v1_10_0 > v1_3_0, isTrue);
    });

    test('départage par build quand les deux en portent un', () {
      final a = AppVersionRef.tryParse('1.3.0+34')!;
      final b = AppVersionRef.tryParse('1.3.0+35')!;
      expect(a < b, isTrue);
    });

    // Parité stricte avec lilia-app/lib/core/update/app_version.dart:92-101.
    // Le serveur publie souvent « 1.3.0 » sans build ; s'en servir pour
    // départager rendrait la version sans build artificiellement plus
    // ancienne, et le plafond laisserait passer ce qu'il doit refuser.
    test('ne départage pas sur le build quand l\'une n\'en a pas', () {
      final sans = AppVersionRef.tryParse('1.3.0')!;
      final avec = AppVersionRef.tryParse('1.3.0+34')!;
      expect(sans.compareTo(avec), 0);
      expect(avec.compareTo(sans), 0);
      expect(sans <= avec, isTrue);
      expect(avec <= sans, isTrue);
    });
  });

  group('validateAppUpdate', () {
    List<String> run({
      String min = '',
      String latest = '',
      String android = '',
      String ios = '',
    }) =>
        validateAppUpdate(
          minVersion: min,
          latestVersion: latest,
          urlAndroid: android,
          urlIos: ios,
        );

    test('tout vide est acceptable — c\'est l\'état de départ', () {
      expect(run(), isEmpty);
    });

    test('refuse un format de version invalide', () {
      expect(run(latest: '1.2'), hasLength(1));
      expect(run(latest: '1.2').first, contains('dernière version'));
      expect(run(min: '1.2', latest: '1.3.0').first, contains('minimale'));
    });

    test('refuse minVersion au-dessus de latestVersion', () {
      final refus = run(min: '1.4.0', latest: '1.3.0');
      expect(refus, hasLength(1));
      expect(refus.first, contains('personne ne peut installer'));
    });

    test('accepte minVersion égale à latestVersion', () {
      expect(run(min: '1.3.0', latest: '1.3.0'), isEmpty);
    });

    test('accepte minVersion sous latestVersion', () {
      expect(run(min: '1.2.0', latest: '1.3.0'), isEmpty);
    });

    test('refuse minVersion sans latestVersion', () {
      final refus = run(min: '1.3.0');
      expect(refus, hasLength(1));
      expect(refus.first, contains('Renseignez d\'abord'));
    });

    test('latestVersion seule est acceptable', () {
      expect(run(latest: '1.3.0'), isEmpty);
    });

    test('valide les protocoles d\'URL', () {
      expect(run(android: 'http://play.google.com'), hasLength(1));
      expect(run(android: 'https://play.google.com'), isEmpty);
      expect(run(android: 'market://details?id=x'), isEmpty);
      expect(run(ios: 'market://details?id=x'), hasLength(1));
      expect(run(ios: 'https://apps.apple.com/app/id1'), isEmpty);
      expect(run(ios: 'itms-apps://apps.apple.com/app/id1'), isEmpty);
    });

    test('cumule les refus', () {
      expect(run(min: '1.2', android: 'http://x'), hasLength(2));
    });
  });

  group('buildAppUpdatePatch', () {
    // C'est `null` qui efface la colonne côté serveur ; `""` échouerait le
    // @Matches du DTO. C'est la sortie de secours d'un blocage posé par erreur.
    test('un champ vidé part en null, pas en chaîne vide', () {
      final patch = buildAppUpdatePatch(
        minVersion: '',
        latestVersion: '   ',
        urlAndroid: '',
        urlIos: '',
        message: '',
      );

      expect(patch['minAppVersion'], isNull);
      expect(patch['latestAppVersion'], isNull);
      expect(patch['updateUrlAndroid'], isNull);
      expect(patch['updateUrlIos'], isNull);
      expect(patch['updateMessage'], isNull);
      expect(patch.containsKey('minAppVersion'), isTrue);
    });

    test('trim les valeurs renseignées', () {
      final patch = buildAppUpdatePatch(
        minVersion: ' 1.2.0 ',
        latestVersion: '1.3.0',
        urlAndroid: ' https://play.google.com ',
        urlIos: '',
        message: '  Nouveautés  ',
      );

      expect(patch['minAppVersion'], '1.2.0');
      expect(patch['latestAppVersion'], '1.3.0');
      expect(patch['updateUrlAndroid'], 'https://play.google.com');
      expect(patch['updateUrlIos'], isNull);
      expect(patch['updateMessage'], 'Nouveautés');
    });

    test('ne porte que les cinq clés du canal de mise à jour', () {
      final patch = buildAppUpdatePatch(
        minVersion: '',
        latestVersion: '',
        urlAndroid: '',
        urlIos: '',
        message: '',
      );

      expect(patch.keys, hasLength(5));
      expect(patch.containsKey('serviceFeePercent'), isFalse);
    });
  });

  group('requiresBlockConfirmation', () {
    test('exigée quand on pose un blocage', () {
      expect(
        requiresBlockConfirmation(minVersion: '1.3.0', savedMinVersion: null),
        isTrue,
      );
    });

    test('exigée quand on change un blocage existant', () {
      expect(
        requiresBlockConfirmation(
            minVersion: '1.4.0', savedMinVersion: '1.3.0'),
        isTrue,
      );
    });

    // L'obstacle doit être sur le chemin qui casse, jamais sur celui qui répare.
    test('pas exigée pour lever un blocage', () {
      expect(
        requiresBlockConfirmation(minVersion: '', savedMinVersion: '1.3.0'),
        isFalse,
      );
    });

    test('pas exigée quand rien ne change', () {
      expect(
        requiresBlockConfirmation(
            minVersion: ' 1.3.0 ', savedMinVersion: '1.3.0'),
        isFalse,
      );
    });
  });

  group('AppVersionRef.tryParse — corrections défaut 4', () {
    test('rend null au lieu de lever sur entier hors bornes', () {
      expect(AppVersionRef.tryParse('99999999999999999999.0.0'), isNull);
      expect(AppVersionRef.tryParse('1.99999999999999999999.0'), isNull);
      expect(AppVersionRef.tryParse('1.0.99999999999999999999'), isNull);
      expect(AppVersionRef.tryParse('1.0.0+99999999999999999999'),
          isNull);
    });
  });

  group('validateAppUpdate — correction défaut 1 (asymétrie build)', () {
    List<String> run({
      String min = '',
      String latest = '',
      String android = '',
      String ios = '',
    }) =>
        validateAppUpdate(
          minVersion: min,
          latestVersion: latest,
          urlAndroid: android,
          urlIos: ios,
        );

    test('refuse minVersion avec build quand latestVersion n\'en a pas', () {
      final refus = run(min: '1.3.0+40', latest: '1.3.0');
      expect(refus, hasLength(1));
      expect(refus.first, contains('Impossible de vérifier'));
    });

    test('accepte latestVersion avec build quand minVersion n\'en a pas', () {
      // minVersion sans build = « n'importe quel build de 1.3.0 »
      // latestVersion+41 le satisfait trivialement
      expect(run(min: '1.3.0', latest: '1.3.0+40'), isEmpty);
    });

    test('accepte build symétrique', () {
      expect(run(min: '1.3.0+34', latest: '1.3.0+40'), isEmpty);
      expect(run(min: '1.3.0', latest: '1.3.0'), isEmpty);
    });

    test('message prioritaire si minVersion dépasse latestVersion+build', () {
      final refus = run(min: '1.4.0', latest: '1.3.0+99');
      expect(refus, hasLength(1));
      // "personne ne peut installer" prime sur le message d'asymétrie
      expect(refus.first, contains('personne ne peut installer'));
      expect(refus.first, isNot(contains('Impossible de vérifier')));
    });
  });

  group('validateAppUpdate — correction défaut 2 (hôte manquant)', () {
    List<String> run({
      String min = '',
      String latest = '',
      String android = '',
      String ios = '',
    }) =>
        validateAppUpdate(
          minVersion: min,
          latestVersion: latest,
          urlAndroid: android,
          urlIos: ios,
        );

    test('refuse https:// ou market:// sans hôte', () {
      expect(run(android: 'https://'), hasLength(1));
      expect(run(android: 'market://'), hasLength(1));
      expect(run(ios: 'https://'), hasLength(1));
      expect(run(ios: 'itms-apps://'), hasLength(1));
    });

    test('accepte URLs avec hôte', () {
      expect(run(android: 'https://play.google.com'), isEmpty);
      expect(run(android: 'market://details?id=x'), isEmpty);
      expect(run(ios: 'https://apps.apple.com/app/id1'), isEmpty);
      expect(run(ios: 'itms-apps://apps.apple.com/app/id1'), isEmpty);
    });
  });

  group('buildAppUpdatePatch — correction défaut 3 (préfixe v)', () {
    test('normalise v au lieu de l\'envoyer', () {
      final patch = buildAppUpdatePatch(
        minVersion: 'v1.3.0',
        latestVersion: 'V1.4.0+50',
        urlAndroid: '',
        urlIos: '',
        message: '',
      );

      expect(patch['minAppVersion'], '1.3.0');
      expect(patch['latestAppVersion'], '1.4.0+50');
    });

    test('retombe sur valeur trimée si parsing échoue', () {
      final patch = buildAppUpdatePatch(
        minVersion: '  v1.2  ',
        latestVersion: 'pas-valide',
        urlAndroid: '',
        urlIos: '',
        message: '',
      );

      expect(patch['minAppVersion'], 'v1.2');
      expect(patch['latestAppVersion'], 'pas-valide');
    });

    test('autres champs gardent simple trim()', () {
      final patch = buildAppUpdatePatch(
        minVersion: '',
        latestVersion: '',
        urlAndroid: '  https://play.google.com  ',
        urlIos: '  itms-apps://apps.apple.com  ',
        message: '  v1.3 disponible  ',
      );

      expect(patch['updateUrlAndroid'], 'https://play.google.com');
      expect(patch['updateUrlIos'], 'itms-apps://apps.apple.com');
      expect(patch['updateMessage'], 'v1.3 disponible');
    });
  });
}

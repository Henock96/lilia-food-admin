import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/features/admin/presentation/screens/vendor_onboarding_steps.dart';
import 'package:lilia_admin/models/onboarding_report.dart';

/// Avance de l'assistant de configuration vendeur.
///
/// **Le défaut.** `_save` faisait `_step++` après **tout** enregistrement
/// réussi. Le raccourci tient tant qu'une étape porte un seul formulaire ;
/// « Commercial » en porte deux — les paramètres commerciaux, puis le compte de
/// reversement. Enregistrer les premiers projetait donc sur « Catalogue », et le
/// champ de reversement disparaissait après s'être affiché une fois. `payout`
/// étant une case **bloquante**, la checklist réclamait ensuite un compte que
/// l'assistant venait d'escamoter : le vendeur restait non activable sans que
/// rien ne dise où corriger.
///
/// Rien ne pouvait l'attraper : la règle vivait dans une méthode privée d'un
/// `State`, invisible d'un test.
void main() {
  ReadinessCheck check(
    String key, {
    required bool blocking,
    required bool ok,
  }) => ReadinessCheck(
    key: key,
    label: key,
    status: ok ? 'OK' : 'MISSING',
    blocking: blocking,
  );

  OnboardingReport reportOf(List<ReadinessCheck> checks) => OnboardingReport(
    restaurantId: 'r_1',
    onboardingStatus: 'DRAFT',
    isReady: false,
    progress: 0,
    checks: checks,
  );

  final commercial = vendorOnboardingSteps.firstWhere(
    (s) => s.title == 'Commercial',
  );

  group('canLeaveStep — étape « Commercial »', () {
    test('reste sur place tant que le compte de reversement manque', () {
      // Le scénario signalé : l'administrateur enregistre commission et
      // minimum de commande, et le champ de reversement ne doit pas fuir.
      final report = reportOf([
        check('commerce', blocking: false, ok: true),
        check('payout', blocking: true, ok: false),
      ]);

      expect(canLeaveStep(commercial, report), isFalse);
    });

    test('avance une fois le compte de reversement enregistré', () {
      final report = reportOf([
        check('commerce', blocking: false, ok: true),
        check('payout', blocking: true, ok: true),
      ]);

      expect(canLeaveStep(commercial, report), isTrue);
    });

    test('une case facultative en défaut ne retient personne', () {
      // `commerce` (commission) n'est pas bloquant : ne pas le renseigner est
      // un choix légitime — le taux plateforme s'applique.
      final report = reportOf([
        check('commerce', blocking: false, ok: false),
        check('payout', blocking: true, ok: true),
      ]);

      expect(canLeaveStep(commercial, report), isTrue);
    });
  });

  group('canLeaveStep — prudence', () {
    test('une case absente du rapport compte comme non satisfaite', () {
      // Backend plus ancien, ou clé renommée. Reparcourir une étape ne coûte
      // rien ; publier un vendeur sans compte de reversement, si.
      final report = reportOf([check('commerce', blocking: false, ok: true)]);

      expect(canLeaveStep(commercial, report), isFalse);
    });

    test('sans checklist chargée, on ne quitte pas une étape à cases', () {
      expect(canLeaveStep(commercial, null), isFalse);
    });

    test('une étape sans case ne bloque jamais', () {
      final verification = vendorOnboardingSteps.firstWhere(
        (s) => s.title == 'Vérification',
      );

      expect(canLeaveStep(verification, null), isTrue);
    });
  });

  group('vendorOnboardingSteps', () {
    test('« Commercial » porte bien les deux formulaires', () {
      expect(commercial.checkKeys, containsAll(<String>['commerce', 'payout']));
    });

    test('la case bloquante `payout` est rattachée à une étape', () {
      // Sans rattachement, la checklist signalerait un manque que l'assistant
      // ne saurait pas où corriger.
      final allKeys = vendorOnboardingSteps.expand((s) => s.checkKeys);
      expect(allKeys, contains('payout'));
    });
  });
}

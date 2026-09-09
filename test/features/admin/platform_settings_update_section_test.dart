import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/features/admin/data/admin_operations_repository.dart';
import 'package:lilia_admin/features/admin/presentation/providers/admin_operations_provider.dart';
import 'package:lilia_admin/features/admin/presentation/screens/platform_settings_screen.dart';
import 'package:lilia_admin/models/platform_settings.dart';

/// Repository factice : cette route sert la production, le test ne doit
/// jamais l'atteindre. Si la validation laisse passer un `_save()` malgré un
/// refus attendu, cette classe le signale au lieu de tenter un vrai PATCH.
class _RepositoryQuiNeDoitJamaisEtreAppelee extends AdminOperationsRepository {
  _RepositoryQuiNeDoitJamaisEtreAppelee()
      : super(ApiClient.test(
          baseUrl: 'https://test.local',
          tokenProvider: () async => null,
          forceRefreshToken: () async => null,
        ));

  bool patchEnvoye = false;

  @override
  Future<PlatformSettings> updatePlatformSettings(
      Map<String, dynamic> dto) async {
    patchEnvoye = true;
    throw StateError(
        'Ne doit jamais être appelé : la validation devait refuser avant.');
  }
}

/// Un blocage déjà actif (`minAppVersion` posé) sans `latestAppVersion` : la
/// validation refuse tant que la dernière version publiée n'est pas
/// renseignée (cf. `app_update_rules.dart::validateAppUpdate`).
PlatformSettings _settingsAvecBlocageActif() {
  return PlatformSettings(
    id: 'singleton',
    serviceFeePercent: 8,
    loyaltyPointsPerOrder: 1,
    loyaltyPointValueXaf: 50,
    loyaltyMinRedemption: 1,
    referrerBonusPoints: 1,
    maintenanceMode: false,
    maintenanceMessage: null,
    minAppVersion: '1.4.0',
    latestAppVersion: null,
    updateUrlAndroid: null,
    updateUrlIos: null,
    updateMessage: null,
    updatedAt: DateTime(2026, 9, 8),
  );
}

void main() {
  testWidgets(
    'le repli « Blocage du parc » se rouvre quand la validation refuse, '
    'même après avoir été fermé manuellement',
    (tester) async {
      // La `ListView` de l'écran construit ses enfants paresseusement : sur
      // la taille de fenêtre par défaut du test, la section « Mise à jour de
      // l'application » (en bas de liste) n'est même pas montée. On agrandit
      // la surface pour que tout tienne sans avoir à scroller — un `scroll`
      // reproduirait de toute façon la même mécanique de montage paresseux
      // que le bug qu'on vérifie ici.
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _RepositoryQuiNeDoitJamaisEtreAppelee();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            platformSettingsProvider
                .overrideWith((ref) => _settingsAvecBlocageActif()),
            adminOperationsRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(home: PlatformSettingsScreen()),
        ),
      );

      // Le projet interdit pumpAndSettle (animations qui peuvent ne jamais se
      // stabiliser) : deux pumps bornés suffisent à résoudre le
      // FutureProvider puis l'ouverture initiale du ExpansionTile.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Le blocage est actif dès le chargement : le repli est ouvert d'office.
      expect(find.text('Tapez BLOQUER pour confirmer'), findsOneWidget);

      // L'admin le referme d'un tap sur le titre.
      await tester.tap(find.text('⚠ Blocage du parc (avancé)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Tapez BLOQUER pour confirmer'), findsNothing);

      // Il enregistre sans avoir renseigné la dernière version publiée : la
      // validation refuse (minVersion posée sans latestVersion, cf.
      // validateAppUpdate). Aucun appel réseau ne doit partir.
      await tester.tap(find.text('Enregistrer'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Le repli doit s'être rouvert tout seul pour que l'admin voie
      // pourquoi le refus le concerne.
      expect(find.text('Tapez BLOQUER pour confirmer'), findsOneWidget);
      expect(repo.patchEnvoye, isFalse,
          reason: 'la validation aurait dû arrêter _save() avant le PATCH');
    },
  );
}

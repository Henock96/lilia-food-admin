import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/core/network/api_exception.dart';
import 'package:lilia_admin/features/admin/data/admin_operations_repository.dart';
import 'package:lilia_admin/features/admin/presentation/providers/admin_operations_provider.dart';
import 'package:lilia_admin/features/admin/presentation/screens/platform_settings_screen.dart';
import 'package:lilia_admin/models/platform_settings.dart';

/// Enregistrement de l'écran « Paramètres plateforme » (SET-001, R-09).
///
/// Le dépôt est remplacé : la route réelle sert la production.
class _RecordingRepository extends AdminOperationsRepository {
  _RecordingRepository({this.error})
      : super(ApiClient.test(
          baseUrl: 'https://test.local',
          tokenProvider: () async => null,
          forceRefreshToken: () async => null,
        ));

  final Object? error;
  final sent = <Map<String, dynamic>>[];

  @override
  Future<PlatformSettings> updatePlatformSettings(
      Map<String, dynamic> dto) async {
    sent.add(dto);
    if (error != null) throw error!;
    return _settings();
  }
}

PlatformSettings _settings() => PlatformSettings(
      id: 'singleton',
      serviceFeePercent: 15,
      restaurantCommissionPercent: 10,
      loyaltyPointsPerOrder: 1,
      loyaltyPointValueXaf: 50,
      loyaltyMinRedemption: 1,
      referrerBonusPoints: 1,
      maintenanceMode: false,
      minAppVersion: '1.3.0',
      latestAppVersion: '1.3.0',
      updateUrlAndroid:
          'https://play.google.com/store/apps/details?id=com.dreesis.lilia.lilia_app',
      updatedAt: DateTime.utc(2026, 9, 22, 10),
      updatedAtRaw: '2026-09-22T10:00:00.000Z',
    );

Future<void> _pump(WidgetTester tester, _RecordingRepository repo) async {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        platformSettingsProvider.overrideWith((ref) => _settings()),
        adminOperationsRepositoryProvider.overrideWithValue(repo),
      ],
      child: const MaterialApp(home: PlatformSettingsScreen()),
    ),
  );
  // Pas de pumpAndSettle (règle du projet) : pumps bornés.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Finder get _maintenanceMessage => find.byWidgetPredicate(
      (w) =>
          w is TextField &&
          w.decoration?.hintText == 'La plateforme est en maintenance…',
    );

void main() {
  /// R-09 — les réglages qui fixent de l'argent se demandent depuis l'admin
  /// web et s'approuvent à deux : cette app les affiche sans les modifier.
  group('réglages d’argent (R-09)', () {
    testWidgets('frais de service : affichés, pas de champ de saisie',
        (tester) async {
      await _pump(tester, _RecordingRepository());
      final row = find.ancestor(
        of: find.text('15 %'),
        matching: find.byType(Row),
      );
      expect(row, findsWidgets);
      expect(
        find.descendant(of: row.first, matching: find.byType(TextField)),
        findsNothing,
      );
      expect(find.text('15 %'), findsOneWidget);
      expect(find.textContaining('admin web'), findsWidgets);
    });

    testWidgets('aucun réglage d’argent ne part jamais dans le PATCH',
        (tester) async {
      final repo = _RecordingRepository();
      await _pump(tester, repo);
      await tester.enterText(_maintenanceMessage, 'Retour à 14 h');
      await tester.tap(find.text('Enregistrer'));
      await tester.pump();
      await tester.pump();
      expect(repo.sent.single.keys.toSet(),
          {'expectedUpdatedAt', 'maintenanceMessage'});
    });
  });

  testWidgets('une modification : seul le champ modifié part, avec le verrou',
      (tester) async {
    final repo = _RecordingRepository();
    await _pump(tester, repo);

    await tester.enterText(_maintenanceMessage, 'Retour à 14 h');
    await tester.tap(find.text('Enregistrer'));
    await tester.pump();
    await tester.pump();

    expect(repo.sent.single, {
      'expectedUpdatedAt': '2026-09-22T10:00:00.000Z',
      'maintenanceMessage': 'Retour à 14 h',
    });
    expect(find.text('Configuration enregistrée'), findsOneWidget);
  });

  testWidgets('rien de modifié : aucun PATCH', (tester) async {
    final repo = _RecordingRepository();
    await _pump(tester, repo);
    await tester.tap(find.text('Enregistrer'));
    await tester.pump();
    expect(repo.sent, isEmpty);
    expect(find.text('Aucune modification à enregistrer.'), findsOneWidget);
  });

  testWidgets('409 : dialogue de conflit, pas de faux succès', (tester) async {
    final repo = _RecordingRepository(
      error: const ApiException(
        'conflit',
        statusCode: 409,
        code: 'SETTINGS_STALE',
      ),
    );
    await _pump(tester, repo);

    await tester.enterText(_maintenanceMessage, 'Retour à 14 h');
    await tester.tap(find.text('Enregistrer'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Configuration modifiée entre-temps'), findsOneWidget);
    expect(find.text('Configuration enregistrée'), findsNothing);
  });

  testWidgets('500 : message d’erreur, pas de faux succès', (tester) async {
    final repo = _RecordingRepository(
      error: const ApiException('Erreur interne du serveur', statusCode: 500),
    );
    await _pump(tester, repo);

    await tester.enterText(_maintenanceMessage, 'Retour à 14 h');
    await tester.tap(find.text('Enregistrer'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Erreur interne du serveur'), findsOneWidget);
    expect(find.text('Configuration enregistrée'), findsNothing);
  });
}

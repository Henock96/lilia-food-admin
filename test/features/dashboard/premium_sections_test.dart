import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/features/dashboard/data/dashboard_service.dart';
import 'package:lilia_admin/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:lilia_admin/features/dashboard/presentation/screens/dashboard_screen.dart';

/// Répond par route, comme le serveur ; `failPeakHours` simule une panne.
class _RouteAdapter implements HttpClientAdapter {
  _RouteAdapter({required this.premium, this.failPeakHours = false});
  final bool premium;
  final bool failPeakHours;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    if (path.endsWith('/dashboard/peak-hours') && failPeakHours) {
      return ResponseBody.fromString('{"message":"panne"}', 500, headers: _json);
    }
    final Object body = switch (path) {
      _ when path.endsWith('/dashboard/top-products') => premium
          ? {
              'data': [
                {
                  'rank': 1,
                  'product': {'id': 'p1', 'nom': 'Poulet DG'},
                  'totalSold': 3,
                  'totalRevenue': 6000,
                  'orderCount': 2,
                },
              ],
              'premiumRequired': false,
            }
          : {'data': <Object>[], 'premiumRequired': true},
      _ when path.endsWith('/dashboard/peak-hours') => premium
          ? {
              'data': [
                for (var h = 0; h < 24; h++)
                  {'hour': h, 'count': h == 12 ? 120 : (h == 19 ? 40 : 0)},
              ],
              'peakHour': {'hour': 12, 'count': 120},
              'premiumRequired': false,
            }
          : {'data': <Object>[], 'peakHour': null, 'premiumRequired': true},
      _ => {'data': <String, Object>{}},
    };
    return ResponseBody.fromString(jsonEncode(body), 200, headers: _json);
  }

  static final _json = {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  };

  @override
  void close({bool force = false}) {}
}

Future<void> _pump(
  WidgetTester tester, {
  required bool premium,
  bool failPeakHours = false,
  double textScale = 1,
}) async {
  final api = ApiClient.test(
    baseUrl: 'http://test.local',
    tokenProvider: () async => 'jeton',
    forceRefreshToken: () async => 'jeton',
  );
  // Intercepteurs retirés : `PackageInfo.fromPlatform` (version de l'app) ne
  // se résout jamais sous l'horloge simulée d'un test de widget. Ce test porte
  // sur l'écran, pas sur le transport.
  api.dio.interceptors.clear();
  api.dio.httpClientAdapter =
      _RouteAdapter(premium: premium, failPeakHours: failPeakHours);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dashboardServiceProvider.overrideWithValue(DashboardService(api)),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: const DashboardScreen(),
        ),
      ),
    ),
  );
  // Les réponses du faux adaptateur arrivent sur des microtâches.
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Lot D (16/11/2026) — produits phares et heures de pointe réservés au
/// Premium, sur le verdict du serveur.
void main() {
  testWidgets('vendeur Standard : les deux sections sont absentes', (
    tester,
  ) async {
    await _pump(tester, premium: false);
    // L'écran est un `SingleChildScrollView` : toutes ses sections sont
    // construites, visibles ou non — aucun défilement nécessaire.
    expect(find.text('Produits les plus vendus'), findsNothing);
    expect(find.text('Heures de pointe'), findsNothing);
  });

  testWidgets('vendeur Premium : produits phares et heures de pointe', (
    tester,
  ) async {
    await _pump(tester, premium: true);

    expect(find.text('Heures de pointe'), findsOneWidget);
    expect(find.text('Produits les plus vendus'), findsOneWidget);
    expect(find.text('Poulet DG'), findsOneWidget);
    expect(find.text('Le plus de commandes vers 12 h'), findsOneWidget);
    // Une annonce par heure active, pas trois.
    expect(find.bySemanticsLabel('12 h : 120 commandes'), findsOneWidget);
  });

  testWidgets('panne des heures de pointe : une erreur, pas « non Premium »', (
    tester,
  ) async {
    await _pump(tester, premium: true, failPeakHours: true);

    expect(
      find.text('Impossible de charger les heures de pointe.'),
      findsOneWidget,
    );
    expect(find.text('Réessayer'), findsWidgets);
  });

  testWidgets('texte à 1,5× : la section des heures ne déborde pas', (
    tester,
  ) async {
    await _pump(tester, premium: true, textScale: 1.5);
    expect(find.text('Heures de pointe'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

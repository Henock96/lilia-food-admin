import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/features/earnings/data/earnings_repository.dart';
import 'package:lilia_admin/features/earnings/presentation/earnings_providers.dart';
import 'package:lilia_admin/features/earnings/presentation/earnings_screen.dart';

/// « Mes gains » (F3-07) : le vendeur voit ce qui arrive, ce qu'il a reçu et
/// ce qu'il doit. Réponse modelée sur `VendorEarningsService.forOwner`.
Map<String, dynamic> _body({int debt = 1500, int awaiting = 1}) => {
      'success': true,
      'data': {
        'summary': {
          'upcomingXaf': 4500,
          'upcomingCount': 1,
          'awaitingProofCount': awaiting,
          'pendingXaf': 0,
          'paidLast30DaysXaf': 3000,
          'debtXaf': debt,
        },
        'upcoming': [
          {
            'orderId': 'cmdue000001',
            'orderRef': 'DUE001',
            'payoutDueAt': '2026-09-25T15:00:00.000Z',
            'deliveryProof': 'PICKUP_CODE',
            'estimatedXaf': 4500,
          },
        ],
        'payouts': [
          {
            'id': 'pay-1',
            'orderId': 'cmpaid00001',
            'orderRef': 'PAID01',
            'status': 'SUCCESS',
            'provider': 'PAWAPAY',
            'grossAmount': 5000,
            'commissionAmount': 500,
            'deliverySubsidyAmount': 0,
            'refundDeductionAmount': 0,
            'debtDeductionAmount': 1500,
            'amount': 3000,
            'requestedAt': '2026-09-25T12:00:00.000Z',
            'completedAt': '2026-09-25T12:01:00.000Z',
          },
          {
            'id': 'pay-2',
            'orderId': 'cmnet000001',
            'orderRef': 'NET001',
            'status': 'SUCCESS',
            'provider': 'NETTING',
            'grossAmount': 5000,
            'commissionAmount': 500,
            'deliverySubsidyAmount': 0,
            'refundDeductionAmount': 0,
            'debtDeductionAmount': 4500,
            'amount': 0,
          },
        ],
        'debtEntries': [
          {
            'id': 'd1',
            'kind': 'REFUND_CLAWBACK',
            'amountXaf': -1500,
            'createdAt': '2026-09-25T11:00:00.000Z',
          },
        ],
      },
      'meta': {'page': 1, 'limit': 20, 'total': 2},
    };

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  group('EarningsRepository', () {
    test('GET /vendors/me/earnings, sans identifiant de boutique', () async {
      final client = ApiClient.test(
        baseUrl: 'https://test.local',
        tokenProvider: () async => 'tok',
        forceRefreshToken: () async => 'tok2',
      );
      final adapter = DioAdapter(dio: client.dio);
      adapter.onGet(
        '/vendors/me/earnings',
        (s) => s.reply(200, _body()),
        queryParameters: {'page': '1', 'limit': '20'},
      );

      final e = await EarningsRepository(client).mine();

      expect(e.debtXaf, 1500);
      expect(e.upcoming.single.orderRef, 'DUE001');
      expect(e.payouts.first.debtDeductionAmount, 1500);
      expect(e.payouts.last.isNetting, isTrue);
      expect(e.payouts.last.statusLabel, 'Retenu sur dette');
      expect(e.debtEntries.single.label, 'Remboursement client après versement');
      expect(e.total, 2);
    });

    test('un champ absent (serveur plus ancien) ne casse rien', () {
      final e = VendorEarnings.fromJson(const {}, const {});
      expect(e.isEmpty, isTrue);
      expect(e.debtXaf, 0);
    });
  });

  group('EarningsScreen', () {
    Future<void> pump(
      WidgetTester tester,
      Future<VendorEarnings> Function() load,
    ) async {
      // Écran de téléphone haut : la liste est paresseuse, ce qui sort de la
      // fenêtre n'est pas construit.
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
          ProviderScope(
            overrides: [vendorEarningsProvider.overrideWith((ref) => load())],
            child: const MaterialApp(home: EarningsScreen()),
          ),
        );
    }

    VendorEarnings earnings({int debt = 1500, int awaiting = 1}) =>
        VendorEarnings.fromJson(
          _body(debt: debt, awaiting: awaiting)['data'] as Map<String, dynamic>,
          const {'total': 2},
        );

    testWidgets('résumé, dette, commandes sans preuve, à venir, versements', (
      tester,
    ) async {
      await pump(tester, () async => earnings());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('earnings-upcoming')), findsOneWidget);
      expect(find.byKey(const Key('earnings-debt')), findsOneWidget);
      expect(find.byKey(const Key('earnings-awaiting-proof')), findsOneWidget);
      expect(find.text('Commande #DUE001'), findsOneWidget);
      expect(find.text('Commande #PAID01'), findsOneWidget);
      expect(find.text('Retenu sur dette'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('le détail d’un versement montre chaque retenue', (tester) async {
      await pump(tester, () async => earnings());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Commande #PAID01'));
      await tester.pumpAndSettle();
      expect(find.textContaining('dette 1'), findsOneWidget);
      expect(find.textContaining('commission 500'), findsOneWidget);
    });

    testWidgets('sans dette ni commande sans preuve : pas de bandeau', (tester) async {
      await pump(tester, () async => earnings(debt: 0, awaiting: 0));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('earnings-debt')), findsNothing);
      expect(find.byKey(const Key('earnings-awaiting-proof')), findsNothing);
    });

    testWidgets('rien encore : un message, pas un écran vide', (tester) async {
      await pump(tester, () async => VendorEarnings.fromJson(const {}, const {}));
      await tester.pumpAndSettle();
      expect(find.textContaining('Aucun versement pour l’instant'), findsOneWidget);
    });

    testWidgets('erreur : message et « Réessayer », jamais un spinner sans fin', (
      tester,
    ) async {
      await pump(tester, () async => throw Exception('réseau'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Réessayer'), findsOneWidget);
    });
  });
}

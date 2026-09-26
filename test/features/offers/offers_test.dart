import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/core/network/api_exception.dart';
import 'package:lilia_admin/features/earnings/data/earnings_repository.dart';
import 'package:lilia_admin/features/offers/data/offers_repository.dart';
import 'package:lilia_admin/features/offers/presentation/offer_form_screen.dart';
import 'package:lilia_admin/features/offers/presentation/offers_providers.dart';
import 'package:lilia_admin/features/offers/presentation/offers_screen.dart';

/// « Mes offres » (F3-11). Réponses modelées sur `VendorOffersService.listMine`.
Map<String, dynamic> _offer({
  String id = 'o1',
  String status = 'ACTIVE',
  int spent = 5000,
  String? stoppedReason,
}) =>
    {
      'id': id,
      'kind': 'PERCENT',
      'value': 10,
      'minSubTotalXaf': 0,
      'maxDiscountXaf': null,
      'startsAt': '2026-09-26T10:00:00.000Z',
      'endsAt': '2026-10-10T10:00:00.000Z',
      'budgetXaf': 20000,
      'spentXaf': spent,
      'remainingXaf': 20000 - spent,
      'status': status,
      'stoppedReason': stoppedReason,
      'ordersCount': 10,
      'label': '−10 % sur toute la boutique',
    };

ApiClient _client() => ApiClient.test(
      baseUrl: 'https://test.local',
      tokenProvider: () async => 'tok',
      forceRefreshToken: () async => 'tok2',
    );

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  group('OffersRepository', () {
    test('GET /vendors/me/offers : interrupteur, offre en cours, passées', () async {
      final client = _client();
      DioAdapter(dio: client.dio).onGet(
        '/vendors/me/offers',
        (s) => s.reply(200, {
          'data': {
            'enabled': true,
            'offers': [
              _offer(),
              _offer(id: 'o0', status: 'STOPPED_BY_ADMIN', stoppedReason: 'Abus'),
            ],
          },
        }),
      );
      final mine = await OffersRepository(client).mine();
      expect(mine.enabled, isTrue);
      expect(mine.current?.id, 'o1');
      expect(mine.current?.spentRatio, 0.25);
      expect(mine.past.single.statusLabel, 'Arrêtée par Lilia Food');
    });

    test('POST : termes envoyés, sans identifiant de boutique', () async {
      final client = _client();
      final end = DateTime.utc(2026, 10, 10, 10);
      DioAdapter(dio: client.dio).onPost(
        '/vendors/me/offers',
        (s) => s.reply(201, {'data': _offer()}),
        data: {
          'kind': 'FIXED_THRESHOLD',
          'value': 500,
          'minSubTotalXaf': 5000,
          'budgetXaf': 20000,
          'endsAt': end.toIso8601String(),
        },
      );
      final created = await OffersRepository(client).create(
        NewOffer(
          kind: OfferKind.fixedThreshold,
          value: 500,
          minSubTotalXaf: 5000,
          maxDiscountXaf: 400, // ignoré : pas de plafond sur une remise fixe
          budgetXaf: 20000,
          endsAt: end,
        ),
      );
      expect(created.id, 'o1');
    });

    test('PATCH : seul le geste part', () async {
      final client = _client();
      DioAdapter(dio: client.dio).onPatch(
        '/vendors/me/offers/o1',
        (s) => s.reply(200, {'data': _offer(status: 'PAUSED')}),
        data: {'action': 'PAUSE'},
      );
      final o = await OffersRepository(client).act('o1', OfferAction.pause);
      expect(o.isPaused, isTrue);
    });

    test('aperçu : seuil, plafond, jamais plus que le panier', () {
      final pct = NewOffer(
        kind: OfferKind.percent,
        value: 20,
        maxDiscountXaf: 800,
        budgetXaf: 1,
        endsAt: DateTime(2026),
      );
      expect(pct.discountOn(5000), 800);
      final fixed = NewOffer(
        kind: OfferKind.fixedThreshold,
        value: 500,
        minSubTotalXaf: 5000,
        budgetXaf: 1,
        endsAt: DateTime(2026),
      );
      expect(fixed.discountOn(4999), 0);
      expect(fixed.discountOn(5000), 500);
    });
  });

  test('Mes gains : la retenue d’offre est lue (F3-11)', () {
    final line = PayoutLine.fromJson({
      'id': 'p',
      'orderRef': 'X',
      'status': 'SUCCESS',
      'provider': 'PAWAPAY',
      'grossAmount': 5000,
      'commissionAmount': 500,
      'vendorOfferAmount': 500,
      'amount': 4000,
    });
    expect(line.vendorOfferAmount, 500);
  });

  group('OffersScreen', () {
    Future<void> pump(WidgetTester tester, MyOffers offers) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [myOffersProvider.overrideWith((ref) async => offers)],
          child: const MaterialApp(home: OffersScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('offre en cours : budget consommé, pause, pas de nouvelle offre', (
      tester,
    ) async {
      await pump(
        tester,
        MyOffers.fromJson({
          'enabled': true,
          'offers': [_offer()],
        }),
      );
      expect(find.byKey(const Key('offers-current')), findsOneWidget);
      expect(find.byKey(const Key('offers-budget-bar')), findsOneWidget);
      expect(find.textContaining('10 commandes'), findsOneWidget);
      expect(find.text('Mettre en pause'), findsOneWidget);
      expect(find.byKey(const Key('offers-new')), findsNothing);
    });

    testWidgets('aucune offre : invitation et bouton « Nouvelle offre »', (
      tester,
    ) async {
      await pump(tester, const MyOffers(enabled: true, offers: []));
      expect(find.byKey(const Key('offers-empty')), findsOneWidget);
      expect(find.byKey(const Key('offers-new')), findsOneWidget);
    });

    testWidgets('interrupteur éteint : message, aucune création possible', (
      tester,
    ) async {
      await pump(tester, const MyOffers(enabled: false, offers: []));
      expect(find.byKey(const Key('offers-disabled')), findsOneWidget);
      expect(find.byKey(const Key('offers-new')), findsNothing);
    });
  });

  group('OfferFormScreen', () {
    Future<void> pump(WidgetTester tester, OffersRepository repo) async {
      tester.view.physicalSize = const Size(1080, 3200);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [offersRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            home: OfferFormScreen(now: () => DateTime.utc(2026, 9, 26)),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('aperçu du coût, puis publication de −10 % / 14 jours', (
      tester,
    ) async {
      final repo = _FakeRepo();
      await pump(tester, repo);
      expect(find.byKey(const Key('offer-preview')), findsOneWidget);
      expect(find.textContaining('environ 40 commandes'), findsOneWidget);

      await tester.tap(find.byKey(const Key('offer-submit')));
      await tester.pumpAndSettle();
      expect(repo.created?.kind, OfferKind.percent);
      expect(repo.created?.value, 10);
      expect(repo.created?.budgetXaf, 20000);
      expect(repo.created?.endsAt, DateTime.utc(2026, 10, 10));
    });

    testWidgets('refus du serveur : son message s’affiche tel quel', (
      tester,
    ) async {
      final repo = _FakeRepo(
        error: const ApiException(
          'La remise doit être comprise entre 1 et 50 %.',
          statusCode: 400,
          code: 'OFFER_PERCENT_OUT_OF_RANGE',
        ),
      );
      await pump(tester, repo);
      await tester.enterText(find.byKey(const Key('offer-value')), '60');
      await tester.tap(find.byKey(const Key('offer-submit')));
      await tester.pumpAndSettle();
      expect(
        find.text('La remise doit être comprise entre 1 et 50 %.'),
        findsOneWidget,
      );
    });
  });
}

class _FakeRepo implements OffersRepository {
  _FakeRepo({this.error});

  final ApiException? error;
  NewOffer? created;

  @override
  Future<VendorOffer> create(NewOffer offer) async {
    if (error != null) throw error!;
    created = offer;
    return VendorOffer.fromJson(_offer());
  }

  @override
  Future<VendorOffer> act(String offerId, OfferAction action) =>
      throw UnimplementedError();

  @override
  Future<MyOffers> mine() => throw UnimplementedError();
}

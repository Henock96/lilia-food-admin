import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/features/reviews/data/reviews_repository.dart';
import 'package:lilia_admin/features/reviews/presentation/reviews_providers.dart';
import 'package:lilia_admin/features/reviews/presentation/reviews_screen.dart';

/// « Avis reçus » (lot B). Réponses modelées sur `ReviewsService.listForVendor`,
/// ré-enveloppées par l'intercepteur (`stats` hors de `{data, message, meta}`).
Map<String, dynamic> _review({
  String id = 'r1',
  int rating = 4,
  String? reply,
  bool replyHidden = false,
  String? orderRef = 'A3F2B1',
}) =>
    {
      'id': id,
      'rating': rating,
      'comment': 'Très bon garba',
      'createdAt': '2026-11-14T12:00:00.000Z',
      'restaurantId': 'shop',
      'restaurantName': 'Chez Awa',
      'orderRef': orderRef,
      'author': 'Client',
      'vendorReply': reply,
      'vendorReplyAt': reply == null ? null : '2026-11-14T13:00:00.000Z',
      'vendorReplyHidden': replyHidden,
    };

Map<String, dynamic> _page(List<Map<String, dynamic>> reviews) => {
      'data': {
        'data': reviews,
        'stats': {
          'averageRating': 4.5,
          'totalReviews': 2,
          'ratingDistribution': {'1': 0, '2': 0, '3': 0, '4': 1, '5': 1},
        },
        'meta': {'page': 1, 'limit': 20, 'total': 2, 'totalPages': 1},
      },
    };

ApiClient _client() => ApiClient.test(
      baseUrl: 'https://test.local',
      tokenProvider: () async => 'tok',
      forceRefreshToken: () async => 'tok2',
    );

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  group('ReviewsRepository', () {
    test('GET /vendors/me/reviews : avis, moyenne, répartition (double enveloppe)',
        () async {
      final client = _client();
      DioAdapter(dio: client.dio).onGet(
        '/vendors/me/reviews',
        (s) => s.reply(200, _page([_review(), _review(id: 'r2', rating: 5)])),
        queryParameters: {'page': 1, 'limit': 20},
      );

      final res = await ReviewsRepository(client).received();

      expect(res.reviews, hasLength(2));
      expect(res.reviews.first.orderRef, 'A3F2B1');
      expect(res.averageRating, 4.5);
      expect(res.totalReviews, 2);
      expect(res.distribution, {1: 0, 2: 0, 3: 0, 4: 1, 5: 1});
    });

    test('forme simple (sans ré-enveloppe) acceptée aussi', () {
      final res = ReceivedReviews.fromJson(_page([_review()])['data']);
      expect(res.reviews, hasLength(1));
      expect(res.totalReviews, 2);
    });

    test('PUT /vendors/me/reviews/:id/reply : texte nettoyé', () async {
      final client = _client();
      DioAdapter(dio: client.dio).onPut(
        '/vendors/me/reviews/r1/reply',
        (s) => s.reply(200, {'data': {'id': 'r1'}}),
        data: {'text': 'Merci !'},
      );
      await ReviewsRepository(client).reply('r1', '  Merci !  ');
    });
  });

  group('ReviewsScreen', () {
    Future<void> pump(
      WidgetTester tester,
      ReceivedReviews data,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            receivedReviewsProvider.overrideWith((ref) async => data),
          ],
          child: const MaterialApp(home: ReviewsScreen()),
        ),
      );
      await tester.pump();
    }

    testWidgets('auteur anonyme, référence de commande, bouton Répondre',
        (tester) async {
      await pump(tester, ReceivedReviews.fromJson(_page([_review()])));

      expect(find.text('Client'), findsOneWidget);
      expect(find.textContaining('Commande #A3F2B1'), findsOneWidget);
      expect(find.text('Répondre'), findsOneWidget);
      expect(find.text('4.5'), findsOneWidget);
    });

    testWidgets('réponse existante : « Modifier » ; masquée : plus de bouton',
        (tester) async {
      await pump(
        tester,
        ReceivedReviews.fromJson(_page([
          _review(reply: 'Merci !'),
          _review(id: 'r2', reply: 'Insulte', replyHidden: true),
        ])),
      );

      expect(find.text('Modifier'), findsOneWidget);
      expect(find.byKey(const Key('review-reply-r2')), findsNothing);
      expect(
        find.text('Votre réponse (masquée par la modération)'),
        findsOneWidget,
      );
    });

    testWidgets('aucun avis : message d’état vide', (tester) async {
      await pump(tester, ReceivedReviews.fromJson(_page(const [])));
      expect(find.byKey(const Key('reviews-empty')), findsOneWidget);
    });
  });
}

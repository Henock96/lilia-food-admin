import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/features/admin/data/refunds_service.dart';
import 'package:lilia_admin/models/refund.dart';

/// File des remboursements dus après annulation d'une commande payée.
///
/// Le point sensible est le **total**. Le backend pagine (`limit` par défaut à
/// 20) et renvoie le décompte réel dans `meta.total` ; le client, lui, ne
/// demandait aucune page et comptait les éléments reçus. Le badge de
/// navigation affichait donc « 20 » quel que soit le nombre de clients en
/// attente de leur argent — un plafond silencieux sur une file qui représente
/// des sommes dues.
void main() {
  Map<String, dynamic> refundJson(String id) => {
    'id': id,
    'orderId': 'ckabcdef123456',
    'amount': 6400,
    'status': 'PENDING',
    'reason': 'Annulation',
    'createdAt': '2026-08-29T10:00:00.000Z',
  };

  ({RefundsService service, DioAdapter adapter}) build() {
    final client = ApiClient.test(
      baseUrl: 'https://test.local',
      tokenProvider: () async => 'tok',
      forceRefreshToken: () async => 'tok2',
    );
    return (
      service: RefundsService(client),
      adapter: DioAdapter(dio: client.dio),
    );
  }

  test('demande explicitement une page et une taille de page', () async {
    // Sans ces paramètres, le backend appliquait sa valeur par défaut (20) et
    // aucune page suivante n'était atteignable.
    final t = build();
    t.adapter.onGet(
      '/refunds',
      (s) => s.reply(200, {
        'data': [refundJson('r1')],
        'meta': {'page': 2, 'limit': 50, 'total': 57},
      }),
      queryParameters: {'status': 'PENDING', 'page': '2', 'limit': '50'},
    );

    final page = await t.service.list(status: RefundStatus.pending, page: 2);

    expect(page.items, hasLength(1));
    expect(page.page, 2);
  });

  test('rapporte le total serveur, pas le nombre d’éléments reçus', () async {
    final t = build();
    t.adapter.onGet(
      '/refunds',
      (s) => s.reply(200, {
        'data': [refundJson('r1'), refundJson('r2')],
        'meta': {'page': 1, 'limit': 50, 'total': 57},
      }),
      queryParameters: {'status': 'PENDING', 'page': '1', 'limit': '50'},
    );

    final page = await t.service.list(status: RefundStatus.pending);

    // C'est ce chiffre qu'affiche le badge : 57 clients attendent, pas 2.
    expect(page.total, 57);
    expect(page.items, hasLength(2));
  });

  test('retombe sur la taille de page si le backend n’envoie pas de meta', () async {
    // L'enveloppe API est encore en cours d'uniformisation : un endpoint qui
    // renvoie une liste nue ne doit pas faire échouer l'écran. On sous-estime
    // alors le total, ce qui reste préférable à une exception.
    final t = build();
    t.adapter.onGet(
      '/refunds',
      (s) => s.reply(200, {
        'data': [refundJson('r1'), refundJson('r2')],
      }),
      queryParameters: {'page': '1', 'limit': '50'},
    );

    final page = await t.service.list();

    expect(page.total, 2);
  });

  group('RefundPage.hasMore', () {
    RefundPage pageWith(int count) => RefundPage(
      items: List.generate(count, (i) => Refund.fromJson(refundJson('r$i'))),
      total: 100,
      page: 1,
    );

    test('une page pleine laisse supposer une suite', () {
      expect(pageWith(RefundsService.pageSize).hasMore, isTrue);
    });

    test('une page incomplète est la dernière', () {
      expect(pageWith(RefundsService.pageSize - 1).hasMore, isFalse);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/features/home/data/order_service.dart';
import 'package:lilia_admin/models/order.dart';

/// Contrat de lecture de l'écran Commandes.
///
/// `getRestaurantOrders()` appelait `/orders/restaurant` **sans transmettre de
/// pagination**. Le backend appliquait donc son `limit = 20` par défaut, et
/// l'application affichait les vingt dernières commandes de toute la
/// plateforme — les sept onglets se contentant de filtrer ces vingt lignes en
/// mémoire. Une commande plus ancienne était inatteignable, et « En attente
/// (2) » pouvait s'afficher pendant que quarante commandes attendaient.
///
/// C'est exactement le défaut corrigé en août sur la file des remboursements
/// (`refunds_service_test.dart`), resté ici.
void main() {
  Map<String, dynamic> orderJson(String id, {String status = 'EN_ATTENTE'}) => {
    'id': id,
    'total': 6400,
    'subTotal': 5000,
    'deliveryFee': 1000,
    'serviceFee': 400,
    'createdAt': '2026-09-09T10:00:00.000Z',
    'status': status,
    'deliveryAddress': 'Moungali',
    'isDelivery': true,
    'items': <dynamic>[],
  };

  ({OrderService service, DioAdapter adapter}) build() {
    final client = ApiClient.test(
      baseUrl: 'https://test.local',
      tokenProvider: () async => 'tok',
      forceRefreshToken: () async => 'tok2',
    );
    return (
      service: OrderService(client),
      adapter: DioAdapter(dio: client.dio),
    );
  }

  test('transmet toujours page et limit — c’est le défaut corrigé', () async {
    final t = build();
    t.adapter.onGet(
      '/orders/restaurant',
      (s) => s.reply(200, {
        'data': [orderJson('o1')],
        'meta': {'page': 1, 'limit': OrderService.pageSize, 'total': 1},
      }),
      queryParameters: {'page': '1', 'limit': '${OrderService.pageSize}'},
    );

    final page = await t.service.getRestaurantOrders(isAdmin: false);

    expect(page.items, hasLength(1));
    expect(page.page, 1);
  });

  test('vise la route d’administration pour un ADMIN', () async {
    final t = build();
    t.adapter.onGet(
      '/admin/orders',
      (s) => s.reply(200, {
        'data': <dynamic>[],
        'meta': {'page': 3, 'limit': OrderService.pageSize, 'total': 0},
      }),
      queryParameters: {'page': '3', 'limit': '${OrderService.pageSize}'},
    );

    final page = await t.service.getRestaurantOrders(isAdmin: true, page: 3);

    expect(page.page, 3);
  });

  test('envoie le filtre de statut au serveur', () async {
    // Filtrer en mémoire une page déjà tronquée ne rend que les commandes de
    // cette page, en annonçant qu'il n'y en a pas d'autres.
    final t = build();
    t.adapter.onGet(
      '/admin/orders',
      (s) => s.reply(200, {
        'data': [orderJson('o1', status: 'PRET')],
        'meta': {'page': 1, 'limit': OrderService.pageSize, 'total': 4},
      }),
      queryParameters: {
        'page': '1',
        'limit': '${OrderService.pageSize}',
        'status': 'PRET',
      },
    );

    final page = await t.service.getRestaurantOrders(
      isAdmin: true,
      status: OrderStatus.pret,
    );

    expect(page.total, 4);
  });

  test('envoie la recherche au serveur', () async {
    // Chercher dans la page reçue ne fouillerait que vingt commandes — c'est
    // exactement ce que la pagination vient de rendre visible.
    final t = build();
    t.adapter.onGet(
      '/admin/orders',
      (s) => s.reply(200, {
        'data': [orderJson('o1')],
        'meta': {'page': 1, 'limit': OrderService.pageSize, 'total': 1},
      }),
      queryParameters: {
        'page': '1',
        'limit': '${OrderService.pageSize}',
        'search': 'Marie',
      },
    );

    final page = await t.service.getRestaurantOrders(
      isAdmin: true,
      search: 'Marie',
    );

    expect(page.items, hasLength(1));
  });

  test('n’envoie pas de paramètre sur une recherche vide', () async {
    // Un `search=` vide ferait porter au serveur une clause `OR` qui ne filtre
    // rien tout en coûtant trois jointures.
    final t = build();
    t.adapter.onGet(
      '/orders/restaurant',
      (s) => s.reply(200, {
        'data': <dynamic>[],
        'meta': {'page': 1, 'limit': OrderService.pageSize, 'total': 0},
      }),
      queryParameters: {'page': '1', 'limit': '${OrderService.pageSize}'},
    );

    final page = await t.service.getRestaurantOrders(
      isAdmin: false,
      search: '   ',
    );

    expect(page.total, 0);
  });

  test('combine recherche, statut et page', () async {
    final t = build();
    t.adapter.onGet(
      '/admin/orders',
      (s) => s.reply(200, {
        'data': <dynamic>[],
        'meta': {'page': 2, 'limit': OrderService.pageSize, 'total': 0},
      }),
      queryParameters: {
        'page': '2',
        'limit': '${OrderService.pageSize}',
        'status': 'PRET',
        'search': '066123456',
      },
    );

    final page = await t.service.getRestaurantOrders(
      isAdmin: true,
      page: 2,
      status: OrderStatus.pret,
      search: '066123456',
    );

    expect(page.page, 2);
  });

  test('rapporte le total serveur, pas le nombre d’éléments reçus', () async {
    final t = build();
    t.adapter.onGet(
      '/admin/orders',
      (s) => s.reply(200, {
        'data': [orderJson('o1'), orderJson('o2')],
        'meta': {'page': 1, 'limit': 20, 'total': 148, 'totalPages': 8},
      }),
      queryParameters: {'page': '1', 'limit': '${OrderService.pageSize}'},
    );

    final page = await t.service.getRestaurantOrders(isAdmin: true);

    // C'est ce chiffre qu'affiche l'en-tête : 148 commandes, pas 2.
    expect(page.total, 148);
    expect(page.totalPages, 8);
    expect(page.items, hasLength(2));
  });

  test('traduit meta.statusCounts en compteurs typés', () async {
    final t = build();
    t.adapter.onGet(
      '/admin/orders',
      (s) => s.reply(200, {
        'data': <dynamic>[],
        'meta': {
          'page': 1,
          'limit': 20,
          'total': 0,
          'statusCounts': {
            'EN_ATTENTE': 3,
            'PRET': 4,
            'LIVRER': 31,
          },
        },
      }),
      queryParameters: {'page': '1', 'limit': '${OrderService.pageSize}'},
    );

    final page = await t.service.getRestaurantOrders(isAdmin: true);

    expect(page.statusCounts[OrderStatus.enattente], 3);
    expect(page.statusCounts[OrderStatus.pret], 4);
    expect(page.statusCounts[OrderStatus.livrer], 31);
    // Un statut absent de la réponse vaut zéro, pas `null` : l'onglet doit
    // pouvoir afficher « (0) » sans que l'écran ait à le deviner.
    expect(page.statusCounts[OrderStatus.annuler], 0);
  });

  test('ignore un statut inconnu du serveur sans casser l’écran', () async {
    // Le backend peut gagner une valeur d'enum avant que l'app ne soit mise à
    // jour. Une clé inconnue ne doit pas faire échouer la lecture — c'est la
    // leçon d'`ACCEPTER` ajouté à `DeliveryStatus` en août.
    final t = build();
    t.adapter.onGet(
      '/admin/orders',
      (s) => s.reply(200, {
        'data': <dynamic>[],
        'meta': {
          'page': 1,
          'limit': 20,
          'total': 0,
          'statusCounts': {'PRET': 2, 'STATUT_DU_FUTUR': 9},
        },
      }),
      queryParameters: {'page': '1', 'limit': '${OrderService.pageSize}'},
    );

    final page = await t.service.getRestaurantOrders(isAdmin: true);

    expect(page.statusCounts[OrderStatus.pret], 2);
    expect(page.statusCounts.containsKey(OrderStatus.unknown), isFalse);
  });

  test('dégrade sans mentir quand le backend n’envoie pas de meta', () async {
    // Un backend antérieur à `meta` ne doit pas casser l'écran — mais il ne
    // doit pas non plus faire afficher « 0 commande » sous une liste qui en
    // montre deux.
    final t = build();
    t.adapter.onGet(
      '/orders/restaurant',
      (s) => s.reply(200, {
        'data': [orderJson('o1'), orderJson('o2')],
      }),
      queryParameters: {'page': '1', 'limit': '${OrderService.pageSize}'},
    );

    final page = await t.service.getRestaurantOrders(isAdmin: false);

    expect(page.total, 2);
    expect(page.statusCounts, isEmpty);
    expect(page.hasMore, isFalse);
  });

  group('OrderPage.hasMore', () {
    OrderPage pageWith({required int received, required int total}) => OrderPage(
      items: List.generate(received, (i) => Order.fromJson(orderJson('o$i'))),
      total: total,
      page: 1,
      totalPages: 1,
      statusCounts: const {},
    );

    test('une page pleine suivie d’autres commandes annonce une suite', () {
      expect(
        pageWith(received: OrderService.pageSize, total: 148).hasMore,
        isTrue,
      );
    });

    test('la dernière page ne propose pas d’en charger davantage', () {
      expect(
        pageWith(received: OrderService.pageSize, total: OrderService.pageSize)
            .hasMore,
        isFalse,
      );
    });
  });

  group('OrderStatusWire.toWire', () {
    test('rend les libellés attendus par le backend', () {
      expect(OrderStatus.enattente.toWire(), 'EN_ATTENTE');
      expect(OrderStatus.enRoute.toWire(), 'EN_ROUTE');
      expect(OrderStatus.annuler.toWire(), 'ANNULER');
    });

    test('boucle avec le parseur du modèle sur les sept statuts', () {
      // Une commande relue après écriture doit retrouver son statut. Le sens
      // enum → chaîne vivait dans un `switch` recopié du service, avec un
      // `default: 'EN_ATTENTE'` qui transformait une valeur inconnue en
      // demande de remise à zéro du cycle de vie.
      for (final s in OrderStatus.values) {
        if (s == OrderStatus.unknown) continue;
        expect(Order.statusFromWire(s.toWire()), s);
      }
    });
  });
}

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/features/products/data/product_service.dart';

/// Contrat de lecture du catalogue côté gestionnaire.
///
/// `getProducts` visait `GET /products`, la route **client** : sans pagination
/// (donc 20 produits au plus) et filtrée sur la visibilité marketplace. Un
/// vendeur suspendu n'y voyait rien, et un produit retiré de la vente
/// disparaissait de l'écran qui permet de le remettre.
///
/// Ces tests fixent les deux propriétés qui manquaient : **la bonne route**, et
/// **la totalité du catalogue**.
void main() {
  ApiClient buildClient(void Function(DioAdapter) stub) {
    final client = ApiClient.test(
      baseUrl: 'https://test.local',
      tokenProvider: () async => 'tok',
      forceRefreshToken: () async => 'tok2',
    );
    stub(DioAdapter(dio: client.dio));
    return client;
  }

  Map<String, dynamic> product(String id) => {
        'id': id,
        'nom': 'Produit $id',
        'prixOriginal': 1500,
        'restaurantId': 'resto-a',
        'variants': <dynamic>[],
      };

  test('interroge /products/manage, pas le catalogue public', () async {
    var pathVu = '';
    final client = buildClient((a) {
      a.onGet(
        '/products/manage',
        (s) => s.reply(200, {
          'data': [product('p1')],
          'meta': {'total': 1, 'page': 1, 'limit': 100, 'totalPages': 1},
        }),
        queryParameters: {
          'restaurantId': 'resto-a',
          'page': '1',
          'limit': '100',
        },
      );
    });
    client.dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
      pathVu = o.path;
      h.next(o);
    }));

    final products = await ProductService(client).getProducts('resto-a');

    expect(pathVu, '/products/manage');
    expect(products.single.id, 'p1');
  });

  test('enchaîne les pages jusqu’au total annoncé par le serveur', () async {
    // 2 pages : l'ancien appel, sans pagination, s'arrêtait à la première —
    // et le vendeur ne savait pas que la moitié de sa carte manquait.
    final client = buildClient((a) {
      a.onGet(
        '/products/manage',
        (s) => s.reply(200, {
          'data': [product('p1')],
          'meta': {'total': 2, 'page': 1, 'limit': 100, 'totalPages': 2},
        }),
        queryParameters: {
          'restaurantId': 'resto-a',
          'page': '1',
          'limit': '100',
        },
      );
      a.onGet(
        '/products/manage',
        (s) => s.reply(200, {
          'data': [product('p2')],
          'meta': {'total': 2, 'page': 2, 'limit': 100, 'totalPages': 2},
        }),
        queryParameters: {
          'restaurantId': 'resto-a',
          'page': '2',
          'limit': '100',
        },
      );
    });

    final products = await ProductService(client).getProducts('resto-a');

    expect(products.map((p) => p.id), ['p1', 'p2']);
  });

  test('ne boucle pas si la réponse ne porte pas de meta', () async {
    // Un client à jour contre un backend antérieur à la route : une page, et on
    // s'arrête. Boucler indéfiniment serait pire que d'en montrer moins.
    var appels = 0;
    final client = buildClient((a) {
      a.onGet(
        '/products/manage',
        (s) => s.reply(200, {
          'data': [product('p1')],
        }),
        queryParameters: {
          'restaurantId': 'resto-a',
          'page': '1',
          'limit': '100',
        },
      );
    });
    client.dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
      appels++;
      h.next(o);
    }));

    final products = await ProductService(client).getProducts('resto-a');

    expect(appels, 1);
    expect(products, hasLength(1));
  });
}

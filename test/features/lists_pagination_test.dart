import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/features/admin/data/admin_vendors_service.dart';
import 'package:lilia_admin/features/clients/data/client_repository.dart';
import 'package:lilia_admin/utils/api_response.dart';

/// Lot 4 (ADM-12) — listes qui s'arrêtaient à la première page.
///
/// Clients d'un vendeur : 20 (page par défaut du serveur, rien transmis).
/// Vendeurs côté ADMIN : 50. Sélecteur du catalogue : 100. Au-delà, rien,
/// et aucun écran ne le disait.
void main() {
  ({ApiClient client, DioAdapter adapter}) build() {
    final client = ApiClient.test(
      baseUrl: 'https://test.local',
      tokenProvider: () async => 'tok',
      forceRefreshToken: () async => 'tok2',
    );
    return (client: client, adapter: DioAdapter(dio: client.dio));
  }

  List<Map<String, dynamic>> people(int from, int count) => [
    for (var i = from; i < from + count; i++)
      {'id': 'c$i', 'email': 'c$i@lilia.cg'},
  ];

  List<Map<String, dynamic>> shops(int from, int count) => [
    for (var i = from; i < from + count; i++) {'id': 'v$i', 'nom': 'Boutique $i'},
  ];

  group('clients d\'un vendeur', () {
    test('enchaîne les pages jusqu\'au total annoncé (double enveloppe)', () async {
      final t = build();
      for (final page in [1, 2, 3]) {
        t.adapter.onGet(
          '/restaurants/r1/clients',
          (s) => s.reply(200, {
            'data': {
              'data': people((page - 1) * 100, page < 3 ? 100 : 30),
              'total': 230,
              'page': page,
              'limit': 100,
            },
          }),
          queryParameters: {'page': '$page', 'limit': '100'},
        );
      }

      final clients = await ClientRepository(t.client).fetchClients('r1');

      expect(clients, hasLength(230));
      expect(clients.last.id, 'c229');
    });

    test('une seule page : un seul appel, page et limit transmis', () async {
      final t = build();
      t.adapter.onGet(
        '/restaurants/r1/clients',
        (s) => s.reply(200, {
          'data': {'data': people(0, 3), 'total': 3, 'page': 1, 'limit': 100},
        }),
        queryParameters: {'page': '1', 'limit': '100'},
      );

      final clients = await ClientRepository(t.client).fetchClients('r1');
      expect(clients, hasLength(3));
    });
  });

  group('vendeurs (ADMIN)', () {
    test('enchaîne les pages selon meta.totalPages', () async {
      final t = build();
      for (final page in [1, 2]) {
        t.adapter.onGet(
          '/admin/vendors',
          (s) => s.reply(200, {
            'data': shops((page - 1) * 100, page == 1 ? 100 : 40),
            'meta': {'page': page, 'limit': 100, 'total': 140, 'totalPages': 2},
          }),
          queryParameters: {'page': '$page', 'limit': '100'},
        );
      }

      final vendors = await AdminVendorsService(t.client).listAllVendors();

      expect(vendors, hasLength(140));
      expect(vendors.last.restaurant.id, 'v139');
    });

    test('réponse sans pagination (backend ancien) : une page, pas de boucle', () async {
      final t = build();
      t.adapter.onGet(
        '/admin/vendors',
        (s) => s.reply(200, {'data': shops(0, 5)}),
        queryParameters: {'page': '1', 'limit': '100'},
      );

      final vendors = await AdminVendorsService(t.client).listAllVendors();
      expect(vendors, hasLength(5));
    });
  });

  group('ApiResponse.totalPagesOf', () {
    test('meta.totalPages, simple ou double enveloppe', () {
      expect(ApiResponse.totalPagesOf({'data': [], 'meta': {'totalPages': 4}}), 4);
      expect(
        ApiResponse.totalPagesOf({
          'data': {'data': [], 'meta': {'totalPages': 3}},
        }),
        3,
      );
    });

    test('total et limit à plat', () {
      expect(
        ApiResponse.totalPagesOf({
          'data': {'data': [], 'total': 201, 'limit': 100},
        }),
        3,
      );
      expect(
        ApiResponse.totalPagesOf({
          'data': {'data': [], 'total': 0, 'limit': 100},
        }),
        1,
      );
    });

    test('rien d\'exploitable → 1', () {
      expect(ApiResponse.totalPagesOf({'data': []}), 1);
      expect(ApiResponse.totalPagesOf([1, 2]), 1);
      expect(
        ApiResponse.totalPagesOf({
          'data': {'data': [], 'total': 10, 'limit': 0},
        }),
        1,
      );
    });
  });
}

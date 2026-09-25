import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/features/modifiers/data/modifier_service.dart';
import 'package:lilia_admin/models/modifier_group.dart';
import 'package:lilia_admin/models/order.dart';

/// F3-09 — éditeur d'options côté vendeur : contrat HTTP et modèles.
///
/// Les chemins sont ceux de `ModifiersController` (`/products/manage/…`) ; un
/// chemin faux serait capturé par `/products/:id` ou répondrait 404.
void main() {
  ApiClient buildClient(
    void Function(DioAdapter) stub, {
    void Function(RequestOptions)? voir,
  }) {
    final client = ApiClient.test(
      baseUrl: 'https://test.local',
      tokenProvider: () async => 'tok',
      forceRefreshToken: () async => 'tok2',
    );
    stub(DioAdapter(dio: client.dio));
    if (voir != null) {
      client.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            voir(o);
            h.next(o);
          },
        ),
      );
    }
    return client;
  }

  final groupJson = {
    'id': 'g-acc',
    'restaurantId': 'r1',
    'name': 'Accompagnement',
    'minSelect': 1,
    'maxSelect': 1,
    'required': true,
    'options': [
      {'id': 'o1', 'name': 'Alloco', 'priceDeltaXaf': 500, 'maxQuantity': 1, 'isAvailable': true},
      {'id': 'o2', 'name': 'Riz', 'priceDeltaXaf': 0, 'maxQuantity': 1, 'isAvailable': false},
    ],
    'products': [
      {'id': 'p1', 'nom': 'Poulet braisé'},
    ],
  };

  test('bibliothèque : groupes + interrupteurs de déploiement (meta)', () async {
    final client = buildClient((a) {
      a.onGet(
        '/products/manage/modifier-groups',
        (s) => s.reply(200, {
          'data': [groupJson],
          'meta': {'modifiersEnabled': true, 'modifiersManagementEnabled': false},
        }),
      );
    });
    final lib = await ModifierService(client).getLibrary();
    expect(lib.groups.single.name, 'Accompagnement');
    expect(lib.groups.single.options.last.isAvailable, isFalse);
    expect(lib.groups.single.products.single.name, 'Poulet braisé');
    expect(lib.modifiersEnabled, isTrue);
    expect(lib.managementEnabled, isFalse);
  });

  test('ADMIN : restaurantId en query pour lire, dans le corps pour écrire', () async {
    final vus = <RequestOptions>[];
    final client = buildClient((a) {
      a.onGet(
        '/products/manage/modifier-groups',
        (s) => s.reply(200, {'data': [], 'meta': {}}),
        queryParameters: {'restaurantId': 'r9'},
      );
      a.onPost(
        '/products/manage/modifier-groups',
        (s) => s.reply(201, {'data': groupJson}),
        data: Matchers.any,
      );
    }, voir: vus.add);
    final service = ModifierService(client);
    await service.getLibrary(restaurantId: 'r9');
    await service.createGroup(
      name: ' Sauce ',
      minSelect: 0,
      maxSelect: 1,
      options: const [ModifierOption(name: 'Piment')],
      restaurantId: 'r9',
    );
    final body = vus.last.data as Map<String, dynamic>;
    expect(body['restaurantId'], 'r9');
    expect(body['name'], 'Sauce');
    // Création : aucune option ne porte d'identifiant.
    expect((body['options'] as List).single, isNot(contains('id')));
  });

  test('rupture, attache, ordre : les bons chemins et verbes', () async {
    final vus = <RequestOptions>[];
    final client = buildClient((a) {
      a.onPatch(
        '/products/manage/modifier-options/o1/availability',
        (s) => s.reply(200, {'data': {}}),
        data: Matchers.any,
      );
      a.onPut(
        '/products/manage/p1/modifier-groups',
        (s) => s.reply(200, {'data': {}}),
        data: Matchers.any,
      );
      a.onPatch(
        '/products/manage/modifier-groups/reorder',
        (s) => s.reply(200, {'data': {}}),
        data: Matchers.any,
      );
      a.onPatch(
        '/products/manage/modifier-groups/g-acc',
        (s) => s.reply(200, {
          'data': groupJson,
          'meta': {'purgedCartLines': 2},
        }),
        data: Matchers.any,
      );
    }, voir: vus.add);
    final service = ModifierService(client);
    await service.setOptionAvailability('o1', false);
    await service.setProductGroups('p1', ['g-acc', 'g-sup']);
    await service.reorderGroups(['g-sup', 'g-acc']);
    final purged = await service.updateGroup(
      'g-acc',
      name: 'Accompagnement',
      minSelect: 1,
      maxSelect: 1,
      options: const [ModifierOption(id: 'o1', name: 'Alloco', priceDeltaXaf: 500)],
    );
    expect(vus.map((o) => '${o.method} ${o.path}'), [
      'PATCH /products/manage/modifier-options/o1/availability',
      'PUT /products/manage/p1/modifier-groups',
      'PATCH /products/manage/modifier-groups/reorder',
      'PATCH /products/manage/modifier-groups/g-acc',
    ]);
    expect((vus[1].data as Map)['groupIds'], ['g-acc', 'g-sup']);
    expect(purged, 2);
  });

  test('règles lisibles', () {
    expect(ModifierGroup.fromJson(groupJson).ruleLabel, 'Obligatoire · 1 choix');
    expect(
      const ModifierGroup(id: 'x', name: 'Sup', maxSelect: 2).ruleLabel,
      'Facultatif · jusqu\'à 2',
    );
  });

  test('ticket de commande : options figées, lues depuis la commande', () {
    final item = OrderItem.fromJson({
      'product': {'nom': 'Poulet braisé'},
      'quantite': 2,
      'prix': 4100,
      'options': [
        {'optionName': 'Alloco', 'groupName': 'Accompagnement', 'priceDeltaXaf': 500, 'quantity': 1},
        {'optionName': 'Œuf', 'groupName': 'Suppléments', 'priceDeltaXaf': 300, 'quantity': 2},
      ],
    });
    expect(item.optionsLabel, 'Alloco · Œuf ×2');
    // `prix` inclut déjà les options : la ligne vaut prix × quantité.
    expect(item.prix * item.quantite, 8200);
    // Commande antérieure : aucune option, aucun plantage.
    expect(OrderItem.fromJson({'quantite': 1, 'prix': 1000}).options, isEmpty);
  });
}

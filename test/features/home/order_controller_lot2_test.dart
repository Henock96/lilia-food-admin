import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/core/network/api_exception.dart';
import 'package:lilia_admin/features/home/data/order_controller.dart';
import 'package:lilia_admin/features/home/data/order_service.dart';
import 'package:lilia_admin/models/order.dart';

/// Lot 2 — la liste et la fiche disent ce que dit le serveur.
///
/// - ADM-06 : un échec ne prouve pas que rien n'a été écrit (timeout après
///   commit). Revenir à l'ancien statut affichait un état faux ; la liste se
///   relit sur le serveur.
/// - ADM-02 : la fiche se lit par identifiant, plus dans la page 1.
Order _order(String id, String status) => Order.fromJson({
  'id': id,
  'total': 4000,
  'createdAt': '2026-10-21T10:00:00.000Z',
  'status': status,
  'isDelivery': false,
  'items': [],
});

class _FakeService extends OrderService {
  _FakeService()
    : super(
        ApiClient.test(
          baseUrl: 'https://test.local',
          tokenProvider: () async => 'tok',
          forceRefreshToken: () async => 'tok',
        ),
      );

  /// Ce que le serveur sait vraiment.
  String serverStatus = 'EN_PREPARATION';
  int listReads = 0;
  final staffReads = <String>[];

  @override
  Future<OrderPage> getRestaurantOrders({
    required bool isAdmin,
    int page = 1,
    OrderStatus? status,
    String search = '',
  }) async {
    listReads++;
    return OrderPage(
      items: [_order('o1', serverStatus)],
      total: 1,
      page: 1,
      totalPages: 1,
      statusCounts: const {},
    );
  }

  @override
  Future<void> updateOrderStatus(
    String orderId,
    OrderStatus status, {
    String? reason,
  }) async {
    // Le serveur a commité, puis la réponse s'est perdue en route.
    serverStatus = 'PRET';
    throw const ApiException(
      'Le serveur met trop de temps à répondre.',
      kind: ApiErrorKind.timeout,
    );
  }

  bool staffFails = false;

  @override
  Future<Order> getStaffOrder(String orderId) async {
    staffReads.add(orderId);
    if (staffFails) {
      throw const ApiException('Commande introuvable.', statusCode: 404);
    }
    return _order(orderId, serverStatus);
  }
}

void main() {
  late _FakeService service;
  late ProviderContainer container;

  setUp(() {
    service = _FakeService();
    container = ProviderContainer(
      overrides: [orderServiceRepositoryProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
  });

  test(
    'échec après commit : la liste montre le statut du serveur, pas l’ancien',
    () async {
      final provider = restaurantOrdersProvider(null, '');
      container.listen(provider, (_, _) {});
      await container.read(provider.future);

      await expectLater(
        container
            .read(provider.notifier)
            .updateOrderStatus('o1', OrderStatus.pret),
        throwsA(isA<ApiException>()),
      );

      final page = await container.read(provider.future);
      expect(service.listReads, 2);
      expect(page.items.single.status, OrderStatus.pret);
    },
  );

  // Revue Flutter (HIGH) — Riverpod 3 garde la valeur précédente dans
  // l'erreur : `hasError && !hasValue` ne signalait jamais une fiche devenue
  // illisible après une première lecture réussie.
  test(
    'succès puis échec : la fiche est signalée en retard, valeur conservée',
    () async {
      // Relance automatique coupée : sinon le test attend ses ~38 s. En
      // production, pendant les relances l'état est « en chargement » AVEC son
      // erreur — `hasError` est vrai, le bandeau s'affiche donc aussi.
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [orderServiceRepositoryProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);
      final provider = staffOrderProvider('o1');
      container.listen(provider, (_, _) {});
      await container.read(provider.future);
      expect(staffOrderIsStale(container.read(provider)), isFalse);

      service.staffFails = true;
      container.invalidate(provider);
      await expectLater(
        container.read(provider.future),
        throwsA(isA<ApiException>()),
      );

      final state = container.read(provider);
      expect(
        state.hasValue,
        isTrue,
        reason: 'la valeur précédente reste affichée',
      );
      expect(staffOrderIsStale(state), isTrue);
    },
  );

  test('la fiche se lit par identifiant sur le serveur', () async {
    final order = await container.read(staffOrderProvider('o99').future);

    expect(service.staffReads, ['o99']);
    expect(order.id, 'o99');
  });
}

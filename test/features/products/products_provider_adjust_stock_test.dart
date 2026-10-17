import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/core/network/api_exception.dart';
import 'package:lilia_admin/features/catalog/catalog_scope.dart';
import 'package:lilia_admin/features/products/data/product_service.dart';
import 'package:lilia_admin/features/products/presentation/providers/products_provider.dart';
import 'package:lilia_admin/models/product.dart';

/// ADM-01 — après un échec réseau, on ne sait pas si le serveur a enregistré
/// le réapprovisionnement : le catalogue est relu avant que le vendeur ne
/// recommence, et c'est l'erreur du **geste** qui remonte à l'écran.
class _Scope extends CatalogScope {
  @override
  String? build() => 'r1';
}

class _FakeService extends ProductService {
  _FakeService({required this.readFails})
      : super(ApiClient.test(
          baseUrl: 'https://test.local',
          tokenProvider: () async => 'tok',
          forceRefreshToken: () async => 'tok',
        ));

  bool readFails;
  int reads = 0;

  @override
  Future<List<Product>> getProducts(String restaurantId) async {
    reads++;
    if (readFails) throw const ApiException('relecture impossible');
    return const [];
  }

  @override
  Future<({Product product, int? reservedAtVendor})> adjustStock(
    String productId, {
    required String action,
    required int units,
  }) async =>
      throw const ApiException('Le serveur met trop de temps à répondre.',
          kind: ApiErrorKind.timeout);
}

void main() {
  Future<(ProviderContainer, _FakeService)> setUp() async {
    final service = _FakeService(readFails: false);
    final container = ProviderContainer(overrides: [
      catalogScopeProvider.overrideWith(_Scope.new),
      productServiceProvider.overrideWithValue(service),
    ]);
    addTearDown(container.dispose);
    container.listen(productsProvider, (_, _) {});
    await container.read(productsProvider.future);
    return (container, service);
  }

  test('échec du geste : le stock est relu, l’erreur du geste remonte', () async {
    final (container, service) = await setUp();
    final before = service.reads;

    await expectLater(
      container
          .read(productsProvider.notifier)
          .adjustStock('p1', action: 'RESTOCK', units: 10),
      throwsA(isA<ApiException>()
          .having((e) => e.kind, 'kind', ApiErrorKind.timeout)),
    );
    await container.read(productsProvider.future);
    expect(service.reads, before + 1);
  });

  // Riverpod 3 rejoue un chargement en échec avec un délai croissant : si le
  // geste attendait la relecture, son erreur n'arriverait qu'au bout des
  // rejeux. Elle doit remonter tout de suite.
  test('la relecture échoue aussi : l’erreur du geste remonte sans attendre', () async {
    final (container, service) = await setUp();
    service.readFails = true;

    await expectLater(
      container
          .read(productsProvider.notifier)
          .adjustStock('p1', action: 'RESTOCK', units: 10)
          .timeout(const Duration(seconds: 1)),
      throwsA(isA<ApiException>()
          .having((e) => e.kind, 'kind', ApiErrorKind.timeout)),
    );
  });
}

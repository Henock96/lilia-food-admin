import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:lilia_admin/core/network/api_client.dart';
import '../../../../models/product.dart';
import '../../../catalog/catalog_scope.dart';
import '../../data/product_service.dart';

part 'products_provider.g.dart';

@riverpod
ProductService productService(Ref ref) {
  return ProductService(ref.watch(apiClientProvider));
}

/// Catalogue du vendeur courant (`catalogScopeProvider`).
///
/// La **lecture** est filtrée par `restaurantId` en query — c'est un filtre, il
/// ne donne aucun droit. L'**écriture**, elle, ne transmet ce champ que pour un
/// ADMIN : c'est la seule règle que le backend accepte, et la confondre avec le
/// filtre de lecture est ce qui a mis la création de produit hors service pour
/// tous les restaurateurs.
@riverpod
class Products extends _$Products {
  @override
  Future<List<Product>> build() async {
    final scope = ref.watch(catalogScopeProvider);
    if (scope == null) return const [];
    return ref.watch(productServiceProvider).getProducts(scope);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<Product> createProduct(Map<String, dynamic> productData) async {
    final created = await ref.read(productServiceProvider).createProduct({
      ...productData,
      // Réservé à l'ADMIN — null pour un RESTAURATEUR, dont le vendeur est
      // déduit du compte authentifié par le backend.
      if (ref.read(catalogTargetRestaurantIdProvider) != null)
        'restaurantId': ref.read(catalogTargetRestaurantIdProvider),
    });
    await refresh();
    return created;
  }

  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> productData,
  ) async {
    // Aucun `restaurantId` : un produit ne change pas de vendeur, et le DTO de
    // mise à jour ne déclare pas ce champ (le ValidationPipe le retirerait).
    await ref.read(productServiceProvider).updateProduct(productId, productData);
    await refresh();
  }

  Future<void> deleteProduct(String productId) async {
    await ref.read(productServiceProvider).deleteProduct(productId);
    await refresh();
  }
}

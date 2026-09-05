import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:lilia_admin/core/network/api_client.dart';
import '../../../../models/product.dart';
import '../../../catalog/catalog_scope.dart';
import '../../data/category_service.dart';

part 'categories_provider.g.dart';

@riverpod
CategoryService categoryService(Ref ref) {
  return CategoryService(ref.watch(apiClientProvider));
}

/// Sections de menu du vendeur courant.
///
/// Le périmètre vient de `catalogScopeProvider` : son propre vendeur pour un
/// RESTAURATEUR, celui sélectionné pour un ADMIN. Changer de vendeur recharge
/// automatiquement la liste — `ref.watch` s'en charge, sans invalidation
/// manuelle à répartir sur chaque écran.
@riverpod
class Categories extends _$Categories {
  @override
  Future<List<Category>> build() async {
    // `catalogTargetRestaurantId` est null pour un RESTAURATEUR : le backend
    // déduit alors son vendeur. Mais tant qu'aucun ADMIN n'a choisi de cible,
    // il n'y a rien à charger.
    if (ref.watch(isCatalogAdminProvider) &&
        ref.watch(catalogScopeProvider) == null) {
      return const [];
    }
    return ref
        .watch(categoryServiceProvider)
        .getCategories(restaurantId: ref.watch(catalogTargetRestaurantIdProvider));
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Retourne la Category créée — permet l'auto-sélection depuis le formulaire
  /// produit (LIL-129), conservée comme confort et non plus comme contournement.
  Future<Category> createCategory(Map<String, dynamic> body) async {
    final created = await ref.read(categoryServiceProvider).createCategory(
          body,
          restaurantId: ref.read(catalogTargetRestaurantIdProvider),
        );
    await refresh();
    return created;
  }

  Future<void> updateCategory(String id, Map<String, dynamic> body) async {
    await ref.read(categoryServiceProvider).updateCategory(id, body);
    await refresh();
  }

  Future<void> setActive(String id, bool isActive) =>
      updateCategory(id, {'isActive': isActive});

  /// Envoie la liste ordonnée **complète** : c'est le contrat du backend, et
  /// c'est ce qui évite qu'un réordonnancement concurrent laisse un ordre
  /// qu'aucun des deux appelants n'a voulu.
  Future<void> reorder(List<String> orderedIds) async {
    await ref.read(categoryServiceProvider).reorderCategories(
          orderedIds,
          restaurantId: ref.read(catalogTargetRestaurantIdProvider),
        );
    await refresh();
  }

  Future<void> deleteCategory(String id) async {
    await ref.read(categoryServiceProvider).deleteCategory(id);
    await refresh();
  }
}

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:lilia_admin/core/network/api_client.dart';
import '../../../../models/modifier_group.dart';
import '../../../catalog/catalog_scope.dart';
import '../../data/modifier_service.dart';

part 'modifiers_provider.g.dart';

@riverpod
ModifierService modifierService(Ref ref) {
  return ModifierService(ref.watch(apiClientProvider));
}

/// F3-09 — bibliothèque d'options du vendeur courant (`catalogScopeProvider`).
///
/// Même périmètre que les sections et les produits : son propre vendeur pour
/// un RESTAURATEUR, celui choisi pour un ADMIN.
@riverpod
class Modifiers extends _$Modifiers {
  @override
  Future<ModifierLibrary> build() async {
    if (ref.watch(isCatalogAdminProvider) &&
        ref.watch(catalogScopeProvider) == null) {
      return const ModifierLibrary();
    }
    return ref
        .watch(modifierServiceProvider)
        .getLibrary(restaurantId: ref.watch(catalogTargetRestaurantIdProvider));
  }

  String? get _target => ref.read(catalogTargetRestaurantIdProvider);
  ModifierService get _service => ref.read(modifierServiceProvider);

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> createGroup({
    required String name,
    required int minSelect,
    required int maxSelect,
    required List<ModifierOption> options,
  }) async {
    await _service.createGroup(
      name: name,
      minSelect: minSelect,
      maxSelect: maxSelect,
      options: options,
      restaurantId: _target,
    );
    await refresh();
  }

  /// Rend le nombre de lignes de panier retirées (options supprimées).
  Future<int> updateGroup(
    String id, {
    required String name,
    required int minSelect,
    required int maxSelect,
    required List<ModifierOption> options,
  }) async {
    final purged = await _service.updateGroup(
      id,
      name: name,
      minSelect: minSelect,
      maxSelect: maxSelect,
      options: options,
      restaurantId: _target,
    );
    await refresh();
    return purged;
  }

  Future<void> deleteGroup(String id) async {
    await _service.deleteGroup(id, restaurantId: _target);
    await refresh();
  }

  Future<void> setOptionAvailability(String optionId, bool isAvailable) async {
    await _service.setOptionAvailability(
      optionId,
      isAvailable,
      restaurantId: _target,
    );
    await refresh();
  }

  Future<void> setProductGroups(String productId, List<String> groupIds) async {
    await _service.setProductGroups(productId, groupIds, restaurantId: _target);
    await refresh();
  }

  /// Liste ordonnée **complète** — contrat du backend.
  Future<void> reorder(List<String> orderedIds) async {
    await _service.reorderGroups(orderedIds, restaurantId: _target);
    await refresh();
  }
}

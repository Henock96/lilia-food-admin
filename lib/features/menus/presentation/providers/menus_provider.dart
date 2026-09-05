import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:lilia_admin/core/network/api_client.dart';
import '../../../../models/menu.dart';
import '../../../catalog/catalog_scope.dart';
import '../../data/menu_service.dart';

part 'menus_provider.g.dart';

@riverpod
MenuService menuService(Ref ref) {
  return MenuService(ref.watch(apiClientProvider));
}

@riverpod
class Menus extends _$Menus {
  @override
  Future<List<MenuDuJour>> build() async {
    if (ref.watch(isCatalogAdminProvider) &&
        ref.watch(catalogScopeProvider) == null) {
      return const [];
    }
    return ref.watch(menuServiceProvider).getMenus(
          includeExpired: true,
          restaurantId: ref.watch(catalogTargetRestaurantIdProvider),
        );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> createMenu(Map<String, dynamic> menuData) async {
    await ref.read(menuServiceProvider).createMenu(
          menuData,
          restaurantId: ref.read(catalogTargetRestaurantIdProvider),
        );
    await refresh();
  }

  Future<void> updateMenu(String menuId, Map<String, dynamic> menuData) async {
    final service = ref.read(menuServiceProvider);
    await service.updateMenu(menuId, menuData);
    await refresh();
  }

  Future<void> toggleMenuStatus(String menuId) async {
    final service = ref.read(menuServiceProvider);
    await service.toggleMenuStatus(menuId);
    await refresh();
  }

  Future<void> deleteMenu(String menuId) async {
    final service = ref.read(menuServiceProvider);
    await service.deleteMenu(menuId);
    await refresh();
  }
}

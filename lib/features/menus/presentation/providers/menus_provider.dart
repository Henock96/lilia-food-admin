import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../models/menu.dart';
import '../../data/menu_service.dart';
import 'package:lilia_admin/core/network/api_client.dart';

part 'menus_provider.g.dart';

@riverpod
MenuService menuService(Ref ref) {
  return MenuService(ref.watch(apiClientProvider));
}

@riverpod
class Menus extends _$Menus {
  @override
  Future<List<MenuDuJour>> build() async {
    final service = ref.watch(menuServiceProvider);
    return service.getMenus(includeExpired: true);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(menuServiceProvider);
      return service.getMenus(includeExpired: true);
    });
  }

  Future<void> createMenu(Map<String, dynamic> menuData) async {
    final service = ref.read(menuServiceProvider);
    await service.createMenu(menuData);
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

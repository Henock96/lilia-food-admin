import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/utils/api_response.dart';

import '../../../models/menu.dart';

class MenuService {
  final ApiClient _api;

  MenuService(this._api);

  Future<List<MenuDuJour>> getMenus({bool includeExpired = true}) async {
    final res = await _api.getJson(
      '/menus/restaurant/mine',
      query: {'includeExpired': '$includeExpired'},
    );
    // Backend renvoie { data:[...], count } → double-wrappé par l'interceptor.
    // ApiResponse.listOf tolère liste brute / simple wrap / double wrap.
    final menusData = ApiResponse.listOf(res.data);
    return menusData
        .map((json) => MenuDuJour.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<MenuDuJour> getMenu(String menuId) async {
    final res = await _api.getJson('/menus/$menuId');
    final menuData =
        (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
    if (menuData == null) {
      throw Exception('Menu data is null');
    }
    return MenuDuJour.fromJson(menuData);
  }

  Future<MenuDuJour> createMenu(Map<String, dynamic> menuData) async {
    final res = await _api.postJson('/menus', body: menuData);
    final menuJson =
        (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
    if (menuJson == null) {
      throw Exception('Menu data is null in response');
    }
    return MenuDuJour.fromJson(menuJson);
  }

  Future<MenuDuJour> updateMenu(
      String menuId, Map<String, dynamic> menuData) async {
    final res = await _api.patchJson('/menus/$menuId', body: menuData);
    final menuJson =
        (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
    if (menuJson == null) {
      throw Exception('Menu data is null in response');
    }
    return MenuDuJour.fromJson(menuJson);
  }

  Future<MenuDuJour> toggleMenuStatus(String menuId) async {
    final res = await _api.patchJson('/menus/$menuId/toggle');
    final menuJson =
        (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
    if (menuJson == null) {
      throw Exception('Menu data is null in response');
    }
    return MenuDuJour.fromJson(menuJson);
  }

  Future<void> deleteMenu(String menuId) async {
    await _api.deleteJson('/menus/$menuId');
  }
}

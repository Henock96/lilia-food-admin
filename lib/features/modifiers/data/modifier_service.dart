import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/utils/api_response.dart';

import '../../../models/modifier_group.dart';

/// F3-09 — éditeur d'options (`/products/manage/…`).
///
/// `restaurantId` n'est transmis que pour un ADMIN agissant pour un vendeur :
/// le backend le refuse d'un RESTAURATEUR et déduit son vendeur du compte.
class ModifierService {
  final ApiClient _api;

  ModifierService(this._api);

  static const _base = '/products/manage/modifier-groups';

  Future<ModifierLibrary> getLibrary({String? restaurantId}) async {
    final res = await _api.getJson(_base, query: {'restaurantId': ?restaurantId});
    final raw = res.data;
    final meta = raw is Map<String, dynamic> && raw['meta'] is Map<String, dynamic>
        ? raw['meta'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return ModifierLibrary(
      groups: ApiResponse.listOf(raw)
          .whereType<Map<String, dynamic>>()
          .map(ModifierGroup.fromJson)
          .toList(),
      modifiersEnabled: meta['modifiersEnabled'] == true,
      managementEnabled: meta['modifiersManagementEnabled'] == true,
    );
  }

  Future<void> createGroup({
    required String name,
    required int minSelect,
    required int maxSelect,
    required List<ModifierOption> options,
    String? restaurantId,
  }) async {
    await _api.postJson(_base, body: {
      'name': name.trim(),
      'minSelect': minSelect,
      'maxSelect': maxSelect,
      'options': [for (final o in options) o.toJson()],
      'restaurantId': ?restaurantId,
    });
  }

  /// `options` = liste COMPLÈTE voulue : `id` connu = modifiée, absente = retirée.
  Future<int> updateGroup(
    String groupId, {
    required String name,
    required int minSelect,
    required int maxSelect,
    required List<ModifierOption> options,
    String? restaurantId,
  }) async {
    final res = await _api.patchJson('$_base/$groupId', body: {
      'name': name.trim(),
      'minSelect': minSelect,
      'maxSelect': maxSelect,
      'options': [for (final o in options) o.toJson()],
      'restaurantId': ?restaurantId,
    });
    return _purged(res.data);
  }

  Future<void> deleteGroup(String groupId, {String? restaurantId}) async {
    final query = restaurantId == null
        ? ''
        : '?restaurantId=${Uri.encodeQueryComponent(restaurantId)}';
    await _api.deleteJson('$_base/$groupId$query');
  }

  /// Rupture en un geste — aucune ligne de panier touchée.
  Future<void> setOptionAvailability(
    String optionId,
    bool isAvailable, {
    String? restaurantId,
  }) async {
    await _api.patchJson(
      '/products/manage/modifier-options/$optionId/availability',
      body: {'isAvailable': isAvailable, 'restaurantId': ?restaurantId},
    );
  }

  /// Groupes d'un produit, ordonnés (remplacement complet).
  Future<void> setProductGroups(
    String productId,
    List<String> groupIds, {
    String? restaurantId,
  }) async {
    await _api.putJson(
      '/products/manage/$productId/modifier-groups',
      body: {'groupIds': groupIds, 'restaurantId': ?restaurantId},
    );
  }

  Future<void> reorderGroups(List<String> groupIds, {String? restaurantId}) async {
    await _api.patchJson('$_base/reorder', body: {
      'groupIds': groupIds,
      'restaurantId': ?restaurantId,
    });
  }

  /// Lignes de panier retirées par la modification (options supprimées).
  static int _purged(dynamic raw) {
    if (raw is Map<String, dynamic> && raw['meta'] is Map<String, dynamic>) {
      final n = (raw['meta'] as Map<String, dynamic>)['purgedCartLines'];
      if (n is num) return n.toInt();
    }
    return 0;
  }
}

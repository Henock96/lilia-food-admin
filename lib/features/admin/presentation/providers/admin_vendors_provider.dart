import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/admin_vendors_service.dart';
import 'package:lilia_admin/core/network/api_client.dart';

part 'admin_vendors_provider.g.dart';

final adminVendorsServiceProvider =
    Provider((ref) => AdminVendorsService(ref.watch(apiClientProvider)));

/// LIL-128 : liste complète des vendeurs pour l'admin. Filtres optionnels.
/// Le notifier expose les actions approve/suspend qui invalident la liste.
@riverpod
class AdminVendorsList extends _$AdminVendorsList {
  @override
  Future<List<AdminVendorItem>> build() async {
    final service = ref.read(adminVendorsServiceProvider);
    return service.listVendors();
  }

  Future<void> approve(String restaurantId) async {
    final service = ref.read(adminVendorsServiceProvider);
    await service.approveVendor(restaurantId);
    ref.invalidateSelf();
    ref.invalidate(adminPendingVendorsProvider);
  }

  Future<void> suspend(String restaurantId, String reason) async {
    final service = ref.read(adminVendorsServiceProvider);
    await service.suspendVendor(restaurantId, reason);
    ref.invalidateSelf();
  }

  /// Lève une suspension. `unsuspendVendor` existait dans le service depuis
  /// août 2026 mais **aucun écran ne l'appelait** : un vendeur suspendu depuis
  /// cette application ne pouvait être rétabli que depuis l'admin web. C'est
  /// l'état dans lequel Attieke.com et Maison Kayser sont restés en production.
  Future<void> unsuspend(String restaurantId) async {
    final service = ref.read(adminVendorsServiceProvider);
    await service.unsuspendVendor(restaurantId);
    ref.invalidateSelf();
  }

  Future<void> setDisplayOrder(String restaurantId, int displayOrder) async {
    final service = ref.read(adminVendorsServiceProvider);
    await service.setDisplayOrder(restaurantId, displayOrder);
    ref.invalidateSelf();
  }

  Future<void> setFeatured(String restaurantId, bool isFeatured) async {
    final service = ref.read(adminVendorsServiceProvider);
    await service.setFeatured(restaurantId, isFeatured);
    ref.invalidateSelf();
  }
}

/// LIL-128 : vendeurs en attente d'approbation. Utilisé par le badge "À valider"
/// du dashboard admin et le tab dédié sur /admin/vendeurs.
@riverpod
Future<List<AdminVendorItem>> adminPendingVendors(Ref ref) async {
  final service = ref.read(adminVendorsServiceProvider);
  return service.listPending();
}

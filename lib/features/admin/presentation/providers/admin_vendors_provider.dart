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
}

/// LIL-128 : vendeurs en attente d'approbation. Utilisé par le badge "À valider"
/// du dashboard admin et le tab dédié sur /admin/vendeurs.
@riverpod
Future<List<AdminVendorItem>> adminPendingVendors(Ref ref) async {
  final service = ref.read(adminVendorsServiceProvider);
  return service.listPending();
}

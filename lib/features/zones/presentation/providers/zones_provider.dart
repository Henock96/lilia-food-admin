import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/zones_service.dart';
import 'package:lilia_admin/core/network/api_client.dart';

part 'zones_provider.g.dart';

final zonesServiceProvider =
    Provider((ref) => ZonesService(ref.watch(apiClientProvider)));

@riverpod
Future<List<Quartier>> allQuartiers(Ref ref) async {
  final service = ref.read(zonesServiceProvider);
  return await service.getAllQuartiers();
}

@riverpod
class DeliveryZones extends _$DeliveryZones {
  @override
  Future<DeliveryZonesData> build() async {
    final service = ref.read(zonesServiceProvider);
    return await service.getMyDeliveryZones();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(zonesServiceProvider);
      return await service.getMyDeliveryZones();
    });
  }

  Future<void> createZone(String zoneName, double fee, List<String> quartierIds) async {
    final currentData = state.value;
    if (currentData == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(zonesServiceProvider);
      await service.createDeliveryZone(
        currentData.restaurantId,
        zoneName,
        fee,
        quartierIds,
      );
      return await service.getMyDeliveryZones();
    });
  }

  Future<void> updateZone(
    String zoneId, {
    String? zoneName,
    double? fee,
    List<String>? quartierIds,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(zonesServiceProvider);
      await service.updateDeliveryZone(
        zoneId,
        zoneName: zoneName,
        fee: fee,
        quartierIds: quartierIds,
      );
      return await service.getMyDeliveryZones();
    });
  }

  Future<void> deleteZone(String zoneId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(zonesServiceProvider);
      await service.deleteDeliveryZone(zoneId);
      return await service.getMyDeliveryZones();
    });
  }
}

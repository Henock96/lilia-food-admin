import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../models/restaurant.dart';
import '../../data/restaurant_settings_service.dart';
import 'package:lilia_admin/core/network/api_client.dart';

part 'settings_provider.g.dart';

final restaurantSettingsServiceProvider =
    Provider((ref) => RestaurantSettingsService(ref.watch(apiClientProvider)));

@riverpod
class RestaurantSettings extends _$RestaurantSettings {
  @override
  Future<Restaurant> build() async {
    final service = ref.read(restaurantSettingsServiceProvider);
    return await service.getMyRestaurant();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(restaurantSettingsServiceProvider);
      return await service.getMyRestaurant();
    });
  }

  Future<void> updateOpenStatus(bool isOpen) async {
    final currentRestaurant = state.value;
    if (currentRestaurant == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(restaurantSettingsServiceProvider);
      return await service.updateOpenStatus(currentRestaurant.id, isOpen);
    });
  }

  Future<void> updateGeneralInfo({
    String? name,
    String? address,
    String? phone,
    String? description,
    String? imageUrl,
  }) async {
    final currentRestaurant = state.value;
    if (currentRestaurant == null) return;

    final data = <String, dynamic>{};
    if (name != null) data['nom'] = name;
    if (address != null) data['adresse'] = address;
    if (phone != null) data['phone'] = phone;
    if (description != null) data['description'] = description;
    if (imageUrl != null) data['imageUrl'] = imageUrl;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(restaurantSettingsServiceProvider);
      return await service.updateRestaurant(currentRestaurant.id, data);
    });
  }

  /// Montants en `int` : le XAF n'a pas de sous-unité, et le serveur les
  /// valide en `@IsInt` depuis la migration `money_integers`. Un `double`
  /// portant une décimale se faisait refuser en 400.
  Future<void> updateDeliverySettings({
    int? fixedDeliveryFee,
    int? estimatedDeliveryTimeMin,
    int? estimatedDeliveryTimeMax,
    int? minimumOrderAmount,
    String? deliveryPriceMode,
  }) async {
    final currentRestaurant = state.value;
    if (currentRestaurant == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(restaurantSettingsServiceProvider);
      return await service.updateDeliverySettings(
        currentRestaurant.id,
        fixedDeliveryFee: fixedDeliveryFee,
        estimatedDeliveryTimeMin: estimatedDeliveryTimeMin,
        estimatedDeliveryTimeMax: estimatedDeliveryTimeMax,
        minimumOrderAmount: minimumOrderAmount,
        deliveryPriceMode: deliveryPriceMode,
      );
    });
  }

  Future<void> addSpecialty(String name) async {
    final currentRestaurant = state.value;
    if (currentRestaurant == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(restaurantSettingsServiceProvider);
      await service.addSpecialty(currentRestaurant.id, name);
      return await service.getMyRestaurant();
    });
  }

  Future<void> removeSpecialty(String specialtyId) async {
    final currentRestaurant = state.value;
    if (currentRestaurant == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(restaurantSettingsServiceProvider);
      await service.removeSpecialty(currentRestaurant.id, specialtyId);
      return await service.getMyRestaurant();
    });
  }

  // ============ HORAIRES D'OUVERTURE ============

  Future<void> setOperatingHours(List<Map<String, dynamic>> hours) async {
    final currentRestaurant = state.value;
    if (currentRestaurant == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(restaurantSettingsServiceProvider);
      await service.setOperatingHours(currentRestaurant.id, hours);
      return await service.getMyRestaurant();
    });
  }

  Future<void> updateOperatingHour(String dayOfWeek, Map<String, dynamic> data) async {
    final currentRestaurant = state.value;
    if (currentRestaurant == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(restaurantSettingsServiceProvider);
      await service.updateOperatingHour(currentRestaurant.id, dayOfWeek, data);
      return await service.getMyRestaurant();
    });
  }

  // ============ PRÉ-COMMANDE (LIL-127) ============

  /// Met à jour les paramètres pré-commande via PATCH /restaurants/:id.
  /// Passer `null` pour [preorderLeadHours] ou [maxOrdersPerDay] est traité
  /// comme "ne pas envoyer le champ" — pour effacer une valeur côté backend,
  /// il faudrait un endpoint dédié (pas implémenté ici).
  Future<void> updatePreorderSettings({
    required bool acceptsPreorders,
    int? preorderLeadHours,
    int? maxOrdersPerDay,
  }) async {
    final currentRestaurant = state.value;
    if (currentRestaurant == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(restaurantSettingsServiceProvider);
      final payload = <String, dynamic>{
        'acceptsPreorders': acceptsPreorders,
        'preorderLeadHours': ?preorderLeadHours,
        'maxOrdersPerDay': ?maxOrdersPerDay,
      };
      return await service.updateRestaurant(currentRestaurant.id, payload);
    });
  }
}

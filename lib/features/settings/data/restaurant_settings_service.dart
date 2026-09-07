import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/utils/api_response.dart';
import '../../../models/restaurant.dart';

class RestaurantSettingsService {
  final ApiClient _api;

  RestaurantSettingsService(this._api);

  /// Récupère le restaurant du propriétaire connecté
  Future<Restaurant> getMyRestaurant() async {
    final res = await _api.getJson('/restaurants/mine');
    final restaurantData = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return Restaurant.fromJson(restaurantData);
  }

  /// Met à jour les informations générales du restaurant
  Future<Restaurant> updateRestaurant(String restaurantId, Map<String, dynamic> data) async {
    final res = await _api.patchJson('/restaurants/$restaurantId', body: data);
    return Restaurant.fromJson((res.data as Map<String, dynamic>)['data']);
  }

  /// Met à jour le statut ouvert/fermé du restaurant
  Future<Restaurant> updateOpenStatus(String restaurantId, bool isOpen) async {
    final res = await _api.patchJson(
      '/restaurants/$restaurantId/open-status',
      body: {'isOpen': isOpen},
    );
    return Restaurant.fromJson((res.data as Map<String, dynamic>)['data']);
  }

  /// Met à jour les paramètres de livraison
  Future<Restaurant> updateDeliverySettings(
    String restaurantId, {
    int? fixedDeliveryFee,
    int? estimatedDeliveryTimeMin,
    int? estimatedDeliveryTimeMax,
    int? minimumOrderAmount,
    String? deliveryPriceMode,
  }) async {
    final data = <String, dynamic>{};
    if (fixedDeliveryFee != null) data['fixedDeliveryFee'] = fixedDeliveryFee;
    if (estimatedDeliveryTimeMin != null) data['estimatedDeliveryTimeMin'] = estimatedDeliveryTimeMin;
    if (estimatedDeliveryTimeMax != null) data['estimatedDeliveryTimeMax'] = estimatedDeliveryTimeMax;
    if (minimumOrderAmount != null) data['minimumOrderAmount'] = minimumOrderAmount;
    if (deliveryPriceMode != null) data['deliveryPriceMode'] = deliveryPriceMode;

    // ⚠️ Route changée : `PATCH /vendors/:id/delivery` remplace
    // `PATCH /restaurants/:id/delivery-settings`, dépréciée.
    //
    // Les deux écrivent les mêmes colonnes, mais l'ancienne validait moins :
    // `deliveryPriceMode` y était un simple `@IsString()` — « GRATUIT » passait
    // et remontait en 500 depuis Prisma — et les montants n'avaient pas de
    // borne haute. Deux portes sur la même chose finissent toujours par ne pas
    // poser les mêmes règles.
    //
    // Les montants sont désormais des `int` : le XAF n'a pas de sous-unité, et
    // le serveur exige `@IsInt` depuis la migration `money_integers`.
    final res = await _api.patchJson('/vendors/$restaurantId/delivery', body: data);

    // Cette route renvoie `{ data: { vendor, readiness } }` : elle recalcule la
    // checklist « prêt à vendre » au passage, puisque la livraison en fait
    // partie. On ne lit que le vendeur ici — cet écran n'affiche pas la
    // checklist — mais le repli couvre un backend antérieur au changement.
    final payload = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    final vendor = payload['vendor'] as Map<String, dynamic>? ?? payload;
    return Restaurant.fromJson(vendor);
  }

  /// Récupère les spécialités du restaurant
  Future<List<Specialty>> getSpecialties(String restaurantId) async {
    final res = await _api.getJson('/restaurants/$restaurantId/specialties');
    final specialties = ApiResponse.listOf(res.data);
    return specialties.map((s) => Specialty.fromJson(s)).toList();
  }

  /// Ajoute une spécialité au restaurant
  Future<Specialty> addSpecialty(String restaurantId, String name) async {
    final res = await _api.postJson(
      '/restaurants/$restaurantId/specialties',
      body: {'name': name},
    );
    return Specialty.fromJson((res.data as Map<String, dynamic>)['data']);
  }

  /// Supprime une spécialité du restaurant
  Future<void> removeSpecialty(String restaurantId, String specialtyId) async {
    await _api.deleteJson('/restaurants/$restaurantId/specialties/$specialtyId');
  }

  // ============ HORAIRES D'OUVERTURE ============

  /// Récupère les horaires d'ouverture du restaurant
  Future<List<OperatingHours>> getOperatingHours(String restaurantId) async {
    final res = await _api.getJson('/restaurants/$restaurantId/operating-hours');
    final hours = ApiResponse.listOf(res.data);
    return hours.map((h) => OperatingHours.fromJson(h)).toList();
  }

  /// Définit les horaires de la semaine (bulk upsert)
  Future<List<OperatingHours>> setOperatingHours(
    String restaurantId,
    List<Map<String, dynamic>> hours,
  ) async {
    final res = await _api.putJson(
      '/restaurants/$restaurantId/operating-hours',
      body: {'hours': hours},
    );
    final result = ApiResponse.listOf(res.data);
    return result.map((h) => OperatingHours.fromJson(h)).toList();
  }

  /// Met à jour les horaires d'un seul jour
  Future<OperatingHours> updateOperatingHour(
    String restaurantId,
    String dayOfWeek,
    Map<String, dynamic> data,
  ) async {
    final res = await _api.patchJson(
      '/restaurants/$restaurantId/operating-hours/$dayOfWeek',
      body: data,
    );
    return OperatingHours.fromJson((res.data as Map<String, dynamic>)['data']);
  }
}

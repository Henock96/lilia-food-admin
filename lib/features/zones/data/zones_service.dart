import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/utils/api_response.dart';

class ZonesService {
  final ApiClient _api;

  ZonesService(this._api);

  /// Récupère tous les quartiers disponibles
  Future<List<Quartier>> getAllQuartiers() async {
    final res = await _api.getJson('/quartiers');
    final quartiers = ApiResponse.listOf(res.data);
    return quartiers.map((q) => Quartier.fromJson(q)).toList();
  }

  /// Récupère les zones de livraison du restaurant connecté
  Future<DeliveryZonesData> getMyDeliveryZones() async {
    final res = await _api.getJson('/quartiers/my-zones');
    // /quartiers/my-zones renvoie { data:[...], restaurantId, ... } →
    // double-wrappé par l'interceptor : on déballe l'enveloppe externe.
    return DeliveryZonesData.fromJson(ApiResponse.mapOf(res.data));
  }

  /// Crée une nouvelle zone de livraison
  Future<DeliveryZone> createDeliveryZone(
    String restaurantId,
    String zoneName,
    double fee,
    List<String> quartierIds,
  ) async {
    final res = await _api.postJson(
      '/quartiers/zones/$restaurantId',
      body: {
        'zoneName': zoneName,
        'fee': fee,
        'quartierIds': quartierIds,
      },
    );
    return DeliveryZone.fromJson(ApiResponse.mapOf(res.data));
  }

  /// Met à jour une zone de livraison
  Future<DeliveryZone> updateDeliveryZone(
    String zoneId, {
    String? zoneName,
    double? fee,
    List<String>? quartierIds,
  }) async {
    final body = <String, dynamic>{};
    if (zoneName != null) body['zoneName'] = zoneName;
    if (fee != null) body['fee'] = fee;
    if (quartierIds != null) body['quartierIds'] = quartierIds;

    final res = await _api.patchJson('/quartiers/zones/$zoneId', body: body);
    return DeliveryZone.fromJson(ApiResponse.mapOf(res.data));
  }

  /// Supprime une zone de livraison
  Future<void> deleteDeliveryZone(String zoneId) async {
    await _api.deleteJson('/quartiers/zones/$zoneId');
  }
}

// Models
class Quartier {
  final String id;
  final String nom;
  final String ville;

  Quartier({required this.id, required this.nom, required this.ville});

  factory Quartier.fromJson(Map<String, dynamic> json) {
    return Quartier(
      id: json['id'],
      nom: json['nom'],
      ville: json['ville'] ?? 'Brazzaville',
    );
  }
}

class DeliveryZonesData {
  final List<DeliveryZone> zones;
  final String restaurantId;
  final String deliveryPriceMode;
  final double fixedDeliveryFee;

  DeliveryZonesData({
    required this.zones,
    required this.restaurantId,
    required this.deliveryPriceMode,
    required this.fixedDeliveryFee,
  });

  factory DeliveryZonesData.fromJson(Map<String, dynamic> json) {
    return DeliveryZonesData(
      zones: ApiResponse.listOf(json).map((z) => DeliveryZone.fromJson(z)).toList(),
      restaurantId: json['restaurantId'],
      deliveryPriceMode: json['deliveryPriceMode'] ?? 'FIXED',
      fixedDeliveryFee: (json['fixedDeliveryFee'] as num?)?.toDouble() ?? 500,
    );
  }
}

class DeliveryZone {
  final String id;
  final String zoneName;
  final double fee;
  final String restaurantId;
  final List<ZoneQuartier> quartiers;

  DeliveryZone({
    required this.id,
    required this.zoneName,
    required this.fee,
    required this.restaurantId,
    required this.quartiers,
  });

  factory DeliveryZone.fromJson(Map<String, dynamic> json) {
    return DeliveryZone(
      id: json['id'],
      zoneName: json['zoneName'],
      fee: (json['fee'] as num).toDouble(),
      restaurantId: json['restaurantId'],
      quartiers: json['quartiers'] != null
          ? (json['quartiers'] as List).map((q) => ZoneQuartier.fromJson(q)).toList()
          : [],
    );
  }
}

class ZoneQuartier {
  final String id;
  final String quartierId;
  final Quartier? quartier;

  ZoneQuartier({
    required this.id,
    required this.quartierId,
    this.quartier,
  });

  factory ZoneQuartier.fromJson(Map<String, dynamic> json) {
    return ZoneQuartier(
      id: json['id'],
      quartierId: json['quartierId'],
      quartier: json['quartier'] != null ? Quartier.fromJson(json['quartier']) : null,
    );
  }
}

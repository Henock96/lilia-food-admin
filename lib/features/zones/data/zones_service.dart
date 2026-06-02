import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import 'package:lilia_admin/constants/app_constants.dart';
class ZonesService {
  final String _baseUrl = AppConstants.baseUrl;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<String?> _getAuthToken() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return await user.getIdToken();
  }

  /// Récupère tous les quartiers disponibles
  Future<List<Quartier>> getAllQuartiers() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/quartiers'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      final quartiers = data['data'] as List;
      return quartiers.map((q) => Quartier.fromJson(q)).toList();
    } else {
      throw Exception('Failed to load quartiers: ${response.body}');
    }
  }

  /// Récupère les zones de livraison du restaurant connecté
  Future<DeliveryZonesData> getMyDeliveryZones() async {
    final token = await _getAuthToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/quartiers/my-zones'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return DeliveryZonesData.fromJson(data);
    } else {
      throw Exception('Failed to load delivery zones: ${response.body}');
    }
  }

  /// Crée une nouvelle zone de livraison
  Future<DeliveryZone> createDeliveryZone(
    String restaurantId,
    String zoneName,
    double fee,
    List<String> quartierIds,
  ) async {
    final token = await _getAuthToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/quartiers/zones/$restaurantId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'zoneName': zoneName,
        'fee': fee,
        'quartierIds': quartierIds,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return DeliveryZone.fromJson(data['data']);
    } else {
      throw Exception('Failed to create delivery zone: ${response.body}');
    }
  }

  /// Met à jour une zone de livraison
  Future<DeliveryZone> updateDeliveryZone(
    String zoneId, {
    String? zoneName,
    double? fee,
    List<String>? quartierIds,
  }) async {
    final token = await _getAuthToken();
    final body = <String, dynamic>{};
    if (zoneName != null) body['zoneName'] = zoneName;
    if (fee != null) body['fee'] = fee;
    if (quartierIds != null) body['quartierIds'] = quartierIds;

    final response = await http.patch(
      Uri.parse('$_baseUrl/quartiers/zones/$zoneId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return DeliveryZone.fromJson(data['data']);
    } else {
      throw Exception('Failed to update delivery zone: ${response.body}');
    }
  }

  /// Supprime une zone de livraison
  Future<void> deleteDeliveryZone(String zoneId) async {
    final token = await _getAuthToken();
    final response = await http.delete(
      Uri.parse('$_baseUrl/quartiers/zones/$zoneId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete delivery zone: ${response.body}');
    }
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
      zones: (json['data'] as List).map((z) => DeliveryZone.fromJson(z)).toList(),
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

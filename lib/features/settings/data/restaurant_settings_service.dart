import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/restaurant.dart';

import 'package:lilia_admin/constants/app_constants.dart';
class RestaurantSettingsService {
  final String _baseUrl = AppConstants.baseUrl;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<String?> _getAuthToken() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return await user.getIdToken();
  }

  /// Récupère le restaurant du propriétaire connecté
  Future<Restaurant> getMyRestaurant() async {
    final token = await _getAuthToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/restaurants/mine'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      final restaurantData = data['data'] as Map<String, dynamic>;
      return Restaurant.fromJson(restaurantData);
    } else {
      throw Exception('Failed to load restaurant: ${response.body}');
    }
  }

  /// Met à jour les informations générales du restaurant
  Future<Restaurant> updateRestaurant(String restaurantId, Map<String, dynamic> data) async {
    final token = await _getAuthToken();
    final response = await http.patch(
      Uri.parse('$_baseUrl/restaurants/$restaurantId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(utf8.decode(response.bodyBytes));
      return Restaurant.fromJson(responseData['data']);
    } else {
      throw Exception('Failed to update restaurant: ${response.body}');
    }
  }

  /// Met à jour le statut ouvert/fermé du restaurant
  Future<Restaurant> updateOpenStatus(String restaurantId, bool isOpen) async {
    final token = await _getAuthToken();
    final response = await http.patch(
      Uri.parse('$_baseUrl/restaurants/$restaurantId/open-status'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'isOpen': isOpen}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return Restaurant.fromJson(data['data']);
    } else {
      throw Exception('Failed to update open status: ${response.body}');
    }
  }

  /// Met à jour les paramètres de livraison
  Future<Restaurant> updateDeliverySettings(
    String restaurantId, {
    double? fixedDeliveryFee,
    int? estimatedDeliveryTimeMin,
    int? estimatedDeliveryTimeMax,
    double? minimumOrderAmount,
    String? deliveryPriceMode,
  }) async {
    final token = await _getAuthToken();

    final data = <String, dynamic>{};
    if (fixedDeliveryFee != null) data['fixedDeliveryFee'] = fixedDeliveryFee;
    if (estimatedDeliveryTimeMin != null) data['estimatedDeliveryTimeMin'] = estimatedDeliveryTimeMin;
    if (estimatedDeliveryTimeMax != null) data['estimatedDeliveryTimeMax'] = estimatedDeliveryTimeMax;
    if (minimumOrderAmount != null) data['minimumOrderAmount'] = minimumOrderAmount;
    if (deliveryPriceMode != null) data['deliveryPriceMode'] = deliveryPriceMode;

    final response = await http.patch(
      Uri.parse('$_baseUrl/restaurants/$restaurantId/delivery-settings'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(utf8.decode(response.bodyBytes));
      return Restaurant.fromJson(responseData['data']);
    } else {
      throw Exception('Failed to update delivery settings: ${response.body}');
    }
  }

  /// Récupère les spécialités du restaurant
  Future<List<Specialty>> getSpecialties(String restaurantId) async {
    final token = await _getAuthToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/restaurants/$restaurantId/specialties'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      final specialties = data['data'] as List;
      return specialties.map((s) => Specialty.fromJson(s)).toList();
    } else {
      throw Exception('Failed to load specialties: ${response.body}');
    }
  }

  /// Ajoute une spécialité au restaurant
  Future<Specialty> addSpecialty(String restaurantId, String name) async {
    final token = await _getAuthToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/restaurants/$restaurantId/specialties'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'name': name}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return Specialty.fromJson(data['data']);
    } else {
      throw Exception('Failed to add specialty: ${response.body}');
    }
  }

  /// Supprime une spécialité du restaurant
  Future<void> removeSpecialty(String restaurantId, String specialtyId) async {
    final token = await _getAuthToken();
    final response = await http.delete(
      Uri.parse('$_baseUrl/restaurants/$restaurantId/specialties/$specialtyId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to remove specialty: ${response.body}');
    }
  }

  // ============ HORAIRES D'OUVERTURE ============

  /// Récupère les horaires d'ouverture du restaurant
  Future<List<OperatingHours>> getOperatingHours(String restaurantId) async {
    final token = await _getAuthToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/restaurants/$restaurantId/operating-hours'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      final hours = data['data'] as List;
      return hours.map((h) => OperatingHours.fromJson(h)).toList();
    } else {
      throw Exception('Failed to load operating hours: ${response.body}');
    }
  }

  /// Définit les horaires de la semaine (bulk upsert)
  Future<List<OperatingHours>> setOperatingHours(
    String restaurantId,
    List<Map<String, dynamic>> hours,
  ) async {
    final token = await _getAuthToken();
    final response = await http.put(
      Uri.parse('$_baseUrl/restaurants/$restaurantId/operating-hours'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'hours': hours}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      final result = data['data'] as List;
      return result.map((h) => OperatingHours.fromJson(h)).toList();
    } else {
      throw Exception('Failed to set operating hours: ${response.body}');
    }
  }

  /// Met à jour les horaires d'un seul jour
  Future<OperatingHours> updateOperatingHour(
    String restaurantId,
    String dayOfWeek,
    Map<String, dynamic> data,
  ) async {
    final token = await _getAuthToken();
    final response = await http.patch(
      Uri.parse('$_baseUrl/restaurants/$restaurantId/operating-hours/$dayOfWeek'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(utf8.decode(response.bodyBytes));
      return OperatingHours.fromJson(responseData['data']);
    } else {
      throw Exception('Failed to update operating hour: ${response.body}');
    }
  }
}

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../models/app_deliverer.dart';

import 'package:lilia_admin/constants/app_constants.dart';
import 'package:lilia_admin/utils/api_response.dart';
class DeliveryService {
  static const _baseUrl = AppConstants.baseUrl;

  Future<String?> _token() async => await FirebaseAuth.instance.currentUser?.getIdToken();

  Future<List<AppDeliverer>> getAvailableDeliverers() async {
    final token = await _token();
    final response = await http.get(
      Uri.parse('$_baseUrl/deliveries/deliverers'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = ApiResponse.listOf(json.decode(response.body));
      return data.map((e) => AppDeliverer.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Impossible de charger les livreurs');
  }

  /// PATCH /deliveries/by-order/:orderId/assign
  /// Crée la livraison si elle n'existe pas, puis assigne le livreur.
  Future<void> assignDelivererToOrder(String orderId, String delivererId) async {
    final token = await _token();
    final response = await http.patch(
      Uri.parse('$_baseUrl/deliveries/by-order/$orderId/assign'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'delivererId': delivererId}),
    );
    if (response.statusCode != 200) {
      String msg = "Erreur lors de l'assignation";
      try {
        final body = json.decode(response.body);
        if (body['message'] is String) msg = body['message'];
      } catch (e) {
        if (kDebugMode) debugPrint('[DeliveryService] assign parse error: $e');
      }
      throw Exception(msg);
    }
  }
}

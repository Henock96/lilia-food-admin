import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/order.dart';

import 'package:lilia_admin/constants/app_constants.dart';
import 'package:lilia_admin/utils/api_response.dart';
class OrderService {
  final String _baseUrl =
      AppConstants.baseUrl; // Votre URL de backend
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<String?> _getAuthToken() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return await user.getIdToken();
  }

  Future<List<Order>> getRestaurantOrders() async {
    final token = await _getAuthToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/orders/restaurant'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      // Tolère liste brute / simple wrap / double wrap (interceptor backend).
      final ordersData =
          ApiResponse.listOf(json.decode(utf8.decode(response.bodyBytes)));
      return ordersData.map((json) => Order.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load orders: ${response.body}');
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    final token = await _getAuthToken();

    // Convertir le status enum en string pour le backend
    String statusString;
    switch (status) {
      case OrderStatus.enattente:
        statusString = 'EN_ATTENTE';
        break;
      case OrderStatus.payer:
        statusString = 'PAYER';
        break;
      case OrderStatus.enpreparation:
        statusString = 'EN_PREPARATION';
        break;
      case OrderStatus.pret:
        statusString = 'PRET';
        break;
      case OrderStatus.enRoute:
        statusString = 'EN_ROUTE';
        break;
      case OrderStatus.livrer:
        statusString = 'LIVRER';
        break;
      case OrderStatus.annuler:
        statusString = 'ANNULER';
        break;
      default:
        statusString = 'EN_ATTENTE';
    }

    final response = await http.patch(
      Uri.parse('$_baseUrl/orders/$orderId/status'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'status': statusString}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update order status: ${response.body}');
    }
  }
}

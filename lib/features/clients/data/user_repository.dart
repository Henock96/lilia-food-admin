import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:lilia_admin/models/order.dart';

class UserRepository {
  final String _baseUrl = "https://lilia-backend.onrender.com";
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<String?> _getAuthToken() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non authentifié.');
    }
    return await user.getIdToken();
  }

  Future<List<Order>> fetchUserOrders(
    String restaurantId,
    String userId,
  ) async {
    final token = await _getAuthToken();
    final url = Uri.parse(
      '$_baseUrl/restaurants/$restaurantId/clients/$userId/orders',
    );

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      // Le backend renvoie { "data": [...], "message": "..." }
      final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
      final List<dynamic> ordersData = responseData['data'] as List<dynamic>? ?? [];
      return ordersData.map((json) => Order.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception(
        'Échec du chargement des commandes de l\'utilisateur: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Toutes les commandes d'un client, tous restaurants confondus (ADMIN).
  /// Utilise GET /orders/user/:userId (route admin-only côté backend).
  Future<List<Order>> fetchAllUserOrders(String userId) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/orders/user/$userId');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData =
          json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final List<dynamic> ordersData =
          responseData['data'] as List<dynamic>? ?? [];
      return ordersData
          .map((json) => Order.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
        'Échec du chargement des commandes du client: ${response.statusCode} ${response.body}',
      );
    }
  }
}

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AdminService {
  final String _baseUrl = 'https://lilia-backend.onrender.com';
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<String?> _getAuthToken() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return await user.getIdToken();
  }

  Future<Map<String, dynamic>> createRestaurantWithOwner({
    required String email,
    required String password,
    required String nom,
    String? phone,
    required String restaurantNom,
    required String restaurantAdresse,
    required String restaurantPhone,
    String? restaurantImageUrl,
  }) async {
    final token = await _getAuthToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/admin/restaurants'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'email': email,
        'password': password,
        'nom': nom,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'restaurantNom': restaurantNom,
        'restaurantAdresse': restaurantAdresse,
        'restaurantPhone': restaurantPhone,
        if (restaurantImageUrl != null && restaurantImageUrl.isNotEmpty)
          'restaurantImageUrl': restaurantImageUrl,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final decoded = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return decoded['data'] as Map<String, dynamic>;
    } else {
      final body = json.decode(utf8.decode(response.bodyBytes));
      final message = body['message'] ?? 'Erreur inconnue';
      throw Exception(message);
    }
  }
}

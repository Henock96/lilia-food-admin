import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:lilia_admin/models/app_user.dart';

class ClientRepository {
  final String _baseUrl = "https://lilia-backend.onrender.com"; // Utiliser 10.0.2.2 pour l'émulateur Android
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<String?> _getAuthToken() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non authentifié.');
    }
    return await user.getIdToken();
  }

  Future<List<AppUser>> fetchClients(String restaurantId) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/restaurants/$restaurantId/clients');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
      final List<dynamic> clientsData = responseData['data'] as List<dynamic>? ?? [];
      return clientsData.map((json) => AppUser.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Échec du chargement des clients: ${response.statusCode} ${response.body}');
    }
  }

  /// Récupère tous les clients de la plateforme (ADMIN uniquement)
  Future<List<AppUser>> fetchAllClients() async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/admin/clients');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
      final List<dynamic> clientsData = responseData['data'] as List<dynamic>? ?? [];
      return clientsData.map((json) => AppUser.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Échec du chargement des clients: ${response.statusCode} ${response.body}');
    }
  }
}

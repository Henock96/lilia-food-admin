import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:lilia_admin/models/app_user.dart';
import 'package:lilia_admin/models/client_loyalty.dart';
import 'package:lilia_admin/models/client_referral.dart';
import 'package:lilia_admin/models/paginated_clients.dart';

import 'package:lilia_admin/constants/app_constants.dart';
class ClientRepository {
  final String _baseUrl = AppConstants.baseUrl; // Utiliser 10.0.2.2 pour l'émulateur Android
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

  /// Récupère les clients de la plateforme, paginés et filtrables (ADMIN).
  Future<PaginatedClients> fetchAllClients({int page = 1, String search = ''}) async {
    final token = await _getAuthToken();
    final query = {
      'page': '$page',
      'limit': '20',
      if (search.trim().isNotEmpty) 'search': search.trim(),
    };
    final url = Uri.parse('$_baseUrl/admin/clients').replace(queryParameters: query);

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> body =
          json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final List<dynamic> clientsData = body['data'] as List<dynamic>? ?? [];
      return PaginatedClients(
        clients: clientsData
            .map((j) => AppUser.fromJson(j as Map<String, dynamic>))
            .toList(),
        total: body['total'] as int? ?? clientsData.length,
        page: body['page'] as int? ?? page,
        limit: body['limit'] as int? ?? 20,
      );
    } else {
      throw Exception('Échec du chargement des clients: ${response.statusCode} ${response.body}');
    }
  }

  /// Solde + historique de fidélité d'un client (ADMIN).
  Future<ClientLoyalty> fetchClientLoyalty(String clientId) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/admin/clients/$clientId/loyalty');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> body =
          json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return ClientLoyalty.fromJson(data);
    } else {
      throw Exception('Échec du chargement de la fidélité: ${response.statusCode} ${response.body}');
    }
  }

  /// Statistiques de parrainage d'un client (ADMIN).
  Future<ClientReferral> fetchClientReferral(String clientId) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/admin/clients/$clientId/referral');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> body =
          json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return ClientReferral.fromJson(data);
    } else {
      throw Exception('Échec du chargement du parrainage: ${response.statusCode} ${response.body}');
    }
  }
}

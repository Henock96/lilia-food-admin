import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:lilia_admin/models/admin_payment.dart';
import 'package:lilia_admin/models/admin_deliverer.dart';
import 'package:lilia_admin/models/deliverer_detail.dart';
import 'package:lilia_admin/models/deliverer_stats.dart';
import 'package:lilia_admin/models/delivery.dart';
import 'package:lilia_admin/models/delivery_mission_summary.dart';
import 'package:lilia_admin/models/delivery_status.dart';
import 'package:lilia_admin/models/paginated.dart';
import 'package:lilia_admin/models/platform_settings.dart';

/// Appels HTTP des opérations d'administration transverses :
/// supervision des paiements, des livreurs et configuration plateforme.
/// Toutes les routes sont ADMIN-only côté backend.
class AdminOperationsRepository {
  final String _baseUrl = 'https://lilia-backend.onrender.com';
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<String?> _getAuthToken() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non authentifié.');
    }
    return await user.getIdToken();
  }

  /// Paiements paginés, filtrés par statut (GET /admin/payments).
  Future<PaginatedPayments> fetchPayments({
    int page = 1,
    String status = 'PENDING',
  }) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/admin/payments').replace(
      queryParameters: {'page': '$page', 'limit': '20', 'status': status},
    );

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = json.decode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
      final list = body['data'] as List<dynamic>? ?? [];
      return PaginatedPayments(
        payments: list
            .map((j) => AdminPayment.fromJson(j as Map<String, dynamic>))
            .toList(),
        total: body['total'] as int? ?? list.length,
        page: body['page'] as int? ?? page,
        limit: body['limit'] as int? ?? 20,
      );
    }
    throw Exception(
        'Échec du chargement des paiements: ${response.statusCode} ${response.body}');
  }

  /// Confirmation manuelle d'un paiement (POST /payments/:id/confirm).
  Future<void> confirmPayment(String paymentId) async {
    final token = await _getAuthToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/payments/$paymentId/confirm'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      String message = 'Échec de la confirmation du paiement';
      try {
        final body = json.decode(utf8.decode(response.bodyBytes));
        if (body is Map && body['message'] is String) {
          message = body['message'] as String;
        }
      } catch (_) {}
      throw Exception(message);
    }
  }

  /// Livreurs paginés avec leurs livraisons récentes (GET /admin/deliverers).
  Future<PaginatedDeliverers> fetchDeliverers({int page = 1}) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/admin/deliverers').replace(
      queryParameters: {'page': '$page', 'limit': '20'},
    );

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = json.decode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
      final list = body['data'] as List<dynamic>? ?? [];
      return PaginatedDeliverers(
        deliverers: list
            .map((j) => AdminDeliverer.fromJson(j as Map<String, dynamic>))
            .toList(),
        total: body['total'] as int? ?? list.length,
        page: body['page'] as int? ?? page,
        limit: body['limit'] as int? ?? 20,
      );
    }
    throw Exception(
        'Échec du chargement des livreurs: ${response.statusCode} ${response.body}');
  }

  /// Configuration plateforme (GET /admin/platform-settings).
  Future<PlatformSettings> fetchPlatformSettings() async {
    final token = await _getAuthToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/admin/platform-settings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = json.decode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return PlatformSettings.fromJson(data);
    }
    throw Exception(
        'Échec du chargement de la configuration: ${response.statusCode} ${response.body}');
  }

  /// Mise à jour de la configuration plateforme
  /// (PATCH /admin/platform-settings).
  Future<PlatformSettings> updatePlatformSettings(
      Map<String, dynamic> dto) async {
    final token = await _getAuthToken();
    final response = await http.patch(
      Uri.parse('$_baseUrl/admin/platform-settings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(dto),
    );

    if (response.statusCode == 200) {
      final body = json.decode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return PlatformSettings.fromJson(data);
    }
    String message = 'Échec de la mise à jour de la configuration';
    try {
      final body = json.decode(utf8.decode(response.bodyBytes));
      if (body is Map && body['message'] is String) {
        message = body['message'] as String;
      } else if (body is Map && body['message'] is List) {
        message = (body['message'] as List).join(', ');
      }
    } catch (_) {}
    throw Exception(message);
  }

  // ---------------------------------------------------------------------------
  // Fiche livreur (LIL-85 stubs — LIL-84 livrera l'implémentation finale)
  // ---------------------------------------------------------------------------

  /// Fiche détaillée d'un livreur (GET /admin/deliverers/:id).
  ///
  /// **Stub LIL-85** : implémentation HTTP minimale pour que les providers
  /// compilent. LIL-84 livrera la version définitive (parsing complet, gestion
  /// d'erreurs alignée sur le reste du fichier). Au merge, LIL-84 prévaut.
  Future<DelivererDetail> getDelivererDetail(String id) async {
    final token = await _getAuthToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/admin/deliverers/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = json.decode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? const {};
      return DelivererDetail.fromJson(data);
    }
    throw Exception(
      'Échec du chargement de la fiche livreur: '
      '${response.statusCode} ${response.body}',
    );
  }

  /// Stats agrégées d'un livreur (GET /admin/deliverers/:id/stats).
  ///
  /// **Stub LIL-85** — voir [getDelivererDetail].
  Future<DelivererStats> getDelivererStats(String id) async {
    final token = await _getAuthToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/admin/deliverers/$id/stats'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = json.decode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? const {};
      return DelivererStats.fromJson(data);
    }
    throw Exception(
      'Échec du chargement des stats livreur: '
      '${response.statusCode} ${response.body}',
    );
  }

  /// Missions d'un livreur paginées et optionnellement filtrées par statut
  /// (GET /admin/deliverers/:id/missions?status=...&page=...&limit=...).
  ///
  /// **Stub LIL-85** — voir [getDelivererDetail].
  Future<Paginated<DeliveryMissionSummary>> getDelivererMissions(
    String id, {
    DeliveryStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    final token = await _getAuthToken();
    final queryParameters = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (status != null) 'status': status.wireValue,
    };
    final url = Uri.parse('$_baseUrl/admin/deliverers/$id/missions')
        .replace(queryParameters: queryParameters);

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = json.decode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
      return Paginated<DeliveryMissionSummary>.fromJson(
        body,
        DeliveryMissionSummary.fromJson,
      );
    }
    throw Exception(
      'Échec du chargement des missions livreur: '
      '${response.statusCode} ${response.body}',
    );
  }

  /// Livraison associée à une commande
  /// (GET /deliveries/by-order/:orderId).
  ///
  /// **Stub LIL-85** — `DeliveryService` n'expose pas encore cette route.
  /// LIL-84 décidera s'il garde la méthode ici ou s'il la déplace dans
  /// `DeliveryService`. En attendant, on l'ajoute ici pour que le provider
  /// `deliveryByOrderProvider` puisse compiler.
  Future<Delivery> getDeliveryByOrder(String orderId) async {
    final token = await _getAuthToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/deliveries/by-order/$orderId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = json.decode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? const {};
      return Delivery.fromJson(data);
    }
    throw Exception(
      'Échec du chargement de la livraison: '
      '${response.statusCode} ${response.body}',
    );
  }
}

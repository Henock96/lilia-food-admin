import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:lilia_admin/models/admin_payment.dart';
import 'package:lilia_admin/models/payments_stats.dart';
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

  /// Paiements paginés (GET /admin/payments).
  /// `status` vide → vue "Tous statuts confondus" (pas de filtre côté backend).
  Future<PaginatedPayments> fetchPayments({
    int page = 1,
    String status = '',
  }) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/admin/payments').replace(
      queryParameters: {
        'page': '$page',
        'limit': '20',
        if (status.isNotEmpty) 'status': status,
      },
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

  /// KPI paiements agrégés (GET /admin/payments/stats).
  Future<PaymentsStats> fetchPaymentsStats() async {
    final token = await _getAuthToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/admin/payments/stats'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final body = json.decode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
      // Le backend renvoie l'objet plat (pas wrappé) — on tolère les 2 formes.
      final data = body['data'] as Map<String, dynamic>? ?? body;
      return PaymentsStats.fromJson(data);
    }
    throw Exception(_parseError(
        response, 'Échec du chargement des stats paiements'));
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

  // ─── Fiche livreur détaillée (LIL-84) ────────────────────────────────────

  /// Stats agrégées d'un livreur — `GET /admin/deliverers/:id/stats`.
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
    throw Exception(_parseError(
        response, 'Échec du chargement des stats livreur'));
  }

  /// Missions d'un livreur paginées et optionnellement filtrées par statut —
  /// `GET /admin/deliverers/:id/missions?status=&page=&limit=`.
  Future<Paginated<DeliveryMissionSummary>> getDelivererMissions(
    String id, {
    DeliveryStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/admin/deliverers/$id/missions').replace(
      queryParameters: {
        'page': '$page',
        'limit': '$limit',
        if (status != null) 'status': status.wireValue,
      },
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
      return Paginated<DeliveryMissionSummary>.fromJson(
        body,
        DeliveryMissionSummary.fromJson,
      );
    }
    throw Exception(_parseError(
        response, 'Échec du chargement des missions livreur'));
  }

  /// Livraison associée à une commande — `GET /deliveries/by-order/:orderId`.
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
      final data = body['data'] as Map<String, dynamic>? ?? body;
      return Delivery.fromJson(data);
    }
    throw Exception(_parseError(
        response, 'Échec du chargement de la livraison'));
  }

  /// Fiche détaillée composée : user (depuis la liste paginée) + stats +
  /// mission en cours (EN_TRANSIT prioritaire, sinon ASSIGNER).
  ///
  /// Backend manquant : pas de `GET /admin/deliverers/:id`. On scanne la
  /// liste paginée jusqu'à trouver le bon id. TODO : ajouter un endpoint
  /// backend dédié si le volume dépasse ~500 livreurs.
  Future<DelivererDetail> getDelivererDetail(String id) async {
    final results = await Future.wait([
      _findDelivererInList(id),
      getDelivererStats(id),
      _findCurrentMission(id),
    ]);

    final user = results[0] as AdminDeliverer;
    final stats = results[1] as DelivererStats;
    final current = results[2] as DeliveryMissionSummary?;

    return DelivererDetail(user: user, stats: stats, currentMission: current);
  }

  /// Lookup linéaire dans `GET /admin/deliverers` (paginé).
  Future<AdminDeliverer> _findDelivererInList(String id) async {
    var page = 1;
    while (true) {
      final paginated = await fetchDeliverers(page: page);
      final match =
          paginated.deliverers.where((d) => d.id == id).cast<AdminDeliverer?>();
      if (match.isNotEmpty) return match.first!;
      final totalFetched = paginated.page * paginated.limit;
      if (paginated.deliverers.isEmpty || totalFetched >= paginated.total) {
        throw Exception('Livreur introuvable');
      }
      page += 1;
    }
  }

  /// Mission en cours = première `EN_TRANSIT`, sinon première `ASSIGNER`.
  Future<DeliveryMissionSummary?> _findCurrentMission(String id) async {
    try {
      final inTransit = await getDelivererMissions(
        id,
        status: DeliveryStatus.enTransit,
        limit: 1,
      );
      if (inTransit.data.isNotEmpty) return inTransit.data.first;

      final assigned = await getDelivererMissions(
        id,
        status: DeliveryStatus.assigner,
        limit: 1,
      );
      return assigned.data.isNotEmpty ? assigned.data.first : null;
    } catch (_) {
      // Dégradation gracieuse : pas de mission en cours plutôt qu'échec total.
      return null;
    }
  }

  String _parseError(http.Response response, String fallback) {
    try {
      final body = json.decode(utf8.decode(response.bodyBytes));
      if (body is Map && body['message'] is String) {
        return body['message'] as String;
      }
      if (body is Map && body['message'] is List) {
        return (body['message'] as List).join(', ');
      }
    } catch (_) {}
    return '$fallback (${response.statusCode})';
  }
}

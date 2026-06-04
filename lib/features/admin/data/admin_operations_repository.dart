import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:lilia_admin/utils/api_response.dart';
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

import 'package:lilia_admin/constants/app_constants.dart';
/// Appels HTTP des opérations d'administration transverses :
/// supervision des paiements, des livreurs et configuration plateforme.
/// Toutes les routes sont ADMIN-only côté backend.
class AdminOperationsRepository {
  final String _baseUrl = AppConstants.baseUrl;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<String?> _getAuthToken() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non authentifié.');
    }
    return await user.getIdToken();
  }

  /// Extrait `{ items, total, page, limit }` d'une réponse paginée en tolérant :
  /// - le **double-wrap** de l'`ApiResponseInterceptor` backend (B24) :
  ///   `{ data: { data: [...], total, page, limit } }`
  /// - la forme cible `{ data: [...], meta: { total, page, limit } }`
  /// - la forme historique simple `{ data: [...], total, page, limit }`
  ({List<dynamic> items, int total, int page, int limit}) _paginated(
    dynamic decoded,
    int requestedPage,
  ) {
    final pg = ApiResponse.mapOf(decoded); // déballe un éventuel niveau `data`
    final items = ApiResponse.listOf(pg);
    final meta = pg['meta'] as Map<String, dynamic>?;
    int read(String key, int fallback) =>
        (pg[key] as int?) ?? (meta?[key] as int?) ?? fallback;
    return (
      items: items,
      total: read('total', items.length),
      page: read('page', requestedPage),
      limit: read('limit', AppConstants.adminPageSize),
    );
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
        'limit': '${AppConstants.adminPageSize}',
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
      final p = _paginated(
        json.decode(utf8.decode(response.bodyBytes)),
        page,
      );
      return PaginatedPayments(
        payments: p.items
            .map((j) => AdminPayment.fromJson(j as Map<String, dynamic>))
            .toList(),
        total: p.total,
        page: p.page,
        limit: p.limit,
      );
    }
    throw Exception(
        _parseError(response, 'Échec du chargement des paiements'));
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
      // Tolère objet plat OU enveloppe `{ data: ... }` via le helper partagé.
      final data = ApiResponse.mapOf(json.decode(utf8.decode(response.bodyBytes)));
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
      } catch (e) {
        if (kDebugMode) debugPrint('[AdminOps] confirmPayment parse error: $e');
      }
      throw Exception(message);
    }
  }

  /// Livreurs paginés avec leurs livraisons récentes (GET /admin/deliverers).
  Future<PaginatedDeliverers> fetchDeliverers({int page = 1}) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/admin/deliverers').replace(
      queryParameters: {
        'page': '$page',
        'limit': '${AppConstants.adminPageSize}',
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
      final p = _paginated(
        json.decode(utf8.decode(response.bodyBytes)),
        page,
      );
      return PaginatedDeliverers(
        deliverers: p.items
            .map((j) => AdminDeliverer.fromJson(j as Map<String, dynamic>))
            .toList(),
        total: p.total,
        page: p.page,
        limit: p.limit,
      );
    }
    throw Exception(
        _parseError(response, 'Échec du chargement des livreurs'));
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
        _parseError(response, 'Échec du chargement de la configuration'));
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
    throw Exception(
        _parseError(response, 'Échec de la mise à jour de la configuration'));
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
      // Déballe l'éventuel double-wrap de l'interceptor backend avant de passer
      // à Paginated.fromJson (qui attend `{ data: [...], (meta|root) }`).
      final body = ApiResponse.mapOf(json.decode(utf8.decode(response.bodyBytes)));
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
      // Tolère objet plat OU enveloppe `{ data: ... }` via le helper partagé.
      final data = ApiResponse.mapOf(json.decode(utf8.decode(response.bodyBytes)));
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
  ///
  /// Garde-fou : borne le scan à [_maxLookupPages] pages pour éviter toute
  /// boucle longue si `total` est incohérent (cf. A24/A11 — à remplacer par un
  /// endpoint backend dédié `GET /admin/deliverers/:id`).
  static const int _maxLookupPages = 50;

  Future<AdminDeliverer> _findDelivererInList(String id) async {
    var page = 1;
    while (page <= _maxLookupPages) {
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
    throw Exception('Livreur introuvable (limite de recherche atteinte)');
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
    } catch (e) {
      if (kDebugMode) debugPrint('[AdminOps] _parseError decode failed: $e');
    }
    return '$fallback (${response.statusCode})';
  }
}

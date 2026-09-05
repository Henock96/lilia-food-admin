import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/models/app_user.dart';
import 'package:lilia_admin/models/client_loyalty.dart';
import 'package:lilia_admin/models/client_referral.dart';
import 'package:lilia_admin/models/paginated_clients.dart';
import 'package:lilia_admin/utils/api_response.dart';

class ClientRepository {
  final ApiClient _api;

  ClientRepository(this._api);

  Future<List<AppUser>> fetchClients(String restaurantId) async {
    final res = await _api.getJson('/restaurants/$restaurantId/clients');
    // /restaurants/:id/clients double-enveloppé (`{ data: { data: [...], total } }`).
    final clientsData = ApiResponse.listOf(ApiResponse.mapOf(res.data));
    return clientsData
        .map((json) => AppUser.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Récupère les clients de la plateforme, paginés et filtrables (ADMIN).
  Future<PaginatedClients> fetchAllClients({int page = 1, String search = ''}) async {
    final res = await _api.getJson('/admin/clients', query: {
      'page': '$page',
      'limit': '20',
      if (search.trim().isNotEmpty) 'search': search.trim(),
    });
    // Contrat v2 : `{ data: [...], meta: { total, page, limit } }`. On tolère
    // aussi l'ancien `{ data, total, page, limit }` à plat (fallback racine).
    final inner = ApiResponse.mapOf(res.data);
    final clientsData = ApiResponse.listOf(inner);
    final meta = inner['meta'] as Map<String, dynamic>?;
    int read(String key, int fallback) =>
        (inner[key] as int?) ?? (meta?[key] as int?) ?? fallback;
    return PaginatedClients(
      clients: clientsData
          .map((j) => AppUser.fromJson(j as Map<String, dynamic>))
          .toList(),
      total: read('total', clientsData.length),
      page: read('page', page),
      limit: read('limit', 20),
    );
  }

  /// Solde + historique de fidélité d'un client (ADMIN).
  Future<ClientLoyalty> fetchClientLoyalty(String clientId) async {
    final res = await _api.getJson('/admin/clients/$clientId/loyalty');
    // Loyalty double-enveloppé : `{ data: { data: { balance, transactions },
    // total, page, limit } }`. Deux niveaux à déballer pour l'objet réel.
    final data = ApiResponse.mapOf(ApiResponse.mapOf(res.data));
    return ClientLoyalty.fromJson(data);
  }

  /// Statistiques de parrainage d'un client (ADMIN).
  Future<ClientReferral> fetchClientReferral(String clientId) async {
    final res = await _api.getJson('/admin/clients/$clientId/referral');
    // Referral renvoie `{ data: {...} }` (conforme, simple wrap) ; le double
    // mapOf reste sûr (no-op si pas de second niveau).
    final data = ApiResponse.mapOf(ApiResponse.mapOf(res.data));
    return ClientReferral.fromJson(data);
  }
}

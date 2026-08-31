import 'package:lilia_admin/core/network/api_client.dart';
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
import 'package:lilia_admin/models/order_financials.dart';

import 'package:lilia_admin/constants/app_constants.dart';

/// Appels HTTP des opérations d'administration transverses :
/// supervision des paiements, des livreurs et configuration plateforme.
/// Toutes les routes sont ADMIN-only côté backend.
class AdminOperationsRepository {
  final ApiClient _api;

  AdminOperationsRepository(this._api);

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
    final res = await _api.getJson('/admin/payments', query: {
      'page': '$page',
      'limit': '${AppConstants.adminPageSize}',
      if (status.isNotEmpty) 'status': status,
    });
    final p = _paginated(res.data, page);
    return PaginatedPayments(
      payments: p.items
          .map((j) => AdminPayment.fromJson(j as Map<String, dynamic>))
          .toList(),
      total: p.total,
      page: p.page,
      limit: p.limit,
    );
  }

  /// KPI paiements agrégés (GET /admin/payments/stats).
  Future<PaymentsStats> fetchPaymentsStats() async {
    final res = await _api.getJson('/admin/payments/stats');
    // Tolère objet plat OU enveloppe `{ data: ... }` via le helper partagé.
    return PaymentsStats.fromJson(ApiResponse.mapOf(res.data));
  }

  /// Confirmation manuelle d'un paiement (POST /payments/:id/confirm).
  Future<void> confirmPayment(String paymentId) async {
    await _api.postJson('/payments/$paymentId/confirm');
  }

  /// Rejet manuel d'un paiement (POST /payments/:id/reject).
  /// `reason` optionnel — virement non retrouvé par défaut côté backend.
  /// La commande reste EN_ATTENTE : le client pourra réessayer.
  Future<void> rejectPayment(String paymentId, {String? reason}) async {
    await _api.postJson('/payments/$paymentId/reject', body: {
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    });
  }

  /// Livreurs paginés avec leurs livraisons récentes (GET /admin/deliverers).
  Future<PaginatedDeliverers> fetchDeliverers({int page = 1}) async {
    final res = await _api.getJson('/admin/deliverers', query: {
      'page': '$page',
      'limit': '${AppConstants.adminPageSize}',
    });
    final p = _paginated(res.data, page);
    return PaginatedDeliverers(
      deliverers: p.items
          .map((j) => AdminDeliverer.fromJson(j as Map<String, dynamic>))
          .toList(),
      total: p.total,
      page: p.page,
      limit: p.limit,
    );
  }

  /// Configuration plateforme (GET /admin/platform-settings).
  Future<PlatformSettings> fetchPlatformSettings() async {
    final res = await _api.getJson('/admin/platform-settings');
    final data =
        (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>? ?? {};
    return PlatformSettings.fromJson(data);
  }

  /// Mise à jour de la configuration plateforme
  /// (PATCH /admin/platform-settings).
  Future<PlatformSettings> updatePlatformSettings(
      Map<String, dynamic> dto) async {
    final res = await _api.patchJson('/admin/platform-settings', body: dto);
    final data =
        (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>? ?? {};
    return PlatformSettings.fromJson(data);
  }

  // ─── Fiche livreur détaillée (LIL-84) ────────────────────────────────────

  /// Stats agrégées d'un livreur — `GET /admin/deliverers/:id/stats`.
  Future<DelivererStats> getDelivererStats(String id) async {
    final res = await _api.getJson('/admin/deliverers/$id/stats');
    final data =
        (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>? ??
            const {};
    return DelivererStats.fromJson(data);
  }

  /// Missions d'un livreur paginées et optionnellement filtrées par statut —
  /// `GET /admin/deliverers/:id/missions?status=&page=&limit=`.
  Future<Paginated<DeliveryMissionSummary>> getDelivererMissions(
    String id, {
    DeliveryStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _api.getJson('/admin/deliverers/$id/missions', query: {
      'page': '$page',
      'limit': '$limit',
      if (status != null) 'status': status.wireValue,
    });
    // Déballe l'éventuel double-wrap de l'interceptor backend avant de passer
    // à Paginated.fromJson (qui attend `{ data: [...], (meta|root) }`).
    return Paginated<DeliveryMissionSummary>.fromJson(
      ApiResponse.mapOf(res.data),
      DeliveryMissionSummary.fromJson,
    );
  }

  /// Livraison associée à une commande — `GET /deliveries/by-order/:orderId`.
  Future<Delivery> getDeliveryByOrder(String orderId) async {
    final res = await _api.getJson('/deliveries/by-order/$orderId');
    // Tolère objet plat OU enveloppe `{ data: ... }` via le helper partagé.
    return Delivery.fromJson(ApiResponse.mapOf(res.data));
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

  // ══════════════════════════════════════════════════════════════════════════
  // Reversements vendeurs (payouts)
  //
  // ⚠️ Aucun montant n'est envoyé au backend : il recalcule tout à partir de la
  // commande et du taux en vigueur. L'application affiche, elle ne décide pas.
  // ══════════════════════════════════════════════════════════════════════════

  /// Récapitulatif financier d'une commande + éligibilité au reversement
  /// (GET /admin/orders/:orderId/financials).
  Future<OrderFinancials> fetchOrderFinancials(String orderId) async {
    final res = await _api.getJson('/admin/orders/$orderId/financials');
    return OrderFinancials.fromJson(ApiResponse.mapOf(res.data));
  }

  /// Déclenche le reversement du vendeur (POST /admin/orders/:orderId/payout).
  ///
  /// Le backend rejoue **toutes** les vérifications d'éligibilité : afficher le
  /// bouton ne l'autorise pas. Un 409 porte un `code` exploitable
  /// (`PAYOUT_ALREADY_COMPLETED`, `VENDOR_PAYOUT_ACCOUNT_MISSING`…).
  Future<void> requestPayout(String orderId, {String? note}) async {
    await _api.postJson(
      '/admin/orders/$orderId/payout',
      body: {if (note != null && note.isNotEmpty) 'note': note},
    );
  }

  /// Nouvelle tentative après échec (POST /admin/orders/:orderId/payout/retry).
  ///
  /// Refusée par le backend tant que le reversement est `PENDING` ou `SUCCESS` :
  /// réessayer un virement peut-être déjà parti est le seul moyen de payer deux
  /// fois un vendeur.
  Future<void> retryPayout(String orderId, {String? note}) async {
    await _api.postJson(
      '/admin/orders/$orderId/payout/retry',
      body: {if (note != null && note.isNotEmpty) 'note': note},
    );
  }

  /// Enregistre le compte Mobile Money de reversement d'un vendeur
  /// (PATCH /admin/vendors/:id/payout-account).
  Future<void> updateVendorPayoutAccount({
    required String restaurantId,
    required String phoneNumber,
    required String provider,
    String? accountName,
  }) async {
    await _api.patchJson(
      '/admin/vendors/$restaurantId/payout-account',
      body: {
        'payoutPhoneNumber': phoneNumber,
        'payoutProvider': provider,
        if (accountName != null && accountName.isNotEmpty)
          'payoutAccountName': accountName,
      },
    );
  }
}

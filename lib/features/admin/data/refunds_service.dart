import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/models/refund.dart';
import 'package:lilia_admin/utils/api_response.dart';

part 'refunds_service.g.dart';

/// File des remboursements dus après annulation d'une commande payée.
///
/// Routes ADMIN-only côté backend. Chaque changement de statut est journalisé
/// dans `AdminAuditLog` — inutile de le tracer une seconde fois côté client.
class RefundsService {
  final ApiClient _api;

  RefundsService(this._api);

  /// Nombre de remboursements chargés par appel. Le backend plafonne de toute
  /// façon `limit`, on reste dans sa fenêtre.
  static const pageSize = 50;

  /// `GET /refunds?status=&page=&limit=` — les plus anciens d'abord (c'est une
  /// file, pas un flux d'actualité : le client qui attend depuis le plus
  /// longtemps passe en premier).
  ///
  /// Renvoie le **total serveur** en plus de la page : sans lui, le badge de
  /// navigation comptait les éléments reçus et plafonnait donc à la taille
  /// d'une page. Un admin voyait « 20 » alors que cinquante clients
  /// attendaient leur argent — et rien ne le lui signalait.
  Future<RefundPage> list({RefundStatus? status, int page = 1}) async {
    final res = await _api.getJson(
      '/refunds',
      query: {
        if (status != null) 'status': status.toApiString(),
        'page': '$page',
        'limit': '$pageSize',
      },
    );

    final items = ApiResponse.listOf(res.data)
        .map((e) => Refund.fromJson(e as Map<String, dynamic>))
        .toList();

    return RefundPage(
      items: items,
      total: _readTotal(res.data) ?? items.length,
      page: page,
    );
  }

  /// `meta.total` quand le backend l'envoie. Le contrat d'enveloppe est encore
  /// en cours d'uniformisation (api-contract-v2) : on retombe sur la taille de
  /// la page reçue plutôt que d'échouer.
  int? _readTotal(dynamic decoded) {
    if (decoded is! Map<String, dynamic>) return null;
    final meta = decoded['meta'];
    if (meta is! Map<String, dynamic>) return null;
    final total = meta['total'];
    return total is int ? total : int.tryParse('$total');
  }

  /// `PATCH /refunds/:id/status`
  Future<void> updateStatus(
    String refundId,
    RefundStatus status, {
    String? notes,
  }) async {
    await _api.patchJson(
      '/refunds/$refundId/status',
      body: {
        'status': status.toApiString(),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );
  }
}

@Riverpod(keepAlive: true)
RefundsService refundsService(Ref ref) =>
    RefundsService(ref.watch(apiClientProvider));

/// Une page de la file, avec le total serveur.
class RefundPage {
  final List<Refund> items;

  /// Nombre total de remboursements correspondant au filtre, toutes pages
  /// confondues — pas seulement ceux de cette page.
  final int total;
  final int page;

  const RefundPage({
    required this.items,
    required this.total,
    required this.page,
  });

  bool get hasMore => items.length >= RefundsService.pageSize;
}

/// Première page, filtrée par statut. `null` = tous.
@riverpod
Future<RefundPage> refundsList(Ref ref, RefundStatus? status) async {
  return ref.watch(refundsServiceProvider).list(status: status);
}

/// Compteur des remboursements à traiter — alimente le badge de navigation.
///
/// Séparé de la liste : le badge doit pouvoir se rafraîchir sans recharger
/// l'écran, et rester disponible depuis n'importe quel onglet.
@riverpod
Future<int> pendingRefundsCount(Ref ref) async {
  // `total` et non `items.length` : le badge doit dire combien de clients
  // attendent, pas combien tiennent sur une page.
  final pending = await ref
      .watch(refundsServiceProvider)
      .list(status: RefundStatus.pending);
  return pending.total;
}

import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/utils/api_response.dart';

import '../../../models/order.dart';

/// Une page de commandes, avec les compteurs d'onglets du serveur.
class OrderPage {
  final List<Order> items;

  /// Nombre total de commandes correspondant au filtre courant, toutes pages
  /// confondues — pas seulement celles de cette page.
  final int total;
  final int page;
  final int totalPages;

  /// Compte des sept statuts sur le **périmètre entier**, filtre courant
  /// exclu. Vide si le backend ne l'envoie pas encore.
  final Map<OrderStatus, int> statusCounts;

  const OrderPage({
    required this.items,
    required this.total,
    required this.page,
    required this.totalPages,
    required this.statusCounts,
  });

  const OrderPage.empty()
    : items = const [],
      total = 0,
      page = 1,
      totalPages = 1,
      statusCounts = const {};

  /// Reste-t-il des commandes à charger ?
  ///
  /// On compare au **total serveur**, pas à la taille de la page reçue : une
  /// dernière page exactement pleine proposerait sinon un « charger plus » qui
  /// ne rapporte rien.
  bool get hasMore => items.length < total;

  /// Concatène la page suivante. La liste reçue est déjà triée par date
  /// décroissante côté serveur, et les pages ne se chevauchent pas.
  OrderPage append(OrderPage next) => OrderPage(
    items: [...items, ...next.items],
    total: next.total,
    page: next.page,
    totalPages: next.totalPages,
    statusCounts: next.statusCounts,
  );
}

/// Lecture des commandes du back-office.
///
/// ## Le défaut corrigé
///
/// `getRestaurantOrders()` appelait `/orders/restaurant` **sans transmettre de
/// pagination**. Le backend appliquait donc son `limit = 20` par défaut, et
/// l'application n'a jamais montré plus de vingt commandes — les sept onglets
/// se contentant de filtrer ces vingt lignes en mémoire. Une commande plus
/// ancienne était inatteignable depuis l'administration, et les compteurs
/// d'onglets annonçaient des nombres calculés sur un échantillon arbitraire.
///
/// C'est le même défaut que celui corrigé en août sur la file des
/// remboursements, et que celui corrigé en septembre sur le catalogue.
///
/// ## Deux routes, un seul contrat
///
/// `/admin/orders` est ADMIN-only ; y envoyer un vendeur produirait un 403 sur
/// l'écran le plus consulté de son back-office. Les deux routes acceptent
/// `page`, `limit` et `status`, et rendent la même enveloppe
/// `{ data, meta: { total, page, limit, totalPages, statusCounts } }`.
class OrderService {
  final ApiClient _api;

  OrderService(this._api);

  /// Commandes chargées par appel. Le backend plafonne `limit` à 100 ; 20 est
  /// la taille d'écran utile, et c'est aussi ce qu'affiche le Web.
  static const pageSize = 20;

  /// `GET /admin/orders` (ADMIN) ou `GET /orders/restaurant` (RESTAURATEUR).
  ///
  /// ⚠️ `status` part **dans la requête**. Filtrer en mémoire une page déjà
  /// tronquée ne rend que les commandes de cette page, en annonçant avec
  /// aplomb qu'il n'y en a pas d'autres.
  /// `search` est libre : identifiant de commande (complet ou tronqué tel qu'il
  /// s'affiche, dièse compris), nom du client, téléphone (compte ou contact de
  /// livraison), nom du vendeur. Appliqué **par le serveur** — chercher dans la
  /// page reçue ne fouillerait que vingt commandes.
  Future<OrderPage> getRestaurantOrders({
    required bool isAdmin,
    int page = 1,
    OrderStatus? status,
    String search = '',
  }) async {
    final path = isAdmin ? '/admin/orders' : '/orders/restaurant';
    final term = search.trim();

    final res = await _api.getJson(
      path,
      query: {
        'page': '$page',
        'limit': '$pageSize',
        if (status != null) 'status': status.toWire(),
        // Un `search=` vide ferait porter au serveur une clause `OR` qui ne
        // filtre rien tout en coûtant trois jointures.
        if (term.isNotEmpty) 'search': term,
      },
    );

    final items = ApiResponse.listOf(res.data)
        .map((json) => Order.fromJson(json as Map<String, dynamic>))
        .toList();

    final meta = _metaOf(res.data);

    // Repli sur ce qu'on a **réellement reçu** plutôt que sur zéro : un backend
    // antérieur à `meta` ne doit pas faire afficher « 0 commande » sous une
    // liste qui en montre vingt.
    final total = _readInt(meta, 'total') ?? items.length;
    final limit = _readInt(meta, 'limit') ?? pageSize;

    return OrderPage(
      items: items,
      total: total,
      page: _readInt(meta, 'page') ?? page,
      totalPages:
          _readInt(meta, 'totalPages') ??
          (limit > 0 ? ((total + limit - 1) ~/ limit).clamp(1, 1 << 31) : 1),
      statusCounts: _readStatusCounts(meta),
    );
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _api.patchJson(
      '/orders/$orderId/status',
      body: {'status': status.toWire()},
    );
  }

  /// `meta` de la réponse, en tolérant l'absence d'enveloppe (le contrat
  /// api-contract-v2 est encore en cours d'uniformisation).
  Map<String, dynamic>? _metaOf(dynamic decoded) {
    if (decoded is! Map<String, dynamic>) return null;
    final meta = decoded['meta'];
    return meta is Map<String, dynamic> ? meta : null;
  }

  int? _readInt(Map<String, dynamic>? meta, String key) {
    final raw = meta?[key];
    if (raw is int) return raw;
    return raw == null ? null : int.tryParse('$raw');
  }

  /// Traduit `meta.statusCounts` en compteurs typés.
  ///
  /// Une clé inconnue est **ignorée** : le backend peut gagner une valeur
  /// d'enum avant que l'application ne soit mise à jour, et une liste qui
  /// refuse de se charger pour cette raison est pire qu'un onglet manquant.
  /// C'est la leçon d'`ACCEPTER`, ajouté à `DeliveryStatus` en août.
  ///
  /// Les statuts connus absents de la réponse valent **zéro** : l'onglet doit
  /// pouvoir afficher « (0) » sans que l'écran ait à le deviner.
  Map<OrderStatus, int> _readStatusCounts(Map<String, dynamic>? meta) {
    final raw = meta?['statusCounts'];
    if (raw is! Map) return const {};

    final counts = <OrderStatus, int>{
      for (final s in OrderStatus.values)
        if (s != OrderStatus.unknown) s: 0,
    };

    raw.forEach((key, value) {
      final status = Order.statusFromWire('$key');
      if (status == OrderStatus.unknown) return;
      counts[status] = value is int ? value : (int.tryParse('$value') ?? 0);
    });

    return counts;
  }
}

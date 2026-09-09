import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/features/auth/user_sync_provider.dart';
import 'package:lilia_admin/models/order.dart';
import 'package:lilia_admin/models/role.dart';

import 'order_service.dart';

part 'order_controller.g.dart';

@riverpod
OrderService orderServiceRepository(Ref ref) {
  return OrderService(ref.watch(apiClientProvider));
}

/// Commandes du back-office, **paginées par le serveur**, une instance par
/// onglet de statut (`null` = « Toutes »).
///
/// ## Pourquoi une famille par statut
///
/// L'écran chargeait une seule liste — les vingt dernières commandes de toute
/// la plateforme, faute de pagination transmise — et les sept onglets la
/// filtraient en mémoire. Deux conséquences : une commande plus ancienne était
/// inatteignable, et les compteurs d'onglets comptaient dans ces vingt lignes.
///
/// Le filtre appartient donc à la requête, et chaque onglet a la sienne. Les
/// compteurs, eux, viennent de `meta.statusCounts` et portent sur le périmètre
/// entier : ils sont identiques quel que soit l'onglet chargé.
///
/// `search` fait partie de la clé de famille, et du périmètre : chercher
/// « Marie » doit dire combien de commandes de Marie sont dans chaque statut.
/// L'écran envoie un terme **débouncé** — une instance par frappe serait créée
/// et jetée aussitôt.
@riverpod
class RestaurantOrders extends _$RestaurantOrders {
  @override
  Future<OrderPage> build(OrderStatus? status, String search) async {
    // Le rôle décide de la route, pas des droits : `/admin/orders` est
    // ADMIN-only et renverrait un 403 à un vendeur, sur l'écran le plus
    // consulté de son back-office.
    final isAdmin = ref.watch(currentUserProfileProvider)?.role == Role.admin;

    return ref
        .watch(orderServiceRepositoryProvider)
        .getRestaurantOrders(isAdmin: isAdmin, status: status, search: search);
  }

  /// Charge la page suivante et l'ajoute à la liste courante.
  ///
  /// Ne fait rien si la page est déjà complète ou si un chargement est en
  /// cours : un double appui ne doit pas insérer deux fois la même page.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || state.isLoading) return;

    final isAdmin = ref.read(currentUserProfileProvider)?.role == Role.admin;
    final service = ref.read(orderServiceRepositoryProvider);

    try {
      final next = await service.getRestaurantOrders(
        isAdmin: isAdmin,
        page: current.page + 1,
        status: status,
        search: search,
      );
      state = AsyncData(current.append(next));
    } catch (_) {
      // On garde la liste déjà affichée : basculer l'écran entier en erreur
      // parce que la *page suivante* n'est pas arrivée effacerait les
      // commandes que l'utilisateur est en train de lire. L'échec est rapporté
      // à l'appelant, qui l'affiche là où le geste a eu lieu — le pied de
      // liste.
      state = AsyncData(current);
      rethrow;
    }
  }

  /// Change le statut d'une commande, avec bascule optimiste.
  ///
  /// La commande peut sortir du filtre courant (passer « Prête » depuis
  /// l'onglet « En préparation ») : on n'essaie donc pas de deviner la nouvelle
  /// liste, on invalide toute la famille au succès. Les compteurs des sept
  /// onglets bougent de toute façon ensemble.
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    final previous = state.value;
    final service = ref.read(orderServiceRepositoryProvider);

    if (previous != null) {
      final items = [...previous.items];
      final index = items.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        items[index] = items[index].copyWith(status: newStatus);
        state = AsyncData(
          OrderPage(
            items: items,
            total: previous.total,
            page: previous.page,
            totalPages: previous.totalPages,
            statusCounts: previous.statusCounts,
          ),
        );
      }
    }

    try {
      await service.updateOrderStatus(orderId, newStatus);
      ref.invalidateSelf();
    } catch (_) {
      if (previous != null) state = AsyncData(previous);
      rethrow;
    }
  }
}

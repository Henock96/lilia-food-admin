import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/features/auth/user_sync_provider.dart';
import 'package:lilia_admin/models/order.dart';
import 'package:lilia_admin/models/pickup_arbitration_reason.dart';
import 'package:lilia_admin/models/role.dart';
import 'package:lilia_admin/models/vendor_rejection_reason.dart';

import 'order_service.dart';

part 'order_controller.g.dart';

@riverpod
OrderService orderServiceRepository(Ref ref) {
  return OrderService(ref.watch(apiClientProvider));
}

/// Lot 2 (ADM-02) — une commande relue par son identifiant pour la fiche.
///
/// La fiche lisait la commande dans la page 1 de « Toutes » : hors de cette
/// page, elle restait figée sur l'instantané de navigation, statut et gestes
/// compris. Invalidé après chaque geste, par le polling et au retour au
/// premier plan.
@riverpod
Future<Order> staffOrder(Ref ref, String orderId) {
  return ref.watch(orderServiceRepositoryProvider).getStaffOrder(orderId);
}

/// La fiche affichée est-elle peut-être en retard sur le serveur ?
///
/// Vrai dès que la **dernière** relecture a échoué. ⚠️ Pas `hasError &&
/// !hasValue` : après une première lecture réussie, Riverpod 3 garde la valeur
/// précédente dans l'erreur (`hasValue` reste vrai), et un échec répété — un
/// timeout, ou un 404 si la commande sort de la portée — ne se verrait jamais.
bool staffOrderIsStale(AsyncValue<Order> state) => state.hasError;

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
  Future<void> updateOrderStatus(
    String orderId,
    OrderStatus newStatus, {
    String? reason,
  }) async {
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
      await service.updateOrderStatus(orderId, newStatus, reason: reason);
      ref.invalidateSelf();
    } catch (_) {
      // Lot 2 (ADM-06) — un échec ne dit pas que rien n'a été écrit : le
      // serveur a pu commiter avant un timeout. Remettre l'ancien statut
      // afficherait un état faux ; on relit le serveur.
      ref.invalidateSelf();
      rethrow;
    }
  }

  /// Accepte une commande payée (F3-01). Pas de bascule optimiste : le statut
  /// d'arrivée, l'heure de fin annoncée et les gestes suivants viennent du
  /// serveur, on relit donc la liste.
  Future<void> acceptOrder(String orderId, {required int prepMinutes}) async {
    await ref
        .read(orderServiceRepositoryProvider)
        .acceptOrder(orderId, prepMinutes: prepMinutes);
    ref.invalidateSelf();
  }

  /// Remet un retrait avec le code du client (F3-07). Pas de bascule
  /// optimiste : un code faux laisse la commande prête.
  Future<void> handOverPickupWithCode(String orderId, String code) async {
    await ref
        .read(orderServiceRepositoryProvider)
        .handOverPickupWithCode(orderId, code);
    ref.invalidateSelf();
  }

  /// 1B — l'ADMIN clôture un retrait par arbitrage motivé. Pas de bascule
  /// optimiste : la preuve et l'échéance viennent du serveur.
  Future<void> arbitratePickup(
    String orderId, {
    required PickupArbitrationReason reason,
    String? note,
  }) async {
    await ref
        .read(orderServiceRepositoryProvider)
        .arbitratePickup(orderId, reason: reason, note: note);
    ref.invalidateSelf();
  }

  /// Refuse une commande payée ou acceptée (F3-01) : le client est remboursé.
  Future<void> rejectOrder(
    String orderId, {
    required VendorRejectionReason reason,
    String? note,
    List<String> outOfStockProductIds = const [],
  }) async {
    await ref.read(orderServiceRepositoryProvider).rejectOrder(
          orderId,
          reason: reason,
          note: note,
          outOfStockProductIds: outOfStockProductIds,
        );
    ref.invalidateSelf();
  }
}

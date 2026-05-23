import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:lilia_admin/models/order.dart';
import 'order_service.dart';

part 'order_controller.g.dart';

@riverpod
OrderService orderServiceRepository(Ref ref) {
  return OrderService();
}

@riverpod
class RestaurantOrders extends _$RestaurantOrders {
  // La méthode `build` est appelée automatiquement et doit retourner l'état initial.
  // Riverpod gère les états `loading` et `error` pour nous.
  @override
  Future<List<Order>> build() async {
    // On récupère le service et on charge les données initiales.
    final orderService = ref.watch(orderServiceRepositoryProvider);
    return orderService.getRestaurantOrders();
  }

  // Méthode pour mettre à jour le statut d'une commande via l'API.
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    final orderService = ref.read(orderServiceRepositoryProvider);

    // Mettre à jour l'état local immédiatement pour une meilleure réactivité
    final List<Order>? previousState = state.value;
    final currentState = <Order>[...?previousState];
    final index = currentState.indexWhere((o) => o.id == orderId);

    if (index != -1) {
      final updatedOrder = currentState[index].copyWith(status: newStatus);
      currentState[index] = updatedOrder;
      state = AsyncData([...currentState]);
    }

    try {
      await orderService.updateOrderStatus(orderId, newStatus);
    } catch (_) {
      if (previousState != null) {
        state = AsyncData(previousState);
      }
      rethrow;
    }
  }

  // Méthode pour mettre à jour ou ajouter une commande dans l'état local.
  // Elle sera appelée depuis l'écran lorsque l'événement SSE est reçu.
  void updateOrAddOrder(Order order) {
    // `state.value` récupère la liste actuelle si elle existe.
    final currentState = <Order>[...?state.value];
    final index = currentState.indexWhere((o) => o.id == order.id);

    if (index != -1) {
      // La commande existe, on la met à jour.
      currentState[index] = order;
    } else {
      // Nouvelle commande, on l'ajoute au début.
      currentState.insert(0, order);
    }

    // On trie pour s'assurer que les nouvelles commandes sont en haut.
    currentState.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // On met à jour l'état avec la nouvelle liste.
    // `AsyncData` signifie que la mise à jour a réussi.
    state = AsyncData([...currentState]);
  }
}

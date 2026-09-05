import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/models/order.dart';
import 'package:lilia_admin/utils/api_response.dart';

class UserRepository {
  final ApiClient _api;

  UserRepository(this._api);

  Future<List<Order>> fetchUserOrders(
    String restaurantId,
    String userId,
  ) async {
    final res = await _api
        .getJson('/restaurants/$restaurantId/clients/$userId/orders');
    // Possiblement double-enveloppé (`{ data: { data: [...], ... } }`).
    final ordersData = ApiResponse.listOf(ApiResponse.mapOf(res.data));
    return ordersData
        .map((json) => Order.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Toutes les commandes d'un client, tous restaurants confondus (ADMIN).
  /// Utilise GET /orders/user/:userId (route admin-only côté backend).
  Future<List<Order>> fetchAllUserOrders(String userId) async {
    final res = await _api.getJson('/orders/user/$userId');
    final ordersData = ApiResponse.listOf(ApiResponse.mapOf(res.data));
    return ordersData
        .map((json) => Order.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

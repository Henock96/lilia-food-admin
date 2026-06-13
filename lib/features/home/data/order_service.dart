import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/utils/api_response.dart';

import '../../../models/order.dart';

class OrderService {
  final ApiClient _api;

  OrderService(this._api);

  Future<List<Order>> getRestaurantOrders() async {
    final res = await _api.getJson('/orders/restaurant');
    // Tolère liste brute / simple wrap / double wrap (interceptor backend).
    final ordersData = ApiResponse.listOf(res.data);
    return ordersData
        .map((json) => Order.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    // Convertir le status enum en string pour le backend
    String statusString;
    switch (status) {
      case OrderStatus.enattente:
        statusString = 'EN_ATTENTE';
        break;
      case OrderStatus.payer:
        statusString = 'PAYER';
        break;
      case OrderStatus.enpreparation:
        statusString = 'EN_PREPARATION';
        break;
      case OrderStatus.pret:
        statusString = 'PRET';
        break;
      case OrderStatus.enRoute:
        statusString = 'EN_ROUTE';
        break;
      case OrderStatus.livrer:
        statusString = 'LIVRER';
        break;
      case OrderStatus.annuler:
        statusString = 'ANNULER';
        break;
      default:
        statusString = 'EN_ATTENTE';
    }

    await _api.patchJson(
      '/orders/$orderId/status',
      body: {'status': statusString},
    );
  }
}

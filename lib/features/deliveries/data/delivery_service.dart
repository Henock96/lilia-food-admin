import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/utils/api_response.dart';

import '../../../models/app_deliverer.dart';

class DeliveryService {
  final ApiClient _api;

  DeliveryService(this._api);

  Future<List<AppDeliverer>> getAvailableDeliverers() async {
    final res = await _api.getJson('/deliveries/deliverers');
    final data = ApiResponse.listOf(res.data);
    return data
        .map((e) => AppDeliverer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// PATCH /deliveries/by-order/:orderId/assign
  /// Crée la livraison si elle n'existe pas, puis assigne le livreur.
  Future<void> assignDelivererToOrder(String orderId, String delivererId) async {
    await _api.patchJson(
      '/deliveries/by-order/$orderId/assign',
      body: {'delivererId': delivererId},
    );
  }
}

import 'package:lilia_admin/core/network/api_client.dart';

class AdminService {
  final ApiClient _api;

  AdminService(this._api);

  Future<Map<String, dynamic>> createRestaurantWithOwner({
    required String email,
    required String password,
    required String nom,
    String? phone,
    required String restaurantNom,
    required String restaurantAdresse,
    required String restaurantPhone,
    String? restaurantImageUrl,
  }) async {
    final res = await _api.postJson('/admin/restaurants', body: {
      'email': email,
      'password': password,
      'nom': nom,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      'restaurantNom': restaurantNom,
      'restaurantAdresse': restaurantAdresse,
      'restaurantPhone': restaurantPhone,
      if (restaurantImageUrl != null && restaurantImageUrl.isNotEmpty)
        'restaurantImageUrl': restaurantImageUrl,
    });
    return (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  }
}

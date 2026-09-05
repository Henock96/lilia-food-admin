import 'package:lilia_admin/core/network/api_client.dart';

import '../../../models/app_user.dart';
import '../../../utils/api_response.dart';

class UserRepository {
  final ApiClient _api;

  UserRepository(this._api);

  /// Extrait l'objet user de `/users/me`, tolérant aux deux formes :
  /// legacy `{ user: {...} }` ET wrappée `{ data: { user: {...} } }`.
  static Map<String, dynamic> _extractUser(dynamic decoded) {
    final unwrapped = ApiResponse.mapOf(decoded);
    return (unwrapped['user'] ?? unwrapped) as Map<String, dynamic>;
  }

  Future<AppUser> updateUserProfile(Map<String, dynamic> data) async {
    final res = await _api.putJson('/users/me', body: data);
    return AppUser.fromJson(_extractUser(res.data));
  }

  Future<AppUser> getUserProfile() async {
    final res = await _api.getJson('/users/me');
    return AppUser.fromJson(_extractUser(res.data));
  }
}

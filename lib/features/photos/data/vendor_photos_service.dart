import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/utils/api_response.dart';

import 'photo_models.dart';

class VendorPhotosService {
  final ApiClient _api;

  VendorPhotosService(this._api);

  Future<List<Photo>> list(String restaurantId) async {
    final res = await _api
        .getJson('/vendor-photos', query: {'restaurantId': restaurantId});
    return ApiResponse.listOf(res.data)
        .map((j) => Photo.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<Photo> create({
    required String restaurantId,
    required String url,
    required String publicId,
    String? alt,
    bool isCover = false,
  }) async {
    final res = await _api.postJson('/vendor-photos', body: {
      'restaurantId': restaurantId,
      'url': url,
      'publicId': publicId,
      if (alt != null) 'alt': alt,
      'isCover': isCover,
    });
    return Photo.fromJson(ApiResponse.mapOf(res.data));
  }

  Future<Photo> update(
    String photoId, {
    String? alt,
    bool? isCover,
    int? displayOrder,
  }) async {
    final body = <String, dynamic>{};
    if (alt != null) body['alt'] = alt;
    if (isCover != null) body['isCover'] = isCover;
    if (displayOrder != null) body['displayOrder'] = displayOrder;

    final res = await _api.patchJson('/vendor-photos/$photoId', body: body);
    return Photo.fromJson(ApiResponse.mapOf(res.data));
  }

  Future<void> delete(String photoId) async {
    await _api.deleteJson('/vendor-photos/$photoId');
  }

  Future<void> reorder(String restaurantId, List<String> ids) async {
    await _api.postJson(
      '/vendor-photos/reorder',
      body: {'restaurantId': restaurantId, 'ids': ids},
    );
  }
}

import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/utils/api_response.dart';

import 'photo_models.dart';

class MenuImagesService {
  final ApiClient _api;

  MenuImagesService(this._api);

  Future<List<Photo>> list(String menuDuJourId) async {
    final res = await _api
        .getJson('/menu-images', query: {'menuDuJourId': menuDuJourId});
    return ApiResponse.listOf(res.data)
        .map((j) => Photo.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<Photo> create({
    required String menuDuJourId,
    required String url,
    required String publicId,
    String? alt,
    bool isCover = false,
  }) async {
    final res = await _api.postJson('/menu-images', body: {
      'menuDuJourId': menuDuJourId,
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

    final res = await _api.patchJson('/menu-images/$photoId', body: body);
    return Photo.fromJson(ApiResponse.mapOf(res.data));
  }

  Future<void> delete(String photoId) async {
    await _api.deleteJson('/menu-images/$photoId');
  }

  Future<void> reorder(String menuDuJourId, List<String> ids) async {
    await _api.postJson(
      '/menu-images/reorder',
      body: {'menuDuJourId': menuDuJourId, 'ids': ids},
    );
  }
}

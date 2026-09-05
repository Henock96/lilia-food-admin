import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/utils/api_response.dart';

import '../../../models/banner.dart';

class BannerService {
  final ApiClient _api;

  BannerService(this._api);

  Future<List<AppBanner>> getBanners({String? restaurantId}) async {
    final res = await _api.getJson(
      '/banners',
      query: {if (restaurantId != null) 'restaurantId': restaurantId},
    );
    // Tolère liste brute / simple wrap / double wrap (interceptor backend).
    final data = ApiResponse.listOf(res.data);
    return data
        .map((json) => AppBanner.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<AppBanner> createBanner(Map<String, dynamic> bannerData) async {
    final res = await _api.postJson('/banners', body: bannerData);
    final bannerJson =
        (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
    if (bannerJson == null) {
      throw Exception('Banner data is null in response');
    }
    return AppBanner.fromJson(bannerJson);
  }

  Future<AppBanner> updateBanner(
      String bannerId, Map<String, dynamic> bannerData) async {
    final res = await _api.patchJson('/banners/$bannerId', body: bannerData);
    final bannerJson =
        (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
    if (bannerJson == null) {
      throw Exception('Banner data is null in response');
    }
    return AppBanner.fromJson(bannerJson);
  }

  Future<void> deleteBanner(String bannerId) async {
    await _api.deleteJson('/banners/$bannerId');
  }

  Future<void> reorderBanner(String bannerId, int displayOrder) async {
    await _api.patchJson(
      '/banners/$bannerId/reorder',
      body: {'displayOrder': displayOrder},
    );
  }
}

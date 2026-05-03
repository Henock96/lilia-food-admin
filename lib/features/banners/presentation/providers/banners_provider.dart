import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../models/banner.dart';
import '../../data/banner_service.dart';

part 'banners_provider.g.dart';

@riverpod
BannerService bannerService(Ref ref) {
  return BannerService();
}

@riverpod
class Banners extends _$Banners {
  @override
  Future<List<AppBanner>> build() async {
    final service = ref.watch(bannerServiceProvider);
    return service.getBanners();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(bannerServiceProvider);
      return service.getBanners();
    });
  }

  Future<void> createBanner(Map<String, dynamic> bannerData) async {
    final service = ref.read(bannerServiceProvider);
    await service.createBanner(bannerData);
    await refresh();
  }

  Future<void> updateBanner(
      String bannerId, Map<String, dynamic> bannerData) async {
    final service = ref.read(bannerServiceProvider);
    await service.updateBanner(bannerId, bannerData);
    await refresh();
  }

  Future<void> toggleBannerStatus(AppBanner banner) async {
    final service = ref.read(bannerServiceProvider);
    await service.updateBanner(banner.id, {'isActive': !banner.isActive});
    await refresh();
  }

  Future<void> deleteBanner(String bannerId) async {
    final service = ref.read(bannerServiceProvider);
    await service.deleteBanner(bannerId);
    await refresh();
  }

  Future<void> reorderBanners(List<AppBanner> reorderedBanners) async {
    final service = ref.read(bannerServiceProvider);
    for (int i = 0; i < reorderedBanners.length; i++) {
      await service.reorderBanner(reorderedBanners[i].id, i);
    }
    await refresh();
  }
}

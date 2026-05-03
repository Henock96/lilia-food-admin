// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'banners_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(bannerService)
final bannerServiceProvider = BannerServiceProvider._();

final class BannerServiceProvider
    extends $FunctionalProvider<BannerService, BannerService, BannerService>
    with $Provider<BannerService> {
  BannerServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bannerServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bannerServiceHash();

  @$internal
  @override
  $ProviderElement<BannerService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BannerService create(Ref ref) {
    return bannerService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BannerService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BannerService>(value),
    );
  }
}

String _$bannerServiceHash() => r'4e30d5537c7dc9e3fe742c79c4af41791b7ac0dd';

@ProviderFor(Banners)
final bannersProvider = BannersProvider._();

final class BannersProvider
    extends $AsyncNotifierProvider<Banners, List<AppBanner>> {
  BannersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bannersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bannersHash();

  @$internal
  @override
  Banners create() => Banners();
}

String _$bannersHash() => r'6da833a089b069a047ecfa6298f29f127b9250b8';

abstract class _$Banners extends $AsyncNotifier<List<AppBanner>> {
  FutureOr<List<AppBanner>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<AppBanner>>, List<AppBanner>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<AppBanner>>, List<AppBanner>>,
              AsyncValue<List<AppBanner>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

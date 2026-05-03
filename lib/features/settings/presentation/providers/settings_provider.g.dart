// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RestaurantSettings)
final restaurantSettingsProvider = RestaurantSettingsProvider._();

final class RestaurantSettingsProvider
    extends $AsyncNotifierProvider<RestaurantSettings, Restaurant> {
  RestaurantSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'restaurantSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$restaurantSettingsHash();

  @$internal
  @override
  RestaurantSettings create() => RestaurantSettings();
}

String _$restaurantSettingsHash() =>
    r'922bfc9d95d3c99f27c6d6169152d7e980418e12';

abstract class _$RestaurantSettings extends $AsyncNotifier<Restaurant> {
  FutureOr<Restaurant> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Restaurant>, Restaurant>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Restaurant>, Restaurant>,
              AsyncValue<Restaurant>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

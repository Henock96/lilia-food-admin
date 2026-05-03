// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restaurant_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider qui retourne l'ID du restaurant de l'utilisateur connecté.
/// Si l'utilisateur n'a pas de restaurant associé, retourne une chaîne vide.

@ProviderFor(currentRestaurantId)
final currentRestaurantIdProvider = CurrentRestaurantIdProvider._();

/// Provider qui retourne l'ID du restaurant de l'utilisateur connecté.
/// Si l'utilisateur n'a pas de restaurant associé, retourne une chaîne vide.

final class CurrentRestaurantIdProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// Provider qui retourne l'ID du restaurant de l'utilisateur connecté.
  /// Si l'utilisateur n'a pas de restaurant associé, retourne une chaîne vide.
  CurrentRestaurantIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentRestaurantIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentRestaurantIdHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return currentRestaurantId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$currentRestaurantIdHash() =>
    r'252c5d2d16f6f96434a6617fb274963906f0980a';

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Lot 4 (ADM-24) — toute erreur d'API passe par la garde de session :
/// compte révoqué ou session expirée ⇒ déconnexion, une seule fois.

@ProviderFor(networkObserver)
final networkObserverProvider = NetworkObserverProvider._();

/// Lot 4 (ADM-24) — toute erreur d'API passe par la garde de session :
/// compte révoqué ou session expirée ⇒ déconnexion, une seule fois.

final class NetworkObserverProvider
    extends
        $FunctionalProvider<NetworkObserver, NetworkObserver, NetworkObserver>
    with $Provider<NetworkObserver> {
  /// Lot 4 (ADM-24) — toute erreur d'API passe par la garde de session :
  /// compte révoqué ou session expirée ⇒ déconnexion, une seule fois.
  NetworkObserverProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'networkObserverProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$networkObserverHash();

  @$internal
  @override
  $ProviderElement<NetworkObserver> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NetworkObserver create(Ref ref) {
    return networkObserver(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NetworkObserver value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NetworkObserver>(value),
    );
  }
}

String _$networkObserverHash() => r'd9b4803a271603e296132907ac733f8b27eb81d4';

@ProviderFor(apiClient)
final apiClientProvider = ApiClientProvider._();

final class ApiClientProvider
    extends $FunctionalProvider<ApiClient, ApiClient, ApiClient>
    with $Provider<ApiClient> {
  ApiClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiClientHash();

  @$internal
  @override
  $ProviderElement<ApiClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ApiClient create(Ref ref) {
    return apiClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ApiClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ApiClient>(value),
    );
  }
}

String _$apiClientHash() => r'4ae7a13907308085d9684c6d049fadd8917d387f';

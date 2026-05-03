// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clients_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(clientRepository)
final clientRepositoryProvider = ClientRepositoryProvider._();

final class ClientRepositoryProvider
    extends
        $FunctionalProvider<
          ClientRepository,
          ClientRepository,
          ClientRepository
        >
    with $Provider<ClientRepository> {
  ClientRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clientRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clientRepositoryHash();

  @$internal
  @override
  $ProviderElement<ClientRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ClientRepository create(Ref ref) {
    return clientRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClientRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClientRepository>(value),
    );
  }
}

String _$clientRepositoryHash() => r'd0503e21d2fff20e3571277eee0eb21271ac7182';

@ProviderFor(restaurantClients)
final restaurantClientsProvider = RestaurantClientsFamily._();

final class RestaurantClientsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AppUser>>,
          List<AppUser>,
          FutureOr<List<AppUser>>
        >
    with $FutureModifier<List<AppUser>>, $FutureProvider<List<AppUser>> {
  RestaurantClientsProvider._({
    required RestaurantClientsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'restaurantClientsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$restaurantClientsHash();

  @override
  String toString() {
    return r'restaurantClientsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<AppUser>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AppUser>> create(Ref ref) {
    final argument = this.argument as String;
    return restaurantClients(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RestaurantClientsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$restaurantClientsHash() => r'd8f3f85c5996b48f9085c48ae87b98f492f602d9';

final class RestaurantClientsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<AppUser>>, String> {
  RestaurantClientsFamily._()
    : super(
        retry: null,
        name: r'restaurantClientsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RestaurantClientsProvider call(String restaurantId) =>
      RestaurantClientsProvider._(argument: restaurantId, from: this);

  @override
  String toString() => r'restaurantClientsProvider';
}

@ProviderFor(allClients)
final allClientsProvider = AllClientsProvider._();

final class AllClientsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AppUser>>,
          List<AppUser>,
          FutureOr<List<AppUser>>
        >
    with $FutureModifier<List<AppUser>>, $FutureProvider<List<AppUser>> {
  AllClientsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allClientsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allClientsHash();

  @$internal
  @override
  $FutureProviderElement<List<AppUser>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AppUser>> create(Ref ref) {
    return allClients(ref);
  }
}

String _$allClientsHash() => r'c5d7097e1d2e0c8c522888704ebcb670eddb96e9';

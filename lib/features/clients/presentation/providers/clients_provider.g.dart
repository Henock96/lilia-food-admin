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

/// Clients d'un restaurant (vue restaurateur).

@ProviderFor(restaurantClients)
final restaurantClientsProvider = RestaurantClientsFamily._();

/// Clients d'un restaurant (vue restaurateur).

final class RestaurantClientsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AppUser>>,
          List<AppUser>,
          FutureOr<List<AppUser>>
        >
    with $FutureModifier<List<AppUser>>, $FutureProvider<List<AppUser>> {
  /// Clients d'un restaurant (vue restaurateur).
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

String _$restaurantClientsHash() => r'76566292c5dc0db8a744ee1a902fa93eb945cb51';

/// Clients d'un restaurant (vue restaurateur).

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

  /// Clients d'un restaurant (vue restaurateur).

  RestaurantClientsProvider call(String restaurantId) =>
      RestaurantClientsProvider._(argument: restaurantId, from: this);

  @override
  String toString() => r'restaurantClientsProvider';
}

/// Tous les clients de la plateforme — paginés et filtrables (ADMIN).

@ProviderFor(allClients)
final allClientsProvider = AllClientsFamily._();

/// Tous les clients de la plateforme — paginés et filtrables (ADMIN).

final class AllClientsProvider
    extends
        $FunctionalProvider<
          AsyncValue<PaginatedClients>,
          PaginatedClients,
          FutureOr<PaginatedClients>
        >
    with $FutureModifier<PaginatedClients>, $FutureProvider<PaginatedClients> {
  /// Tous les clients de la plateforme — paginés et filtrables (ADMIN).
  AllClientsProvider._({
    required AllClientsFamily super.from,
    required ({int page, String search}) super.argument,
  }) : super(
         retry: null,
         name: r'allClientsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$allClientsHash();

  @override
  String toString() {
    return r'allClientsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<PaginatedClients> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PaginatedClients> create(Ref ref) {
    final argument = this.argument as ({int page, String search});
    return allClients(ref, page: argument.page, search: argument.search);
  }

  @override
  bool operator ==(Object other) {
    return other is AllClientsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$allClientsHash() => r'37ce7b6dee5d38fe1a5eef38764242dd0f054433';

/// Tous les clients de la plateforme — paginés et filtrables (ADMIN).

final class AllClientsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<PaginatedClients>,
          ({int page, String search})
        > {
  AllClientsFamily._()
    : super(
        retry: null,
        name: r'allClientsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Tous les clients de la plateforme — paginés et filtrables (ADMIN).

  AllClientsProvider call({required int page, required String search}) =>
      AllClientsProvider._(argument: (page: page, search: search), from: this);

  @override
  String toString() => r'allClientsProvider';
}

/// Fidélité d'un client (ADMIN).

@ProviderFor(clientLoyalty)
final clientLoyaltyProvider = ClientLoyaltyFamily._();

/// Fidélité d'un client (ADMIN).

final class ClientLoyaltyProvider
    extends
        $FunctionalProvider<
          AsyncValue<ClientLoyalty>,
          ClientLoyalty,
          FutureOr<ClientLoyalty>
        >
    with $FutureModifier<ClientLoyalty>, $FutureProvider<ClientLoyalty> {
  /// Fidélité d'un client (ADMIN).
  ClientLoyaltyProvider._({
    required ClientLoyaltyFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'clientLoyaltyProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$clientLoyaltyHash();

  @override
  String toString() {
    return r'clientLoyaltyProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ClientLoyalty> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ClientLoyalty> create(Ref ref) {
    final argument = this.argument as String;
    return clientLoyalty(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ClientLoyaltyProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$clientLoyaltyHash() => r'1ef472b3dd6e123a2ff3d00b803301e6d3722be0';

/// Fidélité d'un client (ADMIN).

final class ClientLoyaltyFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ClientLoyalty>, String> {
  ClientLoyaltyFamily._()
    : super(
        retry: null,
        name: r'clientLoyaltyProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fidélité d'un client (ADMIN).

  ClientLoyaltyProvider call(String clientId) =>
      ClientLoyaltyProvider._(argument: clientId, from: this);

  @override
  String toString() => r'clientLoyaltyProvider';
}

/// Parrainage d'un client (ADMIN).

@ProviderFor(clientReferral)
final clientReferralProvider = ClientReferralFamily._();

/// Parrainage d'un client (ADMIN).

final class ClientReferralProvider
    extends
        $FunctionalProvider<
          AsyncValue<ClientReferral>,
          ClientReferral,
          FutureOr<ClientReferral>
        >
    with $FutureModifier<ClientReferral>, $FutureProvider<ClientReferral> {
  /// Parrainage d'un client (ADMIN).
  ClientReferralProvider._({
    required ClientReferralFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'clientReferralProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$clientReferralHash();

  @override
  String toString() {
    return r'clientReferralProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ClientReferral> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ClientReferral> create(Ref ref) {
    final argument = this.argument as String;
    return clientReferral(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ClientReferralProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$clientReferralHash() => r'452d985da2b8b768a925bfc7086cebeb824cc647';

/// Parrainage d'un client (ADMIN).

final class ClientReferralFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ClientReferral>, String> {
  ClientReferralFamily._()
    : super(
        retry: null,
        name: r'clientReferralProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Parrainage d'un client (ADMIN).

  ClientReferralProvider call(String clientId) =>
      ClientReferralProvider._(argument: clientId, from: this);

  @override
  String toString() => r'clientReferralProvider';
}

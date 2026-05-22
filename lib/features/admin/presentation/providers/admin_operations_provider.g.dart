// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_operations_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(adminOperationsRepository)
final adminOperationsRepositoryProvider = AdminOperationsRepositoryProvider._();

final class AdminOperationsRepositoryProvider
    extends
        $FunctionalProvider<
          AdminOperationsRepository,
          AdminOperationsRepository,
          AdminOperationsRepository
        >
    with $Provider<AdminOperationsRepository> {
  AdminOperationsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminOperationsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminOperationsRepositoryHash();

  @$internal
  @override
  $ProviderElement<AdminOperationsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AdminOperationsRepository create(Ref ref) {
    return adminOperationsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdminOperationsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdminOperationsRepository>(value),
    );
  }
}

String _$adminOperationsRepositoryHash() =>
    r'5c58ae7be403969ed9c3b15bb6bf6d9a3c176c4a';

/// Paiements paginés, filtrés par statut (ADMIN).

@ProviderFor(adminPayments)
final adminPaymentsProvider = AdminPaymentsFamily._();

/// Paiements paginés, filtrés par statut (ADMIN).

final class AdminPaymentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<PaginatedPayments>,
          PaginatedPayments,
          FutureOr<PaginatedPayments>
        >
    with
        $FutureModifier<PaginatedPayments>,
        $FutureProvider<PaginatedPayments> {
  /// Paiements paginés, filtrés par statut (ADMIN).
  AdminPaymentsProvider._({
    required AdminPaymentsFamily super.from,
    required ({int page, String status}) super.argument,
  }) : super(
         retry: null,
         name: r'adminPaymentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$adminPaymentsHash();

  @override
  String toString() {
    return r'adminPaymentsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<PaginatedPayments> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PaginatedPayments> create(Ref ref) {
    final argument = this.argument as ({int page, String status});
    return adminPayments(ref, page: argument.page, status: argument.status);
  }

  @override
  bool operator ==(Object other) {
    return other is AdminPaymentsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$adminPaymentsHash() => r'd586ab74617563d6b5842fce22400ee17d7dffc9';

/// Paiements paginés, filtrés par statut (ADMIN).

final class AdminPaymentsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<PaginatedPayments>,
          ({int page, String status})
        > {
  AdminPaymentsFamily._()
    : super(
        retry: null,
        name: r'adminPaymentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Paiements paginés, filtrés par statut (ADMIN).

  AdminPaymentsProvider call({required int page, required String status}) =>
      AdminPaymentsProvider._(
        argument: (page: page, status: status),
        from: this,
      );

  @override
  String toString() => r'adminPaymentsProvider';
}

/// Livreurs paginés (ADMIN).

@ProviderFor(adminDeliverers)
final adminDeliverersProvider = AdminDeliverersFamily._();

/// Livreurs paginés (ADMIN).

final class AdminDeliverersProvider
    extends
        $FunctionalProvider<
          AsyncValue<PaginatedDeliverers>,
          PaginatedDeliverers,
          FutureOr<PaginatedDeliverers>
        >
    with
        $FutureModifier<PaginatedDeliverers>,
        $FutureProvider<PaginatedDeliverers> {
  /// Livreurs paginés (ADMIN).
  AdminDeliverersProvider._({
    required AdminDeliverersFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'adminDeliverersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$adminDeliverersHash();

  @override
  String toString() {
    return r'adminDeliverersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PaginatedDeliverers> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PaginatedDeliverers> create(Ref ref) {
    final argument = this.argument as int;
    return adminDeliverers(ref, page: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AdminDeliverersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$adminDeliverersHash() => r'075ef572f24527326e5b53f254cb607e1257200e';

/// Livreurs paginés (ADMIN).

final class AdminDeliverersFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PaginatedDeliverers>, int> {
  AdminDeliverersFamily._()
    : super(
        retry: null,
        name: r'adminDeliverersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Livreurs paginés (ADMIN).

  AdminDeliverersProvider call({required int page}) =>
      AdminDeliverersProvider._(argument: page, from: this);

  @override
  String toString() => r'adminDeliverersProvider';
}

/// Configuration plateforme (ADMIN).

@ProviderFor(platformSettings)
final platformSettingsProvider = PlatformSettingsProvider._();

/// Configuration plateforme (ADMIN).

final class PlatformSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<PlatformSettings>,
          PlatformSettings,
          FutureOr<PlatformSettings>
        >
    with $FutureModifier<PlatformSettings>, $FutureProvider<PlatformSettings> {
  /// Configuration plateforme (ADMIN).
  PlatformSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'platformSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$platformSettingsHash();

  @$internal
  @override
  $FutureProviderElement<PlatformSettings> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PlatformSettings> create(Ref ref) {
    return platformSettings(ref);
  }
}

String _$platformSettingsHash() => r'a77a1ce9d8afd9758f2800e58dd18a40e042b8eb';

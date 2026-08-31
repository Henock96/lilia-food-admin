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
    r'6bea5cac2925b43fba3fddff7e628475420ba791';

/// Paiements paginés (ADMIN). `status` vide → vue "Tous statuts confondus".

@ProviderFor(adminPayments)
final adminPaymentsProvider = AdminPaymentsFamily._();

/// Paiements paginés (ADMIN). `status` vide → vue "Tous statuts confondus".

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
  /// Paiements paginés (ADMIN). `status` vide → vue "Tous statuts confondus".
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

/// Paiements paginés (ADMIN). `status` vide → vue "Tous statuts confondus".

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

  /// Paiements paginés (ADMIN). `status` vide → vue "Tous statuts confondus".

  AdminPaymentsProvider call({required int page, required String status}) =>
      AdminPaymentsProvider._(
        argument: (page: page, status: status),
        from: this,
      );

  @override
  String toString() => r'adminPaymentsProvider';
}

/// KPI paiements (ADMIN) — pending à confirmer, encaissé ce mois, 7j roulants.

@ProviderFor(adminPaymentsStats)
final adminPaymentsStatsProvider = AdminPaymentsStatsProvider._();

/// KPI paiements (ADMIN) — pending à confirmer, encaissé ce mois, 7j roulants.

final class AdminPaymentsStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<PaymentsStats>,
          PaymentsStats,
          FutureOr<PaymentsStats>
        >
    with $FutureModifier<PaymentsStats>, $FutureProvider<PaymentsStats> {
  /// KPI paiements (ADMIN) — pending à confirmer, encaissé ce mois, 7j roulants.
  AdminPaymentsStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminPaymentsStatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminPaymentsStatsHash();

  @$internal
  @override
  $FutureProviderElement<PaymentsStats> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PaymentsStats> create(Ref ref) {
    return adminPaymentsStats(ref);
  }
}

String _$adminPaymentsStatsHash() =>
    r'5e59aaa86b23e90bdaf646976216f931b7a3922f';

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

/// Récapitulatif financier d'une commande (ADMIN) : encaissement client,
/// reversement vendeur, marge Lilia Food — et l'éligibilité au paiement du
/// restaurant, **décidée par le serveur**.
///
/// `autoDispose` implicite (`@riverpod`) : la fiche n'est chargée que tant
/// qu'un écran l'affiche. Après un reversement, l'appelant invalide ce provider
/// pour relire l'état réel plutôt que de le supposer.

@ProviderFor(orderFinancials)
final orderFinancialsProvider = OrderFinancialsFamily._();

/// Récapitulatif financier d'une commande (ADMIN) : encaissement client,
/// reversement vendeur, marge Lilia Food — et l'éligibilité au paiement du
/// restaurant, **décidée par le serveur**.
///
/// `autoDispose` implicite (`@riverpod`) : la fiche n'est chargée que tant
/// qu'un écran l'affiche. Après un reversement, l'appelant invalide ce provider
/// pour relire l'état réel plutôt que de le supposer.

final class OrderFinancialsProvider
    extends
        $FunctionalProvider<
          AsyncValue<OrderFinancials>,
          OrderFinancials,
          FutureOr<OrderFinancials>
        >
    with $FutureModifier<OrderFinancials>, $FutureProvider<OrderFinancials> {
  /// Récapitulatif financier d'une commande (ADMIN) : encaissement client,
  /// reversement vendeur, marge Lilia Food — et l'éligibilité au paiement du
  /// restaurant, **décidée par le serveur**.
  ///
  /// `autoDispose` implicite (`@riverpod`) : la fiche n'est chargée que tant
  /// qu'un écran l'affiche. Après un reversement, l'appelant invalide ce provider
  /// pour relire l'état réel plutôt que de le supposer.
  OrderFinancialsProvider._({
    required OrderFinancialsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'orderFinancialsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$orderFinancialsHash();

  @override
  String toString() {
    return r'orderFinancialsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<OrderFinancials> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<OrderFinancials> create(Ref ref) {
    final argument = this.argument as String;
    return orderFinancials(ref, orderId: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OrderFinancialsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$orderFinancialsHash() => r'7caeaf27a67b595540533053548c022862d5529f';

/// Récapitulatif financier d'une commande (ADMIN) : encaissement client,
/// reversement vendeur, marge Lilia Food — et l'éligibilité au paiement du
/// restaurant, **décidée par le serveur**.
///
/// `autoDispose` implicite (`@riverpod`) : la fiche n'est chargée que tant
/// qu'un écran l'affiche. Après un reversement, l'appelant invalide ce provider
/// pour relire l'état réel plutôt que de le supposer.

final class OrderFinancialsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<OrderFinancials>, String> {
  OrderFinancialsFamily._()
    : super(
        retry: null,
        name: r'orderFinancialsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Récapitulatif financier d'une commande (ADMIN) : encaissement client,
  /// reversement vendeur, marge Lilia Food — et l'éligibilité au paiement du
  /// restaurant, **décidée par le serveur**.
  ///
  /// `autoDispose` implicite (`@riverpod`) : la fiche n'est chargée que tant
  /// qu'un écran l'affiche. Après un reversement, l'appelant invalide ce provider
  /// pour relire l'état réel plutôt que de le supposer.

  OrderFinancialsProvider call({required String orderId}) =>
      OrderFinancialsProvider._(argument: orderId, from: this);

  @override
  String toString() => r'orderFinancialsProvider';
}

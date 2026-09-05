// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refunds_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(refundsService)
final refundsServiceProvider = RefundsServiceProvider._();

final class RefundsServiceProvider
    extends $FunctionalProvider<RefundsService, RefundsService, RefundsService>
    with $Provider<RefundsService> {
  RefundsServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'refundsServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$refundsServiceHash();

  @$internal
  @override
  $ProviderElement<RefundsService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RefundsService create(Ref ref) {
    return refundsService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RefundsService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RefundsService>(value),
    );
  }
}

String _$refundsServiceHash() => r'42ca45751b8ea4e48808b8bdd41709f43ebf6dc4';

/// Première page, filtrée par statut. `null` = tous.

@ProviderFor(refundsList)
final refundsListProvider = RefundsListFamily._();

/// Première page, filtrée par statut. `null` = tous.

final class RefundsListProvider
    extends
        $FunctionalProvider<
          AsyncValue<RefundPage>,
          RefundPage,
          FutureOr<RefundPage>
        >
    with $FutureModifier<RefundPage>, $FutureProvider<RefundPage> {
  /// Première page, filtrée par statut. `null` = tous.
  RefundsListProvider._({
    required RefundsListFamily super.from,
    required RefundStatus? super.argument,
  }) : super(
         retry: null,
         name: r'refundsListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$refundsListHash();

  @override
  String toString() {
    return r'refundsListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<RefundPage> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<RefundPage> create(Ref ref) {
    final argument = this.argument as RefundStatus?;
    return refundsList(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RefundsListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$refundsListHash() => r'ddd7f06017e469386b188055ad2956f0f5169901';

/// Première page, filtrée par statut. `null` = tous.

final class RefundsListFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<RefundPage>, RefundStatus?> {
  RefundsListFamily._()
    : super(
        retry: null,
        name: r'refundsListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Première page, filtrée par statut. `null` = tous.

  RefundsListProvider call(RefundStatus? status) =>
      RefundsListProvider._(argument: status, from: this);

  @override
  String toString() => r'refundsListProvider';
}

/// Compteur des remboursements à traiter — alimente le badge de navigation.
///
/// Séparé de la liste : le badge doit pouvoir se rafraîchir sans recharger
/// l'écran, et rester disponible depuis n'importe quel onglet.

@ProviderFor(pendingRefundsCount)
final pendingRefundsCountProvider = PendingRefundsCountProvider._();

/// Compteur des remboursements à traiter — alimente le badge de navigation.
///
/// Séparé de la liste : le badge doit pouvoir se rafraîchir sans recharger
/// l'écran, et rester disponible depuis n'importe quel onglet.

final class PendingRefundsCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Compteur des remboursements à traiter — alimente le badge de navigation.
  ///
  /// Séparé de la liste : le badge doit pouvoir se rafraîchir sans recharger
  /// l'écran, et rester disponible depuis n'importe quel onglet.
  PendingRefundsCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingRefundsCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingRefundsCountHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return pendingRefundsCount(ref);
  }
}

String _$pendingRefundsCountHash() =>
    r'04526daceb2c705ba78d39d72ab68fe2707c8d17';

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deliverer_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fiche détaillée d'un livreur (user + stats + mission en cours).
///
/// Composé côté repository à partir de 3 appels HTTP — voir
/// [AdminOperationsRepository.getDelivererDetail].

@ProviderFor(delivererDetail)
final delivererDetailProvider = DelivererDetailFamily._();

/// Fiche détaillée d'un livreur (user + stats + mission en cours).
///
/// Composé côté repository à partir de 3 appels HTTP — voir
/// [AdminOperationsRepository.getDelivererDetail].

final class DelivererDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<DelivererDetail>,
          DelivererDetail,
          FutureOr<DelivererDetail>
        >
    with $FutureModifier<DelivererDetail>, $FutureProvider<DelivererDetail> {
  /// Fiche détaillée d'un livreur (user + stats + mission en cours).
  ///
  /// Composé côté repository à partir de 3 appels HTTP — voir
  /// [AdminOperationsRepository.getDelivererDetail].
  DelivererDetailProvider._({
    required DelivererDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'delivererDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$delivererDetailHash();

  @override
  String toString() {
    return r'delivererDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<DelivererDetail> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DelivererDetail> create(Ref ref) {
    final argument = this.argument as String;
    return delivererDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DelivererDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$delivererDetailHash() => r'9e8e57a460130e807da06f9822f61880677528b4';

/// Fiche détaillée d'un livreur (user + stats + mission en cours).
///
/// Composé côté repository à partir de 3 appels HTTP — voir
/// [AdminOperationsRepository.getDelivererDetail].

final class DelivererDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<DelivererDetail>, String> {
  DelivererDetailFamily._()
    : super(
        retry: null,
        name: r'delivererDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fiche détaillée d'un livreur (user + stats + mission en cours).
  ///
  /// Composé côté repository à partir de 3 appels HTTP — voir
  /// [AdminOperationsRepository.getDelivererDetail].

  DelivererDetailProvider call(String id) =>
      DelivererDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'delivererDetailProvider';
}

/// Stats seules d'un livreur — utile si l'écran veut rafraîchir les stats
/// sans recharger toute la fiche.

@ProviderFor(delivererStats)
final delivererStatsProvider = DelivererStatsFamily._();

/// Stats seules d'un livreur — utile si l'écran veut rafraîchir les stats
/// sans recharger toute la fiche.

final class DelivererStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<DelivererStats>,
          DelivererStats,
          FutureOr<DelivererStats>
        >
    with $FutureModifier<DelivererStats>, $FutureProvider<DelivererStats> {
  /// Stats seules d'un livreur — utile si l'écran veut rafraîchir les stats
  /// sans recharger toute la fiche.
  DelivererStatsProvider._({
    required DelivererStatsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'delivererStatsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$delivererStatsHash();

  @override
  String toString() {
    return r'delivererStatsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<DelivererStats> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DelivererStats> create(Ref ref) {
    final argument = this.argument as String;
    return delivererStats(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DelivererStatsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$delivererStatsHash() => r'2a063509d69fea5a7e68a3e249f3ee4c0434eac8';

/// Stats seules d'un livreur — utile si l'écran veut rafraîchir les stats
/// sans recharger toute la fiche.

final class DelivererStatsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<DelivererStats>, String> {
  DelivererStatsFamily._()
    : super(
        retry: null,
        name: r'delivererStatsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Stats seules d'un livreur — utile si l'écran veut rafraîchir les stats
  /// sans recharger toute la fiche.

  DelivererStatsProvider call(String id) =>
      DelivererStatsProvider._(argument: id, from: this);

  @override
  String toString() => r'delivererStatsProvider';
}

/// Livraison associée à une commande — point d'entrée pour
/// [DeliveryTrackingScreen] (LIL-86) qui a besoin de l'adresse client +
/// info livreur avant d'ouvrir le stream WebSocket.

@ProviderFor(deliveryByOrder)
final deliveryByOrderProvider = DeliveryByOrderFamily._();

/// Livraison associée à une commande — point d'entrée pour
/// [DeliveryTrackingScreen] (LIL-86) qui a besoin de l'adresse client +
/// info livreur avant d'ouvrir le stream WebSocket.

final class DeliveryByOrderProvider
    extends
        $FunctionalProvider<AsyncValue<Delivery>, Delivery, FutureOr<Delivery>>
    with $FutureModifier<Delivery>, $FutureProvider<Delivery> {
  /// Livraison associée à une commande — point d'entrée pour
  /// [DeliveryTrackingScreen] (LIL-86) qui a besoin de l'adresse client +
  /// info livreur avant d'ouvrir le stream WebSocket.
  DeliveryByOrderProvider._({
    required DeliveryByOrderFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'deliveryByOrderProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$deliveryByOrderHash();

  @override
  String toString() {
    return r'deliveryByOrderProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Delivery> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Delivery> create(Ref ref) {
    final argument = this.argument as String;
    return deliveryByOrder(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DeliveryByOrderProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$deliveryByOrderHash() => r'7d1ce6db9e774aee849231eef9475a3ffd15eabe';

/// Livraison associée à une commande — point d'entrée pour
/// [DeliveryTrackingScreen] (LIL-86) qui a besoin de l'adresse client +
/// info livreur avant d'ouvrir le stream WebSocket.

final class DeliveryByOrderFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Delivery>, String> {
  DeliveryByOrderFamily._()
    : super(
        retry: null,
        name: r'deliveryByOrderProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Livraison associée à une commande — point d'entrée pour
  /// [DeliveryTrackingScreen] (LIL-86) qui a besoin de l'adresse client +
  /// info livreur avant d'ouvrir le stream WebSocket.

  DeliveryByOrderProvider call(String orderId) =>
      DeliveryByOrderProvider._(argument: orderId, from: this);

  @override
  String toString() => r'deliveryByOrderProvider';
}

/// Contrôleur paginé des missions d'un livreur.
///
/// API publique :
/// - `loadMore()` — appelle la page suivante et accumule dans `state.items`.
/// - `setStatusFilter(status)` — réinitialise et refetch avec le nouveau filtre.
/// - `refresh()` — repart de la page 1 en gardant le filtre courant.

@ProviderFor(DelivererMissionsController)
final delivererMissionsControllerProvider =
    DelivererMissionsControllerFamily._();

/// Contrôleur paginé des missions d'un livreur.
///
/// API publique :
/// - `loadMore()` — appelle la page suivante et accumule dans `state.items`.
/// - `setStatusFilter(status)` — réinitialise et refetch avec le nouveau filtre.
/// - `refresh()` — repart de la page 1 en gardant le filtre courant.
final class DelivererMissionsControllerProvider
    extends
        $AsyncNotifierProvider<
          DelivererMissionsController,
          DelivererMissionsState
        > {
  /// Contrôleur paginé des missions d'un livreur.
  ///
  /// API publique :
  /// - `loadMore()` — appelle la page suivante et accumule dans `state.items`.
  /// - `setStatusFilter(status)` — réinitialise et refetch avec le nouveau filtre.
  /// - `refresh()` — repart de la page 1 en gardant le filtre courant.
  DelivererMissionsControllerProvider._({
    required DelivererMissionsControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'delivererMissionsControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$delivererMissionsControllerHash();

  @override
  String toString() {
    return r'delivererMissionsControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DelivererMissionsController create() => DelivererMissionsController();

  @override
  bool operator ==(Object other) {
    return other is DelivererMissionsControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$delivererMissionsControllerHash() =>
    r'55f616c8317568bc1a45cbf6b2c24dd69c69d691';

/// Contrôleur paginé des missions d'un livreur.
///
/// API publique :
/// - `loadMore()` — appelle la page suivante et accumule dans `state.items`.
/// - `setStatusFilter(status)` — réinitialise et refetch avec le nouveau filtre.
/// - `refresh()` — repart de la page 1 en gardant le filtre courant.

final class DelivererMissionsControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          DelivererMissionsController,
          AsyncValue<DelivererMissionsState>,
          DelivererMissionsState,
          FutureOr<DelivererMissionsState>,
          String
        > {
  DelivererMissionsControllerFamily._()
    : super(
        retry: null,
        name: r'delivererMissionsControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Contrôleur paginé des missions d'un livreur.
  ///
  /// API publique :
  /// - `loadMore()` — appelle la page suivante et accumule dans `state.items`.
  /// - `setStatusFilter(status)` — réinitialise et refetch avec le nouveau filtre.
  /// - `refresh()` — repart de la page 1 en gardant le filtre courant.

  DelivererMissionsControllerProvider call(String delivererId) =>
      DelivererMissionsControllerProvider._(argument: delivererId, from: this);

  @override
  String toString() => r'delivererMissionsControllerProvider';
}

/// Contrôleur paginé des missions d'un livreur.
///
/// API publique :
/// - `loadMore()` — appelle la page suivante et accumule dans `state.items`.
/// - `setStatusFilter(status)` — réinitialise et refetch avec le nouveau filtre.
/// - `refresh()` — repart de la page 1 en gardant le filtre courant.

abstract class _$DelivererMissionsController
    extends $AsyncNotifier<DelivererMissionsState> {
  late final _$args = ref.$arg as String;
  String get delivererId => _$args;

  FutureOr<DelivererMissionsState> build(String delivererId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<DelivererMissionsState>, DelivererMissionsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<DelivererMissionsState>,
                DelivererMissionsState
              >,
              AsyncValue<DelivererMissionsState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

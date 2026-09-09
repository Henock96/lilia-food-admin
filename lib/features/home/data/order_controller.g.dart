// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(orderServiceRepository)
final orderServiceRepositoryProvider = OrderServiceRepositoryProvider._();

final class OrderServiceRepositoryProvider
    extends $FunctionalProvider<OrderService, OrderService, OrderService>
    with $Provider<OrderService> {
  OrderServiceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'orderServiceRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$orderServiceRepositoryHash();

  @$internal
  @override
  $ProviderElement<OrderService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OrderService create(Ref ref) {
    return orderServiceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OrderService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OrderService>(value),
    );
  }
}

String _$orderServiceRepositoryHash() =>
    r'a6deabd3562a64c9ebf57900cce5d3aa40671b25';

/// Commandes du back-office, **paginées par le serveur**, une instance par
/// onglet de statut (`null` = « Toutes »).
///
/// ## Pourquoi une famille par statut
///
/// L'écran chargeait une seule liste — les vingt dernières commandes de toute
/// la plateforme, faute de pagination transmise — et les sept onglets la
/// filtraient en mémoire. Deux conséquences : une commande plus ancienne était
/// inatteignable, et les compteurs d'onglets comptaient dans ces vingt lignes.
///
/// Le filtre appartient donc à la requête, et chaque onglet a la sienne. Les
/// compteurs, eux, viennent de `meta.statusCounts` et portent sur le périmètre
/// entier : ils sont identiques quel que soit l'onglet chargé.
///
/// `search` fait partie de la clé de famille, et du périmètre : chercher
/// « Marie » doit dire combien de commandes de Marie sont dans chaque statut.
/// L'écran envoie un terme **débouncé** — une instance par frappe serait créée
/// et jetée aussitôt.

@ProviderFor(RestaurantOrders)
final restaurantOrdersProvider = RestaurantOrdersFamily._();

/// Commandes du back-office, **paginées par le serveur**, une instance par
/// onglet de statut (`null` = « Toutes »).
///
/// ## Pourquoi une famille par statut
///
/// L'écran chargeait une seule liste — les vingt dernières commandes de toute
/// la plateforme, faute de pagination transmise — et les sept onglets la
/// filtraient en mémoire. Deux conséquences : une commande plus ancienne était
/// inatteignable, et les compteurs d'onglets comptaient dans ces vingt lignes.
///
/// Le filtre appartient donc à la requête, et chaque onglet a la sienne. Les
/// compteurs, eux, viennent de `meta.statusCounts` et portent sur le périmètre
/// entier : ils sont identiques quel que soit l'onglet chargé.
///
/// `search` fait partie de la clé de famille, et du périmètre : chercher
/// « Marie » doit dire combien de commandes de Marie sont dans chaque statut.
/// L'écran envoie un terme **débouncé** — une instance par frappe serait créée
/// et jetée aussitôt.
final class RestaurantOrdersProvider
    extends $AsyncNotifierProvider<RestaurantOrders, OrderPage> {
  /// Commandes du back-office, **paginées par le serveur**, une instance par
  /// onglet de statut (`null` = « Toutes »).
  ///
  /// ## Pourquoi une famille par statut
  ///
  /// L'écran chargeait une seule liste — les vingt dernières commandes de toute
  /// la plateforme, faute de pagination transmise — et les sept onglets la
  /// filtraient en mémoire. Deux conséquences : une commande plus ancienne était
  /// inatteignable, et les compteurs d'onglets comptaient dans ces vingt lignes.
  ///
  /// Le filtre appartient donc à la requête, et chaque onglet a la sienne. Les
  /// compteurs, eux, viennent de `meta.statusCounts` et portent sur le périmètre
  /// entier : ils sont identiques quel que soit l'onglet chargé.
  ///
  /// `search` fait partie de la clé de famille, et du périmètre : chercher
  /// « Marie » doit dire combien de commandes de Marie sont dans chaque statut.
  /// L'écran envoie un terme **débouncé** — une instance par frappe serait créée
  /// et jetée aussitôt.
  RestaurantOrdersProvider._({
    required RestaurantOrdersFamily super.from,
    required (OrderStatus?, String) super.argument,
  }) : super(
         retry: null,
         name: r'restaurantOrdersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$restaurantOrdersHash();

  @override
  String toString() {
    return r'restaurantOrdersProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  RestaurantOrders create() => RestaurantOrders();

  @override
  bool operator ==(Object other) {
    return other is RestaurantOrdersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$restaurantOrdersHash() => r'a75c1f693420f19d381a5942ddaa3bb97f00391e';

/// Commandes du back-office, **paginées par le serveur**, une instance par
/// onglet de statut (`null` = « Toutes »).
///
/// ## Pourquoi une famille par statut
///
/// L'écran chargeait une seule liste — les vingt dernières commandes de toute
/// la plateforme, faute de pagination transmise — et les sept onglets la
/// filtraient en mémoire. Deux conséquences : une commande plus ancienne était
/// inatteignable, et les compteurs d'onglets comptaient dans ces vingt lignes.
///
/// Le filtre appartient donc à la requête, et chaque onglet a la sienne. Les
/// compteurs, eux, viennent de `meta.statusCounts` et portent sur le périmètre
/// entier : ils sont identiques quel que soit l'onglet chargé.
///
/// `search` fait partie de la clé de famille, et du périmètre : chercher
/// « Marie » doit dire combien de commandes de Marie sont dans chaque statut.
/// L'écran envoie un terme **débouncé** — une instance par frappe serait créée
/// et jetée aussitôt.

final class RestaurantOrdersFamily extends $Family
    with
        $ClassFamilyOverride<
          RestaurantOrders,
          AsyncValue<OrderPage>,
          OrderPage,
          FutureOr<OrderPage>,
          (OrderStatus?, String)
        > {
  RestaurantOrdersFamily._()
    : super(
        retry: null,
        name: r'restaurantOrdersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Commandes du back-office, **paginées par le serveur**, une instance par
  /// onglet de statut (`null` = « Toutes »).
  ///
  /// ## Pourquoi une famille par statut
  ///
  /// L'écran chargeait une seule liste — les vingt dernières commandes de toute
  /// la plateforme, faute de pagination transmise — et les sept onglets la
  /// filtraient en mémoire. Deux conséquences : une commande plus ancienne était
  /// inatteignable, et les compteurs d'onglets comptaient dans ces vingt lignes.
  ///
  /// Le filtre appartient donc à la requête, et chaque onglet a la sienne. Les
  /// compteurs, eux, viennent de `meta.statusCounts` et portent sur le périmètre
  /// entier : ils sont identiques quel que soit l'onglet chargé.
  ///
  /// `search` fait partie de la clé de famille, et du périmètre : chercher
  /// « Marie » doit dire combien de commandes de Marie sont dans chaque statut.
  /// L'écran envoie un terme **débouncé** — une instance par frappe serait créée
  /// et jetée aussitôt.

  RestaurantOrdersProvider call(OrderStatus? status, String search) =>
      RestaurantOrdersProvider._(argument: (status, search), from: this);

  @override
  String toString() => r'restaurantOrdersProvider';
}

/// Commandes du back-office, **paginées par le serveur**, une instance par
/// onglet de statut (`null` = « Toutes »).
///
/// ## Pourquoi une famille par statut
///
/// L'écran chargeait une seule liste — les vingt dernières commandes de toute
/// la plateforme, faute de pagination transmise — et les sept onglets la
/// filtraient en mémoire. Deux conséquences : une commande plus ancienne était
/// inatteignable, et les compteurs d'onglets comptaient dans ces vingt lignes.
///
/// Le filtre appartient donc à la requête, et chaque onglet a la sienne. Les
/// compteurs, eux, viennent de `meta.statusCounts` et portent sur le périmètre
/// entier : ils sont identiques quel que soit l'onglet chargé.
///
/// `search` fait partie de la clé de famille, et du périmètre : chercher
/// « Marie » doit dire combien de commandes de Marie sont dans chaque statut.
/// L'écran envoie un terme **débouncé** — une instance par frappe serait créée
/// et jetée aussitôt.

abstract class _$RestaurantOrders extends $AsyncNotifier<OrderPage> {
  late final _$args = ref.$arg as (OrderStatus?, String);
  OrderStatus? get status => _$args.$1;
  String get search => _$args.$2;

  FutureOr<OrderPage> build(OrderStatus? status, String search);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<OrderPage>, OrderPage>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<OrderPage>, OrderPage>,
              AsyncValue<OrderPage>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}

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

@ProviderFor(RestaurantOrders)
final restaurantOrdersProvider = RestaurantOrdersProvider._();

final class RestaurantOrdersProvider
    extends $AsyncNotifierProvider<RestaurantOrders, List<Order>> {
  RestaurantOrdersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'restaurantOrdersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$restaurantOrdersHash();

  @$internal
  @override
  RestaurantOrders create() => RestaurantOrders();
}

String _$restaurantOrdersHash() => r'ee1142778995f5d5ffba1769a9eb1fef66123a5c';

abstract class _$RestaurantOrders extends $AsyncNotifier<List<Order>> {
  FutureOr<List<Order>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Order>>, List<Order>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Order>>, List<Order>>,
              AsyncValue<List<Order>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

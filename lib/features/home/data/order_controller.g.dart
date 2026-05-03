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
    r'9aa390137ae3c42bec5ccf5dbbea95bca28144de';

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

String _$restaurantOrdersHash() => r'74b342ccacf20d1b0ab0515e887e3ddc1541ec4f';

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

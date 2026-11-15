// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// État de la livraison d'une commande, rafraîchi à l'ouverture de l'écran.

@ProviderFor(orderDeliveryState)
final orderDeliveryStateProvider = OrderDeliveryStateFamily._();

/// État de la livraison d'une commande, rafraîchi à l'ouverture de l'écran.

final class OrderDeliveryStateProvider
    extends
        $FunctionalProvider<
          AsyncValue<OrderDeliveryState?>,
          OrderDeliveryState?,
          FutureOr<OrderDeliveryState?>
        >
    with
        $FutureModifier<OrderDeliveryState?>,
        $FutureProvider<OrderDeliveryState?> {
  /// État de la livraison d'une commande, rafraîchi à l'ouverture de l'écran.
  OrderDeliveryStateProvider._({
    required OrderDeliveryStateFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'orderDeliveryStateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$orderDeliveryStateHash();

  @override
  String toString() {
    return r'orderDeliveryStateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<OrderDeliveryState?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<OrderDeliveryState?> create(Ref ref) {
    final argument = this.argument as String;
    return orderDeliveryState(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OrderDeliveryStateProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$orderDeliveryStateHash() =>
    r'0ffc546d4ffa7d7fd4853194cc61c69ca2dc38d3';

/// État de la livraison d'une commande, rafraîchi à l'ouverture de l'écran.

final class OrderDeliveryStateFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<OrderDeliveryState?>, String> {
  OrderDeliveryStateFamily._()
    : super(
        retry: null,
        name: r'orderDeliveryStateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// État de la livraison d'une commande, rafraîchi à l'ouverture de l'écran.

  OrderDeliveryStateProvider call(String orderId) =>
      OrderDeliveryStateProvider._(argument: orderId, from: this);

  @override
  String toString() => r'orderDeliveryStateProvider';
}

@ProviderFor(orderDispatchView)
final orderDispatchViewProvider = OrderDispatchViewFamily._();

final class OrderDispatchViewProvider
    extends
        $FunctionalProvider<
          AsyncValue<OrderDispatchView?>,
          OrderDispatchView?,
          FutureOr<OrderDispatchView?>
        >
    with
        $FutureModifier<OrderDispatchView?>,
        $FutureProvider<OrderDispatchView?> {
  OrderDispatchViewProvider._({
    required OrderDispatchViewFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'orderDispatchViewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$orderDispatchViewHash();

  @override
  String toString() {
    return r'orderDispatchViewProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<OrderDispatchView?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<OrderDispatchView?> create(Ref ref) {
    final argument = this.argument as String;
    return orderDispatchView(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OrderDispatchViewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$orderDispatchViewHash() => r'26f3454fc33c8ba4a4f2686273642cd4f3a648a2';

final class OrderDispatchViewFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<OrderDispatchView?>, String> {
  OrderDispatchViewFamily._()
    : super(
        retry: null,
        name: r'orderDispatchViewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  OrderDispatchViewProvider call(String orderId) =>
      OrderDispatchViewProvider._(argument: orderId, from: this);

  @override
  String toString() => r'orderDispatchViewProvider';
}

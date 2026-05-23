// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tracking_socket_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Singleton du [TrackingSocketService] pour toute la session admin.
///
/// `keepAlive: true` : on garde **une seule** socket pour toute la durée de
/// vie de l'app — la connexion est coûteuse à établir et le backend déduit du
/// token Firebase quels rooms l'utilisateur peut watcher.
///
/// La socket est créée à la première demande (lazy) puis réutilisée. Au
/// dispose du provider (jamais en pratique sauf logout / hot restart), on
/// libère proprement la socket.

@ProviderFor(trackingSocketService)
final trackingSocketServiceProvider = TrackingSocketServiceProvider._();

/// Singleton du [TrackingSocketService] pour toute la session admin.
///
/// `keepAlive: true` : on garde **une seule** socket pour toute la durée de
/// vie de l'app — la connexion est coûteuse à établir et le backend déduit du
/// token Firebase quels rooms l'utilisateur peut watcher.
///
/// La socket est créée à la première demande (lazy) puis réutilisée. Au
/// dispose du provider (jamais en pratique sauf logout / hot restart), on
/// libère proprement la socket.

final class TrackingSocketServiceProvider
    extends
        $FunctionalProvider<
          TrackingSocketService,
          TrackingSocketService,
          TrackingSocketService
        >
    with $Provider<TrackingSocketService> {
  /// Singleton du [TrackingSocketService] pour toute la session admin.
  ///
  /// `keepAlive: true` : on garde **une seule** socket pour toute la durée de
  /// vie de l'app — la connexion est coûteuse à établir et le backend déduit du
  /// token Firebase quels rooms l'utilisateur peut watcher.
  ///
  /// La socket est créée à la première demande (lazy) puis réutilisée. Au
  /// dispose du provider (jamais en pratique sauf logout / hot restart), on
  /// libère proprement la socket.
  TrackingSocketServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trackingSocketServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trackingSocketServiceHash();

  @$internal
  @override
  $ProviderElement<TrackingSocketService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TrackingSocketService create(Ref ref) {
    return trackingSocketService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TrackingSocketService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TrackingSocketService>(value),
    );
  }
}

String _$trackingSocketServiceHash() =>
    r'6b27d125f54dd1bcf65519d95f28f5033d0dc135';

/// Stream des positions GPS du livreur pour une commande donnée.
///
/// `autoDispose` (par défaut) : dès que plus aucun widget n'écoute le
/// provider, on émet `order:unwatch` côté backend pour libérer la room.
/// La socket sous-jacente reste vivante (keepAlive sur le service).

@ProviderFor(orderTrackingStream)
final orderTrackingStreamProvider = OrderTrackingStreamFamily._();

/// Stream des positions GPS du livreur pour une commande donnée.
///
/// `autoDispose` (par défaut) : dès que plus aucun widget n'écoute le
/// provider, on émet `order:unwatch` côté backend pour libérer la room.
/// La socket sous-jacente reste vivante (keepAlive sur le service).

final class OrderTrackingStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<DriverPositionEvent>,
          DriverPositionEvent,
          Stream<DriverPositionEvent>
        >
    with
        $FutureModifier<DriverPositionEvent>,
        $StreamProvider<DriverPositionEvent> {
  /// Stream des positions GPS du livreur pour une commande donnée.
  ///
  /// `autoDispose` (par défaut) : dès que plus aucun widget n'écoute le
  /// provider, on émet `order:unwatch` côté backend pour libérer la room.
  /// La socket sous-jacente reste vivante (keepAlive sur le service).
  OrderTrackingStreamProvider._({
    required OrderTrackingStreamFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'orderTrackingStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$orderTrackingStreamHash();

  @override
  String toString() {
    return r'orderTrackingStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<DriverPositionEvent> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<DriverPositionEvent> create(Ref ref) {
    final argument = this.argument as String;
    return orderTrackingStream(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OrderTrackingStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$orderTrackingStreamHash() =>
    r'78d57358863adfdbba06fe80d8ac82f847ea855d';

/// Stream des positions GPS du livreur pour une commande donnée.
///
/// `autoDispose` (par défaut) : dès que plus aucun widget n'écoute le
/// provider, on émet `order:unwatch` côté backend pour libérer la room.
/// La socket sous-jacente reste vivante (keepAlive sur le service).

final class OrderTrackingStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<DriverPositionEvent>, String> {
  OrderTrackingStreamFamily._()
    : super(
        retry: null,
        name: r'orderTrackingStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Stream des positions GPS du livreur pour une commande donnée.
  ///
  /// `autoDispose` (par défaut) : dès que plus aucun widget n'écoute le
  /// provider, on émet `order:unwatch` côté backend pour libérer la room.
  /// La socket sous-jacente reste vivante (keepAlive sur le service).

  OrderTrackingStreamProvider call(String orderId) =>
      OrderTrackingStreamProvider._(argument: orderId, from: this);

  @override
  String toString() => r'orderTrackingStreamProvider';
}

/// Stream des changements de statut backend pour une commande donnée.
///
/// `autoDispose` : libère la room côté backend dès qu'il n'y a plus de
/// listener. ATTENTION : si la même UI écoute aussi `orderTrackingStream`
/// pour le même `orderId`, c'est le premier `unwatchOrder` exécuté qui ferme
/// la room (le service mutualise le watch). En pratique on watch les deux
/// streams ensemble dans le TrackingScreen (LIL-86) donc le risque de fermer
/// trop tôt est nul.

@ProviderFor(orderStatusStream)
final orderStatusStreamProvider = OrderStatusStreamFamily._();

/// Stream des changements de statut backend pour une commande donnée.
///
/// `autoDispose` : libère la room côté backend dès qu'il n'y a plus de
/// listener. ATTENTION : si la même UI écoute aussi `orderTrackingStream`
/// pour le même `orderId`, c'est le premier `unwatchOrder` exécuté qui ferme
/// la room (le service mutualise le watch). En pratique on watch les deux
/// streams ensemble dans le TrackingScreen (LIL-86) donc le risque de fermer
/// trop tôt est nul.

final class OrderStatusStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<OrderStatusEvent>,
          OrderStatusEvent,
          Stream<OrderStatusEvent>
        >
    with $FutureModifier<OrderStatusEvent>, $StreamProvider<OrderStatusEvent> {
  /// Stream des changements de statut backend pour une commande donnée.
  ///
  /// `autoDispose` : libère la room côté backend dès qu'il n'y a plus de
  /// listener. ATTENTION : si la même UI écoute aussi `orderTrackingStream`
  /// pour le même `orderId`, c'est le premier `unwatchOrder` exécuté qui ferme
  /// la room (le service mutualise le watch). En pratique on watch les deux
  /// streams ensemble dans le TrackingScreen (LIL-86) donc le risque de fermer
  /// trop tôt est nul.
  OrderStatusStreamProvider._({
    required OrderStatusStreamFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'orderStatusStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$orderStatusStreamHash();

  @override
  String toString() {
    return r'orderStatusStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<OrderStatusEvent> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<OrderStatusEvent> create(Ref ref) {
    final argument = this.argument as String;
    return orderStatusStream(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OrderStatusStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$orderStatusStreamHash() => r'5e8414820d1b065d98a9fb3f9852a5e6a166cf1a';

/// Stream des changements de statut backend pour une commande donnée.
///
/// `autoDispose` : libère la room côté backend dès qu'il n'y a plus de
/// listener. ATTENTION : si la même UI écoute aussi `orderTrackingStream`
/// pour le même `orderId`, c'est le premier `unwatchOrder` exécuté qui ferme
/// la room (le service mutualise le watch). En pratique on watch les deux
/// streams ensemble dans le TrackingScreen (LIL-86) donc le risque de fermer
/// trop tôt est nul.

final class OrderStatusStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<OrderStatusEvent>, String> {
  OrderStatusStreamFamily._()
    : super(
        retry: null,
        name: r'orderStatusStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Stream des changements de statut backend pour une commande donnée.
  ///
  /// `autoDispose` : libère la room côté backend dès qu'il n'y a plus de
  /// listener. ATTENTION : si la même UI écoute aussi `orderTrackingStream`
  /// pour le même `orderId`, c'est le premier `unwatchOrder` exécuté qui ferme
  /// la room (le service mutualise le watch). En pratique on watch les deux
  /// streams ensemble dans le TrackingScreen (LIL-86) donc le risque de fermer
  /// trop tôt est nul.

  OrderStatusStreamProvider call(String orderId) =>
      OrderStatusStreamProvider._(argument: orderId, from: this);

  @override
  String toString() => r'orderStatusStreamProvider';
}

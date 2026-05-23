import 'dart:developer' as developer;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/tracking/driver_position_event.dart';
import '../models/tracking/order_status_event.dart';
import 'tracking_socket_service.dart';

part 'tracking_socket_provider.g.dart';

/// Singleton du [TrackingSocketService] pour toute la session admin.
///
/// `keepAlive: true` : on garde **une seule** socket pour toute la durée de
/// vie de l'app — la connexion est coûteuse à établir et le backend déduit du
/// token Firebase quels rooms l'utilisateur peut watcher.
///
/// La socket est créée à la première demande (lazy) puis réutilisée. Au
/// dispose du provider (jamais en pratique sauf logout / hot restart), on
/// libère proprement la socket.
@Riverpod(keepAlive: true)
TrackingSocketService trackingSocketService(Ref ref) {
  final service = TrackingSocketService();
  ref.onDispose(() {
    developer.log(
      'Disposing TrackingSocketService (keepAlive provider tearDown)',
      name: 'trackingSocketServiceProvider',
    );
    service.dispose();
  });
  return service;
}

/// Stream des positions GPS du livreur pour une commande donnée.
///
/// `autoDispose` (par défaut) : dès que plus aucun widget n'écoute le
/// provider, on émet `order:unwatch` côté backend pour libérer la room.
/// La socket sous-jacente reste vivante (keepAlive sur le service).
@riverpod
Stream<DriverPositionEvent> orderTrackingStream(
  Ref ref,
  String orderId,
) {
  final svc = ref.watch(trackingSocketServiceProvider);
  developer.log(
    'orderTrackingStream subscribed for $orderId',
    name: 'orderTrackingStreamProvider',
  );

  ref.onDispose(() {
    developer.log(
      'orderTrackingStream disposed for $orderId — emitting order:unwatch',
      name: 'orderTrackingStreamProvider',
    );
    svc.unwatchOrder(orderId);
  });

  return svc.watchOrder(orderId);
}

/// Stream des changements de statut backend pour une commande donnée.
///
/// `autoDispose` : libère la room côté backend dès qu'il n'y a plus de
/// listener. ATTENTION : si la même UI écoute aussi `orderTrackingStream`
/// pour le même `orderId`, c'est le premier `unwatchOrder` exécuté qui ferme
/// la room (le service mutualise le watch). En pratique on watch les deux
/// streams ensemble dans le TrackingScreen (LIL-86) donc le risque de fermer
/// trop tôt est nul.
@riverpod
Stream<OrderStatusEvent> orderStatusStream(
  Ref ref,
  String orderId,
) {
  final svc = ref.watch(trackingSocketServiceProvider);
  developer.log(
    'orderStatusStream subscribed for $orderId',
    name: 'orderStatusStreamProvider',
  );

  // On ne re-`unwatchOrder` pas ici si `orderTrackingStream` est aussi actif
  // — le service garde la trace dans `_watchedOrders`, et un seul unwatch
  // suffit. Si seul ce stream est consommé, on libère ici.
  ref.onDispose(() {
    developer.log(
      'orderStatusStream disposed for $orderId',
      name: 'orderStatusStreamProvider',
    );
    svc.unwatchOrder(orderId);
  });

  return svc.orderStatusStream(orderId);
}

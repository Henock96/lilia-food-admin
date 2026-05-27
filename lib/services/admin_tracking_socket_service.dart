import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:lilia_admin/constants/app_constants.dart';
import 'package:lilia_admin/features/auth/repository/firebase_auth_repository.dart';

part 'admin_tracking_socket_service.g.dart';

/// Event WebSocket reçu côté admin quand le statut d'une commande change.
///
/// Le backend `tracking.gateway::broadcastOrderStatus` n'inclut que
/// `{ status }` dans le payload — l'admin connaît implicitement les
/// commandes qu'il watch via [AdminTrackingSocketService.subscribeToOrders].
/// Pour l'instant on n'a pas besoin du orderId : recevoir l'event suffit
/// à déclencher un refresh de la liste.
class AdminOrderStatusEvent {
  final String status;
  final DateTime receivedAt;

  const AdminOrderStatusEvent({
    required this.status,
    required this.receivedAt,
  });
}

/// Service WebSocket admin pour écouter les changements de statut des
/// commandes en temps réel.
///
/// Architecture :
///   - 1 seul socket Socket.io connecté au namespace `/tracking` (cf.
///     [AppConstants.trackingNamespace]) auth par Firebase ID token
///   - `subscribeToOrders([id1, id2, ...])` émet `order:watch` par order
///     non encore watché. Diff implicite — déjà watché = no-op
///   - `events` : stream broadcast de [AdminOrderStatusEvent], consommé
///     par `RestaurantOrdersScreen` qui invalide
///     `restaurantOrdersProvider` à chaque event reçu
///   - Reconnexion auto (10 tentatives, backoff 2s → 10s) + re-watch
///     automatique de tous les `_watchedOrders` après reconnect
///   - FCM est conservé comme fallback (cf. [NotificationService]) :
///     l'admin ne dépend pas du WebSocket pour ne rien rater
///
/// Différence avec le client `lilia-app/.../tracking_socket_service.dart` :
///   - L'admin watch potentiellement N commandes simultanément (ses
///     commandes actives) au lieu d'une seule
///   - On ignore `driver:position` (non utilisé côté admin)
class AdminTrackingSocketService {
  final FirebaseAuthenticationRepository _auth;

  io.Socket? _socket;
  bool _isConnecting = false;
  bool _isDisposed = false;

  final _watchedOrders = <String>{};
  final _events = StreamController<AdminOrderStatusEvent>.broadcast();

  AdminTrackingSocketService(this._auth);

  /// Stream broadcast des changements de statut. Plusieurs widgets
  /// peuvent écouter simultanément ; les events ratés avant subscribe
  /// ne sont pas rejoués (broadcast = pas de buffer).
  Stream<AdminOrderStatusEvent> get events => _events.stream;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> _ensureConnected() async {
    if (_isDisposed || isConnected || _isConnecting) return;
    _isConnecting = true;

    try {
      final token = await _auth.getIdToken();
      if (token == null) {
        debugPrint('[Admin Tracking WS] Pas de token — connexion annulée');
        return;
      }

      _socket?.dispose();
      _socket = io.io(
        '${AppConstants.wsUrl}${AppConstants.trackingNamespace}',
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .setAuth({'token': token})
            .enableReconnection()
            .setReconnectionAttempts(10)
            .setReconnectionDelay(2000)
            .setReconnectionDelayMax(10000)
            .disableAutoConnect()
            .build(),
      );

      _socket!
        ..onConnect((_) {
          debugPrint(
            '[Admin Tracking WS] connected — re-watching ${_watchedOrders.length} order(s)',
          );
          // Re-emit `order:watch` pour toutes les commandes en mémoire
          // après une reconnexion (le serveur ne se souvient pas des
          // rooms d'un socket déconnecté).
          for (final orderId in _watchedOrders) {
            _socket!.emit('order:watch', {'orderId': orderId});
          }
        })
        ..onDisconnect(
            (reason) => debugPrint('[Admin Tracking WS] disconnected: $reason'))
        ..onConnectError(
            (e) => debugPrint('[Admin Tracking WS] connect error: $e'))
        ..onError((e) => debugPrint('[Admin Tracking WS] error: $e'))
        ..on('order:status', (data) {
          if (data is! Map) return;
          final status = data['status'] as String?;
          if (status == null) return;
          if (!_events.isClosed) {
            _events.add(AdminOrderStatusEvent(
              status: status,
              receivedAt: DateTime.now(),
            ));
          }
        });

      _socket!.connect();
    } catch (e) {
      debugPrint('[Admin Tracking WS] connect threw: $e');
    } finally {
      _isConnecting = false;
    }
  }

  /// Abonne le socket aux rooms `order:<id>` pour la liste fournie.
  ///
  /// Le diff est implicite : les orderIds déjà watchés sont no-op, les
  /// nouveaux déclenchent un `order:watch`. On ne tente PAS de unwatch
  /// les anciens (Socket.io ne propose pas de `leave` côté client ; on
  /// laisse le serveur ignorer les events des rooms abandonnées —
  /// l'overhead est négligeable et le socket sera nettoyé au logout).
  Future<void> subscribeToOrders(Iterable<String> orderIds) async {
    if (_isDisposed) return;
    final newOrders = orderIds.toSet().difference(_watchedOrders);
    if (newOrders.isEmpty) return;

    _watchedOrders.addAll(newOrders);
    await _ensureConnected();
    if (isConnected) {
      for (final orderId in newOrders) {
        _socket!.emit('order:watch', {'orderId': orderId});
      }
    }
    // Si pas encore connecté, onConnect re-emit toutes les rooms.
  }

  /// Reconnecte après un refresh du Firebase ID token (le précédent
  /// pourrait être expiré côté serveur).
  Future<void> reconnect() async {
    if (_isDisposed) return;
    _socket?.dispose();
    _socket = null;
    await _ensureConnected();
  }

  /// Coupe le socket sans perdre la liste des `_watchedOrders` — utile
  /// quand l'app passe en background pour économiser la batterie. Au
  /// retour foreground, appeler [reconnect].
  void disconnect() {
    if (_isDisposed) return;
    _socket?.disconnect();
  }

  void dispose() {
    _isDisposed = true;
    _events.close();
    _watchedOrders.clear();
    _socket?.dispose();
    _socket = null;
  }
}

@Riverpod(keepAlive: true)
AdminTrackingSocketService adminTrackingSocketService(Ref ref) {
  final auth = ref.watch(authRepositoryProvider);
  final service = AdminTrackingSocketService(auth);
  ref.onDispose(service.dispose);
  return service;
}

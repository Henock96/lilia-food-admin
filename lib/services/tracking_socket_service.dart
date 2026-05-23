import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../constants/app_constants.dart';
import '../models/tracking/driver_position_event.dart';
import '../models/tracking/order_status_event.dart';

/// Service Socket.io qui écoute le namespace `/tracking` du backend pour l'app
/// admin. Permet à un ADMIN (ou RESTAURATEUR) de suivre en temps réel les
/// positions des livreurs et les changements de statut d'une commande
/// `EN_ROUTE`.
///
/// Events Socket.io :
///   - emit `order:watch`   { orderId }  → rejoindre la room d'une commande
///   - emit `order:unwatch` { orderId }  → quitter la room
///   - on   `driver:position` { lat, lng, eta, timestamp }
///   - on   `order:status`    { status,             timestamp? }
///
/// Le payload backend ne contient pas l'`orderId`. On garde donc l'orderId
/// associé à chaque stream et on route les events en fonction des rooms
/// actuellement watchées.
///
/// Lifecycle : `TrackingSocketService` implémente [WidgetsBindingObserver] et
/// se reconnecte automatiquement quand l'app repasse au foreground si la
/// connexion a été perdue en background. Pensez à appeler `dispose()` pour
/// nettoyer (ou laisser un provider Riverpod `keepAlive` le gérer dans LIL-85).
class TrackingSocketService with WidgetsBindingObserver {
  TrackingSocketService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance {
    WidgetsBinding.instance.addObserver(this);
  }

  static const String _logName = 'TrackingSocketService';

  final FirebaseAuth _firebaseAuth;

  io.Socket? _socket;
  bool _isConnecting = false;
  bool _explicitlyDisconnected = false;

  // Backoff exponentiel léger (en complément du backoff interne du package).
  int _reconnectAttempt = 0;
  Timer? _reconnectTimer;

  /// orderId → controller (broadcast pour permettre plusieurs abonnés UI).
  final Map<String, StreamController<DriverPositionEvent>> _positionStreams =
      {};
  final Map<String, StreamController<OrderStatusEvent>> _statusStreams = {};

  /// Liste des commandes activement watchées (pour re-emit `order:watch`
  /// après une reconnexion).
  final Set<String> _watchedOrders = <String>{};

  bool get isConnected => _socket?.connected ?? false;

  // ---------------------------------------------------------------------------
  // API publique
  // ---------------------------------------------------------------------------

  /// Initialise et connecte le socket sur `/tracking`. Idempotent : appels
  /// successifs ne créent pas plusieurs sockets.
  Future<void> connect() async {
    _explicitlyDisconnected = false;
    await _ensureConnected();
  }

  /// Déconnecte explicitement le socket et annule toute reconnexion auto.
  /// Les streams ouverts restent disponibles (sans nouveaux events) jusqu'à
  /// `dispose()`.
  Future<void> disconnect() async {
    _explicitlyDisconnected = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempt = 0;

    final socket = _socket;
    if (socket != null) {
      try {
        // Quitter proprement les rooms côté serveur avant de fermer.
        for (final orderId in _watchedOrders) {
          socket.emit('order:unwatch', {'orderId': orderId});
        }
      } catch (e, st) {
        developer.log(
          'Erreur lors de l\'émission order:unwatch',
          name: _logName,
          error: e,
          stackTrace: st,
        );
      }
      socket.disconnect();
      socket.dispose();
    }
    _socket = null;
  }

  /// S'abonne aux positions du livreur pour une commande. Émet `order:watch`
  /// dès que le socket est connecté. Le caller peut écouter le stream pour
  /// recevoir les positions GPS du livreur.
  ///
  /// Pour arrêter d'écouter, le caller doit `cancel()` la subscription. Le
  /// stream reste vivant tant que la classe n'est pas `dispose()`-ée — c'est
  /// au consumer (ex: provider Riverpod) de gérer son cycle de vie via
  /// [unwatchOrder] s'il veut libérer la room côté backend.
  Stream<DriverPositionEvent> watchOrder(String orderId) {
    final ctrl = _positionStreams.putIfAbsent(
      orderId,
      () => StreamController<DriverPositionEvent>.broadcast(),
    );

    final wasNotWatched = _watchedOrders.add(orderId);

    // Connexion à la demande + emit order:watch (si déjà connecté).
    unawaited(_ensureConnected().then((_) {
      if (isConnected && wasNotWatched) {
        try {
          _socket!.emit('order:watch', {'orderId': orderId});
          developer.log('order:watch émis pour $orderId', name: _logName);
        } catch (e, st) {
          developer.log(
            'Erreur emit order:watch',
            name: _logName,
            error: e,
            stackTrace: st,
          );
        }
      }
    }));

    return ctrl.stream;
  }

  /// Stream des changements de statut pour une commande. Comme [watchOrder],
  /// déclenche `order:watch` si nécessaire (le backend renvoie position +
  /// statut dans la même room).
  Stream<OrderStatusEvent> orderStatusStream(String orderId) {
    final ctrl = _statusStreams.putIfAbsent(
      orderId,
      () => StreamController<OrderStatusEvent>.broadcast(),
    );

    final wasNotWatched = _watchedOrders.add(orderId);

    unawaited(_ensureConnected().then((_) {
      if (isConnected && wasNotWatched) {
        try {
          _socket!.emit('order:watch', {'orderId': orderId});
        } catch (e, st) {
          developer.log(
            'Erreur emit order:watch (status)',
            name: _logName,
            error: e,
            stackTrace: st,
          );
        }
      }
    }));

    return ctrl.stream;
  }

  /// Quitte la room côté serveur et ferme les streams associés à `orderId`.
  /// À appeler quand l'UI n'a plus besoin de suivre cette commande.
  void unwatchOrder(String orderId) {
    if (!_watchedOrders.remove(orderId)) return;

    try {
      _socket?.emit('order:unwatch', {'orderId': orderId});
    } catch (e, st) {
      developer.log(
        'Erreur emit order:unwatch',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }

    _positionStreams.remove(orderId)?.close();
    _statusStreams.remove(orderId)?.close();
  }

  /// Libère toutes les ressources. À appeler quand le service ne sera plus
  /// utilisé (ex: `ref.onDispose` côté Riverpod).
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    for (final c in _positionStreams.values) {
      if (!c.isClosed) c.close();
    }
    for (final c in _statusStreams.values) {
      if (!c.isClosed) c.close();
    }
    _positionStreams.clear();
    _statusStreams.clear();
    _watchedOrders.clear();

    _socket?.dispose();
    _socket = null;
  }

  // ---------------------------------------------------------------------------
  // WidgetsBindingObserver
  // ---------------------------------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        !_explicitlyDisconnected &&
        !isConnected) {
      developer.log(
        'App resumed — tentative de reconnexion',
        name: _logName,
      );
      unawaited(_ensureConnected());
    }
  }

  // ---------------------------------------------------------------------------
  // Connexion / reconnexion
  // ---------------------------------------------------------------------------

  Future<void> _ensureConnected() async {
    if (_explicitlyDisconnected) return;
    if (isConnected || _isConnecting) return;
    _isConnecting = true;

    final isReconnect = _reconnectAttempt > 0;
    // Breadcrumb Sentry — utile pour corréler les déconnexions/reconnexions
    // dans les sessions admin (cf. LIL-89). Sentry est initialisé dans
    // `main.dart` ; `addBreadcrumb` est no-op si le SDK n'est pas actif.
    Sentry.addBreadcrumb(Breadcrumb(
      message: 'tracking_socket_connect',
      category: 'tracking',
      level: SentryLevel.info,
      data: {
        'reconnect': isReconnect,
        'attempt': _reconnectAttempt,
        'watchedOrders': _watchedOrders.length,
      },
    ));

    try {
      final token = await _getFreshIdToken();
      if (token == null) {
        developer.log(
          'Pas d\'utilisateur Firebase — connexion annulée',
          name: _logName,
        );
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

      _attachListeners(_socket!);
      _socket!.connect();
    } catch (e, st) {
      developer.log(
        'Erreur _ensureConnected',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      _scheduleReconnect();
    } finally {
      _isConnecting = false;
    }
  }

  void _attachListeners(io.Socket socket) {
    socket
      ..onConnect((_) {
        developer.log('connecté', name: _logName);
        _reconnectAttempt = 0;
        _reconnectTimer?.cancel();
        _reconnectTimer = null;
        // Re-watch toutes les commandes après une (re)connexion.
        for (final orderId in _watchedOrders) {
          try {
            socket.emit('order:watch', {'orderId': orderId});
          } catch (e, st) {
            developer.log(
              'Erreur re-emit order:watch pour $orderId',
              name: _logName,
              error: e,
              stackTrace: st,
            );
          }
        }
      })
      ..onDisconnect((reason) {
        developer.log('déconnecté: $reason', name: _logName);
        if (!_explicitlyDisconnected) {
          _scheduleReconnect();
        }
      })
      ..onConnectError((err) {
        developer.log(
          'connect error: $err',
          name: _logName,
        );
        if (!_explicitlyDisconnected) {
          _scheduleReconnect();
        }
      })
      ..onError((err) {
        developer.log('error: $err', name: _logName);
      })
      ..on('driver:position', _handleDriverPosition)
      ..on('order:status', _handleOrderStatus);
  }

  void _handleDriverPosition(dynamic data) {
    if (data is! Map) return;
    try {
      final json = Map<String, dynamic>.from(data);
      // Le backend n'envoie pas l'orderId dans le payload : on broadcast à tous
      // les listeners watchés (en pratique l'admin ne watch souvent qu'une
      // commande à la fois).
      for (final entry in _positionStreams.entries) {
        if (entry.value.isClosed) continue;
        entry.value.add(
          DriverPositionEvent.fromJson(json, orderId: entry.key),
        );
      }
    } catch (e, st) {
      developer.log(
        'Parse driver:position échoué',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  void _handleOrderStatus(dynamic data) {
    if (data is! Map) return;
    try {
      final json = Map<String, dynamic>.from(data);
      for (final entry in _statusStreams.entries) {
        if (entry.value.isClosed) continue;
        entry.value.add(
          OrderStatusEvent.fromJson(json, orderId: entry.key),
        );
      }
    } catch (e, st) {
      developer.log(
        'Parse order:status échoué',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  void _scheduleReconnect() {
    if (_explicitlyDisconnected) return;
    if (_reconnectTimer != null) return;

    _reconnectAttempt++;
    // Backoff exponentiel léger : 1s, 2s, 4s, 8s, max 30s.
    final delaySeconds = (1 << (_reconnectAttempt - 1)).clamp(1, 30);
    final delay = Duration(seconds: delaySeconds);
    developer.log(
      'reconnexion programmée dans ${delay.inSeconds}s (tentative '
      '$_reconnectAttempt)',
      name: _logName,
    );

    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      if (_explicitlyDisconnected) return;
      unawaited(_reconnectWithFreshToken());
    });
  }

  Future<void> _reconnectWithFreshToken() async {
    try {
      _socket?.dispose();
      _socket = null;
      await _ensureConnected();
    } catch (e, st) {
      developer.log(
        'Erreur _reconnectWithFreshToken',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      _scheduleReconnect();
    }
  }

  /// Récupère un ID Token Firebase frais. Force le refresh pour éviter de
  /// présenter un token expiré au backend lors d'une (re)connexion.
  Future<String?> _getFreshIdToken() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;
      return await user.getIdToken(true);
    } catch (e, st) {
      developer.log(
        'getIdToken(true) échoué',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }
}

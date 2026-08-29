import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lilia_admin/features/admin/presentation/providers/admin_vendors_provider.dart';
import 'package:lilia_admin/features/auth/user_sync_provider.dart';
import 'package:lilia_admin/features/home/data/order_controller.dart';
import 'package:lilia_admin/features/incidents/presentation/providers/incidents_provider.dart';
import 'package:lilia_admin/firebase_options.dart';
import 'package:lilia_admin/routing/app_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/services/fcm_token_registrar.dart';
import 'package:lilia_admin/services/notification_router.dart';

part 'notification_service.g.dart';

// --- Background Message Handler ---
// Doit etre une fonction de haut niveau (en dehors d'une classe)
//
// ⚠️ Ne PAS y afficher de notification locale. Le backend envoie toujours un
// bloc `notification` (`notifications.service.ts`) et l'app déclare
// `default_notification_channel_id` dans son manifest : Android affiche donc
// déjà la notification tout seul quand l'app est en arrière-plan. Un
// `show()` ici en produisait une seconde, identique.
//
// Ce handler tourne dans un isolate séparé : il n'a accès ni au ProviderScope
// ni au router. Le rafraîchissement des données se fait au retour au premier
// plan (`onMessageOpenedApp` / `getInitialMessage`).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('[ADMIN NOTIF] Message reçu en arrière-plan: ${message.data}');
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FcmTokenRegistrar _registrar;
  final Ref _ref;
  static const NotificationRouter _router = NotificationRouter();

  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSubscription;
  StreamSubscription<String>? _onTokenRefreshSubscription;
  bool _isDisposed = false;

  NotificationService(this._registrar, this._ref);

  /// Token FCM effectivement enregistré côté serveur (`null` hors session).
  String? get fcmToken => _registrar.token;

  Future<void> _requestPermission() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('[ADMIN NOTIF] Permission accordee');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('[ADMIN NOTIF] Permission provisoire accordee');
    } else {
      debugPrint('[ADMIN NOTIF] Permission refusee');
    }
  }

  void _setupMessageHandlers() {
    _cancelSubscriptions();

    // Clic sur notification quand l'app est en arriere-plan
    _onMessageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
      RemoteMessage message,
    ) {
      debugPrint(
        '[ADMIN NOTIF] Notification ouverte depuis background: ${message.data}',
      );
      _handleNotificationData(message.data, NotificationTrigger.tap);
    });

    // Message recu quand l'app est au premier plan
    _onMessageSubscription = FirebaseMessaging.onMessage.listen((
      RemoteMessage message,
    ) {
      debugPrint(
        '[ADMIN NOTIF] Message foreground: ${message.notification?.title}',
      );
      if (message.notification != null) {
        _showLocalNotification(message);
      }
      // Trigger foreground : on rafraîchit les données, mais on ne déplace pas
      // l'utilisateur — il est en train de travailler sur un autre écran.
      _handleNotificationData(message.data, NotificationTrigger.foreground);
    });
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _createNotificationChannel();
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notifications Commandes',
      description: 'Notifications pour les nouvelles commandes.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        debugPrint('[ADMIN NOTIF] Notification tappee: $data');
        _handleNotificationData(
          Map<String, dynamic>.from(data),
          NotificationTrigger.tap,
        );
      } catch (e) {
        debugPrint('[ADMIN NOTIF] Erreur parsing payload: $e');
      }
    }
  }

  /// Applique l'action décidée par [NotificationRouter] (couvert par
  /// `test/services/notification_router_test.dart`).
  void _handleNotificationData(
    Map<String, dynamic> data,
    NotificationTrigger trigger,
  ) {
    if (_isDisposed) return;

    final action = _router.resolve(data, trigger: trigger);
    if (action == NotificationAction.none) {
      debugPrint('[ADMIN NOTIF] Message sans action : $data');
      return;
    }

    switch (action.refresh) {
      case NotificationTarget.orders:
        _ref.invalidate(restaurantOrdersProvider);
      case NotificationTarget.incidents:
        _ref.invalidate(incidentsListProvider);
      case NotificationTarget.pendingVendors:
        _ref.invalidate(adminPendingVendorsProvider);
        _ref.invalidate(adminVendorsListProvider);
      case NotificationTarget.vendorProfile:
        // Le profil porte le restaurant et son `adminApproved`.
        _ref.invalidate(userDataSynchronizerProvider);
      case null:
        break;
    }

    final route = action.route;
    if (route == null) return;

    // `pushNamed` empile par dessus l'écran courant : le vendeur peut revenir
    // en arrière sur ce qu'il faisait.
    try {
      _ref
          .read(routerProvider)
          .pushNamed(route.name, pathParameters: route.pathParameters);
    } catch (e) {
      debugPrint('[ADMIN NOTIF] Erreur navigation ${route.name}: $e');
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'high_importance_channel',
          'Notifications Commandes',
          channelDescription: 'Notifications pour les nouvelles commandes.',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
          showWhen: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: platformDetails,
      payload: jsonEncode(message.data),
    );
  }

  Future<bool> _requestLocalNotificationPermission() async {
    final platform = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (platform != null) {
      return await platform.requestNotificationsPermission() ?? false;
    }

    final iosPlatform = _localNotifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (iosPlatform != null) {
      return await iosPlatform.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return true;
  }

  Future<void> init() async {
    if (_isDisposed) {
      debugPrint('[ADMIN NOTIF] Service deja dispose, init ignoree');
      return;
    }

    try {
      await _initLocalNotifications();

      final hasLocalPermission = await _requestLocalNotificationPermission();
      if (!hasLocalPermission) {
        debugPrint('[ADMIN NOTIF] Permission notification locale refusee');
      }

      await _requestPermission();

      // Les handlers sont branchés AVANT `getToken()` : sur simulateur iOS ou
      // quand APNS n'a pas encore rendu son token, `getToken()` lève et le
      // catch plus bas avalait l'exception — l'app se retrouvait sans aucun
      // handler `onMessage` / `onMessageOpenedApp`.
      _setupMessageHandlers();

      await registerTokenOnServer();

      _onTokenRefreshSubscription?.cancel();
      _onTokenRefreshSubscription = _fcm.onTokenRefresh.listen((newToken) {
        if (!_isDisposed) {
          debugPrint('[ADMIN NOTIF] FCM Token rafraichi');
          _registrar.register(newToken);
        }
      });

      // Gerer l'ouverture de l'app via une notification (app terminee)
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
          '[ADMIN NOTIF] App ouverte depuis notification (terminated)',
        );
        // L'app a été lancée en tapant la notification : la navigation est
        // bien voulue par l'utilisateur.
        _handleNotificationData(initialMessage.data, NotificationTrigger.tap);
      }
    } catch (e) {
      debugPrint('[ADMIN NOTIF] Erreur initialisation: $e');
    }
  }

  /// Récupère le token FCM courant et l'enregistre côté serveur.
  ///
  /// Appelé à l'init et après chaque sync de profil (donc à chaque login). Le
  /// token est redemandé à FCM à chaque fois : après un [removeToken] le
  /// registrar n'en a plus en mémoire, et sans ce re-fetch une reconnexion
  /// dans la même session d'app n'enregistrerait plus rien.
  Future<void> registerTokenOnServer({int maxRetries = 3}) async {
    final String? token;
    try {
      token = await _fetchFcmToken();
    } catch (e) {
      debugPrint('[ADMIN NOTIF] Echec obtention FCM token: $e');
      return;
    }

    if (token == null) {
      debugPrint('[ADMIN NOTIF] FCM Token null, enregistrement impossible');
      return;
    }

    await _registrar.register(token, maxRetries: maxRetries);
  }

  /// Récupère le token FCM en attendant d'abord le token APNS sur iOS.
  ///
  /// L'enregistrement APNS est **asynchrone** : au premier lancement, il n'est
  /// pas encore terminé quand `init()` s'exécute. Appeler `getToken()` tout de
  /// suite lève `apns-token-not-set` — sans cette attente, l'app resterait
  /// sans token FCM pour toute la session, donc sans aucun push.
  ///
  /// Renvoie `null` quand APNS est réellement indisponible (simulateur iOS).
  Future<String?> _fetchFcmToken({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final deadline = DateTime.now().add(timeout);
    var attempt = 0;

    while (DateTime.now().isBefore(deadline)) {
      attempt++;
      try {
        return await _fcm.getToken();
      } on FirebaseException catch (e) {
        if (e.code != 'apns-token-not-set') rethrow;
        // APNS pas encore prêt : on retente jusqu'à l'échéance.
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }

    debugPrint(
      '[ADMIN NOTIF] ⚠️ Token APNS indisponible après $attempt tentatives '
      '(${timeout.inSeconds}s). Simulateur iOS, ou entitlement '
      '`aps-environment` absent de la config de build. Aucun push ne sera reçu.',
    );
    return null;
  }

  /// Supprime le token du serveur au logout, pour qu'un appareil déconnecté
  /// cesse de recevoir les pushs de commandes.
  Future<void> removeToken() => _registrar.remove();

  void _cancelSubscriptions() {
    _onMessageSubscription?.cancel();
    _onMessageOpenedSubscription?.cancel();
    _onTokenRefreshSubscription?.cancel();
  }

  void dispose() {
    if (_isDisposed) return;

    debugPrint('[ADMIN NOTIF] Dispose du service...');
    _isDisposed = true;

    _cancelSubscriptions();

    _onMessageSubscription = null;
    _onMessageOpenedSubscription = null;
    _onTokenRefreshSubscription = null;
  }
}

@Riverpod(keepAlive: true)
FcmTokenRegistrar fcmTokenRegistrar(Ref ref) =>
    FcmTokenRegistrar(ref.watch(apiClientProvider));

@Riverpod(keepAlive: true)
NotificationService notificationService(Ref ref) {
  final service = NotificationService(ref.watch(fcmTokenRegistrarProvider), ref);

  ref.onDispose(() {
    service.dispose();
  });

  return service;
}

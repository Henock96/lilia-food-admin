import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:lilia_admin/features/auth/repository/firebase_auth_repository.dart';
import 'package:lilia_admin/features/home/data/order_controller.dart';
import 'package:lilia_admin/features/incidents/presentation/providers/incidents_provider.dart';
import 'package:lilia_admin/firebase_options.dart';
import 'package:lilia_admin/routing/app_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:http/http.dart' as http;

import 'package:lilia_admin/constants/app_constants.dart';
part 'notification_service.g.dart';

/// Provider pour stocker l'ID de la derniere commande notifiee
final latestOrderNotificationProvider = StateProvider<String?>((ref) => null);

/// Provider pour stocker l'ID du dernier incident notifié (FCM data.type='incident').
/// Consommé en lecture par les écrans qui veulent surligner le nouvel élément.
final latestIncidentNotificationProvider = StateProvider<String?>((ref) => null);

// --- Background Message Handler ---
// Doit etre une fonction de haut niveau (en dehors d'une classe)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (message.notification != null) {
    final FlutterLocalNotificationsPlugin localNotifications =
        FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await localNotifications.initialize(settings: initializationSettings);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'high_importance_channel',
          'Notifications Commandes',
          channelDescription: 'Notifications pour les nouvelles commandes.',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await localNotifications.show(
      id: message.notification.hashCode,
      title: message.notification!.title,
      body: message.notification!.body,
      notificationDetails: platformDetails,
      payload: jsonEncode(message.data),
    );
  }
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseAuthenticationRepository _authRepository;
  final Ref _ref;

  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSubscription;
  StreamSubscription<String>? _onTokenRefreshSubscription;
  bool _isDisposed = false;

  NotificationService(this._authRepository, this._ref);

  String? fcmToken;

  static const String _baseUrl = AppConstants.baseUrl;

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
      _handleNotificationData(message.data);
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
      _handleNotificationData(message.data);
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
        _handleNotificationData(Map<String, dynamic>.from(data));
      } catch (e) {
        debugPrint('[ADMIN NOTIF] Erreur parsing payload: $e');
      }
    }
  }

  void _handleNotificationData(Map<String, dynamic> data) {
    if (_isDisposed) return;

    final type = data['type'] as String?;

    // Incident : naviguer directement vers le détail (admin clique sur la push
    // FCM envoyée par IncidentsNotificationListener côté backend pour les
    // sévérités HIGH/CRITICAL).
    if (type == 'incident') {
      final incidentId = data['incidentId'] as String?;
      if (incidentId == null || incidentId.isEmpty) {
        debugPrint('[ADMIN NOTIF] Incident reçu sans incidentId — ignoré');
        return;
      }
      debugPrint('[ADMIN NOTIF] Incident détecté: $incidentId');
      _ref.read(latestIncidentNotificationProvider.notifier).state = incidentId;
      _ref.invalidate(incidentsListProvider);
      // Deep link : pousser le détail dans le router. `pushNamed` ajoute par
      // dessus la pile courante — si l'utilisateur était déjà sur une page, il
      // peut revenir en arrière.
      try {
        _ref.read(routerProvider).pushNamed(
          'incident-detail',
          pathParameters: {'id': incidentId},
        );
      } catch (e) {
        debugPrint('[ADMIN NOTIF] Erreur navigation incident: $e');
      }
      return;
    }

    if (data.containsKey('orderId')) {
      final orderId = data['orderId'] as String;
      debugPrint('[ADMIN NOTIF] Nouvelle commande detectee: $orderId');
      _ref.read(latestOrderNotificationProvider.notifier).state = orderId;
      // Rafraichir la liste des commandes
      _ref.invalidate(restaurantOrdersProvider);
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

      fcmToken = await _fcm.getToken();
      if (fcmToken != null) {
        debugPrint(
          '[ADMIN NOTIF] FCM Token obtenu: ${fcmToken!.substring(0, 20)}...',
        );
        await registerTokenOnServer();
      } else {
        debugPrint('[ADMIN NOTIF] Echec obtention FCM token');
      }

      _setupMessageHandlers();

      _onTokenRefreshSubscription?.cancel();
      _onTokenRefreshSubscription = _fcm.onTokenRefresh.listen((newToken) {
        if (!_isDisposed) {
          debugPrint('[ADMIN NOTIF] FCM Token rafraichi');
          fcmToken = newToken;
          registerTokenOnServer();
        }
      });

      // Gerer l'ouverture de l'app via une notification (app terminee)
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
          '[ADMIN NOTIF] App ouverte depuis notification (terminated)',
        );
        _handleNotificationData(initialMessage.data);
      }
    } catch (e) {
      debugPrint('[ADMIN NOTIF] Erreur initialisation: $e');
    }
  }

  Future<void> registerTokenOnServer({int maxRetries = 3}) async {
    if (fcmToken == null) {
      debugPrint('[ADMIN NOTIF] FCM Token null, enregistrement impossible');
      return;
    }

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final idToken = await _authRepository.getIdToken();
        if (idToken == null) {
          debugPrint('[ADMIN NOTIF] ID Token Firebase null, auth impossible');
          return;
        }

        final url = Uri.parse('$_baseUrl/notifications/register-token');

        final response = await http
            .post(
              url,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $idToken',
              },
              body: jsonEncode({'token': fcmToken}),
            )
            .timeout(const Duration(seconds: 35));

        if (response.statusCode == 200 || response.statusCode == 201) {
          debugPrint(
            '[ADMIN NOTIF] Token FCM enregistre sur le serveur avec succes',
          );
          return;
        } else {
          debugPrint(
            '[ADMIN NOTIF] Echec enregistrement token (tentative $attempt/$maxRetries). '
            'Status: ${response.statusCode}',
          );
        }
      } catch (e) {
        debugPrint(
          '[ADMIN NOTIF] Erreur enregistrement token (tentative $attempt/$maxRetries): $e',
        );

        if (attempt == maxRetries) {
          debugPrint('[ADMIN NOTIF] Nombre max de tentatives atteint');
        } else {
          await Future.delayed(Duration(seconds: attempt * 15));
        }
      }
    }
  }

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
NotificationService notificationService(Ref ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final service = NotificationService(authRepository, ref);

  ref.onDispose(() {
    service.dispose();
  });

  return service;
}

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lilia_admin/routing/app_router.dart';
import 'package:lilia_admin/services/notification_service.dart';
import 'package:lilia_admin/theme/app_theme.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'features/auth/user_sync_provider.dart';
import 'firebase_options.dart';

// Provider pour initialiser le service de notification au demarrage
final notificationInitializerProvider = FutureProvider<void>((ref) async {
  await ref.watch(notificationServiceProvider).init();
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  // Locale FR pour DateFormat / NumberFormat (fiche livreur, missions, etc.).
  await initializeDateFormatting('fr_FR');

  await SentryFlutter.init(
    (options) {
      // DSN injecté au build via --dart-define=SENTRY_DSN=...
      // S'il est vide (dev local), Sentry reste inactif : zéro overhead.
      options.dsn = const String.fromEnvironment('SENTRY_DSN');
      options.environment = const String.fromEnvironment(
        'SENTRY_ENV',
        defaultValue: 'production',
      );
      options.tracesSampleRate = 0.1;
      // ignore: experimental_member_use
      options.profilesSampleRate = 0.1;
      // Le contexte user (id/email/role) est attaché explicitement après login.
      options.sendDefaultPii = false;
    },
    appRunner: () => runApp(ProviderScope(child: const MyApp())),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(routerProvider);
    ref.watch(notificationInitializerProvider);
    ref.watch(userDataSynchronizerProvider);
    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      title: 'Lilia Food Admin',
      theme: AppTheme.light,
    );
  }
}


import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lilia_admin/routing/app_router.dart';
import 'package:lilia_admin/services/notification_service.dart';

import 'features/auth/user_sync_provider.dart';
import 'firebase_options.dart';

// Provider pour initialiser le service de notification au demarrage
final notificationInitializerProvider = FutureProvider<void>((ref) async {
  await ref.watch(notificationServiceProvider).init();
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(ProviderScope(child: const MyApp()));
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
    );
  }
}


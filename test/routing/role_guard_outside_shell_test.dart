import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lilia_admin/features/auth/app_user_model.dart';
import 'package:lilia_admin/features/auth/presentation/access_denied_screen.dart';
import 'package:lilia_admin/features/auth/repository/firebase_auth_repository.dart';
import 'package:lilia_admin/features/auth/user_sync_provider.dart';
import 'package:lilia_admin/models/role.dart';
import 'package:lilia_admin/routing/app_router.dart';

/// Lot 5 (ADM-22) — les écrans hors de la barre d'onglets (`/gains`,
/// `/offres`, `/reservations`, `/reclamations`, `/photos`) échappaient à la
/// garde de rôle du shell : un compte CLIENT y voyait un écran vide, chaque
/// appel refusé en 403. Ils portent désormais la même garde.
class _FakeAuthRepository implements FirebaseAuthenticationRepository {
  final controller = StreamController<AppUser?>.broadcast();

  @override
  AppUser? get currentUser => const AppUser(uid: 'fb-client');

  @override
  Stream<AppUser?> authStateChanges() => controller.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _ClientProfile extends CurrentUserProfile {
  @override
  AppUser? build() => const AppUser(
    uid: 'fb-client',
    id: 'client',
    email: 'client@lilia.cg',
    role: Role.client,
  );
}

void main() {
  for (final location in [
    '/gains',
    '/offres',
    '/reservations',
    '/reclamations',
    '/reclamations/c1',
    '/photos?entityType=PRODUCT&parentId=p1',
  ]) {
    testWidgets('compte CLIENT sur $location : écran « accès refusé »', (
      tester,
    ) async {
      final auth = _FakeAuthRepository();
      addTearDown(auth.controller.close);
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          authStateChangeProvider.overrideWith((ref) => auth.controller.stream),
          currentUserProfileProvider.overrideWith(_ClientProfile.new),
        ],
      );
      addTearDown(container.dispose);

      final GoRouter router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      router.go(location);
      // Fin de la transition : l'écran d'accueil (lui aussi refusé au CLIENT)
      // ne doit plus être à l'écran.
      await tester.pumpAndSettle();

      expect(find.byType(AccessDeniedScreen), findsOneWidget);
      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        location,
      );
    });
  }
}

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lilia_admin/features/auth/app_user_model.dart';
import 'package:lilia_admin/features/auth/repository/firebase_auth_repository.dart';
import 'package:lilia_admin/routing/app_router.dart';

/// Double du dépôt d'auth : seules les deux lectures du routeur sont
/// implémentées ; tout autre appel échoue bruyamment.
class _FakeAuthRepository implements FirebaseAuthenticationRepository {
  final controller = StreamController<AppUser?>.broadcast();
  AppUser? user;

  @override
  AppUser? get currentUser => user;

  @override
  Stream<AppUser?> authStateChanges() => controller.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  group('authRedirect', () {
    test('hors session : tout mène à la connexion', () {
      expect(authRedirect(isLoggedIn: false, location: '/commandes'), '/sign-in');
      expect(authRedirect(isLoggedIn: false, location: '/sign-in'), isNull);
    });

    test('connecté : la connexion mène à l\'accueil, le reste ne bouge pas', () {
      expect(authRedirect(isLoggedIn: true, location: '/sign-in'), '/');
      expect(authRedirect(isLoggedIn: true, location: '/commandes/o1'), isNull);
    });
  });

  // Lot 4 (ADM-23) — le routeur était recréé à chaque changement d'état
  // d'auth (`ref.watch(authStateChangeProvider)`), et la pile perdue.
  test('un changement de connexion ne recrée pas le routeur', () async {
    final auth = _FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        authStateChangeProvider.overrideWith((ref) => auth.controller.stream),
      ],
    );
    addTearDown(() {
      container.dispose();
      auth.controller.close();
    });
    container.listen(routerProvider, (_, _) {});
    // L'ancien routeur suivait ce provider : on le garde vivant comme l'app.
    container.listen(authStateChangeProvider, (_, _) {});

    final first = container.read(routerProvider);

    auth.user = const AppUser(uid: 'a');
    auth.controller.add(auth.user);
    await Future<void>.delayed(Duration.zero);
    auth.user = null;
    auth.controller.add(null);
    await Future<void>.delayed(Duration.zero);

    expect(identical(container.read(routerProvider), first), isTrue);
    expect(first, isA<GoRouter>());
  });
}

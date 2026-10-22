import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/core/network/api_exception.dart';
import 'package:lilia_admin/features/auth/app_user_model.dart';
import 'package:lilia_admin/features/auth/presentation/profile_sync_error_screen.dart';
import 'package:lilia_admin/features/auth/repository/firebase_auth_repository.dart';
import 'package:lilia_admin/features/auth/user_sync_provider.dart';
import 'package:lilia_admin/models/role.dart';

AppUser _session(String uid) =>
    AppUser(uid: uid, email: '$uid@lilia.cg');

AppUser _profile(String uid) =>
    AppUser(uid: uid, id: 'id-$uid', email: '$uid@lilia.cg', role: Role.restaurateur);

/// Laisse passer les microtâches et les `await` du synchroniseur.
Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _Harness {
  _Harness() {
    container = ProviderContainer(
      overrides: [
        authStateChangeProvider.overrideWith((ref) => auth.stream),
        profileLoaderProvider.overrideWithValue(() {
          loads++;
          return loader();
        }),
        onProfileSyncedProvider.overrideWithValue((_) async => synced++),
        onProfileClearedProvider.overrideWithValue(() async {}),
      ],
    );
    container.listen(userDataSynchronizerProvider, (_, _) {});
  }

  final auth = StreamController<AppUser?>();
  late final ProviderContainer container;
  int loads = 0;
  int synced = 0;

  /// Réponse du serveur pour le prochain chargement.
  Future<AppUser?> Function() loader = () async => null;

  AppUser? get profile => container.read(currentUserProfileProvider);
  ProfileSyncState get status => container.read(profileSyncStatusProvider);

  Future<void> emit(AppUser? user) async {
    auth.add(user);
    await _settle();
  }

  void dispose() {
    container.dispose();
    auth.close();
  }
}

void main() {
  late _Harness h;

  setUp(() => h = _Harness());
  tearDown(() => h.dispose());

  test('connexion → profil chargé une fois, état prêt, effets lancés', () async {
    h.loader = () async => _profile('a');
    await h.emit(_session('a'));

    expect(h.loads, 1);
    expect(h.profile?.uid, 'a');
    expect(h.status.phase, ProfileSyncPhase.ready);
    expect(h.synced, 1);
  });

  test('ADM-26 : même compte réémis (jeton rafraîchi) → aucune nouvelle synchronisation', () async {
    h.loader = () async => _profile('a');
    await h.emit(_session('a'));
    await h.emit(_session('a'));
    await h.emit(_session('a'));

    expect(h.loads, 1);
  });

  test('changement de compte → nouvelle synchronisation', () async {
    h.loader = () async => _profile('a');
    await h.emit(_session('a'));
    h.loader = () async => _profile('b');
    await h.emit(_session('b'));

    expect(h.loads, 2);
    expect(h.profile?.uid, 'b');
  });

  test('ADM-07 : échec → état en échec avec le message serveur, profil absent', () async {
    h.loader = () async => throw const ApiException(
      'Le serveur met trop de temps à répondre.',
      kind: ApiErrorKind.timeout,
    );
    await h.emit(_session('a'));

    expect(h.profile, isNull);
    expect(h.status.failed, isTrue);
    expect(h.status.message, 'Le serveur met trop de temps à répondre.');
    expect(h.synced, 0);
  });

  test('ADM-07 : réponse sans utilisateur → échec avec message générique', () async {
    await h.emit(_session('a'));
    expect(h.status.failed, isTrue);
    expect(h.status.message, kProfileSyncFailedMessage);
  });

  test('Réessayer après un échec → profil chargé', () async {
    h.loader = () async => throw const ApiException('Réseau', kind: ApiErrorKind.network);
    await h.emit(_session('a'));
    expect(h.status.failed, isTrue);

    h.loader = () async => _profile('a');
    await h.container.read(userDataSynchronizerProvider.notifier).resync();

    expect(h.loads, 2);
    expect(h.profile?.uid, 'a');
    expect(h.status.phase, ProfileSyncPhase.ready);
  });

  test('déconnexion → profil vidé, état au repos', () async {
    h.loader = () async => _profile('a');
    await h.emit(_session('a'));
    await h.emit(null);

    expect(h.profile, isNull);
    expect(h.status.phase, ProfileSyncPhase.idle);
  });

  test('résultat d\'un compte précédent arrivé en retard → ignoré', () async {
    final slow = Completer<AppUser?>();
    h.loader = () => slow.future;
    await h.emit(_session('a'));

    h.loader = () async => _profile('b');
    await h.emit(_session('b'));
    slow.complete(_profile('a'));
    await _settle();

    expect(h.profile?.uid, 'b');
    expect(h.status.phase, ProfileSyncPhase.ready);
  });

  testWidgets('écran d\'échec : message, puis Réessayer recharge le profil', (tester) async {
    h.loader = () async => throw const ApiException('Réseau coupé.', kind: ApiErrorKind.network);
    await tester.runAsync(() => h.emit(_session('a')));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: h.container,
        child: const MaterialApp(
          home: ProfileSyncFailureGate(child: Text('application')),
        ),
      ),
    );
    expect(find.text('Réseau coupé.'), findsOneWidget);
    expect(find.text('application'), findsNothing);
    expect(find.text('Se déconnecter'), findsOneWidget);

    h.loader = () async => _profile('a');
    await tester.tap(find.text('Réessayer'));
    await tester.runAsync(_settle);
    await tester.pump();

    expect(find.text('application'), findsOneWidget);
  });

  testWidgets('pendant le chargement : pas d\'écran d\'échec', (tester) async {
    final pending = Completer<AppUser?>();
    h.loader = () => pending.future;
    await tester.runAsync(() => h.emit(_session('a')));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: h.container,
        child: const MaterialApp(
          home: ProfileSyncFailureGate(child: Text('application')),
        ),
      ),
    );
    expect(find.text('application'), findsOneWidget);
    pending.complete(_profile('a'));
  });
}

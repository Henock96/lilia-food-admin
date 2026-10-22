import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/core/network/api_exception.dart';
import 'package:lilia_admin/core/network/network_observer.dart';
import 'package:lilia_admin/features/auth/application/session_guard.dart';

const _revoked = ApiException(
  'Compte suspendu.',
  statusCode: 403,
  kind: ApiErrorKind.client,
  code: 'ACCOUNT_REVOKED',
);
const _forbidden = ApiException(
  'Accès refusé.',
  statusCode: 403,
  kind: ApiErrorKind.client,
  code: 'FORBIDDEN',
);
const _expired = ApiException(
  'Non authentifié.',
  statusCode: 401,
  kind: ApiErrorKind.unauthorized,
);

class _RecordingObserver implements NetworkObserver {
  final errors = <ApiException>[];
  @override
  void onRequest(RequestSnapshot r) {}
  @override
  void onError(ApiException e, RequestSnapshot r) => errors.add(e);
}

void main() {
  group('sessionEndNoticeFor', () {
    test('403 ACCOUNT_REVOKED → compte suspendu', () {
      expect(sessionEndNoticeFor(_revoked), kSessionRevokedNotice);
    });
    test('401 persistant → session expirée', () {
      expect(sessionEndNoticeFor(_expired), kSessionExpiredNotice);
    });
    test('autre 403 → aucune déconnexion', () {
      expect(sessionEndNoticeFor(_forbidden), isNull);
    });
    test('erreur réseau ou non-API → aucune déconnexion', () {
      expect(
        sessionEndNoticeFor(
          const ApiException('Réseau', kind: ApiErrorKind.network),
        ),
        isNull,
      );
      expect(sessionEndNoticeFor(StateError('x')), isNull);
    });
  });

  group('SessionGuard', () {
    late int signOuts;
    late bool hasSession;
    late Completer<void> signOutGate;
    late ProviderContainer container;

    setUp(() {
      signOuts = 0;
      hasSession = true;
      signOutGate = Completer<void>()..complete();
      container = ProviderContainer(
        overrides: [
          hasFirebaseSessionProvider.overrideWithValue(() => hasSession),
          sessionSignOutProvider.overrideWithValue(() async {
            signOuts++;
            await signOutGate.future;
            hasSession = false;
            return true;
          }),
        ],
      );
    });

    tearDown(() => container.dispose());

    SessionGuard guard() => container.read(sessionGuardProvider.notifier);

    test('compte révoqué : déconnexion et motif pour l\'écran de connexion', () async {
      await guard().handle(_revoked);
      expect(signOuts, 1);
      expect(container.read(sessionEndNoticeProvider), kSessionRevokedNotice);
    });

    test('trois erreurs simultanées → une seule déconnexion', () async {
      signOutGate = Completer<void>();
      final calls = [
        guard().handle(_revoked),
        guard().handle(_revoked),
        guard().handle(_expired),
      ];
      signOutGate.complete();
      await Future.wait(calls);
      expect(signOuts, 1);
    });

    test('un 403 ordinaire ne déconnecte pas', () async {
      await guard().handle(_forbidden);
      expect(signOuts, 0);
      expect(container.read(sessionEndNoticeProvider), isNull);
    });

    test('sans session ouverte : rien à fermer, aucun message', () async {
      hasSession = false;
      await guard().handle(_revoked);
      expect(signOuts, 0);
      expect(container.read(sessionEndNoticeProvider), isNull);
    });

    test('la garde se réarme après la déconnexion', () async {
      await guard().handle(_revoked);
      hasSession = true; // reconnexion
      await guard().handle(_expired);
      expect(signOuts, 2);
      expect(container.read(sessionEndNoticeProvider), kSessionExpiredNotice);
    });
  });

  test('SessionAwareNetworkObserver relaie au délégué et à la garde', () async {
    var signOuts = 0;
    final container = ProviderContainer(
      overrides: [
        hasFirebaseSessionProvider.overrideWithValue(() => true),
        sessionSignOutProvider.overrideWithValue(() async {
          signOuts++;
          return true;
        }),
      ],
    );
    addTearDown(container.dispose);
    final delegate = _RecordingObserver();
    final observer = SessionAwareNetworkObserver(
      delegate,
      container.read(sessionGuardProvider.notifier),
    );

    observer.onError(
      _revoked,
      const RequestSnapshot(method: 'GET', path: '/orders/restaurant'),
    );
    await Future<void>.delayed(Duration.zero);

    expect(delegate.errors, [_revoked]);
    expect(signOuts, 1);
  });
}

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/features/home/application/notification_permission.dart';
import 'package:lilia_admin/features/home/presentation/widgets/notification_permission_banner.dart';

/// Audit du 28/10/2026 (F-03) — une permission refusée se voit.
void main() {
  group('permissionFromStatus', () {
    test('autorisée ou provisoire : accordée', () {
      expect(permissionFromStatus(AuthorizationStatus.authorized),
          NotificationPermission.granted);
      expect(permissionFromStatus(AuthorizationStatus.provisional),
          NotificationPermission.granted);
    });
    test('refusée et jamais demandée sont distinguées', () {
      expect(permissionFromStatus(AuthorizationStatus.denied),
          NotificationPermission.denied);
      expect(permissionFromStatus(AuthorizationStatus.notDetermined),
          NotificationPermission.notDetermined);
    });
  });

  group('shouldWarnAboutNotifications', () {
    test('avertit quand l’app ne peut pas notifier', () {
      expect(
          shouldWarnAboutNotifications(NotificationPermission.denied), isTrue);
      expect(shouldWarnAboutNotifications(NotificationPermission.notDetermined),
          isTrue);
    });
    test('se tait quand tout va bien ou quand on ne sait pas', () {
      expect(shouldWarnAboutNotifications(NotificationPermission.granted),
          isFalse);
      expect(shouldWarnAboutNotifications(NotificationPermission.unknown),
          isFalse);
    });
  });

  testWidgets('le bandeau dit le risque et propose d’activer', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: NotificationPermissionWarning(onEnable: () => tapped++),
      ),
    ));
    expect(find.textContaining('Notifications désactivées'), findsOneWidget);
    await tester.tap(find.text('Activer'));
    expect(tapped, 1);
  });
}

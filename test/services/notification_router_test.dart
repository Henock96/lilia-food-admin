import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/services/notification_router.dart';

void main() {
  const router = NotificationRouter();

  NotificationAction onTap(Map<String, dynamic> data) =>
      router.resolve(data, trigger: NotificationTrigger.tap);

  NotificationAction inForeground(Map<String, dynamic> data) =>
      router.resolve(data, trigger: NotificationTrigger.foreground);

  group('incidents', () {
    test('un tap ouvre le détail de l\'incident', () {
      final action = onTap({'type': 'incident', 'incidentId': 'inc-1'});

      expect(action.refresh, NotificationTarget.incidents);
      expect(
        action.route,
        const NotificationRoute('incident-detail', pathParameters: {'id': 'inc-1'}),
      );
    });

    // Régression : `_handleNotificationData` était appelé aussi depuis
    // `onMessage`, donc un incident reçu pendant que le vendeur remplissait un
    // formulaire le projetait sur l'écran de détail sans qu'il ait rien touché.
    test('en foreground, rafraîchit sans naviguer', () {
      final action = inForeground({'type': 'incident', 'incidentId': 'inc-1'});

      expect(action.refresh, NotificationTarget.incidents);
      expect(action.route, isNull);
    });

    test('un incident sans incidentId ne déclenche rien', () {
      expect(onTap({'type': 'incident'}), NotificationAction.none);
      expect(onTap({'type': 'incident', 'incidentId': ''}),
          NotificationAction.none);
    });
  });

  group('vendeurs', () {
    // Le backend envoie ce type à tous les admins (vendors.listener.ts), mais
    // l'app ne le traitait pas : le badge « à valider » restait périmé.
    test('un vendeur à valider rafraîchit la liste des vendeurs en attente',
        () {
      final action =
          inForeground({'type': 'vendor_pending_approval', 'vendorId': 'v-1'});

      expect(action.refresh, NotificationTarget.pendingVendors);
    });

    test('un tap sur un vendeur à valider ouvre l\'écran des vendeurs', () {
      final action =
          onTap({'type': 'vendor_pending_approval', 'vendorId': 'v-1'});

      expect(action.route, const NotificationRoute('admin-vendors'));
    });

    test('une boutique approuvée rafraîchit le profil du vendeur', () {
      final action = inForeground({'type': 'vendor_approved', 'vendorId': 'v-1'});

      expect(action.refresh, NotificationTarget.vendorProfile);
      expect(action.route, isNull);
    });
  });

  group('commandes', () {
    test('une nouvelle commande rafraîchit la liste', () {
      final action =
          inForeground({'type': 'new_order', 'orderId': 'ord-1'});

      expect(action.refresh, NotificationTarget.orders);
    });

    test('un changement de statut rafraîchit la liste', () {
      final action = inForeground(
          {'type': 'status_update_restaurant', 'orderId': 'ord-1'});

      expect(action.refresh, NotificationTarget.orders);
    });

    // Le rappel J-1 (preorder-reminder.service.ts) ne porte pas d'orderId :
    // il tombait donc dans le trou et la liste restait périmée.
    test('le rappel de pré-commande rafraîchit la liste', () {
      final action = inForeground({'type': 'preorder_reminder'});

      expect(action.refresh, NotificationTarget.orders);
    });
  });

  group('messages non reconnus', () {
    test('un payload vide ne déclenche rien', () {
      expect(inForeground({}), NotificationAction.none);
    });

    test('un type inconnu sans orderId ne déclenche rien', () {
      expect(inForeground({'type': 'quelque_chose'}), NotificationAction.none);
    });
  });
}

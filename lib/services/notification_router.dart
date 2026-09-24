/// D'où vient le message FCM en cours de traitement.
///
/// La distinction est ce qui empêche une notification reçue **pendant** que le
/// vendeur travaille de le projeter ailleurs dans l'app : seul un tap explicite
/// autorise une navigation.
enum NotificationTrigger { foreground, tap }

/// Ce qu'il faut rafraîchir à réception.
enum NotificationTarget { orders, incidents, pendingVendors, vendorProfile }

/// Destination go_router associée à une notification.
class NotificationRoute {
  const NotificationRoute(this.name, {this.pathParameters = const {}});

  final String name;
  final Map<String, String> pathParameters;

  @override
  bool operator ==(Object other) =>
      other is NotificationRoute &&
      other.name == name &&
      _sameParams(other.pathParameters, pathParameters);

  static bool _sameParams(Map<String, String> a, Map<String, String> b) =>
      a.length == b.length && a.keys.every((k) => a[k] == b[k]);

  @override
  int get hashCode => Object.hash(
        name,
        Object.hashAllUnordered(
          pathParameters.entries.map((e) => Object.hash(e.key, e.value)),
        ),
      );

  @override
  String toString() => 'NotificationRoute($name, $pathParameters)';
}

/// Ce que l'app doit faire en réponse à un message FCM.
class NotificationAction {
  const NotificationAction({this.refresh, this.route, this.alertOrderId});

  /// Provider à invalider, `null` si rien à recharger.
  final NotificationTarget? refresh;

  /// Écran à ouvrir, `null` hors d'un tap explicite.
  final NotificationRoute? route;

  /// Commande payée à signaler en plein écran, avec sonnerie répétée jusqu'à
  /// ce que le vendeur s'en occupe (F3-01). Seulement en premier plan : en
  /// arrière-plan le système joue le son du canal `new_orders_channel`.
  final String? alertOrderId;

  static const none = NotificationAction();

  @override
  bool operator ==(Object other) =>
      other is NotificationAction &&
      other.refresh == refresh &&
      other.route == route &&
      other.alertOrderId == alertOrderId;

  @override
  int get hashCode => Object.hash(refresh, route, alertOrderId);

  @override
  String toString() =>
      'NotificationAction(refresh: $refresh, route: $route, alert: $alertOrderId)';
}

/// Traduit le payload `data` d'un push FCM en action applicative.
///
/// Volontairement pur : aucune dépendance à Firebase, Riverpod ou go_router,
/// pour que la table de correspondance avec les types émis par le backend
/// (`orders.listener.ts`, `vendors.listener.ts`,
/// `incidents-notification.listener.ts`, `preorder-reminder.service.ts`) soit
/// vérifiable directement.
class NotificationRouter {
  const NotificationRouter();

  NotificationAction resolve(
    Map<String, dynamic> data, {
    required NotificationTrigger trigger,
  }) {
    final type = data['type'] as String?;
    final isTap = trigger == NotificationTrigger.tap;

    switch (type) {
      case 'incident':
        final incidentId = data['incidentId'] as String?;
        // Un incident sans identifiant n'est pas exploitable : ni détail à
        // ouvrir, ni certitude que la liste ait changé.
        if (incidentId == null || incidentId.isEmpty) {
          return NotificationAction.none;
        }
        return NotificationAction(
          refresh: NotificationTarget.incidents,
          route: isTap
              ? NotificationRoute(
                  'incident-detail',
                  pathParameters: {'id': incidentId},
                )
              : null,
        );

      case 'vendor_pending_approval':
        return NotificationAction(
          refresh: NotificationTarget.pendingVendors,
          route: isTap ? const NotificationRoute('admin-vendors') : null,
        );

      case 'vendor_approved':
        // Reçu par le vendeur lui-même : son `adminApproved` vient de passer à
        // true, son profil en cache est périmé.
        return const NotificationAction(
          refresh: NotificationTarget.vendorProfile,
        );

      case 'new_order':
        final newOrderId = data['orderId'] as String?;
        if (newOrderId == null || newOrderId.isEmpty) {
          return const NotificationAction(refresh: NotificationTarget.orders);
        }
        return NotificationAction(
          refresh: NotificationTarget.orders,
          // Touchée : le vendeur l'a vue, on ouvre la commande. Reçue en
          // premier plan : elle doit se faire entendre.
          route: isTap
              ? NotificationRoute(
                  'order-detail',
                  pathParameters: {'id': newOrderId},
                )
              : null,
          alertOrderId: isTap ? null : newOrderId,
        );

      case 'preorder_reminder':
        // Le rappel J-1 ne porte pas d'orderId, mais concerne bien des
        // commandes programmées à afficher.
        return const NotificationAction(refresh: NotificationTarget.orders);
    }

    // Tous les autres messages liés à une commande (`new_order`,
    // `status_update_restaurant`, `order_cancelled_restaurant`…) sont
    // reconnus à la présence de l'orderId plutôt qu'à une liste de types
    // figée, pour ne pas rater un nouveau type côté backend.
    final orderId = data['orderId'] as String?;
    if (orderId != null && orderId.isNotEmpty) {
      return const NotificationAction(refresh: NotificationTarget.orders);
    }

    return NotificationAction.none;
  }
}

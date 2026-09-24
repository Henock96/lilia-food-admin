import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/features/home/presentation/widgets/order_actions_panel.dart';
import 'package:lilia_admin/models/order.dart';
import 'package:lilia_admin/models/order_actions.dart';
import 'package:lilia_admin/models/role.dart';
import 'package:lilia_admin/models/vendor_rejection_reason.dart';

/// Panneau des gestes sur une commande (Phase 3, F3-01).
///
/// Il n'affiche QUE ce que le serveur publie (`allowedActions`), et il
/// recueille ce que chaque geste exige avant de partir : un temps de
/// préparation pour accepter, un motif pour refuser, une confirmation pour
/// annuler. Le panneau ne parle pas au réseau — il rend une demande.
Order _order(List<String> actions, {String status = 'PAYER'}) => Order.fromJson({
      'id': 'o-1',
      'total': 6750,
      'createdAt': '2026-09-24T12:00:00.000Z',
      'status': status,
      'isDelivery': true,
      'items': [],
      'allowedActions': actions,
    });

void main() {
  late List<OrderActionRequest> requests;

  Future<void> pump(WidgetTester tester, Order order) async {
    requests = [];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: OrderActionsPanel(
              order: order,
              role: Role.restaurateur,
              onAction: (request) async => requests.add(request),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('n’affiche que les gestes publiés par le serveur', (tester) async {
    await pump(tester, _order(['ACCEPT', 'REJECT']));

    expect(find.text('Accepter'), findsOneWidget);
    expect(find.text('Refuser'), findsOneWidget);
    expect(find.text('En préparation'), findsNothing);
  });

  testWidgets('aucun geste publié : rien à afficher', (tester) async {
    await pump(tester, _order([], status: 'LIVRER'));

    expect(find.byType(ElevatedButton), findsNothing);
  });

  testWidgets('Accepter demande un temps de préparation, puis l’envoie', (tester) async {
    await pump(tester, _order(['ACCEPT', 'REJECT']));

    await tester.tap(find.text('Accepter'));
    await tester.pumpAndSettle();
    expect(find.text('Temps de préparation'), findsOneWidget);

    await tester.tap(find.text('30 min'));
    await tester.tap(find.text('Accepter la commande'));
    await tester.pumpAndSettle();

    expect(requests.single.action, OrderAction.accept);
    expect(requests.single.prepMinutes, 30);
  });

  testWidgets('Accepter puis renoncer : rien ne part', (tester) async {
    await pump(tester, _order(['ACCEPT']));

    await tester.tap(find.text('Accepter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retour'));
    await tester.pumpAndSettle();

    expect(requests, isEmpty);
  });

  testWidgets('Refuser exige un motif avant d’envoyer', (tester) async {
    await pump(tester, _order(['ACCEPT', 'REJECT']));

    await tester.tap(find.text('Refuser'));
    await tester.pumpAndSettle();

    // Sans motif, le bouton de confirmation est désactivé.
    final confirm = find.widgetWithText(FilledButton, 'Refuser la commande');
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

    await tester.tap(find.text(VendorRejectionReason.outOfStock.label));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Plus de poulet');
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(requests.single.action, OrderAction.reject);
    expect(requests.single.reason, VendorRejectionReason.outOfStock);
    expect(requests.single.note, 'Plus de poulet');
  });

  testWidgets('Annuler demande confirmation', (tester) async {
    await pump(tester, _order(['CANCEL'], status: 'EN_PREPARATION'));

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oui, annuler'));
    await tester.pumpAndSettle();

    expect(requests.single.action, OrderAction.cancel);
  });

  testWidgets('un geste simple part sans boîte de dialogue', (tester) async {
    await pump(tester, _order(['MARK_READY', 'CANCEL'], status: 'EN_PREPARATION'));

    await tester.tap(find.text('Prête'));
    await tester.pumpAndSettle();

    expect(requests.single.action, OrderAction.markReady);
  });
}

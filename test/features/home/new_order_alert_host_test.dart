import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/features/home/application/new_order_alerts.dart';
import 'package:lilia_admin/features/home/presentation/widgets/new_order_alert_host.dart';

/// Alerte plein écran « nouvelle commande » (sonnerie vendeur, F3-01).
void main() {
  late List<String> silenced;
  late ProviderContainer container;

  Future<void> pump(WidgetTester tester) async {
    silenced = [];
    container = ProviderContainer(
      overrides: [
        alertSilencerProvider.overrideWithValue((id) async => silenced.add(id)),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          builder: (context, child) => NewOrderAlertHost(child: child!),
          home: const Scaffold(body: Text('écran courant')),
        ),
      ),
    );
  }

  testWidgets('rien à signaler : l’écran courant seul', (tester) async {
    await pump(tester);

    expect(find.text('écran courant'), findsOneWidget);
    expect(find.text('Nouvelle commande à accepter'), findsNothing);
  });

  testWidgets('une commande payée : alerte plein écran avec sa référence', (tester) async {
    await pump(tester);
    container.read(newOrderAlertsProvider.notifier).raise('cmd-abc123');
    await tester.pump();

    expect(find.text('Nouvelle commande à accepter'), findsOneWidget);
    expect(find.text('Commande #ABC123'), findsOneWidget);
  });

  testWidgets('plusieurs commandes : indique combien d’autres attendent', (tester) async {
    await pump(tester);
    container.read(newOrderAlertsProvider.notifier)
      ..raise('o1')
      ..raise('o2')
      ..raise('o3');
    await tester.pump();

    expect(find.text('+ 2 autres commandes en attente'), findsOneWidget);
  });

  testWidgets('« Plus tard » ferme l’alerte et coupe la sonnerie', (tester) async {
    await pump(tester);
    container.read(newOrderAlertsProvider.notifier).raise('o1');
    await tester.pump();

    await tester.tap(find.text('Plus tard'));
    await tester.pumpAndSettle();

    expect(find.text('Nouvelle commande à accepter'), findsNothing);
    expect(silenced, ['o1']);
  });
}

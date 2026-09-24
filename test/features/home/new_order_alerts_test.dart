import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/features/home/application/new_order_alerts.dart';

/// File des alertes « nouvelle commande » (sonnerie vendeur, F3-01).
///
/// Trois commandes payées d'affilée = trois alertes successives ; la même
/// commande notifiée deux fois (push immédiat + relance outbox) = une seule.
void main() {
  late ProviderContainer container;
  late List<String> silenced;

  setUp(() {
    silenced = [];
    container = ProviderContainer(
      overrides: [
        alertSilencerProvider.overrideWithValue((orderId) async => silenced.add(orderId)),
      ],
    );
  });
  tearDown(() => container.dispose());

  NewOrderAlerts notifier() => container.read(newOrderAlertsProvider.notifier);
  List<String> queue() => container.read(newOrderAlertsProvider);

  test('une commande signalée entre dans la file', () {
    notifier().raise('o1');
    expect(queue(), ['o1']);
  });

  test('la même commande signalée deux fois ne sonne qu’une fois', () {
    notifier()
      ..raise('o1')
      ..raise('o1');
    expect(queue(), ['o1']);
  });

  test('plusieurs commandes : l’ordre d’arrivée est conservé', () {
    notifier()
      ..raise('o1')
      ..raise('o2');
    expect(queue(), ['o1', 'o2']);
  });

  test('traiter une alerte la retire ET coupe sa sonnerie', () async {
    notifier()
      ..raise('o1')
      ..raise('o2');

    await notifier().dismiss('o1');

    expect(queue(), ['o2']);
    expect(silenced, ['o1']);
  });

  test('une commande déjà traitée ne revient pas avec la relance suivante', () async {
    notifier().raise('o1');
    await notifier().dismiss('o1');

    notifier().raise('o1');

    expect(queue(), isEmpty);
  });
}

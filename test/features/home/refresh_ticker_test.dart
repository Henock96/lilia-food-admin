import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/features/home/presentation/refresh_ticker.dart';

/// Lot 2 (ADM-04, décision D-4) — l'ADMIN ne voyait pas arriver les nouvelles
/// commandes : aucun polling, aucune relecture au retour au premier plan. Le
/// rythme est de 30 s, et il s'arrête quand l'app n'est plus à l'écran
/// (batterie, données mobiles).
void main() {
  testWidgets('un tick toutes les 30 s, pas avant', (tester) async {
    var ticks = 0;
    final ticker = RefreshTicker(onTick: () => ticks++)..start();

    await tester.pump(const Duration(seconds: 29));
    expect(ticks, 0);
    await tester.pump(const Duration(seconds: 1));
    expect(ticks, 1);
    await tester.pump(const Duration(seconds: 60));
    expect(ticks, 3);
    ticker.stop();
  });

  testWidgets('arrière-plan : plus aucun tick', (tester) async {
    var ticks = 0;
    final ticker = RefreshTicker(onTick: () => ticks++)..start();

    ticker.handleLifecycle(AppLifecycleState.paused);
    await tester.pump(const Duration(minutes: 5));

    expect(ticks, 0);
    expect(ticker.isRunning, isFalse);
  });

  testWidgets(
    'retour au premier plan : relecture immédiate, puis le rythme reprend',
    (tester) async {
      var ticks = 0;
      final ticker = RefreshTicker(onTick: () => ticks++)..start();

      ticker.handleLifecycle(AppLifecycleState.paused);
      ticker.handleLifecycle(AppLifecycleState.resumed);
      expect(ticks, 1);

      await tester.pump(const Duration(seconds: 30));
      expect(ticks, 2);
      ticker.stop();
    },
  );

  testWidgets('démarrer deux fois ne double pas le rythme', (tester) async {
    var ticks = 0;
    final ticker = RefreshTicker(onTick: () => ticks++)
      ..start()
      ..start();

    await tester.pump(const Duration(seconds: 30));
    expect(ticks, 1);
    ticker.stop();
  });
}

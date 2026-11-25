import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Fiche réservation → « voir la commande » (constaté le 23/11/2026, iOS) :
/// `navigator.dart: failed assertion: !keyReservation.contains(key)`.
///
/// La fiche réservation est déclarée **hors** des onglets (`/reservations/:id`)
/// alors que `order-detail` vit **dans** la `StatefulShellRoute`. Empiler
/// `order-detail` depuis la réservation reconstruit une seconde coquille
/// d'onglets portant la même clé que celle déjà dans la pile.
///
/// Le routeur reprend la forme de `app_router.dart`, écrans factices.
Widget _page(String title, {VoidCallback? onTap}) => Scaffold(
  appBar: AppBar(title: Text(title)),
  body: onTap == null
      ? const SizedBox()
      : TextButton(onPressed: onTap, child: const Text('voir la commande')),
);

GoRouter _router(String orderRouteName) => GoRouter(
  initialLocation: '/commandes',
  routes: [
    GoRoute(
      path: '/reservations/:id',
      name: 'reservation-detail',
      builder: (context, state) => Builder(
        builder: (context) => _page(
          'réservation',
          onTap: () => context.pushNamed(
            orderRouteName,
            pathParameters: orderRouteName == 'order-detail'
                ? {'id': 'o1'}
                : {'id': 'r1', 'orderId': 'o1'},
          ),
        ),
      ),
      routes: [
        GoRoute(
          path: 'commande/:orderId',
          name: 'reservation-order',
          builder: (context, state) => _page('commande liée'),
        ),
      ],
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => Scaffold(body: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/commandes',
              name: 'commandes',
              builder: (context, state) => Builder(
                builder: (context) => _page(
                  'commandes',
                  onTap: () => context.pushNamed(
                    'reservation-detail',
                    pathParameters: {'id': 'r1'},
                  ),
                ),
              ),
              routes: [
                GoRoute(
                  path: ':id',
                  name: 'order-detail',
                  builder: (context, state) => _page('fiche commande'),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

Future<void> _openReservationThenOrder(
  WidgetTester tester,
  GoRouter router,
) async {
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  await tester.tap(find.text('voir la commande')); // → réservation
  await tester.pumpAndSettle();
  await tester.tap(find.text('voir la commande')); // → commande liée
  await tester.pumpAndSettle();
}

// Reproduit le 23/11 avec `_router('order-detail')` : le Navigator lève
// `_dependents.isEmpty` sous test (`!keyReservation.contains(key)` sur
// iPhone) et laisse le framework de test corrompu pour les tests suivants —
// d'où l'absence de ce cas dans la suite.
void main() {
  testWidgets('la commande liée s’ouvre sous la réservation, et le retour y '
      'ramène', (tester) async {
    final router = _router('reservation-order');
    await _openReservationThenOrder(tester, router);
    expect(tester.takeException(), isNull);
    expect(find.text('commande liée'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('réservation'), findsOneWidget);
  });
}

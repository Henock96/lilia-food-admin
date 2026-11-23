import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/features/home/data/order_controller.dart';
import 'package:lilia_admin/features/home/presentation/screens/order_by_id_screen.dart';
import 'package:lilia_admin/models/order.dart';

/// « Voir la commande » depuis l'alerte : la fiche est relue par son id
/// (22/11/2026). Riverpod 3 relance un fournisseur en échec et le repasse en
/// chargement entre deux tentatives : un `when` y montrait le spinner une
/// quarantaine de secondes, sans retour possible.
void main() {
  Widget host(Future<Order> Function() load) => ProviderScope(
    overrides: [staffOrderProvider('o-1').overrideWith((ref) => load())],
    child: const MaterialApp(home: OrderByIdScreen(orderId: 'o-1')),
  );

  testWidgets('refus (403, 404) : l’erreur, pas le spinner des relances', (
    tester,
  ) async {
    await tester.pumpWidget(host(() => Future.error(Exception('403'))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Impossible de charger cette commande.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Voir les commandes'), findsOneWidget);

    // Le minuteur de relance survit au test sinon.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 1));
  });

  testWidgets('chargement : une barre avec retour, personne n’est bloqué', (
    tester,
  ) async {
    final pending = Completer<Order>();
    await tester.pumpWidget(host(() => pending.future));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });
}

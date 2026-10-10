import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/features/admin/presentation/screens/create_restaurant_screen.dart';
import 'package:lilia_admin/models/vendor_type.dart';

/// Types proposés à la création d'un vendeur (`POST /admin/vendors`).
///
/// Né en G0 pour caractériser F-01 (GROCERY accepté par le serveur, absent de
/// l'écran) ; réécrit avec le lot G1. Le serveur accepte les cinq types : un
/// type absent ici est un type que personne ne peut créer.
void main() {
  testWidgets('les cinq types sont proposés, épicerie comprise', (tester) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: CreateRestaurantScreen()),
      ),
    );
    await tester.pump();

    final offered = tester
        .widgetList<RadioListTile<VendorType>>(
          find.byWidgetPredicate((w) => w is RadioListTile<VendorType>),
        )
        .map((tile) => tile.value)
        .toList();

    expect(offered, VendorType.values);
    expect(find.textContaining('Épicerie'), findsOneWidget);
  });
}

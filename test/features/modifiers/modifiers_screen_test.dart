import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/features/catalog/catalog_scope.dart';
import 'package:lilia_admin/features/modifiers/presentation/providers/modifiers_provider.dart';
import 'package:lilia_admin/features/modifiers/presentation/screens/modifiers_screen.dart';
import 'package:lilia_admin/models/modifier_group.dart';

/// F3-09 — l'écran « Options » est réellement rendu (et pas seulement compilé).
class _FakeModifiers extends Modifiers {
  _FakeModifiers(this.library);
  final ModifierLibrary library;
  final List<(String, bool)> availability = [];

  @override
  Future<ModifierLibrary> build() async => library;

  @override
  Future<void> setOptionAvailability(String optionId, bool isAvailable) async {
    availability.add((optionId, isAvailable));
  }
}

const _library = ModifierLibrary(
  modifiersEnabled: true,
  managementEnabled: true,
  groups: [
    ModifierGroup(
      id: 'g-acc',
      name: 'Accompagnement',
      minSelect: 1,
      maxSelect: 1,
      options: [
        ModifierOption(id: 'o1', name: 'Alloco', priceDeltaXaf: 500),
        ModifierOption(id: 'o2', name: 'Riz', isAvailable: false),
      ],
      products: [ModifierProductRef(id: 'p1', name: 'Poulet braisé')],
    ),
  ],
);

Future<_FakeModifiers> _pump(WidgetTester tester, ModifierLibrary library) async {
  final fake = _FakeModifiers(library);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        modifiersProvider.overrideWith(() => fake),
        // RESTAURATEUR : pas de sélecteur de vendeur.
        isCatalogAdminProvider.overrideWithValue(false),
      ],
      child: const MaterialApp(home: ModifiersScreen()),
    ),
  );
  // Chargement puis fin de l'animation du bouton flottant.
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  return fake;
}

void main() {
  testWidgets('groupes, règle, produits et options (rupture visible)', (tester) async {
    await _pump(tester, _library);
    expect(find.text('Accompagnement'), findsOneWidget);
    expect(find.textContaining('Obligatoire · 1 choix · Poulet braisé'), findsOneWidget);
    expect(find.text('Alloco +500'), findsOneWidget);
    expect(find.text('Riz · épuisé'), findsOneWidget);
    expect(find.text('Nouveau groupe'), findsOneWidget);
  });

  testWidgets('toucher une option la met en rupture', (tester) async {
    final fake = await _pump(tester, _library);
    await tester.tap(find.byKey(const ValueKey('option-o1')));
    await tester.pump();
    expect(fake.availability, [('o1', false)]);
  });

  testWidgets('éditeur fermé : lecture seule, et on le dit', (tester) async {
    await _pump(
      tester,
      const ModifierLibrary(
        modifiersEnabled: false,
        managementEnabled: false,
        groups: [],
      ),
    );
    expect(find.textContaining('ouvrira dès que les applications clientes'), findsOneWidget);
    expect(find.textContaining('pas encore proposées aux clients'), findsOneWidget);
    expect(find.text('Nouveau groupe'), findsNothing);
  });
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/features/admin/data/admin_vendors_service.dart';
import 'package:lilia_admin/features/catalog/catalog_scope.dart';
import 'package:lilia_admin/features/categories/presentation/providers/categories_provider.dart';
import 'package:lilia_admin/features/products/presentation/providers/products_provider.dart';
import 'package:lilia_admin/features/products/presentation/screens/product_form_screen.dart';
import 'package:lilia_admin/features/settings/presentation/providers/settings_provider.dart';
import 'package:lilia_admin/models/product.dart';
import 'package:lilia_admin/models/product_type.dart';
import 'package:lilia_admin/models/restaurant.dart';
import 'package:lilia_admin/models/stock_policy.dart';
import 'package:lilia_admin/models/vendor_type.dart';

/// Type de produit et disponibilité par défaut, selon le vendeur **ciblé**.
///
/// Né en G0 comme test de caractérisation du défaut F-18 (FOOD figé avant le
/// chargement de la boutique, boutique de l'appelant au lieu de la boutique
/// ciblée par un ADMIN) ; réécrit avec son correctif (lot G2).
class _FakeSettings extends RestaurantSettings {
  _FakeSettings(this._load);
  final Future<Restaurant> Function() _load;

  @override
  Future<Restaurant> build() => _load();
}

class _NoCategories extends Categories {
  @override
  Future<List<Category>> build() async => const [];
}

class _Scope extends CatalogScope {
  _Scope(this._id);
  final String? _id;

  @override
  String? build() => _id;
}

Restaurant _shop(VendorType type, {String id = 'g1'}) => Restaurant(
      id: id,
      name: 'Boutique $id',
      address: 'Moungali',
      ownerId: 'o1',
      vendorType: type,
    );

List<Override> _vendor(Future<Restaurant> Function() settings) => [
      restaurantSettingsProvider.overrideWith(() => _FakeSettings(settings)),
      isCatalogAdminProvider.overrideWithValue(false),
      categoriesProvider.overrideWith(_NoCategories.new),
      multiUnitVariantsEnabledProvider.overrideWith((ref) async => false),
    ];

List<Override> _admin({required String target, required List<Restaurant> vendors}) => [
      // L'ADMIN n'a pas de boutique : /restaurants/mine échoue.
      restaurantSettingsProvider
          .overrideWith(() => _FakeSettings(() async => throw Exception('404'))),
      isCatalogAdminProvider.overrideWithValue(true),
      catalogScopeProvider.overrideWith(() => _Scope(target)),
      catalogSelectableVendorsProvider.overrideWith(
        (ref) async => [for (final r in vendors) AdminVendorItem(restaurant: r)],
      ),
      categoriesProvider.overrideWith(_NoCategories.new),
      multiUnitVariantsEnabledProvider.overrideWith((ref) async => false),
    ];

ProductType? _selectedType(WidgetTester tester) => tester
    .state<FormFieldState<ProductType>>(
      find.byWidgetPredicate((w) => w is DropdownButtonFormField<ProductType>),
    )
    .value;

Set<StockPolicy> _selectedPolicy(WidgetTester tester) => tester
    .widget<SegmentedButton<StockPolicy>>(
      find.byWidgetPredicate((w) => w is SegmentedButton<StockPolicy>),
    )
    .selected;

bool _canSave(WidgetTester tester) => tester
        .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Créer le produit'))
        .onPressed !=
    null;

Future<void> _pump(WidgetTester tester, List<Override> overrides) async {
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: const MaterialApp(home: ProductFormScreen()),
    ),
  );
}

void main() {
  testWidgets(
    'vendeur épicerie, boutique encore en chargement : rien n’est choisi ni enregistrable, '
    'puis « Épicerie » et « Stock réel » à l’arrivée du type',
    (tester) async {
      final settings = Completer<Restaurant>();
      await _pump(tester, _vendor(() => settings.future));

      expect(_selectedType(tester), isNull);
      expect(_canSave(tester), isFalse);

      settings.complete(_shop(VendorType.GROCERY));
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(_selectedType(tester), ProductType.GROCERY);
      expect(_selectedPolicy(tester), {StockPolicy.INVENTORY});
      expect(_canSave(tester), isTrue);
    },
  );

  testWidgets(
    'ADMIN ciblant une épicerie : les types de l’épicerie, pas ceux de sa propre boutique',
    (tester) async {
      await _pump(
        tester,
        _admin(target: 'g1', vendors: [
          _shop(VendorType.RESTAURANT, id: 'r1'),
          _shop(VendorType.GROCERY, id: 'g1'),
        ]),
      );
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(_selectedType(tester), ProductType.GROCERY);
      expect(find.text('Épicerie'), findsOneWidget);
      expect(_canSave(tester), isTrue);
    },
  );

  testWidgets(
    'ADMIN qui change de vendeur ciblé : le type d’un produit neuf suit le nouveau vendeur',
    (tester) async {
      await _pump(
        tester,
        _admin(target: 'g1', vendors: [
          _shop(VendorType.GROCERY, id: 'g1'),
          _shop(VendorType.RESTAURANT, id: 'r1'),
        ]),
      );
      await tester.pump();
      await tester.pump();
      expect(_selectedType(tester), ProductType.GROCERY);

      ProviderScope.containerOf(tester.element(find.byType(ProductFormScreen)))
          .read(catalogScopeProvider.notifier)
          .select('r1');
      await tester.pump();
      await tester.pump();

      // L'épicerie quittée ne laisse pas « Épicerie » sur un restaurant.
      expect(tester.takeException(), isNull);
      expect(_selectedType(tester), ProductType.FOOD);
      expect(find.text('Épicerie'), findsNothing);
    },
  );

  testWidgets(
    'ADMIN sans vendeur ciblé : enregistrement impossible, aucun type deviné',
    (tester) async {
      await _pump(
        tester,
        _admin(target: 'absent', vendors: [_shop(VendorType.GROCERY)]),
      );
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(_selectedType(tester), isNull);
      expect(_canSave(tester), isFalse);
    },
  );

  testWidgets(
    'non-régression restaurant : « Plat » et « Toujours disponible »',
    (tester) async {
      await _pump(tester, _vendor(() async => _shop(VendorType.RESTAURANT)));
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(_selectedType(tester), ProductType.FOOD);
      expect(_selectedPolicy(tester), {StockPolicy.UNLIMITED});
      expect(_canSave(tester), isTrue);
    },
  );

  testWidgets(
    'boutique de boissons : « Boisson » pré-sélectionné (le défaut FOOD y était refusé)',
    (tester) async {
      await _pump(tester, _vendor(() async => _shop(VendorType.BEVERAGE_SHOP)));
      await tester.pump();
      await tester.pump();

      expect(_selectedType(tester), ProductType.BEVERAGE);
    },
  );
}

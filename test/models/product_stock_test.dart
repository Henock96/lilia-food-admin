import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/models/product.dart';
import 'package:lilia_admin/models/stock_mode.dart';
import 'package:lilia_admin/models/stock_policy.dart';
import 'package:lilia_admin/models/stock_unit.dart';

/// F3-10 — formats multi-unités et politique de stock, côté app vendeurs.
void main() {
  group('ProductVariant.toJson', () {
    test('envoie l’identifiant du format (lot 0 : sans lui, chaque '
        'enregistrement recréait les formats et vidait les paniers)', () {
      final json = ProductVariant(
        id: 'v-c6',
        label: 'Carton de 6',
        prix: 70000,
        stockConsumption: 6,
      ).toJson();
      expect(json, {
        'id': 'v-c6',
        'label': 'Carton de 6',
        'prix': 70000.0,
        'stockConsumption': 6,
      });
    });

    test('un format neuf n’a pas d’identifiant', () {
      final json = ProductVariant(label: 'Bouteille', prix: 13000).toJson();
      expect(json.containsKey('id'), isFalse);
      expect(json['stockConsumption'], 1);
    });

    test('lit la consommation et le verdict du serveur', () {
      final v = ProductVariant.fromJson({
        'id': 'v',
        'label': 'Carton de 6',
        'prix': 70000,
        'stockConsumption': 6,
        'availableQuantity': 0,
        'stockStatus': 'OUT_OF_STOCK',
      });
      expect(v.stockConsumption, 6);
      expect(v.availableQuantity, 0);
      expect(v.isPersisted, isTrue);
    });

    test('serveur antérieur à F3-10 : consommation 1', () {
      expect(
        ProductVariant.fromJson({'id': 'v', 'prix': 1}).stockConsumption,
        1,
      );
    });
  });

  group('StockPolicy', () {
    test('lue telle quelle quand le serveur l’envoie', () {
      expect(StockPolicy.fromJson('INVENTORY'), StockPolicy.INVENTORY);
    });

    test('déduite de l’ancien contrat, comme la migration', () {
      expect(
        StockPolicy.fromJson(null, stockRestant: null),
        StockPolicy.UNLIMITED,
      );
      expect(
        StockPolicy.fromJson(null, stockMode: 'DAILY', stockRestant: 3),
        StockPolicy.DAILY_QUOTA,
      );
      expect(
        StockPolicy.fromJson(null, stockMode: 'PERMANENT', stockRestant: 3),
        StockPolicy.INVENTORY,
      );
    });

    test('stockMode envoyé en double pour un serveur antérieur', () {
      expect(StockPolicy.INVENTORY.legacyMode, StockMode.PERMANENT);
      expect(StockPolicy.DAILY_QUOTA.legacyMode, StockMode.DAILY);
    });
  });

  test('StockUnit dit le nombre dans l’unité', () {
    expect(StockUnit.BOTTLE.format(6), '6 bouteilles');
    expect(StockUnit.PORTION.format(1), '1 portion');
  });

  test('Product lit politique et unité', () {
    final p = Product.fromJson({
      'id': 'vin',
      'nom': 'Vin',
      'prixOriginal': 13000,
      'restaurantId': 'r',
      'stockPolicy': 'INVENTORY',
      'stockUnit': 'BOTTLE',
      'stockRestant': 52,
      'variants': [],
    });
    expect(p.stockPolicy, StockPolicy.INVENTORY);
    expect(p.stockUnit, StockUnit.BOTTLE);
    expect(p.toJson()['stockMode'], 'PERMANENT');
  });
}

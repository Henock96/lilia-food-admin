// ignore_for_file: constant_identifier_names

import 'vendor_type.dart';

/// Types de produits sur la marketplace (cf. backend `ProductType`).
///
/// `ALCOHOL` existe dans l'enum DB mais est rejeté par le `ProductValidator`
/// backend depuis le pivot mai 2026 (lancement sans alcool).
enum ProductType {
  FOOD,
  BEVERAGE,
  ALCOHOL,
  PASTRY,
  GROCERY;

  String get label {
    switch (this) {
      case ProductType.FOOD:
        return 'Plat';
      case ProductType.BEVERAGE:
        return 'Boisson';
      case ProductType.ALCOHOL:
        return 'Alcool';
      case ProductType.PASTRY:
        return 'Pâtisserie';
      case ProductType.GROCERY:
        return 'Épicerie';
    }
  }

  static ProductType fromString(String? value) {
    return ProductType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ProductType.FOOD,
    );
  }
}

/// Matrice vendor↔product alignée sur `ProductValidatorService` backend.
/// ALCOHOL est toujours exclu (pivot lancement).
const Map<VendorType, List<ProductType>> kAllowedProductTypes = {
  VendorType.RESTAURANT: [ProductType.FOOD, ProductType.BEVERAGE],
  VendorType.HOME_COOK: [ProductType.FOOD, ProductType.PASTRY],
  VendorType.BAKERY: [ProductType.PASTRY, ProductType.BEVERAGE],
  VendorType.BEVERAGE_SHOP: [ProductType.BEVERAGE],
  VendorType.GROCERY: [ProductType.GROCERY, ProductType.BEVERAGE],
};

// ignore_for_file: constant_identifier_names

/// Types de vendeurs sur la marketplace Lilia (cf. backend `VendorType`).
///
/// `RESTAURANT` reste le comportement historique. Les autres types passent
/// par une validation admin (`adminApproved`) côté backend.
enum VendorType {
  RESTAURANT,
  HOME_COOK,
  BAKERY,
  BEVERAGE_SHOP,
  GROCERY;

  String get label {
    switch (this) {
      case VendorType.RESTAURANT:
        return 'Restaurant';
      case VendorType.HOME_COOK:
        return 'Vendeur maison';
      case VendorType.BAKERY:
        return 'Boulangerie';
      case VendorType.BEVERAGE_SHOP:
        return 'Boissons';
      case VendorType.GROCERY:
        return 'Épicerie';
    }
  }

  String get emoji {
    switch (this) {
      case VendorType.RESTAURANT:
        return '🍽️';
      case VendorType.HOME_COOK:
        return '🍲';
      case VendorType.BAKERY:
        return '🥐';
      case VendorType.BEVERAGE_SHOP:
        return '🥤';
      case VendorType.GROCERY:
        return '🛒';
    }
  }

  static VendorType fromString(String? value) {
    return VendorType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => VendorType.RESTAURANT,
    );
  }
}

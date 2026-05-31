import 'product_type.dart';
import 'stock_mode.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double prixOriginal;
  final String? imageUrl;
  final String restaurantId;
  final String? categoryId;
  final Category? category;
  final List<ProductVariant> variants;
  final int? stockQuotidien;
  final int? stockRestant;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // LIL-124 : marketplace + preorder fields
  final ProductType productType;
  final StockMode stockMode;
  final bool madeToOrder;
  final String? availableFrom;
  final String? availableUntil;
  final bool isActive;

  // LIL-130 : métadonnées fait maison / pâtisserie
  final String? ingredients;
  final int? shelfLifeDays;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.prixOriginal,
    this.imageUrl,
    required this.restaurantId,
    this.categoryId,
    this.category,
    required this.variants,
    this.stockQuotidien,
    this.stockRestant,
    this.createdAt,
    this.updatedAt,
    this.productType = ProductType.FOOD,
    this.stockMode = StockMode.DAILY,
    this.madeToOrder = false,
    this.availableFrom,
    this.availableUntil,
    this.isActive = true,
    this.ingredients,
    this.shelfLifeDays,
  });

  bool get isAvailable => stockRestant == null || stockRestant! > 0;

  factory Product.fromJson(Map<String, dynamic> json) {
    var variantsList = json['variants'] as List? ?? [];
    List<ProductVariant> variants =
        variantsList.map((i) => ProductVariant.fromJson(i as Map<String, dynamic>)).toList();

    return Product(
      id: json['id'] as String? ?? '',
      name: json['nom'] as String? ?? 'Produit inconnu',
      description: json['description'] as String? ?? '',
      prixOriginal: (json['prixOriginal'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl'] as String?,
      restaurantId: json['restaurantId'] as String? ?? '',
      categoryId: json['categoryId'] as String?,
      category:
          json['category'] != null ? Category.fromJson(json['category'] as Map<String, dynamic>) : null,
      variants: variants,
      stockQuotidien: json['stockQuotidien'] as int?,
      stockRestant: json['stockRestant'] as int?,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      productType: ProductType.fromString(json['productType'] as String?),
      stockMode: StockMode.fromString(json['stockMode'] as String?),
      madeToOrder: json['madeToOrder'] as bool? ?? false,
      availableFrom: json['availableFrom'] as String?,
      availableUntil: json['availableUntil'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      ingredients: json['ingredients'] as String?,
      shelfLifeDays: (json['shelfLifeDays'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': name,
      'description': description,
      'prixOriginal': prixOriginal,
      'imageUrl': imageUrl,
      'categoryId': categoryId,
      'variants': variants.map((v) => v.toJson()).toList(),
      'productType': productType.name,
      'stockMode': stockMode.name,
      'madeToOrder': madeToOrder,
      'availableFrom': ?availableFrom,
      'availableUntil': ?availableUntil,
      'ingredients': ?ingredients,
      'shelfLifeDays': ?shelfLifeDays,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? prixOriginal,
    String? imageUrl,
    String? restaurantId,
    String? categoryId,
    Category? category,
    List<ProductVariant>? variants,
    ProductType? productType,
    StockMode? stockMode,
    bool? madeToOrder,
    String? availableFrom,
    String? availableUntil,
    bool? isActive,
    String? ingredients,
    int? shelfLifeDays,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      prixOriginal: prixOriginal ?? this.prixOriginal,
      imageUrl: imageUrl ?? this.imageUrl,
      restaurantId: restaurantId ?? this.restaurantId,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      variants: variants ?? this.variants,
      createdAt: createdAt,
      updatedAt: updatedAt,
      productType: productType ?? this.productType,
      stockMode: stockMode ?? this.stockMode,
      madeToOrder: madeToOrder ?? this.madeToOrder,
      availableFrom: availableFrom ?? this.availableFrom,
      availableUntil: availableUntil ?? this.availableUntil,
      isActive: isActive ?? this.isActive,
      ingredients: ingredients ?? this.ingredients,
      shelfLifeDays: shelfLifeDays ?? this.shelfLifeDays,
    );
  }
}

class ProductVariant {
  final String? id;
  final String? label; // Nullable dans le backend
  final double prix;

  ProductVariant({
    this.id,
    this.label,
    required this.prix,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as String?,
      label: json['label'] as String?,
      prix: (json['prix'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'prix': prix,
    };
  }

  ProductVariant copyWith({
    String? id,
    String? label,
    double? prix,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      label: label ?? this.label,
      prix: prix ?? this.prix,
    );
  }
}

class Category {
  final String id;
  final String name;
  final String? restaurantId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Category({
    required this.id,
    required this.name,
    this.restaurantId,
    this.createdAt,
    this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String? ?? '',
      name: json['nom'] as String? ?? 'Categorie inconnue',
      restaurantId: json['restaurantId'] as String?,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': name,
    };
  }

  Category copyWith({
    String? id,
    String? name,
    String? restaurantId,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      restaurantId: restaurantId ?? this.restaurantId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

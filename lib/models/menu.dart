import 'product.dart';

class MenuDuJour {
  final String id;
  final String nom;
  final String? description;
  final String? imageUrl;
  final double prix;
  final String type; // 'COMBO' ou 'PLAT_SPECIAL'
  final String? ingredients; // Composition pour PLAT_SPECIAL
  final DateTime dateDebut;
  final DateTime dateFin;
  final bool isActive;
  final String restaurantId;
  final List<MenuProduct> products;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MenuDuJour({
    required this.id,
    required this.nom,
    this.description,
    this.imageUrl,
    required this.prix,
    this.type = 'COMBO',
    this.ingredients,
    required this.dateDebut,
    required this.dateFin,
    required this.isActive,
    required this.restaurantId,
    required this.products,
    this.createdAt,
    this.updatedAt,
  });

  bool get isPlatSpecial => type == 'PLAT_SPECIAL';

  factory MenuDuJour.fromJson(Map<String, dynamic> json) {
    var productsList = json['products'] as List? ?? [];
    List<MenuProduct> products =
        productsList.map((i) => MenuProduct.fromJson(i as Map<String, dynamic>)).toList();

    return MenuDuJour(
      id: json['id'] as String? ?? '',
      nom: json['nom'] as String? ?? 'Menu sans nom',
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      prix: (json['prix'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] as String? ?? 'COMBO',
      ingredients: json['ingredients'] as String?,
      dateDebut: json['dateDebut'] != null
          ? DateTime.parse(json['dateDebut'] as String)
          : DateTime.now(),
      dateFin: json['dateFin'] != null
          ? DateTime.parse(json['dateFin'] as String)
          : DateTime.now().add(const Duration(days: 1)),
      isActive: json['isActive'] as bool? ?? true,
      restaurantId: json['restaurantId'] as String? ?? '',
      products: products,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'nom': nom,
      'description': description,
      'imageUrl': imageUrl,
      'prix': prix,
      'type': type,
      'dateDebut': dateDebut.toIso8601String(),
      'dateFin': dateFin.toIso8601String(),
      'isActive': isActive,
    };
    if (isPlatSpecial) {
      map['ingredients'] = ingredients;
    } else {
      map['products'] = products
          .map((p) => {'productId': p.productId, 'ordre': p.ordre})
          .toList();
    }
    return map;
  }

  bool get isCurrentlyValid {
    final now = DateTime.now();
    return isActive && now.isAfter(dateDebut) && now.isBefore(dateFin);
  }

  bool get isExpired {
    return DateTime.now().isAfter(dateFin);
  }

  MenuDuJour copyWith({
    String? id,
    String? nom,
    String? description,
    String? imageUrl,
    double? prix,
    String? type,
    String? ingredients,
    DateTime? dateDebut,
    DateTime? dateFin,
    bool? isActive,
    String? restaurantId,
    List<MenuProduct>? products,
  }) {
    return MenuDuJour(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      prix: prix ?? this.prix,
      type: type ?? this.type,
      ingredients: ingredients ?? this.ingredients,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      isActive: isActive ?? this.isActive,
      restaurantId: restaurantId ?? this.restaurantId,
      products: products ?? this.products,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class MenuProduct {
  final String id;
  final String menuId;
  final String productId;
  final int ordre;
  final Product? product;
  final DateTime? createdAt;

  MenuProduct({
    required this.id,
    required this.menuId,
    required this.productId,
    required this.ordre,
    this.product,
    this.createdAt,
  });

  factory MenuProduct.fromJson(Map<String, dynamic> json) {
    return MenuProduct(
      id: json['id'] as String? ?? '',
      menuId: json['menuId'] as String? ?? '',
      productId: json['productId'] as String? ?? '',
      ordre: (json['ordre'] as num?)?.toInt() ?? 0,
      product:
          json['product'] != null ? Product.fromJson(json['product'] as Map<String, dynamic>) : null,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }
}

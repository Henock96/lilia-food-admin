/// Modèles partagés pour la feature galeries photos (Restaurant / Product /
/// MenuDuJour). Les 3 entités backend partagent un shape identique côté
/// API, donc on les modélise via une classe unique `Photo` paramétrée par
/// [EntityType].
enum EntityType { vendor, product, menu }

extension EntityTypeX on EntityType {
  /// Préfixe URL de l'endpoint REST associé.
  String get endpoint {
    switch (this) {
      case EntityType.vendor:
        return '/vendor-photos';
      case EntityType.product:
        return '/product-images';
      case EntityType.menu:
        return '/menu-images';
    }
  }

  /// Nom du champ "parent" attendu en query (GET) et en body (POST /reorder).
  String get parentField {
    switch (this) {
      case EntityType.vendor:
        return 'restaurantId';
      case EntityType.product:
        return 'productId';
      case EntityType.menu:
        return 'menuDuJourId';
    }
  }

  /// Libellé humain pour les écrans / toasts.
  String get label {
    switch (this) {
      case EntityType.vendor:
        return 'restaurant';
      case EntityType.product:
        return 'produit';
      case EntityType.menu:
        return 'menu du jour';
    }
  }

  static EntityType fromString(String value) {
    switch (value) {
      case 'vendor':
        return EntityType.vendor;
      case 'product':
        return EntityType.product;
      case 'menu':
        return EntityType.menu;
      default:
        throw ArgumentError('EntityType inconnu: $value');
    }
  }

  String get asString {
    switch (this) {
      case EntityType.vendor:
        return 'vendor';
      case EntityType.product:
        return 'product';
      case EntityType.menu:
        return 'menu';
    }
  }
}

/// Réponse d'un upload Cloudinary direct. On capture `publicId` pour
/// permettre au backend de faire le cleanup à la suppression.
class CloudinaryUploadResult {
  final String secureUrl;
  final String publicId;

  const CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
  });
}

/// Représente une photo de galerie côté Flutter, indépendamment de
/// l'entité parente (Restaurant / Product / MenuDuJour).
class Photo {
  final String id;
  final String url;
  final String? publicId;
  final String? alt;
  final int displayOrder;
  final bool isCover;
  final DateTime createdAt;

  const Photo({
    required this.id,
    required this.url,
    required this.publicId,
    required this.alt,
    required this.displayOrder,
    required this.isCover,
    required this.createdAt,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] as String,
      url: json['url'] as String,
      publicId: json['publicId'] as String?,
      alt: json['alt'] as String?,
      displayOrder: json['displayOrder'] as int? ?? 0,
      isCover: json['isCover'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Photo copyWith({
    String? id,
    String? url,
    String? publicId,
    String? alt,
    int? displayOrder,
    bool? isCover,
    DateTime? createdAt,
  }) {
    return Photo(
      id: id ?? this.id,
      url: url ?? this.url,
      publicId: publicId ?? this.publicId,
      alt: alt ?? this.alt,
      displayOrder: displayOrder ?? this.displayOrder,
      isCover: isCover ?? this.isCover,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

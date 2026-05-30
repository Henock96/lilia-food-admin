// ignore_for_file: constant_identifier_names

import 'vendor_type.dart';

class Restaurant {
  final String id;
  final String name;
  final String address;
  final String? phoneNumber;
  final String? imageUrl;
  final String? description;
  final String ownerId;
  final double? averageRating;
  final int? totalReviews;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Statut d'ouverture
  final bool isOpen;
  final bool manualOverride;

  // LIL-124 : marketplace fields
  final VendorType vendorType;
  final bool isActive;
  final bool adminApproved;

  // LIL-124 : preorder fields (LIL-121)
  final bool acceptsPreorders;
  final int? preorderLeadHours;
  final int? maxOrdersPerDay;

  // Operating hours
  final List<OperatingHours> operatingHours;

  // Delivery settings
  final String deliveryPriceMode;
  final double fixedDeliveryFee;
  final int estimatedDeliveryTimeMin;
  final int estimatedDeliveryTimeMax;
  final double minimumOrderAmount;

  // Specialties
  final List<Specialty> specialties;

  Restaurant({
    required this.id,
    required this.name,
    required this.address,
    this.phoneNumber,
    this.imageUrl,
    this.description,
    required this.ownerId,
    this.averageRating,
    this.totalReviews,
    this.createdAt,
    this.updatedAt,
    this.isOpen = true,
    this.manualOverride = false,
    this.vendorType = VendorType.RESTAURANT,
    this.isActive = true,
    this.adminApproved = true,
    this.acceptsPreorders = false,
    this.preorderLeadHours,
    this.maxOrdersPerDay,
    this.operatingHours = const [],
    this.deliveryPriceMode = 'FIXED',
    this.fixedDeliveryFee = 500,
    this.estimatedDeliveryTimeMin = 15,
    this.estimatedDeliveryTimeMax = 30,
    this.minimumOrderAmount = 0,
    this.specialties = const [],
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] as String? ?? '',
      name: json['nom'] as String? ?? 'Restaurant inconnu',
      address: json['adresse'] as String? ?? '',
      phoneNumber: json['phone'] as String?,
      imageUrl: json['imageUrl'] as String?,
      description: json['description'] as String?,
      ownerId: json['ownerId'] as String? ?? '',
      averageRating: json['averageRating'] != null
          ? (json['averageRating'] as num).toDouble()
          : null,
      totalReviews: json['totalReviews'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      isOpen: json['isOpen'] as bool? ?? true,
      manualOverride: json['manualOverride'] as bool? ?? false,
      vendorType: VendorType.fromString(json['vendorType'] as String?),
      isActive: json['isActive'] as bool? ?? true,
      adminApproved: json['adminApproved'] as bool? ?? true,
      acceptsPreorders: json['acceptsPreorders'] as bool? ?? false,
      preorderLeadHours: (json['preorderLeadHours'] as num?)?.toInt(),
      maxOrdersPerDay: (json['maxOrdersPerDay'] as num?)?.toInt(),
      operatingHours: json['operatingHours'] != null
          ? (json['operatingHours'] as List)
                .map((h) => OperatingHours.fromJson(h as Map<String, dynamic>))
                .toList()
          : [],
      deliveryPriceMode: json['deliveryPriceMode'] as String? ?? 'FIXED',
      fixedDeliveryFee: (json['fixedDeliveryFee'] as num?)?.toDouble() ?? 500,
      estimatedDeliveryTimeMin:
          (json['estimatedDeliveryTimeMin'] as num?)?.toInt() ?? 15,
      estimatedDeliveryTimeMax:
          (json['estimatedDeliveryTimeMax'] as num?)?.toInt() ?? 30,
      minimumOrderAmount: (json['minimumOrderAmount'] as num?)?.toDouble() ?? 0,
      specialties: json['specialties'] != null
          ? (json['specialties'] as List)
                .map((s) => Specialty.fromJson(s as Map<String, dynamic>))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': name,
      'adresse': address,
      'phone': phoneNumber,
      'imageUrl': imageUrl,
      'description': description,
    };
  }

  Restaurant copyWith({
    String? id,
    String? name,
    String? address,
    String? phoneNumber,
    String? imageUrl,
    String? description,
    String? ownerId,
    double? averageRating,
    int? totalReviews,
    bool? isOpen,
    bool? manualOverride,
    VendorType? vendorType,
    bool? isActive,
    bool? adminApproved,
    bool? acceptsPreorders,
    int? preorderLeadHours,
    int? maxOrdersPerDay,
    List<OperatingHours>? operatingHours,
    String? deliveryPriceMode,
    double? fixedDeliveryFee,
    int? estimatedDeliveryTimeMin,
    int? estimatedDeliveryTimeMax,
    double? minimumOrderAmount,
    List<Specialty>? specialties,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isOpen: isOpen ?? this.isOpen,
      manualOverride: manualOverride ?? this.manualOverride,
      vendorType: vendorType ?? this.vendorType,
      isActive: isActive ?? this.isActive,
      adminApproved: adminApproved ?? this.adminApproved,
      acceptsPreorders: acceptsPreorders ?? this.acceptsPreorders,
      preorderLeadHours: preorderLeadHours ?? this.preorderLeadHours,
      maxOrdersPerDay: maxOrdersPerDay ?? this.maxOrdersPerDay,
      operatingHours: operatingHours ?? this.operatingHours,
      deliveryPriceMode: deliveryPriceMode ?? this.deliveryPriceMode,
      fixedDeliveryFee: fixedDeliveryFee ?? this.fixedDeliveryFee,
      estimatedDeliveryTimeMin:
          estimatedDeliveryTimeMin ?? this.estimatedDeliveryTimeMin,
      estimatedDeliveryTimeMax:
          estimatedDeliveryTimeMax ?? this.estimatedDeliveryTimeMax,
      minimumOrderAmount: minimumOrderAmount ?? this.minimumOrderAmount,
      specialties: specialties ?? this.specialties,
    );
  }
}

class Specialty {
  final String id;
  final String name;
  final DateTime? createdAt;

  Specialty({required this.id, required this.name, this.createdAt});

  factory Specialty.fromJson(Map<String, dynamic> json) {
    return Specialty(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name};
  }
}

enum DayOfWeek {
  LUNDI,
  MARDI,
  MERCREDI,
  JEUDI,
  VENDREDI,
  SAMEDI,
  DIMANCHE;

  String get label {
    switch (this) {
      case DayOfWeek.LUNDI:
        return 'Lundi';
      case DayOfWeek.MARDI:
        return 'Mardi';
      case DayOfWeek.MERCREDI:
        return 'Mercredi';
      case DayOfWeek.JEUDI:
        return 'Jeudi';
      case DayOfWeek.VENDREDI:
        return 'Vendredi';
      case DayOfWeek.SAMEDI:
        return 'Samedi';
      case DayOfWeek.DIMANCHE:
        return 'Dimanche';
    }
  }

  String get shortLabel {
    switch (this) {
      case DayOfWeek.LUNDI:
        return 'Lun';
      case DayOfWeek.MARDI:
        return 'Mar';
      case DayOfWeek.MERCREDI:
        return 'Mer';
      case DayOfWeek.JEUDI:
        return 'Jeu';
      case DayOfWeek.VENDREDI:
        return 'Ven';
      case DayOfWeek.SAMEDI:
        return 'Sam';
      case DayOfWeek.DIMANCHE:
        return 'Dim';
    }
  }

  static DayOfWeek fromString(String value) {
    return DayOfWeek.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DayOfWeek.LUNDI,
    );
  }
}

class OperatingHours {
  final String id;
  final String restaurantId;
  final DayOfWeek dayOfWeek;
  final String openTime;
  final String closeTime;
  final bool isClosed;

  OperatingHours({
    required this.id,
    required this.restaurantId,
    required this.dayOfWeek,
    required this.openTime,
    required this.closeTime,
    this.isClosed = false,
  });

  factory OperatingHours.fromJson(Map<String, dynamic> json) {
    return OperatingHours(
      id: json['id'] as String? ?? '',
      restaurantId: json['restaurantId'] as String? ?? '',
      dayOfWeek: DayOfWeek.fromString(json['dayOfWeek'] as String? ?? 'LUNDI'),
      openTime: json['openTime'] as String? ?? '08:00',
      closeTime: json['closeTime'] as String? ?? '22:00',
      isClosed: json['isClosed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayOfWeek': dayOfWeek.name,
      'openTime': openTime,
      'closeTime': closeTime,
      'isClosed': isClosed,
    };
  }

  OperatingHours copyWith({
    String? id,
    String? restaurantId,
    DayOfWeek? dayOfWeek,
    String? openTime,
    String? closeTime,
    bool? isClosed,
  }) {
    return OperatingHours(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      isClosed: isClosed ?? this.isClosed,
    );
  }
}

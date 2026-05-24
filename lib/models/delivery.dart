import 'package:lilia_admin/models/delivery_status.dart';

/// Représente une livraison côté admin (entité Prisma `Delivery`), mappée
/// depuis `GET /deliveries/by-order/:orderId`.
///
/// Le backend renvoie un sous-ensemble :
/// ```
/// {
///   id, status, lastLatitude, lastLongitude, lastPositionAt,
///   estimatedArrival, pickedUpAt, deliveredAt, createdAt,
///   deliverer: { id, nom, phone, imageUrl },
///   order: {
///     id,
///     deliveryLatitude, deliveryLongitude,
///     restaurant: { id, nom, latitude, longitude },
///   },
/// }
/// ```
///
/// On expose tout à plat pour faciliter l'usage côté écrans
/// (tracking, bottom sheet, marker destination, marker resto).
class Delivery {
  final String id;
  final String orderId;
  final DeliveryStatus status;

  // Livreur
  final String? delivererId;
  final String? delivererNom;
  final String? delivererPhone;
  final String? delivererImageUrl;

  // Position live du livreur (dernière connue persistée en DB)
  final double? lastLatitude;
  final double? lastLongitude;
  final DateTime? lastPositionAt;
  final DateTime? estimatedArrival;

  // Coords destination (adresse client)
  final double? destinationLatitude;
  final double? destinationLongitude;

  // Restaurant de la commande
  final String? restaurantId;
  final String? restaurantNom;
  final double? restaurantLatitude;
  final double? restaurantLongitude;

  // Timestamps
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? deliveredAt;

  const Delivery({
    required this.id,
    required this.orderId,
    required this.status,
    required this.createdAt,
    this.delivererId,
    this.delivererNom,
    this.delivererPhone,
    this.delivererImageUrl,
    this.lastLatitude,
    this.lastLongitude,
    this.lastPositionAt,
    this.estimatedArrival,
    this.destinationLatitude,
    this.destinationLongitude,
    this.restaurantId,
    this.restaurantNom,
    this.restaurantLatitude,
    this.restaurantLongitude,
    this.acceptedAt,
    this.deliveredAt,
  });

  /// `true` ssi on a des coords destination utilisables pour la carte.
  bool get hasDestinationCoords =>
      destinationLatitude != null && destinationLongitude != null;

  factory Delivery.fromJson(Map<String, dynamic> json) {
    final delivererJson = json['deliverer'] as Map<String, dynamic>?;
    final flatDelivererId = json['delivererId'] as String?;
    final nestedDelivererId = delivererJson?['id'] as String?;

    final orderJson = json['order'] as Map<String, dynamic>?;
    final restaurantJson = orderJson?['restaurant'] as Map<String, dynamic>?;

    return Delivery(
      id: json['id'] as String? ?? '',
      orderId:
          (json['orderId'] as String?) ?? (orderJson?['id'] as String?) ?? '',
      status: DeliveryStatus.fromWire(json['status'] as String?),
      delivererId: flatDelivererId ?? nestedDelivererId,
      delivererNom: delivererJson?['nom'] as String?,
      delivererPhone: delivererJson?['phone'] as String?,
      delivererImageUrl: delivererJson?['imageUrl'] as String?,
      lastLatitude: (json['lastLatitude'] as num?)?.toDouble(),
      lastLongitude: (json['lastLongitude'] as num?)?.toDouble(),
      lastPositionAt: _parseDate(json['lastPositionAt']),
      estimatedArrival: _parseDate(json['estimatedArrival']),
      destinationLatitude:
          (orderJson?['deliveryLatitude'] as num?)?.toDouble(),
      destinationLongitude:
          (orderJson?['deliveryLongitude'] as num?)?.toDouble(),
      restaurantId: restaurantJson?['id'] as String?,
      restaurantNom: restaurantJson?['nom'] as String?,
      restaurantLatitude: (restaurantJson?['latitude'] as num?)?.toDouble(),
      restaurantLongitude: (restaurantJson?['longitude'] as num?)?.toDouble(),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      acceptedAt: _parseDate(json['acceptedAt'] ?? json['pickedUpAt']),
      deliveredAt: _parseDate(json['deliveredAt']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

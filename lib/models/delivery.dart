import 'package:lilia_admin/models/delivery_status.dart';

/// Représente une livraison côté admin (entité Prisma `Delivery`), mappée
/// depuis `GET /deliveries/by-order/:orderId`.
///
/// Le backend renvoie aujourd'hui un sous-ensemble :
/// `{ id, status, lastLatitude, lastLongitude, lastPositionAt, estimatedArrival,
///    deliverer: { id, nom, phone, imageUrl } }`. On expose `delivererId` /
/// `delivererNom` / `delivererPhone` / `delivererImageUrl` à plat pour faciliter
/// l'usage côté écrans (tracking + bottom sheet livreur).
class Delivery {
  final String id;
  final String orderId;
  final DeliveryStatus status;
  final String? delivererId;
  final String? delivererNom;
  final String? delivererPhone;
  final String? delivererImageUrl;
  final double? lastLatitude;
  final double? lastLongitude;
  final DateTime? lastPositionAt;
  final DateTime? estimatedArrival;
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
    this.acceptedAt,
    this.deliveredAt,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    // Le backend imbrique le livreur sous `deliverer: { id, nom, phone, imageUrl }`.
    // On accepte aussi un fallback `delivererId` plat au cas où une autre route
    // l'expose différemment.
    final delivererJson = json['deliverer'] as Map<String, dynamic>?;
    final flatDelivererId = json['delivererId'] as String?;
    final nestedDelivererId = delivererJson?['id'] as String?;

    return Delivery(
      id: json['id'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      status: DeliveryStatus.fromWire(json['status'] as String?),
      delivererId: flatDelivererId ?? nestedDelivererId,
      delivererNom: delivererJson?['nom'] as String?,
      delivererPhone: delivererJson?['phone'] as String?,
      delivererImageUrl: delivererJson?['imageUrl'] as String?,
      lastLatitude: (json['lastLatitude'] as num?)?.toDouble(),
      lastLongitude: (json['lastLongitude'] as num?)?.toDouble(),
      lastPositionAt: _parseDate(json['lastPositionAt']),
      estimatedArrival: _parseDate(json['estimatedArrival']),
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

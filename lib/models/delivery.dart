import 'package:lilia_admin/models/delivery_status.dart';

/// Représente une livraison côté admin (entité Prisma `Delivery`), mappée
/// depuis `GET /deliveries/by-order/:orderId`. Vue minimale suffisante pour
/// l'écran de tracking — peut être enrichie si l'écran en exige davantage.
class Delivery {
  final String id;
  final String orderId;
  final DeliveryStatus status;
  final String? delivererId;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? deliveredAt;

  const Delivery({
    required this.id,
    required this.orderId,
    required this.status,
    required this.createdAt,
    this.delivererId,
    this.acceptedAt,
    this.deliveredAt,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: json['id'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      status: DeliveryStatus.fromWire(json['status'] as String?),
      delivererId: json['delivererId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.tryParse(json['acceptedAt'] as String)
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.tryParse(json['deliveredAt'] as String)
          : null,
    );
  }
}

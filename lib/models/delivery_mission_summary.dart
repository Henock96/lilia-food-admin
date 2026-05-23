import 'package:lilia_admin/models/delivery_status.dart';

/// Résumé d'une mission de livraison telle qu'affichée dans la liste des
/// missions d'un livreur (route `GET /admin/deliverers/:id/missions`).
///
/// **Stub LIL-85** — l'API publique (noms / types) doit rester identique à
/// celle livrée par LIL-84.
class DeliveryMissionSummary {
  final String id;
  final String orderId;
  final DeliveryStatus status;
  final String restaurantName;
  final String clientName;
  final int totalXAF;
  final DateTime? acceptedAt;
  final DateTime? deliveredAt;
  final DateTime createdAt;

  const DeliveryMissionSummary({
    required this.id,
    required this.orderId,
    required this.status,
    required this.restaurantName,
    required this.clientName,
    required this.totalXAF,
    required this.createdAt,
    this.acceptedAt,
    this.deliveredAt,
  });

  factory DeliveryMissionSummary.fromJson(Map<String, dynamic> json) {
    return DeliveryMissionSummary(
      id: json['id'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      status: DeliveryStatus.fromWire(json['status'] as String?),
      restaurantName: json['restaurantName'] as String? ?? '',
      clientName: json['clientName'] as String? ?? '',
      totalXAF: (json['totalXAF'] as num?)?.toInt() ?? 0,
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.tryParse(json['acceptedAt'] as String)
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.tryParse(json['deliveredAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

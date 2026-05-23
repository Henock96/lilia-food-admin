import 'package:lilia_admin/models/delivery_status.dart';

/// Représente une livraison côté admin (entité Prisma `Delivery`).
///
/// **Stub LIL-85** — modèle minimal nécessaire pour faire compiler les
/// providers de tracking. LIL-84 livrera la version définitive (avec sans
/// doute plus de champs : livreur, infos commande, timestamps complets,
/// etc.). Au merge, garder l'API publique compatible (`id`, `orderId`,
/// `status`, `delivererId`) ou patcher les providers consommateurs.
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

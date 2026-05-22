/// Une livraison récente d'un livreur (sous-objet de GET /admin/deliverers).
class AdminDelivery {
  final String id;
  final String status;
  final DateTime createdAt;

  AdminDelivery({
    required this.id,
    required this.status,
    required this.createdAt,
  });

  factory AdminDelivery.fromJson(Map<String, dynamic> json) {
    return AdminDelivery(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

/// Un livreur de la liste de supervision admin (GET /admin/deliverers).
class AdminDeliverer {
  final String id;
  final String? email;
  final String? nom;
  final String? phone;
  final String? imageUrl;
  final DateTime createdAt;
  final List<AdminDelivery> recentDeliveries;
  final int totalDeliveries;

  AdminDeliverer({
    required this.id,
    this.email,
    this.nom,
    this.phone,
    this.imageUrl,
    required this.createdAt,
    required this.recentDeliveries,
    required this.totalDeliveries,
  });

  factory AdminDeliverer.fromJson(Map<String, dynamic> json) {
    final deliveries = json['deliveries'] as List<dynamic>? ?? [];
    final count = json['_count'] as Map<String, dynamic>?;
    return AdminDeliverer(
      id: json['id'] as String? ?? '',
      email: json['email'] as String?,
      nom: json['nom'] as String?,
      phone: json['phone'] as String?,
      imageUrl: json['imageUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      recentDeliveries: deliveries
          .map((d) => AdminDelivery.fromJson(d as Map<String, dynamic>))
          .toList(),
      totalDeliveries: (count?['deliveries'] as int?) ?? 0,
    );
  }
}

/// Enveloppe paginée des livreurs (GET /admin/deliverers).
class PaginatedDeliverers {
  final List<AdminDeliverer> deliverers;
  final int total;
  final int page;
  final int limit;

  PaginatedDeliverers({
    required this.deliverers,
    required this.total,
    required this.page,
    required this.limit,
  });

  int get totalPages =>
      limit > 0 ? ((total + limit - 1) ~/ limit).clamp(1, 1 << 31) : 1;
}

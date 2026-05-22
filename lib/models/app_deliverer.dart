class AppDeliverer {
  final String id;
  final String nom;
  final String? phone;
  final String? imageUrl;
  final int activeDeliveries;

  AppDeliverer({
    required this.id,
    required this.nom,
    this.phone,
    this.imageUrl,
    required this.activeDeliveries,
  });

  factory AppDeliverer.fromJson(Map<String, dynamic> json) {
    return AppDeliverer(
      id: json['id'] as String,
      nom: json['nom'] as String? ?? 'Livreur',
      phone: json['phone'] as String?,
      imageUrl: json['imageUrl'] as String?,
      activeDeliveries: ((json['_count'] as Map<String, dynamic>?)?['deliveries'] as int?) ?? 0,
    );
  }
}

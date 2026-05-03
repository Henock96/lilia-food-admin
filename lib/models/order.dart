// Models (can be moved to their own files)
enum OrderStatus {
  enattente,
  payer,
  enpreparation,
  pret,
  livrer,
  annuler,
  unknown
}

class Order {
  final String id;
  final double total;
  final double subTotal;
  final double deliveryFee;
  final double serviceFee;
  final DateTime createdAt;
  final OrderStatus status;
  final String deliveryAddress;
  final String? notes;
  final bool isDelivery;
  final String? paymentMethod;
  final String? restaurantName;
  final List<OrderItem> items;
  // Infos client
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;
  final String? customerImageUrl;
  final String? customerId;

  Order({
    required this.id,
    required this.total,
    this.subTotal = 0,
    this.deliveryFee = 0,
    this.serviceFee = 0,
    required this.createdAt,
    required this.status,
    required this.deliveryAddress,
    this.notes,
    this.isDelivery = true,
    this.paymentMethod,
    this.restaurantName,
    required this.items,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.customerImageUrl,
    this.customerId,
  });

  Order copyWith({OrderStatus? status}) {
    return Order(
      id: id,
      total: total,
      subTotal: subTotal,
      deliveryFee: deliveryFee,
      serviceFee: serviceFee,
      createdAt: createdAt,
      status: status ?? this.status,
      deliveryAddress: deliveryAddress,
      notes: notes,
      isDelivery: isDelivery,
      paymentMethod: paymentMethod,
      restaurantName: restaurantName,
      items: items,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      customerImageUrl: customerImageUrl,
      customerId: customerId,
    );
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] as Map<String, dynamic>?;
    return Order(
      id: json['id'] as String? ?? 'N/A',
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      subTotal: (json['subTotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      serviceFee: (json['serviceFee'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      status: _statusFromString(json['status'] as String?),
      deliveryAddress:
          json['deliveryAddress'] as String? ?? 'Adresse non spécifiée',
      notes: json['notes'] as String?,
      isDelivery: json['isDelivery'] as bool? ?? true,
      paymentMethod: json['paymentMethod'] as String?,
      restaurantName: (json['restaurant'] as Map<String, dynamic>?)?['nom'] as String?,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((itemJson) => OrderItem.fromJson(itemJson as Map<String, dynamic>))
          .toList(),
      // Parse user data
      customerId: userMap?['id'] as String?,
      customerName: userMap?['nom'] as String?,
      customerPhone: (json['contactPhone'] as String?) ?? (userMap?['phone'] as String?),
      customerEmail: userMap?['email'] as String?,
      customerImageUrl: userMap?['imageUrl'] as String?,
    );
  }

  static OrderStatus _statusFromString(String? status) {
    switch (status) {
      case 'EN_ATTENTE':
        return OrderStatus.enattente;
      case 'PAYER': // Corrige: c'etait 'PAYEZ' mais le backend utilise 'PAYER'
        return OrderStatus.payer;
      case 'EN_PREPARATION':
        return OrderStatus.enpreparation;
      case 'PRET':
        return OrderStatus.pret;
      case 'LIVRER':
        return OrderStatus.livrer;
      case 'ANNULER':
        return OrderStatus.annuler;
      default:
        return OrderStatus.unknown;
    }
  }
}

class OrderItem {
  final String productName;
  final String? productImageUrl;
  final int quantite;
  final double prix;
  final String? variant;

  OrderItem({
    required this.productName,
    this.productImageUrl,
    required this.quantite,
    required this.prix,
    this.variant,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final productMap = json['product'] as Map<String, dynamic>?;
    final productName = productMap?['nom'] as String? ?? 'Produit inconnu';
    return OrderItem(
      productName: productName,
      productImageUrl: productMap?['imageUrl'] as String?,
      quantite: (json['quantite'] as num?)?.toInt() ?? 0,
      prix: (json['prix'] as num?)?.toDouble() ?? 0.0,
      variant: json['variant'] as String?,
    );
  }
}

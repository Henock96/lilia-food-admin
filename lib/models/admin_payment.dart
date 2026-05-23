/// La commande associée à un paiement (sous-objet de GET /admin/payments).
class AdminPaymentOrder {
  final String id;
  final double total;
  final String status;
  final String? clientNom;
  final String? clientPhone;

  AdminPaymentOrder({
    required this.id,
    required this.total,
    required this.status,
    this.clientNom,
    this.clientPhone,
  });

  factory AdminPaymentOrder.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return AdminPaymentOrder(
      id: json['id'] as String? ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? '',
      clientNom: user?['nom'] as String?,
      clientPhone: user?['phone'] as String?,
    );
  }
}

/// Un paiement de la liste de supervision admin (GET /admin/payments).
class AdminPayment {
  final String id;
  final double amount;
  final String currency;
  final String phoneNumber;
  final String status; // PENDING | SUCCESS | FAILED | CANCELLED
  final String provider;
  final DateTime createdAt;
  final AdminPaymentOrder? order;

  AdminPayment({
    required this.id,
    required this.amount,
    required this.currency,
    required this.phoneNumber,
    required this.status,
    required this.provider,
    required this.createdAt,
    this.order,
  });

  factory AdminPayment.fromJson(Map<String, dynamic> json) {
    return AdminPayment(
      id: json['id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'XAF',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      provider: json['provider'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      order: json['order'] != null
          ? AdminPaymentOrder.fromJson(json['order'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Enveloppe paginée des paiements (GET /admin/payments).
class PaginatedPayments {
  final List<AdminPayment> payments;
  final int total;
  final int page;
  final int limit;

  PaginatedPayments({
    required this.payments,
    required this.total,
    required this.page,
    required this.limit,
  });

  int get totalPages =>
      limit > 0 ? ((total + limit - 1) ~/ limit).clamp(1, 1 << 31) : 1;
}

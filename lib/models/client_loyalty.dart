/// Une transaction de fidélité d'un client.
class ClientLoyaltyTransaction {
  final String id;
  final int points;
  final String reason;
  final String? orderId;
  final DateTime createdAt;

  ClientLoyaltyTransaction({
    required this.id,
    required this.points,
    required this.reason,
    this.orderId,
    required this.createdAt,
  });

  factory ClientLoyaltyTransaction.fromJson(Map<String, dynamic> json) {
    return ClientLoyaltyTransaction(
      id: json['id'] as String? ?? '',
      points: json['points'] as int? ?? 0,
      reason: json['reason'] as String? ?? '',
      orderId: json['orderId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

/// Solde + historique de fidélité d'un client (GET /admin/clients/:id/loyalty).
class ClientLoyalty {
  final int balance;
  final List<ClientLoyaltyTransaction> transactions;

  ClientLoyalty({required this.balance, required this.transactions});

  /// Parse l'objet `data` de la réponse : `{ balance, transactions }`.
  factory ClientLoyalty.fromJson(Map<String, dynamic> json) {
    final txns = json['transactions'] as List<dynamic>? ?? [];
    return ClientLoyalty(
      balance: json['balance'] as int? ?? 0,
      transactions: txns
          .map((t) => ClientLoyaltyTransaction.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}

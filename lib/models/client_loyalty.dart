/// Une transaction de fidélité d'un client.
class ClientLoyaltyTransaction {
  final String id;
  final int points;

  /// Nature de l'écriture (`ORDER_EARN`, `REFERRAL_REFERRER`, `ADJUSTMENT`…).
  ///
  /// Exposée depuis septembre 2026 : l'écran ne lisait que `reason`, une chaîne
  /// libre où un gain de commande, une récompense de parrainage et un
  /// ajustement manuel se ressemblaient. Impossible d'auditer, impossible de
  /// filtrer.
  final String type;

  final String reason;

  /// Commande à l'origine de l'écriture, le cas échéant.
  final String? orderId;

  /// Filleul dont la première commande livrée a payé ce point de parrainage.
  final String? sourceUserId;

  /// Administrateur auteur d'un `ADJUSTMENT`. `null` pour le système.
  final String? actorId;

  final DateTime createdAt;

  ClientLoyaltyTransaction({
    required this.id,
    required this.points,
    required this.type,
    required this.reason,
    this.orderId,
    this.sourceUserId,
    this.actorId,
    required this.createdAt,
  });

  /// Libellé humain de [type]. Le repli rend la valeur brute plutôt que de
  /// mentir : une valeur inconnue vient d'un backend plus récent que l'app.
  String get typeLabel => switch (type) {
    'ORDER_EARN' => 'Commande livrée',
    'ORDER_SPEND' => 'Points utilisés',
    'CANCELLATION_REFUND' => 'Annulation',
    'REFERRAL_REFERRER' => 'Parrainage',
    'REFERRAL_REFERRED' => 'Bonus filleul (historique)',
    'ADJUSTMENT' => 'Ajustement manuel',
    _ => type,
  };

  factory ClientLoyaltyTransaction.fromJson(Map<String, dynamic> json) {
    return ClientLoyaltyTransaction(
      id: json['id'] as String? ?? '',
      points: json['points'] as int? ?? 0,
      type: json['type'] as String? ?? 'ADJUSTMENT',
      reason: json['reason'] as String? ?? '',
      orderId: json['orderId'] as String?,
      sourceUserId: json['sourceUserId'] as String?,
      actorId: json['actorId'] as String?,
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

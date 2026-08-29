/// Remboursement dû à un client après annulation d'une commande payée.
///
/// Créé automatiquement par le backend (`RefundsService.openForCancelledOrder`)
/// pour le montant **réellement encaissé** — pas pour une estimation. Sans
/// écran pour le traiter, ces lignes restaient invisibles : le système savait
/// qu'il devait de l'argent, personne ne le voyait.
class Refund {
  final String id;
  final String orderId;
  final double amount;
  final RefundStatus status;
  final String reason;
  final String? notes;
  final DateTime createdAt;
  final DateTime? processedAt;

  // Contexte commande, servi par l'API pour éviter un second appel.
  final String? clientNom;
  final String? clientPhone;
  final String? restaurantNom;
  final String? paymentMethod;

  const Refund({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.status,
    required this.reason,
    required this.createdAt,
    this.notes,
    this.processedAt,
    this.clientNom,
    this.clientPhone,
    this.restaurantNom,
    this.paymentMethod,
  });

  /// Référence courte affichée à l'écran, alignée sur celle des notifications.
  String get shortOrderRef => orderId.length >= 6
      ? '#${orderId.substring(orderId.length - 6).toUpperCase()}'
      : '#$orderId';

  bool get isOpen =>
      status == RefundStatus.pending || status == RefundStatus.processing;

  factory Refund.fromJson(Map<String, dynamic> json) {
    final order = json['order'] as Map<String, dynamic>?;
    final user = order?['user'] as Map<String, dynamic>?;
    final restaurant = order?['restaurant'] as Map<String, dynamic>?;

    return Refund(
      id: json['id'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: RefundStatusX.fromString(json['status'] as String?),
      reason: json['reason'] as String? ?? '',
      notes: json['notes'] as String?,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      processedAt: json['processedAt'] != null
          ? DateTime.tryParse(json['processedAt'] as String)
          : null,
      clientNom: user?['nom'] as String?,
      clientPhone: user?['phone'] as String?,
      restaurantNom: restaurant?['nom'] as String?,
      paymentMethod: order?['paymentMethod'] as String?,
    );
  }
}

enum RefundStatus { pending, processing, completed, rejected }

extension RefundStatusX on RefundStatus {
  static RefundStatus fromString(String? s) => switch (s?.toUpperCase()) {
    'PROCESSING' => RefundStatus.processing,
    'COMPLETED' => RefundStatus.completed,
    'REJECTED' => RefundStatus.rejected,
    _ => RefundStatus.pending,
  };

  String toApiString() => switch (this) {
    RefundStatus.pending => 'PENDING',
    RefundStatus.processing => 'PROCESSING',
    RefundStatus.completed => 'COMPLETED',
    RefundStatus.rejected => 'REJECTED',
  };

  String get label => switch (this) {
    RefundStatus.pending => 'À traiter',
    RefundStatus.processing => 'Virement en cours',
    RefundStatus.completed => 'Remboursé',
    RefundStatus.rejected => 'Refusé',
  };

  /// Transitions proposées à l'admin depuis l'état courant.
  ///
  /// `COMPLETED` et `REJECTED` sont terminaux côté backend (409 si on insiste) :
  /// on n'affiche donc aucune action dessus plutôt que de laisser l'admin
  /// buter sur une erreur.
  List<RefundStatus> get nextStates => switch (this) {
    RefundStatus.pending => [
      RefundStatus.processing,
      RefundStatus.completed,
      RefundStatus.rejected,
    ],
    RefundStatus.processing => [RefundStatus.completed, RefundStatus.rejected],
    RefundStatus.completed || RefundStatus.rejected => const [],
  };
}

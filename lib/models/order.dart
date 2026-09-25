// Models (can be moved to their own files)
import 'order_actions.dart';

enum OrderStatus {
  enattente,
  payer,
  /// Acceptée par le vendeur, pas encore en préparation (Phase 3, F3-01).
  acceptee,
  enpreparation,
  pret,
  enRoute,
  livrer,
  annuler,
  /// Terminal : le repas est parti et n'est pas arrivé (F3-05).
  echecLivraison,
  unknown
}

/// Sens enum → libellé backend.
///
/// ⚠️ Il vivait dans un `switch` recopié à l'intérieur d'`OrderService`, avec
/// un `default: 'EN_ATTENTE'` : une valeur non prévue n'était pas refusée, elle
/// était traduite en **demande de remise à zéro du cycle de vie**. Écrit ici, à
/// côté du parseur inverse, il est vérifiable par aller-retour
/// (`order_service_test.dart`).
extension OrderStatusWire on OrderStatus {
  String toWire() => switch (this) {
    OrderStatus.enattente => 'EN_ATTENTE',
    OrderStatus.payer => 'PAYER',
    OrderStatus.acceptee => 'ACCEPTEE',
    OrderStatus.enpreparation => 'EN_PREPARATION',
    OrderStatus.pret => 'PRET',
    OrderStatus.enRoute => 'EN_ROUTE',
    OrderStatus.livrer => 'LIVRER',
    OrderStatus.annuler => 'ANNULER',
    OrderStatus.echecLivraison => 'ECHEC_LIVRAISON',
    // `unknown` est ce que rend le parseur sur une valeur qu'il ne connaît
    // pas. La renvoyer au serveur n'aurait aucun sens : on le dit ici plutôt
    // que de laisser un `default` inventer un statut.
    OrderStatus.unknown => throw ArgumentError(
      'OrderStatus.unknown ne correspond à aucun statut backend — '
      'il signale une valeur que cette version de l’app ne connaît pas.',
    ),
  };
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
  // LIL-124 : pré-commande (LIL-121)
  final bool isPreorder;
  final DateTime? scheduledFor;
  // Phase 3, F3-01 — acceptation vendeur.
  /// Gestes que le SERVEUR accepte sur cette commande, pour ce compte.
  /// `null` = serveur antérieur qui ne les publie pas (repli, cf.
  /// `resolveOrderActions`) ; liste vide = aucun geste permis.
  final List<OrderAction>? allowedActions;
  /// Au-delà, une commande payée non acceptée est annulée et remboursée.
  final DateTime? acceptDeadlineAt;
  /// Heure de fin de préparation annoncée au client à l'acceptation.
  final DateTime? estimatedReadyAt;
  // F3-07 — preuve de remise et échéance de versement.
  /// Comment la remise est prouvée (`PICKUP_CODE`, `DELIVERY_CODE`…). `null`
  /// avant la remise, ou sur une commande antérieure au dispositif.
  final String? deliveryProof;
  /// Instant de la remise, tous chemins confondus.
  final DateTime? deliveredAt;
  /// Retrait : le client a confirmé « J'ai récupéré ma commande ».
  final DateTime? customerConfirmedAt;
  /// Versement automatique au vendeur prévu à cette heure ; `null` = aucun
  /// versement automatique (preuve insuffisante).
  final DateTime? payoutDueAt;

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
    this.isPreorder = false,
    this.scheduledFor,
    this.allowedActions,
    this.acceptDeadlineAt,
    this.estimatedReadyAt,
    this.deliveryProof,
    this.deliveredAt,
    this.customerConfirmedAt,
    this.payoutDueAt,
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
      isPreorder: isPreorder,
      scheduledFor: scheduledFor,
      allowedActions: allowedActions,
      acceptDeadlineAt: acceptDeadlineAt,
      estimatedReadyAt: estimatedReadyAt,
      deliveryProof: deliveryProof,
      deliveredAt: deliveredAt,
      customerConfirmedAt: customerConfirmedAt,
      payoutDueAt: payoutDueAt,
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
      isPreorder: json['isPreorder'] as bool? ?? false,
      scheduledFor: json['scheduledFor'] != null
          ? DateTime.parse(json['scheduledFor'] as String)
          : null,
      allowedActions: OrderAction.listFromWire(json['allowedActions']),
      acceptDeadlineAt: _dateOrNull(json['acceptDeadlineAt']),
      estimatedReadyAt: _dateOrNull(json['estimatedReadyAt']),
      deliveryProof: json['deliveryProof'] as String?,
      deliveredAt: _dateOrNull(json['deliveredAt']),
      customerConfirmedAt: _dateOrNull(json['customerConfirmedAt']),
      payoutDueAt: _dateOrNull(json['payoutDueAt']),
    );
  }

  static DateTime? _dateOrNull(Object? raw) =>
      raw is String ? DateTime.tryParse(raw) : null;

  /// Traduit le libellé backend en valeur d'enum.
  ///
  /// Exposé publiquement pour que le sens inverse ([OrderStatusWire.toWire])
  /// soit vérifiable par aller-retour : c'est la seule façon de garantir qu'une
  /// commande relue après écriture retrouve son statut.
  static OrderStatus statusFromWire(String? status) =>
      _statusFromString(status);

  static OrderStatus _statusFromString(String? status) {
    switch (status) {
      case 'EN_ATTENTE':
        return OrderStatus.enattente;
      case 'PAYER': // Corrige: c'etait 'PAYEZ' mais le backend utilise 'PAYER'
        return OrderStatus.payer;
      case 'ACCEPTEE':
        return OrderStatus.acceptee;
      case 'EN_PREPARATION':
        return OrderStatus.enpreparation;
      case 'PRET':
        return OrderStatus.pret;
      case 'EN_ROUTE':
        return OrderStatus.enRoute;
      case 'LIVRER':
        return OrderStatus.livrer;
      case 'ANNULER':
        return OrderStatus.annuler;
      case 'ECHEC_LIVRAISON':
        return OrderStatus.echecLivraison;
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

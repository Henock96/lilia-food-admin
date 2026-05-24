// Enums et modèle alignés sur le backend Prisma (`Incident`).
//
// Backend `IncidentType` (11 valeurs), `IncidentSeverity` (4), `IncidentStatus` (4).
// Sérialisation : on garde la valeur backend en `String` interne pour ne pas
// casser si Prisma ajoute une valeur future — on l'expose via `wireValue` et
// on parse via `fromWire` avec fallback safe.

enum IncidentType {
  orderCancelled,
  orderDelayed,
  paymentFailed,
  driverNoShow,
  driverAccident,
  customerComplaint,
  restaurantClosed,
  stockIssue,
  wrongDelivery,
  refundRequest,
  other;

  String get wireValue {
    switch (this) {
      case IncidentType.orderCancelled:
        return 'ORDER_CANCELLED';
      case IncidentType.orderDelayed:
        return 'ORDER_DELAYED';
      case IncidentType.paymentFailed:
        return 'PAYMENT_FAILED';
      case IncidentType.driverNoShow:
        return 'DRIVER_NO_SHOW';
      case IncidentType.driverAccident:
        return 'DRIVER_ACCIDENT';
      case IncidentType.customerComplaint:
        return 'CUSTOMER_COMPLAINT';
      case IncidentType.restaurantClosed:
        return 'RESTAURANT_CLOSED';
      case IncidentType.stockIssue:
        return 'STOCK_ISSUE';
      case IncidentType.wrongDelivery:
        return 'WRONG_DELIVERY';
      case IncidentType.refundRequest:
        return 'REFUND_REQUEST';
      case IncidentType.other:
        return 'OTHER';
    }
  }

  /// Label court FR pour l'UI.
  String get label {
    switch (this) {
      case IncidentType.orderCancelled:
        return 'Commande annulée';
      case IncidentType.orderDelayed:
        return 'Retard de livraison';
      case IncidentType.paymentFailed:
        return 'Échec paiement';
      case IncidentType.driverNoShow:
        return 'Livreur absent';
      case IncidentType.driverAccident:
        return 'Accident livreur';
      case IncidentType.customerComplaint:
        return 'Plainte client';
      case IncidentType.restaurantClosed:
        return 'Restaurant fermé';
      case IncidentType.stockIssue:
        return 'Problème de stock';
      case IncidentType.wrongDelivery:
        return 'Mauvaise livraison';
      case IncidentType.refundRequest:
        return 'Demande de remboursement';
      case IncidentType.other:
        return 'Autre';
    }
  }

  static IncidentType fromWire(String? value) {
    switch (value) {
      case 'ORDER_CANCELLED':
        return IncidentType.orderCancelled;
      case 'ORDER_DELAYED':
        return IncidentType.orderDelayed;
      case 'PAYMENT_FAILED':
        return IncidentType.paymentFailed;
      case 'DRIVER_NO_SHOW':
        return IncidentType.driverNoShow;
      case 'DRIVER_ACCIDENT':
        return IncidentType.driverAccident;
      case 'CUSTOMER_COMPLAINT':
        return IncidentType.customerComplaint;
      case 'RESTAURANT_CLOSED':
        return IncidentType.restaurantClosed;
      case 'STOCK_ISSUE':
        return IncidentType.stockIssue;
      case 'WRONG_DELIVERY':
        return IncidentType.wrongDelivery;
      case 'REFUND_REQUEST':
        return IncidentType.refundRequest;
      case 'OTHER':
      default:
        return IncidentType.other;
    }
  }
}

enum IncidentSeverity {
  low,
  medium,
  high,
  critical;

  String get wireValue {
    switch (this) {
      case IncidentSeverity.low:
        return 'LOW';
      case IncidentSeverity.medium:
        return 'MEDIUM';
      case IncidentSeverity.high:
        return 'HIGH';
      case IncidentSeverity.critical:
        return 'CRITICAL';
    }
  }

  String get label {
    switch (this) {
      case IncidentSeverity.low:
        return 'Faible';
      case IncidentSeverity.medium:
        return 'Moyenne';
      case IncidentSeverity.high:
        return 'Élevée';
      case IncidentSeverity.critical:
        return 'Critique';
    }
  }

  static IncidentSeverity fromWire(String? value) {
    switch (value) {
      case 'LOW':
        return IncidentSeverity.low;
      case 'MEDIUM':
        return IncidentSeverity.medium;
      case 'HIGH':
        return IncidentSeverity.high;
      case 'CRITICAL':
        return IncidentSeverity.critical;
      default:
        return IncidentSeverity.medium;
    }
  }
}

enum IncidentStatus {
  open,
  inProgress,
  resolved,
  closed;

  String get wireValue {
    switch (this) {
      case IncidentStatus.open:
        return 'OPEN';
      case IncidentStatus.inProgress:
        return 'IN_PROGRESS';
      case IncidentStatus.resolved:
        return 'RESOLVED';
      case IncidentStatus.closed:
        return 'CLOSED';
    }
  }

  String get label {
    switch (this) {
      case IncidentStatus.open:
        return 'Ouvert';
      case IncidentStatus.inProgress:
        return 'En cours';
      case IncidentStatus.resolved:
        return 'Résolu';
      case IncidentStatus.closed:
        return 'Fermé';
    }
  }

  bool get isTerminal =>
      this == IncidentStatus.resolved || this == IncidentStatus.closed;

  static IncidentStatus fromWire(String? value) {
    switch (value) {
      case 'OPEN':
        return IncidentStatus.open;
      case 'IN_PROGRESS':
        return IncidentStatus.inProgress;
      case 'RESOLVED':
        return IncidentStatus.resolved;
      case 'CLOSED':
        return IncidentStatus.closed;
      default:
        return IncidentStatus.open;
    }
  }
}

class Incident {
  final String id;
  final IncidentType type;
  final IncidentSeverity severity;
  final IncidentStatus status;
  final String title;
  final String description;
  final String? resolution;
  final String? orderId;
  final String? riderId;
  final String? restaurantId;
  final String? reportedBy;
  final String? resolvedBy;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;

  const Incident({
    required this.id,
    required this.type,
    required this.severity,
    required this.status,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.resolution,
    this.orderId,
    this.riderId,
    this.restaurantId,
    this.reportedBy,
    this.resolvedBy,
    this.metadata,
    this.resolvedAt,
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id'] as String? ?? '',
      type: IncidentType.fromWire(json['type'] as String?),
      severity: IncidentSeverity.fromWire(json['severity'] as String?),
      status: IncidentStatus.fromWire(json['status'] as String?),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      resolution: json['resolution'] as String?,
      orderId: json['orderId'] as String?,
      riderId: json['riderId'] as String?,
      restaurantId: json['restaurantId'] as String?,
      reportedBy: json['reportedBy'] as String?,
      resolvedBy: json['resolvedBy'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
    );
  }
}

/// Enveloppe paginée des incidents (GET /incidents → `{ data, total }`).
/// Pas de `meta` côté backend — on dérive `totalPages` du `limit` requesté.
class PaginatedIncidents {
  final List<Incident> incidents;
  final int total;
  final int limit;
  final int offset;

  const PaginatedIncidents({
    required this.incidents,
    required this.total,
    required this.limit,
    required this.offset,
  });

  int get totalPages => limit > 0
      ? ((total + limit - 1) ~/ limit).clamp(1, 1 << 31)
      : 1;

  int get currentPage => limit > 0 ? (offset ~/ limit) + 1 : 1;
}

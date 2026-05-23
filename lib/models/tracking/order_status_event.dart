/// Event `order:status` reçu via le WebSocket Socket.io `/tracking`.
///
/// Payload backend :
/// ```json
/// { "status": "EN_ROUTE" }
/// ```
///
/// Comme pour `driver:position`, l'`orderId` n'est pas dans le payload — il est
/// rattaché côté client à partir de la commande qu'on watche.
class OrderStatusEvent {
  final String orderId;
  final String status;
  final DateTime ts;

  const OrderStatusEvent({
    required this.orderId,
    required this.status,
    required this.ts,
  });

  factory OrderStatusEvent.fromJson(
    Map<String, dynamic> json, {
    required String orderId,
  }) {
    return OrderStatusEvent(
      orderId: orderId,
      status: json['status'] as String,
      ts: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['timestamp'] as num).toInt(),
            )
          : DateTime.now(),
    );
  }

  @override
  String toString() =>
      'OrderStatusEvent(orderId: $orderId, status: $status, ts: $ts)';
}

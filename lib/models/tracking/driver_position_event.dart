/// Event `driver:position` reçu via le WebSocket Socket.io `/tracking`.
///
/// Payload backend :
/// ```json
/// { "lat": -4.2634, "lng": 15.2429, "eta": 7, "timestamp": 1716480000000 }
/// ```
///
/// Le payload backend ne contient PAS d'`orderId` (la room côté serveur est
/// indexée par commande). Côté admin, on attache l'`orderId` côté client au
/// moment de la réception pour pouvoir router l'event au bon listener.
class DriverPositionEvent {
  final String orderId;
  final double lat;
  final double lng;
  final DateTime ts;
  final double? etaMinutes;

  const DriverPositionEvent({
    required this.orderId,
    required this.lat,
    required this.lng,
    required this.ts,
    this.etaMinutes,
  });

  /// Parse un payload `driver:position` reçu du backend.
  /// `orderId` est passé séparément car non présent dans le payload.
  factory DriverPositionEvent.fromJson(
    Map<String, dynamic> json, {
    required String orderId,
  }) {
    return DriverPositionEvent(
      orderId: orderId,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      etaMinutes: (json['eta'] as num?)?.toDouble(),
      ts: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['timestamp'] as num).toInt(),
            )
          : DateTime.now(),
    );
  }

  @override
  String toString() =>
      'DriverPositionEvent(orderId: $orderId, lat: $lat, lng: $lng, '
      'eta: $etaMinutes, ts: $ts)';
}

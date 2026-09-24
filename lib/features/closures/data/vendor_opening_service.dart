import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/utils/api_response.dart';

/// Fermetures qui se terminent seules (F3-03) : pause, congés, jours fériés.
///
/// Ouvert ou fermé est **décidé par le serveur** (`reason`, `until`), avec la
/// même règle qu'au checkout : l'écran ne la recompose jamais.
class VendorClosure {
  final String id;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? reason;

  const VendorClosure({
    required this.id,
    required this.startsAt,
    required this.endsAt,
    this.reason,
  });

  factory VendorClosure.fromJson(Map<String, dynamic> json) => VendorClosure(
    id: json['id'] as String,
    startsAt: DateTime.parse(json['startsAt'] as String),
    endsAt: DateTime.parse(json['endsAt'] as String),
    reason: json['reason'] as String?,
  );
}

class VendorOpeningState {
  final bool isOpen;

  /// `OPEN`, `PAUSED`, `CLOSURE`, `HOLIDAY`, `MANUAL`, `OUTSIDE_HOURS`.
  final String reason;
  final DateTime? until;
  final DateTime? pausedUntil;
  final bool closedOnHolidays;
  final List<VendorClosure> closures;

  const VendorOpeningState({
    required this.isOpen,
    required this.reason,
    this.until,
    this.pausedUntil,
    required this.closedOnHolidays,
    this.closures = const [],
  });

  factory VendorOpeningState.fromJson(Map<String, dynamic> json) {
    DateTime? date(String key) =>
        json[key] == null ? null : DateTime.parse(json[key] as String);
    return VendorOpeningState(
      isOpen: json['isOpen'] as bool? ?? false,
      reason: json['reason'] as String? ?? 'OUTSIDE_HOURS',
      until: date('until'),
      pausedUntil: date('pausedUntil'),
      closedOnHolidays: json['closedOnHolidays'] as bool? ?? true,
      closures: ((json['closures'] as List?) ?? const [])
          .map((c) => VendorClosure.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Heure de Brazzaville (UTC+1, sans heure d'été), quel que soit le fuseau
/// du téléphone.
DateTime toBrazzaville(DateTime instant) =>
    instant.toUtc().add(const Duration(hours: 1));

/// « 14h30 » ou « 02/10 à 14h30 », heure de Brazzaville.
String formatBrazzaville(DateTime instant, {DateTime? now}) {
  final t = toBrazzaville(instant);
  final n = toBrazzaville(now ?? DateTime.now());
  String two(int v) => v.toString().padLeft(2, '0');
  final hour = '${two(t.hour)}h${two(t.minute)}';
  final sameDay = t.year == n.year && t.month == n.month && t.day == n.day;
  return sameDay ? hour : '${two(t.day)}/${two(t.month)} à $hour';
}

/// Une phrase : ouverte, ou pourquoi fermée et jusqu'à quand.
String openingSummary(VendorOpeningState s, {DateTime? now}) {
  switch (s.reason) {
    case 'OPEN':
      return 'Ouverte';
    case 'PAUSED':
      return 'En pause jusqu’à ${formatBrazzaville(s.until!, now: now)}';
    case 'CLOSURE':
      return 'En congé jusqu’au ${formatBrazzaville(s.until!, now: now)}';
    case 'HOLIDAY':
      return 'Fermée aujourd’hui (jour férié)';
    case 'MANUAL':
      return 'Fermée à la main';
    default:
      return 'Fermée (hors horaires)';
  }
}

class VendorOpeningService {
  final ApiClient _api;
  VendorOpeningService(this._api);

  Future<VendorOpeningState> get(String vendorId) async {
    final res = await _api.getJson('/vendors/$vendorId/opening');
    return VendorOpeningState.fromJson(ApiResponse.mapOf(res.data));
  }

  /// Renvoie le nombre de commandes encore à servir (jamais annulées).
  Future<int> pause(String vendorId, int minutes) async {
    final res = await _api.postJson(
      '/vendors/$vendorId/pause',
      body: {'minutes': minutes},
    );
    return (ApiResponse.mapOf(res.data)['inFlightOrders'] as num?)?.toInt() ??
        0;
  }

  Future<void> resume(String vendorId) async {
    await _api.deleteJson('/vendors/$vendorId/pause');
  }

  Future<int> addClosure(
    String vendorId, {
    required DateTime startsAt,
    required DateTime endsAt,
    String? reason,
  }) async {
    final res = await _api.postJson(
      '/vendors/$vendorId/closures',
      body: {
        'startsAt': startsAt.toUtc().toIso8601String(),
        'endsAt': endsAt.toUtc().toIso8601String(),
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
    return (ApiResponse.mapOf(res.data)['inFlightOrders'] as num?)?.toInt() ??
        0;
  }

  Future<void> removeClosure(String vendorId, String closureId) async {
    await _api.deleteJson('/vendors/$vendorId/closures/$closureId');
  }

  Future<void> setClosedOnHolidays(String vendorId, bool value) async {
    await _api.patchJson(
      '/vendors/$vendorId/closed-on-holidays',
      body: {'closedOnHolidays': value},
    );
  }
}

final vendorOpeningServiceProvider = Provider(
  (ref) => VendorOpeningService(ref.watch(apiClientProvider)),
);

final vendorOpeningProvider = FutureProvider.autoDispose
    .family<VendorOpeningState, String>(
      (ref, vendorId) => ref.watch(vendorOpeningServiceProvider).get(vendorId),
    );

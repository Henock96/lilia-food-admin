import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/utils/api_response.dart';

/// Réclamations clients (F3-06) — vue vendeur et support.
///
/// Le serveur décide de la portée : le vendeur ne reçoit que celles de sa
/// boutique, le support toutes. Le vendeur écrit au support seul
/// (`STAFF_ONLY` imposé par le serveur) ; rembourser, offrir un avoir ou
/// refuser se fait depuis l'admin web, où vit le composeur de remboursement.
class ClaimsRepository {
  ClaimsRepository(this._api);

  final ApiClient _api;

  Future<List<ClaimRow>> list({bool openOnly = false}) async {
    final res = await _api.getJson(
      '/claims',
      query: {'limit': '50', if (openOnly) 'state': 'open'},
    );
    return ApiResponse.listOf(res.data)
        .whereType<Map<String, dynamic>>()
        .map(ClaimRow.fromJson)
        .toList(growable: false);
  }

  Future<ClaimThread> detail(String id) async {
    final res = await _api.getJson('/claims/$id');
    return ClaimThread.fromJson(ApiResponse.mapOf(res.data));
  }

  /// `staffOnly` n'a d'effet que pour le support : le vendeur écrit toujours
  /// au support seul, quoi qu'on envoie.
  Future<void> reply(String id, String body, {bool staffOnly = false}) =>
      _api.postJson(
        '/claims/$id/messages',
        body: {'body': body, if (staffOnly) 'visibility': 'STAFF_ONLY'},
      );
}

String _s(Object? v) => v is String ? v : '';
int _i(Object? v) => v is num ? v.toInt() : 0;
DateTime _d(Object? v) =>
    (v is String ? DateTime.tryParse(v) : null)?.toLocal() ?? DateTime(1970);

const claimReasonLabels = <String, String>{
  'MISSING_ITEM': 'Article manquant',
  'WRONG_ITEM': 'Article erroné',
  'DAMAGED': 'Article abîmé',
  'LATE': 'Retard',
  'OTHER': 'Autre',
  'NOT_RECEIVED': 'Commande non reçue',
  'WRONG_ORDER': 'Mauvaise commande',
};

String claimStateLabel(String status, String? outcome) => switch (outcome) {
  'REFUNDED' => 'Remboursée',
  'VOUCHER' => 'Avoir',
  'REJECTED' => 'Refusée',
  _ => switch (status) {
    'OPEN' => 'Sans réponse',
    'IN_PROGRESS' => 'En cours',
    _ => 'Traitée',
  },
};

class ClaimRow {
  const ClaimRow({
    required this.id,
    required this.orderRef,
    required this.status,
    required this.reason,
    required this.summary,
    required this.outcome,
    required this.createdAt,
  });

  final String id;
  final String orderRef;
  final String status;
  final String reason;
  final String summary;
  final String? outcome;
  final DateTime createdAt;

  factory ClaimRow.fromJson(Map<String, dynamic> j) => ClaimRow(
    id: _s(j['id']),
    orderRef: _s(j['orderRef']),
    status: _s(j['status']),
    reason: _s(j['reason']),
    summary: _s(j['summary']),
    outcome: j['outcome'] as String?,
    createdAt: _d(j['createdAt']),
  );
}

class ClaimThreadMessage {
  const ClaimThreadMessage({
    required this.authorLabel,
    required this.body,
    required this.staffOnly,
    required this.mine,
    required this.createdAt,
  });

  final String authorLabel;
  final String body;
  final bool staffOnly;
  final bool mine;
  final DateTime createdAt;
}

class ClaimThread {
  const ClaimThread({
    required this.id,
    required this.orderRef,
    required this.status,
    required this.reason,
    required this.summary,
    required this.outcome,
    required this.resolution,
    required this.vendorImpactXaf,
    required this.messages,
  });

  final String id;
  final String orderRef;
  final String status;
  final String reason;
  final String summary;
  final String? outcome;
  final String? resolution;

  /// Ce qui sera retenu sur le prochain reversement du vendeur.
  final int vendorImpactXaf;
  final List<ClaimThreadMessage> messages;

  bool get isClosed => status == 'CLOSED';

  factory ClaimThread.fromJson(Map<String, dynamic> j) {
    final raw = j['messages'];
    final list = raw is List
        ? raw.whereType<Map<String, dynamic>>()
        : const <Map<String, dynamic>>[];
    return ClaimThread(
      id: _s(j['id']),
      orderRef: _s(j['orderRef']),
      status: _s(j['status']),
      reason: _s(j['reason']),
      summary: _s(j['summary']),
      outcome: j['outcome'] as String?,
      resolution: j['resolution'] as String?,
      vendorImpactXaf: _i(j['vendorImpactXaf']),
      messages: [
        for (final m in list)
          ClaimThreadMessage(
            authorLabel: _s(m['authorLabel']),
            body: _s(m['body']),
            staffOnly: m['visibility'] == 'STAFF_ONLY',
            mine: m['mine'] == true,
            createdAt: _d(m['createdAt']),
          ),
      ],
    );
  }
}

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/utils/api_response.dart';

part 'audit_log_service.g.dart';

/// Une action d'administration tracée.
///
/// Changer un rôle, bannir un compte, suspendre un vendeur ou confirmer un
/// paiement ne laissait qu'une ligne de log applicatif — perdue à la rotation,
/// non interrogeable, sans valeur en cas de litige. Le backend écrit ces
/// entrées depuis le 28/08 ; cet écran est le premier à les lire.
class AuditLogEntry {
  final String id;
  final String action;
  final String targetType;
  final String targetId;
  final String? reason;
  final DateTime createdAt;
  final String? actorNom;
  final String? actorEmail;
  final Map<String, dynamic>? metadata;

  const AuditLogEntry({
    required this.id,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.createdAt,
    this.reason,
    this.actorNom,
    this.actorEmail,
    this.metadata,
  });

  /// Libellé lisible. Le fallback renvoie l'enum brute plutôt que « Action
  /// inconnue » : si le backend en ajoute une, mieux vaut afficher un nom
  /// technique qu'effacer l'information.
  String get label => switch (action) {
    'USER_ROLE_CHANGED' => 'Rôle modifié',
    'USER_BANNED' => 'Compte banni',
    'USER_UNBANNED' => 'Bannissement levé',
    'VENDOR_APPROVED' => 'Vendeur approuvé',
    'VENDOR_SUSPENDED' => 'Vendeur suspendu',
    'VENDOR_ACTIVE_TOGGLED' => 'Vendeur activé / désactivé',
    'PAYMENT_CONFIRMED' => 'Paiement confirmé',
    'PAYMENT_REJECTED' => 'Paiement rejeté',
    'REFUND_CREATED' => 'Remboursement ouvert',
    'REFUND_UPDATED' => 'Remboursement mis à jour',
    'ORDER_STATUS_FORCED' => 'Statut de commande forcé',
    _ => action,
  };

  bool get isSensitive =>
      action == 'USER_ROLE_CHANGED' ||
      action == 'USER_BANNED' ||
      action == 'PAYMENT_CONFIRMED';

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    final actor = json['actor'] as Map<String, dynamic>?;
    return AuditLogEntry(
      id: json['id'] as String? ?? '',
      action: json['action'] as String? ?? '',
      targetType: json['targetType'] as String? ?? '',
      targetId: json['targetId'] as String? ?? '',
      reason: json['reason'] as String?,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      actorNom: actor?['nom'] as String?,
      actorEmail: actor?['email'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

class AuditLogService {
  final ApiClient _api;

  AuditLogService(this._api);

  /// `GET /admin/audit-log` — le plus récent d'abord.
  Future<List<AuditLogEntry>> list({String? action, int page = 1}) async {
    final res = await _api.getJson(
      '/admin/audit-log',
      query: {
        'page': '$page',
        'limit': '50',
        if (action != null) 'action': action,
      },
    );
    return ApiResponse.listOf(res.data)
        .map((e) => AuditLogEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

@Riverpod(keepAlive: true)
AuditLogService auditLogService(Ref ref) =>
    AuditLogService(ref.watch(apiClientProvider));

@riverpod
Future<List<AuditLogEntry>> auditLogList(Ref ref, String? action) async {
  return ref.watch(auditLogServiceProvider).list(action: action);
}

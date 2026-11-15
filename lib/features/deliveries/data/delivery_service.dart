import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/core/network/api_exception.dart';
import 'package:lilia_admin/utils/api_response.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../models/app_deliverer.dart';

part 'delivery_service.g.dart';

/// État de la course tel que le vendeur a besoin de le voir.
///
/// Le statut de la COMMANDE reste `PRET` entre l'acceptation de la mission et
/// la récupération du repas — c'est voulu : la commande n'est pas « en route »
/// tant qu'elle est sur le comptoir. Mais le vendeur, lui, doit savoir qu'un
/// livreur a pris la course et arrive.
class OrderDeliveryState {
  final String? deliveryId;
  final String? status;
  final String? delivererNom;
  final String? delivererPhone;

  const OrderDeliveryState({
    this.deliveryId,
    this.status,
    this.delivererNom,
    this.delivererPhone,
  });

  bool get isAssigned => status == 'ASSIGNER';
  bool get isAccepted => status == 'ACCEPTER';
  bool get isOnTheWay => status == 'EN_TRANSIT';
  bool get isDone => status == 'LIVRER';

  /// Un livreur est engagé sur la course : inutile de proposer d'en assigner
  /// un autre en premier réflexe.
  bool get hasActiveDeliverer => isAssigned || isAccepted || isOnTheWay;

  /// Le repas est encore au comptoir : le vendeur peut déclarer que personne
  /// n'est venu le chercher (F3-05).
  bool get canDeclareNoShow =>
      deliveryId != null && (isAssigned || isAccepted);

  String get label => switch (status) {
    'ASSIGNER' => 'Livreur assigné — en attente de sa réponse',
    'ACCEPTER' => 'Le livreur a accepté et vient récupérer la commande',
    'EN_TRANSIT' => 'Le livreur est parti avec la commande',
    'LIVRER' => 'Commande livrée',
    'ECHEC' => 'Livraison en échec — Lilia réassigne ou tranche',
    _ => 'Aucun livreur assigné',
  };

  factory OrderDeliveryState.fromJson(Map<String, dynamic> json) {
    final deliverer = json['deliverer'] as Map<String, dynamic>?;
    return OrderDeliveryState(
      deliveryId: json['id'] as String?,
      status: json['status'] as String?,
      delivererNom: deliverer?['nom'] as String?,
      delivererPhone: deliverer?['phone'] as String?,
    );
  }
}

/// État de la recherche de livreur d'une commande — dispatch FCFS
/// (« premier arrivé, premier servi », 10/11/2026).
///
/// Verdict **serveur** (`GET /deliveries/by-order/:orderId/dispatch`) : c'est
/// lui qui dit si l'affectation manuelle existe encore
/// (`manualAssignmentAllowed`, vrai seulement tant que `dispatchEnabled` est
/// éteint) et si l'ADMIN peut relancer. L'app n'en déduit rien d'elle-même :
/// le bouton suit le verdict, et disparaît à l'activation sans nouvelle
/// version.
class OrderDispatchView {
  const OrderDispatchView({
    required this.mode,
    required this.manualAssignmentAllowed,
    required this.redispatchAllowed,
    required this.state,
    this.deliveryId,
    this.deliveryStatus,
    this.startedAt,
    this.endedAt,
    this.nextRoundAt,
    this.round = 0,
    this.maxRounds = 5,
    this.notifiedCount = 0,
    this.waitingSeconds,
    this.outcome,
    this.delivererName,
  });

  /// `AUTOMATIC` (FCFS allumé) ou `MANUAL` (historique).
  final String mode;
  final bool manualAssignmentAllowed;
  final bool redispatchAllowed;

  /// `NONE` · `SEARCHING` · `ASSIGNED` · `EXHAUSTED` · `CLOSED`.
  final String state;
  final String? deliveryId;
  final String? deliveryStatus;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? nextRoundAt;
  final int round;
  final int maxRounds;
  final int notifiedCount;
  final int? waitingSeconds;
  final String? outcome;
  final String? delivererName;

  bool get isAutomatic => mode == 'AUTOMATIC';
  bool get isSearching => state == 'SEARCHING';
  bool get isExhausted => state == 'EXHAUSTED';
  bool get isAssigned => state == 'ASSIGNED';

  String get label => switch (state) {
    'SEARCHING' => 'Recherche d’un livreur en cours',
    'ASSIGNED' => delivererName != null
        ? 'Livreur attribué : $delivererName'
        : 'Livreur attribué',
    'EXHAUSTED' => 'Aucun livreur n’a accepté — relance requise',
    'CLOSED' => 'Recherche terminée',
    _ => isAutomatic
        ? 'En attente de passage à « Prête »'
        : 'Aucune recherche automatique',
  };

  factory OrderDispatchView.fromJson(Map<String, dynamic> json) {
    final deliverer = json['deliverer'];
    return OrderDispatchView(
      mode: json['mode'] as String? ?? 'MANUAL',
      manualAssignmentAllowed: json['manualAssignmentAllowed'] == true,
      redispatchAllowed: json['redispatchAllowed'] == true,
      state: json['state'] as String? ?? 'NONE',
      deliveryId: json['deliveryId'] as String?,
      deliveryStatus: json['deliveryStatus'] as String?,
      startedAt: _date(json['startedAt']),
      endedAt: _date(json['endedAt']),
      nextRoundAt: _date(json['nextRoundAt']),
      round: (json['round'] as num?)?.toInt() ?? 0,
      maxRounds: (json['maxRounds'] as num?)?.toInt() ?? 5,
      notifiedCount: (json['notifiedCount'] as num?)?.toInt() ?? 0,
      waitingSeconds: (json['waitingSeconds'] as num?)?.toInt(),
      outcome: json['outcome'] as String?,
      delivererName: deliverer is Map<String, dynamic>
          ? deliverer['nom'] as String?
          : null,
    );
  }

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;
}

class DeliveryService {
  final ApiClient _api;

  DeliveryService(this._api);

  /// FCFS — verdict serveur sur la recherche de livreur d'une commande.
  /// `null` si le serveur ne connaît pas encore la route (backend ancien) :
  /// l'écran retombe alors sur la règle historique.
  Future<OrderDispatchView?> getDispatchForOrder(String orderId) async {
    try {
      final res = await _api.getJson('/deliveries/by-order/$orderId/dispatch');
      return OrderDispatchView.fromJson(ApiResponse.mapOf(res.data));
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// FCFS — l'ADMIN relance la recherche d'une commande prête (épuisée,
  /// arrêtée, ou sans course). Ne choisit **jamais** de livreur.
  Future<void> redispatchOrder(String orderId) async {
    await _api.postJson('/admin/deliveries/by-order/$orderId/redispatch');
  }

  Future<List<AppDeliverer>> getAvailableDeliverers() async {
    final res = await _api.getJson('/deliveries/deliverers');
    final data = ApiResponse.listOf(res.data);
    return data
        .map((e) => AppDeliverer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// PATCH /deliveries/by-order/:orderId/assign
  /// Crée la livraison si elle n'existe pas, puis assigne le livreur.
  Future<void> assignDelivererToOrder(String orderId, String delivererId) async {
    await _api.patchJson(
      '/deliveries/by-order/$orderId/assign',
      body: {'delivererId': delivererId},
    );
  }

  /// POST /deliveries/:id/failure — « aucun livreur n'est venu » (F3-05).
  ///
  /// Permis au vendeur **avant la récupération seulement** : une fois le repas
  /// parti, il ne sait pas ce qui arrive (le serveur refuse). La commande ne
  /// change pas : l'administration réassigne ou conclut l'échec.
  Future<void> declareDriverNoShow(String deliveryId, {String? note}) async {
    await _api.postJson(
      '/deliveries/$deliveryId/failure',
      body: {
        'reason': 'DRIVER_NO_SHOW',
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
  }

  /// GET /deliveries/by-order/:orderId — état de la course.
  ///
  /// Renvoie `null` si aucune livraison n'existe encore (retrait au comptoir,
  /// ou livreur pas encore assigné) : c'est un cas normal, pas une erreur.
  Future<OrderDeliveryState?> getStateForOrder(String orderId) async {
    try {
      final res = await _api.getJson('/deliveries/by-order/$orderId');
      final data = (res.data as Map<String, dynamic>)['data'];
      if (data == null) return null;
      return OrderDeliveryState.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

/// État de la livraison d'une commande, rafraîchi à l'ouverture de l'écran.
@riverpod
Future<OrderDeliveryState?> orderDeliveryState(Ref ref, String orderId) async {
  return DeliveryService(ref.watch(apiClientProvider)).getStateForOrder(orderId);
}

@riverpod
Future<OrderDispatchView?> orderDispatchView(Ref ref, String orderId) async {
  return DeliveryService(
    ref.watch(apiClientProvider),
  ).getDispatchForOrder(orderId);
}

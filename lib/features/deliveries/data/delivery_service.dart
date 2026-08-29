import 'package:lilia_admin/core/network/api_client.dart';
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

  String get label => switch (status) {
    'ASSIGNER' => 'Livreur assigné — en attente de sa réponse',
    'ACCEPTER' => 'Le livreur a accepté et vient récupérer la commande',
    'EN_TRANSIT' => 'Le livreur est parti avec la commande',
    'LIVRER' => 'Commande livrée',
    'ECHEC' => 'Livraison en échec — action requise',
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

class DeliveryService {
  final ApiClient _api;

  DeliveryService(this._api);

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

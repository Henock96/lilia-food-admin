import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/features/deliveries/data/delivery_service.dart';

/// « Aucun livreur n'est venu » (F3-05) : seulement tant que le repas est
/// au comptoir — le serveur refuse ensuite.
void main() {
  OrderDeliveryState state(String? status, {String? id = 'd1'}) =>
      OrderDeliveryState(deliveryId: id, status: status);

  test('assigné ou accepté : le vendeur peut déclarer', () {
    expect(state('ASSIGNER').canDeclareNoShow, isTrue);
    expect(state('ACCEPTER').canDeclareNoShow, isTrue);
  });

  test('parti, livré, déjà en échec ou sans livraison : non', () {
    expect(state('EN_TRANSIT').canDeclareNoShow, isFalse);
    expect(state('LIVRER').canDeclareNoShow, isFalse);
    expect(state('ECHEC').canDeclareNoShow, isFalse);
    expect(state(null).canDeclareNoShow, isFalse);
    expect(state('ASSIGNER', id: null).canDeclareNoShow, isFalse);
  });
}

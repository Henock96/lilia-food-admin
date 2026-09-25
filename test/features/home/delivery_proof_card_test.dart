import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lilia_admin/features/home/presentation/widgets/delivery_proof_card.dart';
import 'package:lilia_admin/models/order.dart';

/// Preuve de remise vue par le vendeur (F3-07) : « livrée » ne dit plus si
/// le restaurant peut être payé — c'est la preuve qui le dit.
Order _order({
  String status = 'LIVRER',
  bool isDelivery = false,
  String? proof,
  String? payoutDueAt,
  String? customerConfirmedAt,
}) =>
    Order.fromJson({
      'id': 'o-1',
      'total': 4000,
      'createdAt': '2026-09-25T11:00:00.000Z',
      'status': status,
      'isDelivery': isDelivery,
      'items': [],
      'deliveryProof': proof,
      'deliveredAt': '2026-09-25T12:00:00.000Z',
      'payoutDueAt': payoutDueAt,
      'customerConfirmedAt': customerConfirmedAt,
    });

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  Future<void> pump(WidgetTester tester, Order order) => tester.pumpWidget(
        MaterialApp(home: Scaffold(body: DeliveryProofCard(order: order))),
      );

  test('lit la preuve, la remise, la confirmation et l’échéance', () {
    final order = _order(
      proof: 'PICKUP_CUSTOMER_CONFIRMED',
      customerConfirmedAt: '2026-09-25T12:05:00.000Z',
      payoutDueAt: '2026-09-25T13:05:00.000Z',
    );
    expect(order.deliveryProof, 'PICKUP_CUSTOMER_CONFIRMED');
    expect(order.deliveredAt, DateTime.utc(2026, 9, 25, 12));
    expect(order.customerConfirmedAt, DateTime.utc(2026, 9, 25, 12, 5));
    expect(order.payoutDueAt, DateTime.utc(2026, 9, 25, 13, 5));
  });

  test('rien à montrer avant la remise, ou sans preuve (commande ancienne)', () {
    expect(DeliveryProofCard.isRelevant(_order(status: 'PRET')), isFalse);
    expect(DeliveryProofCard.isRelevant(_order()), isFalse);
  });

  testWidgets('remise déclarée seul : le vendeur lit pourquoi il attend', (
    tester,
  ) async {
    await pump(tester, _order(proof: 'PICKUP_VENDOR_DECLARED'));
    expect(find.text('Remise déclarée par le restaurant'), findsOneWidget);
    expect(
      find.textContaining('En attente de la confirmation du client'),
      findsOneWidget,
    );
  });

  testWidgets('code du client : paiement possible à l’échéance', (tester) async {
    await pump(
      tester,
      _order(proof: 'PICKUP_CODE', payoutDueAt: '2026-09-25T13:00:00.000Z'),
    );
    expect(find.text('Remise prouvée par le code du client'), findsOneWidget);
    expect(
      find.textContaining('Paiement du restaurant possible à partir du'),
      findsOneWidget,
    );
  });

  testWidgets('confirmation client : datée', (tester) async {
    await pump(
      tester,
      _order(
        proof: 'PICKUP_CUSTOMER_CONFIRMED',
        customerConfirmedAt: '2026-09-25T12:05:00.000Z',
        payoutDueAt: '2026-09-25T13:05:00.000Z',
      ),
    );
    expect(find.text('Retrait confirmé par le client'), findsOneWidget);
    expect(find.textContaining('Confirmé par le client le'), findsOneWidget);
  });

  testWidgets('livraison sans code : paiement non automatique', (tester) async {
    await pump(tester, _order(isDelivery: true, proof: 'DELIVERY_UNVERIFIED'));
    expect(find.text('Livrée sans code du client'), findsOneWidget);
    expect(find.textContaining('pas automatique'), findsOneWidget);
  });

  test('chaque preuve connue a son libellé', () {
    for (final proof in [
      'DELIVERY_CODE',
      'DELIVERY_ADMIN_OVERRIDE',
      'DELIVERY_UNVERIFIED',
      'PICKUP_CODE',
      'PICKUP_CUSTOMER_CONFIRMED',
      'PICKUP_ADMIN_OVERRIDE',
      'PICKUP_VENDOR_DECLARED',
    ]) {
      expect(deliveryProofLook(_order(proof: proof)), isNotNull, reason: proof);
    }
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/models/order_financials.dart';

/// Lecture du récapitulatif financier.
///
/// Ce que ces tests verrouillent : l'application **n'invente rien**. Elle
/// affiche les chiffres du serveur, et surtout elle ne considère un vendeur
/// comme payé que sur un `SUCCESS` explicite.
void main() {
  Map<String, dynamic> payload({
    String orderStatus = 'PRET',
    Map<String, dynamic>? payout,
    bool paid = false,
    Map<String, dynamic>? eligibility,
    Map<String, dynamic>? liliaOverrides,
  }) =>
      {
        'orderId': 'ord-1',
        'orderRef': 'A1B2C3',
        'orderStatus': orderStatus,
        'client': {
          'subTotal': 5000,
          'deliveryFee': 1000,
          'serviceFee': 400,
          'discountAmount': 0,
          'totalPaid': 6400,
          'collection': {
            'paymentId': 'pay-1',
            'status': 'SUCCESS',
            'provider': 'PAWAPAY',
            'method': 'MTN_MOMO',
            'amount': 6400,
            'completedAt': '2026-08-30T10:15:00.000Z',
          },
        },
        'restaurant': {
          'id': 'r1',
          'nom': 'Chez Mère Lili',
          'grossAmount': 5000,
          'commissionPercent': 10,
          'commissionAmount': 500,
          'payoutAmount': 4500,
          'payoutAccount': {
            'phoneNumber': '***67',
            'provider': 'MTN_MOMO',
            'accountName': 'Lili M.',
            'configured': true,
          },
          'payout': payout,
          'paid': paid,
        },
        'liliaFood': {
          'serviceFee': 400,
          'restaurantCommission': 500,
          'collectionFee': null,
          'payoutFee': null,
          'netMargin': null,
          ...?liliaOverrides,
        },
        'eligibility': eligibility ?? {'eligible': true},
      };

  group('OrderFinancials', () {
    test('lit les trois flux séparément', () {
      final f = OrderFinancials.fromJson(payload());

      // Client
      expect(f.totalPaid, 6400);
      expect(f.serviceFee, 400);
      expect(f.collection?.isPaid, isTrue);

      // Vendeur — la commission ne sort PAS du total client
      expect(f.grossAmount, 5000);
      expect(f.commissionAmount, 500);
      expect(f.payoutAmount, 4500);

      // Plateforme
      expect(f.margin.serviceFee, 400);
      expect(f.margin.restaurantCommission, 500);
    });

    test('« payé » exige un SUCCESS explicite, pas un reversement en cours', () {
      final pending = OrderFinancials.fromJson(
        payload(payout: {'id': 'po-1', 'status': 'PENDING', 'amount': 4500}),
      );
      expect(pending.restaurantPaid, isFalse);
      expect(pending.payout?.status, PayoutStatus.pending);

      final failed = OrderFinancials.fromJson(
        payload(payout: {'id': 'po-1', 'status': 'FAILED', 'amount': 4500}),
      );
      expect(failed.restaurantPaid, isFalse);

      final success = OrderFinancials.fromJson(
        payload(
          payout: {'id': 'po-1', 'status': 'SUCCESS', 'amount': 4500},
          paid: true,
        ),
      );
      expect(success.restaurantPaid, isTrue);
    });

    test('les frais du prestataire restent distincts et peuvent être inconnus', () {
      final unknown = OrderFinancials.fromJson(payload());
      expect(unknown.margin.collectionFee, isNull);
      expect(unknown.margin.payoutFee, isNull);
      expect(unknown.margin.netMargin, isNull);

      final known = OrderFinancials.fromJson(
        payload(liliaOverrides: {
          'collectionFee': 96,
          'payoutFee': 45,
          'netMargin': 759,
        }),
      );
      // 400 + 500 − 96 − 45 = 759. Les frais sont des CHARGES de Lilia Food :
      // ils ne diminuent pas le reversement du vendeur, qui reste 4500.
      expect(known.margin.netMargin, 759);
      expect(known.payoutAmount, 4500);
    });

    test('traduit tous les motifs de non-éligibilité du serveur', () {
      const codes = {
        'ORDER_CANCELLED': PayoutIneligibility.orderCancelled,
        'ORDER_NOT_READY': PayoutIneligibility.orderNotReady,
        'PAYMENT_NOT_COMPLETED': PayoutIneligibility.paymentNotCompleted,
        'ORDER_REFUNDED': PayoutIneligibility.orderRefunded,
        'VENDOR_PAYOUT_ACCOUNT_MISSING':
            PayoutIneligibility.vendorPayoutAccountMissing,
        'PAYOUT_ALREADY_COMPLETED': PayoutIneligibility.payoutAlreadyCompleted,
        'PAYOUT_IN_PROGRESS': PayoutIneligibility.payoutInProgress,
        'PROVIDER_DOES_NOT_SUPPORT_PAYOUT':
            PayoutIneligibility.providerDoesNotSupportPayout,
      };

      codes.forEach((raw, expected) {
        final f = OrderFinancials.fromJson(
          payload(eligibility: {
            'eligible': false,
            'code': raw,
            'reason': 'motif serveur',
          }),
        );
        expect(f.eligibility.eligible, isFalse);
        expect(f.eligibility.code, expected);
        // Le message du serveur est repris tel quel : il porte l'action à mener.
        expect(f.eligibility.reason, 'motif serveur');
      });
    });

    test('un code inconnu ne casse pas l’écran', () {
      // Le backend peut ajouter un motif avant que l'application soit mise à
      // jour : on dégrade sur `unknown` plutôt que de lever.
      final f = OrderFinancials.fromJson(
        payload(eligibility: {
          'eligible': false,
          'code': 'UN_MOTIF_FUTUR',
          'reason': 'texte serveur',
        }),
      );
      expect(f.eligibility.code, PayoutIneligibility.unknown);
      expect(f.eligibility.reason, 'texte serveur');
    });

    test('parsing défensif : un payload amputé ne crashe pas', () {
      final f = OrderFinancials.fromJson({'orderId': 'ord-1'});
      expect(f.orderId, 'ord-1');
      expect(f.totalPaid, 0);
      expect(f.payoutAmount, 0);
      expect(f.restaurantPaid, isFalse);
      expect(f.eligibility.eligible, isFalse);
      expect(f.payoutAccount.configured, isFalse);
    });

    test('le numéro affiché est celui, masqué, fourni par le serveur', () {
      final f = OrderFinancials.fromJson(payload());
      // L'application ne reconstitue jamais un numéro complet : le serveur ne
      // le lui envoie pas.
      expect(f.payoutAccount.phoneNumber, '***67');
      expect(f.payoutAccount.phoneNumber, isNot(contains('242')));
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lilia_admin/features/admin/data/refunds_service.dart';
import 'package:lilia_admin/features/admin/presentation/providers/admin_operations_provider.dart';
import 'package:lilia_admin/features/admin/presentation/screens/refunds_screen.dart';
import 'package:lilia_admin/features/admin/presentation/widgets/manual_payment_confirm_dialog.dart';
import 'package:lilia_admin/features/admin/presentation/widgets/order_payout_card.dart';
import 'package:lilia_admin/features/home/presentation/widgets/delivery_proof_card.dart';
import 'package:lilia_admin/models/admin_payment.dart';
import 'package:lilia_admin/models/order_financials.dart';
import 'package:lilia_admin/models/refund.dart';

/// Lot 3 — gestes d'argent depuis l'app vendeurs/admin.
///
/// ADM-10 : confirmer un virement manuel en un appui.
/// ADM-11 : payer un vendeur sans voir comment la remise est prouvée.
/// ADM-14 (D-3) : remboursements réservés à l'admin web.
void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  group('ADM-10 — confirmation d\'un virement manuel', () {
    final payment = AdminPayment.fromJson({
      'id': 'pay-1',
      'amount': 12500,
      'phoneNumber': '+242061234567',
      'status': 'PENDING',
      'provider': 'MANUAL',
      'createdAt': '2026-10-22T10:00:00.000Z',
      'order': {
        'id': 'o1',
        'total': 12500,
        'status': 'EN_ATTENTE',
        'user': {'nom': 'Mireille'},
        'restaurant': {'nom': 'Chez Mère Lili'},
      },
    });

    Future<bool?> open(WidgetTester tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  result = await confirmManualPaymentDialog(context, payment),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      return result;
    }

    FilledButton confirmButton(WidgetTester tester) =>
        tester.widget<FilledButton>(find.byType(FilledButton));

    testWidgets('montre le montant et le numéro ; bouton inactif tant que la case n\'est pas cochée', (tester) async {
      await open(tester);

      expect(find.textContaining('12'), findsWidgets);
      expect(find.textContaining('+242061234567'), findsOneWidget);
      expect(confirmButton(tester).onPressed, isNull);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(confirmButton(tester).onPressed, isNotNull);
    });

    testWidgets('confirmer après la case → true', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  result = await confirmManualPaymentDialog(context, payment),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('annuler → false, aucune confirmation', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  result = await confirmManualPaymentDialog(context, payment),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });
  });

  group('ADM-11 — preuve de remise avant un versement', () {
    test('preuves faibles : déclarée, sans code, absente', () {
      expect(isWeakDeliveryProof('PICKUP_VENDOR_DECLARED'), isTrue);
      expect(isWeakDeliveryProof('DELIVERY_UNVERIFIED'), isTrue);
      expect(isWeakDeliveryProof(null), isTrue);
      expect(isWeakDeliveryProof('PICKUP_CODE'), isFalse);
      expect(isWeakDeliveryProof('DELIVERY_CODE'), isFalse);
    });

    final financials = OrderFinancials.fromJson({
      'orderId': 'o1',
      'orderRef': 'A1B2C3',
      'orderStatus': 'LIVRER',
      'client': {
        'subTotal': 5000,
        'deliveryFee': 1000,
        'serviceFee': 400,
        'discountAmount': 0,
        'totalPaid': 6400,
        'collection': null,
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
          'configured': true,
        },
        'payout': null,
        'paid': false,
      },
      'liliaFood': {
        'serviceFee': 400,
        'restaurantCommission': 500,
        'collectionFee': null,
        'payoutFee': null,
        'netMargin': null,
      },
      'eligibility': {'eligible': true},
    });

    Future<void> openPayout(WidgetTester tester, String? proof) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderFinancialsProvider(orderId: 'o1')
                .overrideWith((ref) async => financials),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: OrderPayoutCard(orderId: 'o1', deliveryProof: proof),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final pay = find.widgetWithText(FilledButton, 'Payer le restaurant · 4 500 FCFA');
      final button = pay.evaluate().isNotEmpty
          ? pay
          : find.byWidgetPredicate(
              (w) => w is FilledButton && w.onPressed != null,
            );
      expect(button, findsOneWidget);
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    FilledButton confirm(WidgetTester tester) => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Confirmer le paiement'),
    );

    testWidgets('preuve forte : ligne de preuve, pas d\'avertissement, bouton actif', (tester) async {
      await openPayout(tester, 'PICKUP_CODE');

      expect(find.text('Remise prouvée par le code du client'), findsOneWidget);
      expect(find.byKey(const Key('payout-weak-proof-warning')), findsNothing);
      expect(confirm(tester).onPressed, isNotNull);
    });

    testWidgets('remise déclarée par le vendeur : avertissement et case obligatoire', (tester) async {
      await openPayout(tester, 'PICKUP_VENDOR_DECLARED');

      expect(find.byKey(const Key('payout-weak-proof-warning')), findsOneWidget);
      expect(confirm(tester).onPressed, isNull);

      await tester.tap(find.byKey(const Key('payout-weak-proof-ack')));
      await tester.pump();
      expect(confirm(tester).onPressed, isNotNull);
    });

    testWidgets('aucune preuve : traité comme une preuve faible', (tester) async {
      await openPayout(tester, null);

      expect(find.byKey(const Key('payout-weak-proof-warning')), findsOneWidget);
      expect(find.textContaining('Aucune preuve de remise'), findsWidgets);
      expect(confirm(tester).onPressed, isNull);
    });
  });

  group('ADM-14 (D-3) — remboursements en consultation', () {
    testWidgets('bandeau « admin web » et aucun bouton de clôture', (tester) async {
      final pending = Refund.fromJson({
        'id': 'rf-1',
        'orderId': 'o1',
        'amount': 6400,
        'status': 'PENDING',
        'reason': 'Commande annulée',
        'createdAt': '2026-10-22T10:00:00.000Z',
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            refundsListProvider(RefundStatus.pending).overrideWith(
              (ref) async => RefundPage(items: [pending], total: 1, page: 1),
            ),
          ],
          child: const MaterialApp(home: RefundsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('refunds-web-only-banner')), findsOneWidget);
      expect(find.text('À traiter depuis l’admin web.'), findsOneWidget);
      for (final s in RefundStatus.values) {
        expect(find.widgetWithText(OutlinedButton, s.label), findsNothing);
      }
    });
  });
}

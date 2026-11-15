import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/features/home/data/order_service.dart';
import 'package:lilia_admin/features/home/presentation/widgets/delivery_arbitration_dialog.dart';
import 'package:lilia_admin/models/delivery_arbitration.dart';
import 'package:lilia_admin/models/order.dart';

/// 15/11/2026 — clôture d'une livraison par l'ADMIN : requête exacte, avoir
/// lu dans la réponse, bornes du DTO reprises par le dialogue, verdict lu.
void main() {
  ({OrderService service, DioAdapter adapter}) build() {
    final client = ApiClient.test(
      baseUrl: 'https://test.local',
      tokenProvider: () async => 'tok',
      forceRefreshToken: () async => 'tok2',
    );
    return (
      service: OrderService(client),
      adapter: DioAdapter(dio: client.dio),
    );
  }

  group('requête', () {
    test('motif, note nettoyée, avoir ; le code de l’avoir est rendu', () async {
      final t = build();
      t.adapter.onPost(
        '/admin/orders/o1/delivery/arbitrate',
        (s) => s.reply(200, {
          'data': {
            'id': 'o1',
            'status': 'LIVRER',
            'deliveryProof': 'DELIVERY_ADMIN_OVERRIDE',
            'voucher': {
              'code': 'AVOIR-ABCD2345',
              'amountXaf': 2500,
              'expiresAt': '2026-12-15T00:00:00.000Z',
            },
          },
        }),
        data: {
          'reason': 'CUSTOMER_REFUSED',
          'note': 'Refus à la porte',
          'voucherAmountXaf': 2500,
        },
      );

      final voucher = await t.service.arbitrateDelivery(
        'o1',
        reason: DeliveryArbitrationReason.customerRefused,
        note: '  Refus à la porte ',
        voucherAmountXaf: 2500,
      );

      expect(voucher?.code, 'AVOIR-ABCD2345');
      expect(voucher?.amountXaf, 2500);
    });

    test('sans note ni avoir : seul le motif part, aucun avoir rendu', () async {
      final t = build();
      t.adapter.onPost(
        '/admin/orders/o1/delivery/arbitrate',
        (s) => s.reply(200, {
          'data': {'id': 'o1', 'status': 'LIVRER', 'voucher': null},
        }),
        data: {'reason': 'DRIVER_DID_NOT_CONFIRM'},
      );

      final voucher = await t.service.arbitrateDelivery(
        'o1',
        reason: DeliveryArbitrationReason.driverDidNotConfirm,
        note: '   ',
      );

      expect(voucher, isNull);
    });
  });

  group('modèle', () {
    test('motifs = liste fermée du serveur', () {
      expect(DeliveryArbitrationReason.values.map((r) => r.wire), [
        'CUSTOMER_REFUSED',
        'DRIVER_DID_NOT_CONFIRM',
        'DELIVERED_OUTSIDE_APP',
        'OTHER',
      ]);
      expect(DeliveryArbitrationReason.other.acceptsNote('ok'), isFalse);
      expect(DeliveryArbitrationReason.other.acceptsNote('Client parti'), isTrue);
      expect(DeliveryArbitrationReason.customerRefused.acceptsNote(''), isTrue);
    });

    test('avoir : vide = aucun ; entier 100–100 000 sans dépasser le total', () {
      expect(parseVoucherAmount('', 5000), (ok: true, amount: null));
      expect(parseVoucherAmount('2500', 5000), (ok: true, amount: 2500));
      expect(parseVoucherAmount('99', 5000).ok, isFalse);
      expect(parseVoucherAmount('5001', 5000).ok, isFalse);
      expect(parseVoucherAmount('100001', 200000).ok, isFalse);
    });

    test('verdict serveur lu ; absent sur un serveur antérieur', () {
      Map<String, dynamic> json(Object? arbitrable) => {
        'id': 'o1',
        'total': 5000,
        'status': 'PRET',
        'items': <dynamic>[],
        'deliveryArbitrable': ?arbitrable,
      };
      expect(Order.fromJson(json(true)).deliveryArbitrable, isTrue);
      expect(Order.fromJson(json(null)).deliveryArbitrable, isFalse);
      expect(
        Order.fromJson(json(true)).copyWith().deliveryArbitrable,
        isTrue,
      );
    });
  });

  testWidgets('dialogue : motif requis, avoir borné par le total payé', (
    tester,
  ) async {
    DeliveryArbitrationRequest? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDialog<DeliveryArbitrationRequest>(
                context: context,
                builder: (_) =>
                    const DeliveryArbitrationDialog(orderTotal: 5000),
              );
            },
            child: const Text('ouvrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    FilledButton confirm() => tester.widget<FilledButton>(
      find.byKey(const Key('delivery-arbitration-confirm')),
    );
    expect(confirm().onPressed, isNull);

    await tester.tap(find.text('Le client a refusé la commande'));
    await tester.pump();
    expect(confirm().onPressed, isNotNull);

    await tester.enterText(
      find.byKey(const Key('delivery-arbitration-voucher')),
      '9000',
    );
    await tester.pump();
    expect(confirm().onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('delivery-arbitration-voucher')),
      '1500',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('delivery-arbitration-confirm')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(result?.reason, DeliveryArbitrationReason.customerRefused);
    expect(result?.voucherAmountXaf, 1500);
    expect(result?.note, isNull);
  });
}

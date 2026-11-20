import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lilia_admin/features/reservations/data/reservation_agenda_repository.dart';
import 'package:lilia_admin/features/reservations/presentation/reservation_agenda_providers.dart';
import 'package:lilia_admin/features/reservations/presentation/reservation_agenda_screens.dart';
import 'package:lilia_admin/features/reservations/presentation/reservation_order_badge.dart';
import 'package:lilia_admin/models/order.dart';

/// Lot 4 (4C) — l'écran affiche le verdict serveur, rien de plus : un geste
/// non publié n'a pas de bouton, un geste publié en a un.
Map<String, dynamic> _raw(String name) =>
    jsonDecode(
          File(
            'test/features/reservations/fixtures/agenda_$name.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;

Map<String, dynamic> _data(String name) =>
    _raw(name)['data'] as Map<String, dynamic>;

VendorReservation _pending() => VendorReservation.fromJson(
  (_raw('vendor_list_pending')['data'] as List).first as Map<String, dynamic>,
);

VendorReservation _with(String fixture, List<String> actions) =>
    VendorReservation.fromJson({..._data(fixture), 'allowedActions': actions});

Future<void> _pump(
  WidgetTester tester,
  VendorReservation r, {
  VoidCallback? onAccept,
  void Function(String)? onOpenOrder,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: ReservationDetailView(
        r: r,
        busy: false,
        onAccept: onAccept ?? () {},
        onDecline: () {},
        onCancel: () {},
        onNoShow: () {},
        onUndoNoShow: () {},
        onReassign: () {},
        onOpenOrder: onOpenOrder ?? (_) {},
      ),
    ),
  ),
);

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  testWidgets('demande : Accepter, Refuser, Changer de table — rien d’autre', (
    tester,
  ) async {
    var accepted = 0;
    await _pump(tester, _pending(), onAccept: () => accepted++);

    expect(find.text('Demande à traiter'), findsOneWidget);
    expect(find.textContaining('Répondez avant'), findsOneWidget);
    expect(find.text('2 × Poulet DG (Normal)'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Changer de table'), 200);
    expect(find.text('Accepter'), findsOneWidget);
    expect(find.text('Refuser'), findsOneWidget);
    expect(find.text('Annuler la réservation'), findsNothing);
    expect(find.text('Client absent'), findsNothing);

    await tester.tap(find.text('Accepter'));
    expect(accepted, 1);
  });

  testWidgets('confirmée : montants réels et lien vers la commande liée', (
    tester,
  ) async {
    String? opened;
    final r = VendorReservation.fromJson(_data('vendor_get_confirmed'));
    await _pump(tester, r, onOpenOrder: (id) => opened = id);

    expect(find.text('Confirmée (payée)'), findsOneWidget);
    final open = find.text('Ouvrir la commande (préparation, code)');
    await tester.scrollUntilVisible(open, 200);
    expect(find.text('Total payé par le client'), findsOneWidget);
    await tester.tap(open);
    expect(opened, r.payment!.orderId);

    await tester.scrollUntilVisible(find.text('Annuler la réservation'), 200);
    expect(find.text('Accepter'), findsNothing);
  });

  testWidgets('honorée : aucun geste', (tester) async {
    await _pump(tester, VendorReservation.fromJson(_data('vendor_get_honored')));
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pump();
    for (final label in [
      'Accepter',
      'Refuser',
      'Changer de table',
      'Client absent',
      'Retirer l’absence',
      'Annuler la réservation',
    ]) {
      expect(find.text(label), findsNothing, reason: label);
    }
  });

  testWidgets('absence publiée : bouton « Client absent »', (tester) async {
    await _pump(tester, _with('vendor_get_confirmed', ['noShow']));
    await tester.scrollUntilVisible(find.text('Client absent'), 200);
    expect(find.text('Client absent'), findsOneWidget);
  });

  testWidgets('agenda : erreur serveur affichée, pas de roue infinie', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reservationAgendaProvider.overrideWith(
            (ref, date) => Future.error(Exception('réseau coupé')),
          ),
          pendingReservationsProvider.overrideWith(
            (ref) async => const ReservationAgendaPage(items: [], total: 0),
          ),
        ],
        child: const MaterialApp(home: ReservationAgendaScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('réseau coupé'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('agenda : demandes à traiter en tête, jour vide annoncé', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reservationAgendaProvider.overrideWith(
            (ref, date) async =>
                const ReservationAgendaPage(items: [], total: 0),
          ),
          pendingReservationsProvider.overrideWith(
            (ref) async => ReservationAgendaPage(items: [_pending()], total: 1),
          ),
        ],
        child: const MaterialApp(home: ReservationAgendaScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 demande à traiter'), findsOneWidget);
    expect(find.text('Aucune réservation ce jour-là.'), findsOneWidget);
  });

  group('commande liée (F-6)', () {
    Order order(Object? reservationId) => Order.fromJson({
      'id': 'o-1',
      'total': 11500,
      'createdAt': '2026-11-20T12:00:00.000Z',
      'status': 'PAYER',
      'isDelivery': false,
      'items': [],
      'reservationId': reservationId,
    });

    test('reservationId lu depuis la commande', () {
      expect(order('resa-1').reservationId, 'resa-1');
      expect(order('resa-1').isReservation, isTrue);
      expect(order(null).isReservation, isFalse);
      expect(order('').isReservation, isFalse);
    });

    testWidgets('badge : lien pour le restaurateur, simple mention sinon', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ReservationOrderBadge(reservationId: 'resa-1'),
                ReservationOrderBadge(
                  reservationId: 'resa-1',
                  linkToReservation: false,
                ),
              ],
            ),
          ),
        ),
      );
      expect(
        find.text('Réservation de table — précommande'),
        findsNWidgets(2),
      );
      expect(find.text('Voir'), findsOneWidget);
    });
  });
}

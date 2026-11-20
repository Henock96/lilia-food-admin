import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/features/reservations/data/reservation_agenda_repository.dart';
import 'package:lilia_admin/features/reservations/data/reservation_settings_repository.dart';

/// Contrat app vendeurs ↔ backend (Lot 4, 4C), sur des réponses RÉELLES.
///
/// Les fixtures `agenda_*.json` ont été produites par le serveur lui-même :
/// harnais HTTP du backend (`test/http/reservations.http-spec.ts`), option
/// `HTTP_DUMP_DIR`, parcours « demande → acceptation → paiement → code →
/// honorée ». À régénérer quand le contrat évolue.
Map<String, dynamic> _fixture(String name) =>
    jsonDecode(
          File(
            'test/features/reservations/fixtures/agenda_$name.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;

const _path = '/vendors/me/reservations';

ApiClient _client() => ApiClient.test(
  baseUrl: 'https://test.local',
  tokenProvider: () async => 'tok',
  forceRefreshToken: () async => 'tok2',
);

void main() {
  test('liste du jour : demande à traiter, lue champ par champ', () async {
    final client = _client();
    final raw = _fixture('vendor_list_pending');
    DioAdapter(dio: client.dio).onGet(
      _path,
      (s) => s.reply(200, raw),
      queryParameters: {'page': '1', 'limit': '50', 'date': '2026-11-21'},
    );

    final page = await ReservationAgendaRepository(
      client,
    ).list(date: '2026-11-21');

    final row = (raw['data'] as List).first as Map<String, dynamic>;
    expect(page.total, (raw['meta'] as Map)['total']);
    final r = page.items.single;
    expect(r.id, row['id']);
    expect(r.status, 'PENDING');
    expect(r.partySize, row['partySize']);
    expect(r.arrivalAt, DateTime.parse(row['arrivalAt'] as String));
    expect(
      r.responseDeadlineAt,
      DateTime.parse(row['responseDeadlineAt'] as String),
    );
    expect(r.space.label, (row['space'] as Map)['label']);
    expect(r.space.kind, ReservationSpaceKind.table);
    expect(r.customer.phone, (row['customer'] as Map)['phone']);
    expect(r.items.single.name, 'Poulet DG');
    expect(r.items.single.quantity, 2);
    expect(r.items.single.indicativeLineTotal, 10000);
    expect(r.payment, isNull, reason: 'aucune commande avant l’acceptation');
    expect(r.allowedActions, [
      VendorReservationAction.accept,
      VendorReservationAction.decline,
      VendorReservationAction.reassign,
    ]);
  });

  test('confirmée : commande liée et montants réels en XAF entiers', () async {
    final client = _client();
    final raw = _fixture('vendor_get_confirmed');
    final d = raw['data'] as Map<String, dynamic>;
    DioAdapter(
      dio: client.dio,
    ).onGet('$_path/${d['id']}', (s) => s.reply(200, raw));

    final r = await ReservationAgendaRepository(client).get(d['id'] as String);

    final p = d['payment'] as Map<String, dynamic>;
    expect(r.status, 'CONFIRMED');
    expect(r.payment!.orderId, p['orderId']);
    expect(r.payment!.orderStatus, p['orderStatus']);
    expect(r.payment!.subTotal, p['subTotal']);
    expect(r.payment!.serviceFee, p['serviceFee']);
    expect(r.payment!.total, p['total']);
    expect(r.payment!.priceChanged, p['priceChanged']);
    expect(r.allowedActions, [
      VendorReservationAction.cancel,
      VendorReservationAction.reassign,
    ]);
  });

  test('honorée : plus aucun geste', () async {
    final client = _client();
    final raw = _fixture('vendor_get_honored');
    final d = raw['data'] as Map<String, dynamic>;
    DioAdapter(
      dio: client.dio,
    ).onGet('$_path/${d['id']}', (s) => s.reply(200, raw));

    final r = await ReservationAgendaRepository(client).get(d['id'] as String);
    expect(r.status, 'HONORED');
    expect(r.allowedActions, isEmpty);
  });

  test('accepter : POST …/accept, la réponse est la réservation relue', () async {
    final client = _client();
    final raw = _fixture('vendor_accept');
    final d = raw['data'] as Map<String, dynamic>;
    DioAdapter(dio: client.dio).onPost(
      '$_path/${d['id']}/accept',
      (s) => s.reply(200, raw),
      data: <String, dynamic>{},
    );

    final r = await ReservationAgendaRepository(
      client,
    ).accept(d['id'] as String);
    expect(r.status, 'AWAITING_PAYMENT');
    expect(r.paymentDeadlineAt, isNotNull);
  });

  test('refuser et annuler envoient le motif fermé', () async {
    final client = _client();
    final raw = _fixture('vendor_accept');
    final adapter = DioAdapter(dio: client.dio);
    adapter
      ..onPost(
        '$_path/r1/decline',
        (s) => s.reply(200, raw),
        data: {'reason': 'FULLY_BOOKED'},
      )
      ..onPost(
        '$_path/r1/cancel',
        (s) => s.reply(200, raw),
        data: {'reason': 'CLOSED_UNEXPECTEDLY'},
      )
      ..onPost(
        '$_path/r1/reassign',
        (s) => s.reply(200, raw),
        data: {'spaceId': 'table-2'},
      );
    final repo = ReservationAgendaRepository(client);
    await repo.decline('r1', 'FULLY_BOOKED');
    await repo.cancel('r1', 'CLOSED_UNEXPECTEDLY');
    await repo.reassign('r1', 'table-2');
  });

  test('geste inconnu du serveur : ignoré, jamais deviné', () {
    expect(
      VendorReservationAction.listFromWire(['accept', 'teleport']),
      [VendorReservationAction.accept],
    );
    expect(VendorReservationAction.listFromWire(null), isEmpty);
  });

  test('motifs : listes fermées du serveur, libellés en français', () {
    expect(reservationDeclineReasons.keys, [
      'FULLY_BOOKED',
      'CLOSED',
      'ITEMS_UNAVAILABLE',
      'PARTY_TOO_LARGE',
      'OTHER',
    ]);
    expect(reservationVendorCancelReasons.keys, [
      'CLOSED_UNEXPECTEDLY',
      'ITEMS_UNAVAILABLE',
      'OVERBOOKED',
      'CLIENT_REQUEST',
      'OTHER',
    ]);
    expect(reservationReasonLabel('OVERBOOKED'), 'Trop de réservations');
  });
}

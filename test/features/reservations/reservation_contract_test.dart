import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/core/network/api_exception.dart';
import 'package:lilia_admin/features/reservations/data/reservation_settings_repository.dart';

/// Contrat app vendeurs ↔ backend (Premium Lot 3), sur des réponses RÉELLES.
///
/// Les fixtures de `fixtures/` ont été produites par le backend lui-même
/// (`lilia-engineering/features/2026-10-12-premium-lot3-reservations-config/
/// e2e-http-lot3.sh`, option `E2E_DUMP_DIR`), pas écrites à la main. Le parsing
/// du dépôt est tolérant (valeur par défaut sur champ absent) : ce test compare
/// chaque champ lu à sa valeur brute, pour qu'un renommage côté serveur
/// échoue ici au lieu de vider l'écran en silence. À régénérer quand le
/// contrat évolue.
Map<String, dynamic> _fixture(String name) =>
    jsonDecode(
          File(
            'test/features/reservations/fixtures/$name.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;

const _path = '/vendors/me/reservation-settings';

ApiClient _client() => ApiClient.test(
  baseUrl: 'https://test.local',
  tokenProvider: () async => 'tok',
  forceRefreshToken: () async => 'tok2',
);

Future<ReservationState> _mine(String name) async {
  final client = _client();
  DioAdapter(dio: client.dio).onGet(_path, (s) => s.reply(200, _fixture(name)));
  return ReservationSettingsRepository(client).mine();
}

void _expectStateMatches(ReservationState s, Map<String, dynamic> raw) {
  final d = raw['data'] as Map<String, dynamic>;
  for (final k in [
    'eligible',
    'configured',
    'enabled',
    'entitled',
    'platformEnabled',
    'effective',
  ]) {
    expect(d[k], isA<bool>(), reason: '$k absent ou mal typé côté serveur');
  }
  expect(s.eligible, d['eligible']);
  expect(s.configured, d['configured']);
  expect(s.enabled, d['enabled']);
  expect(s.entitled, d['entitled']);
  expect(s.platformEnabled, d['platformEnabled']);
  expect(s.effective, d['effective']);

  final l = d['limits'] as Map<String, dynamic>;
  expect(s.limits.slotStepAllowed, (l['slotStepMin'] as Map)['allowed']);
  expect(s.limits.minLeadMin.max, (l['minLeadMin'] as Map)['max']);
  expect(s.limits.maxPartySize.max, (l['maxPartySize'] as Map)['max']);

  final issues = d['issues'] as List;
  expect(s.issues.map((i) => i.code), issues.map((i) => (i as Map)['code']));
  expect(
    s.issues.map((i) => i.message),
    issues.map((i) => (i as Map)['message']),
  );

  final c = d['config'] as Map<String, dynamic>?;
  if (c == null) {
    expect(s.config, isNull);
  } else {
    final cfg = s.config!;
    expect(cfg.version, c['version']);
    expect(cfg.enabled, c['enabled']);
    expect(cfg.slotDurationMin, c['slotDurationMin']);
    expect(cfg.slotStepMin, c['slotStepMin']);
    expect(cfg.bufferMin, c['bufferMin']);
    expect(cfg.minLeadMin, c['minLeadMin']);
    expect(cfg.maxAdvanceDays, c['maxAdvanceDays']);
    expect(cfg.maxPartySize, c['maxPartySize']);
    void spacesMatch(List<ReservationSpace> parsed, List raw) {
      expect(parsed.length, raw.length);
      for (var i = 0; i < raw.length; i++) {
        final r = raw[i] as Map<String, dynamic>;
        expect(parsed[i].id, r['id']);
        expect(parsed[i].kind.name.toUpperCase(), r['kind']);
        expect(parsed[i].label, r['label']);
        expect(parsed[i].minGuests, r['minGuests']);
        expect(parsed[i].maxGuests, r['maxGuests']);
        expect(parsed[i].seatCount, r['seatCount']);
        expect(parsed[i].maxSeatsPerBooking, r['maxSeatsPerBooking']);
        expect(parsed[i].archivedAt == null, r['archivedAt'] == null);
      }
    }

    spacesMatch(cfg.spaces, c['spaces'] as List);
    spacesMatch(cfg.archivedSpaces, c['archivedSpaces'] as List);
    final w = c['windows'] as List;
    expect(
      cfg.windows.map((x) => '${x.dayOfWeek} ${x.startTime}-${x.endTime}'),
      w.map((x) => '${x['dayOfWeek']} ${x['startTime']}-${x['endTime']}'),
    );
  }

  final p = d['preview'] as Map<String, dynamic>?;
  if (p == null) {
    expect(s.preview, isNull);
  } else {
    final cap = p['capacity'] as Map<String, dynamic>;
    expect(s.preview!.tables, cap['tables']);
    expect(s.preview!.tableCovers, cap['tableCovers']);
    expect(s.preview!.seatSpaces, cap['seatSpaces']);
    expect(s.preview!.seats, cap['seats']);
    expect(s.preview!.totalCovers, cap['totalCovers']);
    expect(s.preview!.uncoveredPartySizes, p['uncoveredPartySizes']);
    expect(s.preview!.days.length, (p['days'] as List).length);
  }
}

void main() {
  group('contrat réel — lecture', () {
    for (final name in [
      'get_standard_unconfigured',
      'get_not_eligible',
      'put_premium_v1',
      'put_with_archived_v2',
      'get_revoked_frozen',
    ]) {
      test(name, () async {
        _expectStateMatches(await _mine(name), _fixture(name));
      });
    }

    test('révoqué : configuration lisible, écriture fermée', () async {
      final s = await _mine('get_revoked_frozen');
      expect(s.config, isNotNull);
      expect(s.canEdit, isFalse);
    });
  });

  test('contrat réel — aperçu refusé : constats par champ', () async {
    final raw = _fixture('preview_invalid');
    final client = _client();
    DioAdapter(
      dio: client.dio,
    ).onPost('$_path/preview', (s) => s.reply(200, raw), data: Matchers.any);
    final check = await ReservationSettingsRepository(
      client,
    ).preview(ReservationDraft.fromState(await _mine('put_premium_v1')));
    final d = raw['data'] as Map<String, dynamic>;
    expect(check.valid, d['valid']);
    expect(check.valid, isFalse);
    expect(
      check.issues.map((i) => '${i.severity}:${i.code}:${i.field}'),
      (d['issues'] as List).map(
        (i) => '${i['severity']}:${i['code']}:${i['field']}',
      ),
    );
    expect(check.issues.map((i) => i.code), contains('RESOURCE_KIND_CHANGED'));
  });

  group('contrat réel — erreurs (error.code lu par l’app)', () {
    for (final (name, status) in [
      ('error_400_invalid', 400),
      ('error_403_premium', 403),
      ('error_409_conflict', 409),
    ]) {
      test(name, () async {
        final raw = _fixture(name);
        final client = _client();
        DioAdapter(
          dio: client.dio,
        ).onPut(_path, (s) => s.reply(status, raw), data: Matchers.any);
        final repo = ReservationSettingsRepository(client);
        final error = await repo
            .save(ReservationDraft.fromState(await _mine('put_premium_v1')))
            .then<ApiException?>(
              (_) => null,
              onError: (Object e) => e as ApiException,
            );
        expect(error, isNotNull);
        expect(error!.statusCode, status);
        expect(error.code, (raw['error'] as Map)['code']);
        expect(error.message, raw['message']);
      });
    }

    test('les codes lus par l’écran sont ceux du serveur', () {
      expect(
        (_fixture('error_400_invalid')['error'] as Map)['code'],
        ReservationErrorCodes.invalid,
      );
      expect(
        (_fixture('error_409_conflict')['error'] as Map)['code'],
        ReservationErrorCodes.conflict,
      );
      expect(
        (_fixture('error_403_premium')['error'] as Map)['code'],
        ReservationErrorCodes.premiumRequired,
      );
    });
  });

  // Corps RÉEL d'un 429 : `message` technique en anglais, sans `error.code`.
  // L'écran ne doit jamais l'afficher tel quel.
  test('contrat réel — 429 : statut lu, message serveur technique', () async {
    final raw = _fixture('error_429_throttle');
    expect(raw['message'], contains('ThrottlerException'));
    final client = _client();
    DioAdapter(
      dio: client.dio,
    ).onPut(_path, (s) => s.reply(429, raw), data: Matchers.any);
    final error = await ReservationSettingsRepository(client)
        .save(ReservationDraft.fromState(await _mine('put_premium_v1')))
        .then<ApiException?>(
          (_) => null,
          onError: (Object e) => e as ApiException,
        );
    expect(error!.statusCode, 429);
    expect(error.code, isNull);
    expect(
      reservationErrorMessage(error),
      'Trop de demandes rapprochées. Patientez une seconde, puis réessayez.',
    );
  });

  test('message d’erreur : le message serveur français est conservé', () {
    const e = ApiException(
      'La configuration a été modifiée entre-temps.',
      statusCode: 409,
    );
    expect(reservationErrorMessage(e), e.message);
  });
}

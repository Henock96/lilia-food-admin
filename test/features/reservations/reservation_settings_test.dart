import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/core/network/api_exception.dart';
import 'package:lilia_admin/features/reservations/data/reservation_settings_repository.dart';
import 'package:lilia_admin/features/reservations/presentation/reservation_settings_providers.dart';
import 'package:lilia_admin/features/reservations/presentation/reservation_settings_screen.dart';

/// « Réservations sur place » (Premium Lot 3). Réponses modelées sur
/// `ReservationSettingsService.getMine` / `preview` (lilia-backend).
const _limits = {
  'slotDurationMin': {'min': 30, 'max': 240, 'default': 90},
  'slotStepMin': {
    'allowed': [15, 30, 60],
    'default': 30,
  },
  'bufferMin': {'min': 0, 'max': 60, 'default': 15},
  'minLeadMin': {'min': 30, 'max': 2880, 'default': 120},
  'maxAdvanceDays': {'min': 1, 'max': 90, 'default': 30},
  'maxPartySize': {'min': 1, 'max': 50, 'default': 8},
  'tableGuestsMax': 50,
  'seatCountMax': 200,
  'maxSeatsPerBookingMax': 50,
  'maxTables': 50,
  'maxSeatSpaces': 5,
  'maxTotalSeats': 200,
  'maxWindowsPerDay': 3,
  'labelMaxLength': 40,
};

Map<String, dynamic> _config() => {
  'version': 3,
  'enabled': true,
  'slotDurationMin': 90,
  'slotStepMin': 30,
  'bufferMin': 15,
  'minLeadMin': 120,
  'maxAdvanceDays': 30,
  'maxPartySize': 4,
  'spaces': [
    {
      'id': 't1',
      'kind': 'TABLE',
      'label': 'Table 1',
      'minGuests': 1,
      'maxGuests': 4,
      'seatCount': null,
      'maxSeatsPerBooking': null,
      'position': 0,
      'archivedAt': null,
    },
    {
      'id': 's1',
      'kind': 'SEATS',
      'label': 'Comptoir',
      'minGuests': null,
      'maxGuests': null,
      'seatCount': 6,
      'maxSeatsPerBooking': 2,
      'position': 1,
      'archivedAt': null,
    },
  ],
  'archivedSpaces': [],
  'windows': [
    {'dayOfWeek': 'LUNDI', 'startTime': '12:00', 'endTime': '14:00'},
  ],
};

Map<String, dynamic> _state({
  bool eligible = true,
  bool entitled = true,
  bool platformEnabled = false,
  bool effective = false,
  bool configured = true,
  List<Map<String, dynamic>> issues = const [],
}) => {
  'eligible': eligible,
  'configured': configured,
  'enabled': configured,
  'entitled': entitled,
  'platformEnabled': platformEnabled,
  'effective': effective,
  'premiumPaidUntil': entitled ? '2026-11-12T09:00:00.000Z' : null,
  'limits': _limits,
  'config': configured ? _config() : null,
  'issues': issues,
  'preview': configured
      ? {
          'capacity': {
            'tables': 1,
            'tableCovers': 4,
            'seatSpaces': 1,
            'seats': 6,
            'totalCovers': 10,
          },
          'uncoveredPartySizes': <int>[],
          'days': [
            {
              'dayOfWeek': 'LUNDI',
              'opening': {'openTime': '08:00', 'closeTime': '23:00'},
              'slots': [
                {
                  'time': '12:00',
                  'inOpeningHours': true,
                  'occupationPastClosing': false,
                },
              ],
            },
          ],
        }
      : null,
};

ApiClient _client() => ApiClient.test(
  baseUrl: 'https://test.local',
  tokenProvider: () async => 'tok',
  forceRefreshToken: () async => 'tok2',
);

void main() {
  group('ReservationSettingsRepository', () {
    test('GET : les cinq notions séparées, bornes et configuration', () async {
      final client = _client();
      DioAdapter(dio: client.dio).onGet(
        '/vendors/me/reservation-settings',
        (s) => s.reply(200, {'data': _state()}),
      );
      final state = await ReservationSettingsRepository(client).mine();
      expect(state.eligible, isTrue);
      expect(state.entitled, isTrue);
      expect(state.platformEnabled, isFalse);
      expect(state.effective, isFalse);
      expect(state.canEdit, isTrue);
      expect(state.limits.slotStepAllowed, [15, 30, 60]);
      expect(state.limits.minLeadMin.max, 2880);
      expect(state.config!.version, 3);
      expect(state.config!.spaces.map((s) => s.kind), [
        ReservationSpaceKind.table,
        ReservationSpaceKind.seats,
      ]);
      expect(state.preview!.totalCovers, 10);
    });

    test(
      'PUT : version lue, aucun identifiant de boutique, archivage explicite',
      () async {
        final client = _client();
        final state = ReservationState.fromJson(_state());
        final draft = ReservationDraft.fromState(state);
        draft.spaces.first.archived = true;
        DioAdapter(dio: client.dio).onPut(
          '/vendors/me/reservation-settings',
          (s) => s.reply(200, {'data': _state()}),
          data: {
            'enabled': true,
            'slotDurationMin': 90,
            'slotStepMin': 30,
            'bufferMin': 15,
            'minLeadMin': 120,
            'maxAdvanceDays': 30,
            'maxPartySize': 4,
            'spaces': [
              {
                'id': 't1',
                'kind': 'TABLE',
                'label': 'Table 1',
                'minGuests': 1,
                'maxGuests': 4,
                'archived': true,
              },
              {
                'id': 's1',
                'kind': 'SEATS',
                'label': 'Comptoir',
                'seatCount': 6,
                'maxSeatsPerBooking': 2,
              },
            ],
            'windows': [
              {'dayOfWeek': 'LUNDI', 'startTime': '12:00', 'endTime': '14:00'},
            ],
            'version': 3,
          },
        );
        final saved = await ReservationSettingsRepository(client).save(draft);
        expect(saved.configured, isTrue);
      },
    );

    test('preview : constats par champ et aperçu', () async {
      final client = _client();
      DioAdapter(dio: client.dio).onPost(
        '/vendors/me/reservation-settings/preview',
        (s) => s.reply(200, {
          'data': {
            'valid': false,
            'effective': false,
            'issues': [
              {
                'severity': 'ERROR',
                'code': 'DUPLICATE_LABEL',
                'field': 'spaces[1].label',
                'message': 'Le nom « Table 1 » est déjà utilisé.',
              },
              {
                'severity': 'WARNING',
                'code': 'PARTY_SIZES_UNCOVERED',
                'field': 'spaces',
                'message':
                    'Aucune ressource n’accueille un groupe de 5 personne(s).',
                'partySizes': [5],
              },
            ],
            'preview': _state()['preview'],
          },
        }),
        data: Matchers.any,
      );
      final draft = ReservationDraft.fromState(
        ReservationState.fromJson(_state()),
      );
      final check = await ReservationSettingsRepository(client).preview(draft);
      expect(check.valid, isFalse);
      expect(check.issues.first.isError, isTrue);
      expect(check.issues.last.partySizes, [5]);
    });

    test(
      'première configuration : valeurs par défaut du serveur, version 0',
      () {
        final draft = ReservationDraft.fromState(
          ReservationState.fromJson(_state(configured: false)),
        );
        expect(draft.version, 0);
        expect(draft.enabled, isFalse);
        expect(draft.slotDurationMin, 90);
        expect(draft.minLeadMin, 120);
        expect(draft.maxPartySize, 8);
        expect(draft.spaces, isEmpty);
      },
    );
  });

  group('ReservationSettingsScreen', () {
    Future<_FakeRepo> pump(
      WidgetTester tester,
      Map<String, dynamic> state, {
      ApiException? saveError,
      ReservationCheck? check,
      ApiException? previewError,
    }) async {
      tester.view.physicalSize = const Size(1080, 4800);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final repo = _FakeRepo(
        saveError: saveError,
        check: check,
        previewError: previewError,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reservationSettingsRepositoryProvider.overrideWithValue(repo),
            myReservationSettingsProvider.overrideWith(
              (ref) async => ReservationState.fromJson(state),
            ),
          ],
          child: const MaterialApp(home: ReservationSettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets(
      'retrait d’une plage : ses constats positionnels ne glissent pas sur la suivante',
      (tester) async {
        await pump(
          tester,
          _state(
            issues: [
              {
                'severity': 'WARNING',
                'code': 'OUTSIDE_OPENING_HOURS',
                'field': 'windows[0]',
                'message': 'Plage hors des horaires d’ouverture.',
              },
            ],
          ),
        );
        expect(
          find.text('Plage hors des horaires d’ouverture.'),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('res-add-window-MARDI')));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Retirer ces heures d’arrivée').first);
        await tester.pumpAndSettle();
        // La plage du mardi a glissé en windows[0] : elle n'hérite de rien.
        expect(find.text('Plage hors des horaires d’ouverture.'), findsNothing);
      },
    );

    testWidgets(
      'Standard : Premium requis, vérifier possible, enregistrer impossible',
      (tester) async {
        final repo = await pump(
          tester,
          _state(entitled: false, configured: false),
        );
        expect(find.byKey(const Key('res-premium-required')), findsOneWidget);
        expect(find.byKey(const Key('res-no-client-yet')), findsOneWidget);
        final save = tester.widget<FilledButton>(
          find.byKey(const Key('res-save')),
        );
        expect(save.onPressed, isNull);

        await tester.tap(find.byKey(const Key('res-check')));
        await tester.pumpAndSettle();
        expect(repo.previews, 1);
        expect(repo.saved, isNull);
      },
    );

    testWidgets('Premium : interrupteur plateforme éteint dit en clair', (
      tester,
    ) async {
      await pump(tester, _state());
      expect(find.byKey(const Key('res-premium-required')), findsNothing);
      expect(find.byKey(const Key('res-platform-off')), findsOneWidget);
      expect(find.byKey(const Key('res-no-client-yet')), findsOneWidget);
      expect(find.text('Table 1'), findsOneWidget);
      // L'aperçu est en bas d'une liste paresseuse : on y descend.
      await tester.scrollUntilVisible(
        find.byKey(const Key('res-capacity')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const Key('res-capacity')), findsOneWidget);
      expect(find.text('Comptoir'), findsOneWidget);
    });

    testWidgets('effective : annoncée, sans promettre de réservation client', (
      tester,
    ) async {
      await pump(tester, _state(platformEnabled: true, effective: true));
      expect(find.byKey(const Key('res-effective')), findsOneWidget);
      expect(find.byKey(const Key('res-no-client-yet')), findsOneWidget);
    });

    testWidgets('type non éligible : message seul, aucun formulaire', (
      tester,
    ) async {
      await pump(tester, _state(eligible: false, configured: false));
      expect(find.byKey(const Key('res-not-eligible')), findsOneWidget);
      expect(find.byKey(const Key('res-save')), findsNothing);
    });

    testWidgets(
      'archiver une table : elle part avec archived=true, jamais omise',
      (tester) async {
        final repo = await pump(tester, _state());
        await tester.tap(find.byKey(const Key('res-space-remove-0')));
        await tester.pumpAndSettle();
        expect(find.textContaining('Sera archivée'), findsOneWidget);

        await tester.tap(find.byKey(const Key('res-save')));
        await tester.pumpAndSettle();
        final sent = repo.saved!;
        expect(sent.version, 3);
        expect(sent.spaces.map((s) => s.id), ['t1', 's1']);
        expect(sent.spaces.first.archived, isTrue);
        expect(sent.spaces.first.toJson()['archived'], isTrue);
      },
    );

    testWidgets('ajouter une table et une plage : envoyées au serveur', (
      tester,
    ) async {
      final repo = await pump(tester, _state());
      await tester.tap(find.byKey(const Key('res-add-table')));
      await tester.tap(find.byKey(const Key('res-add-window-MARDI')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('res-save')));
      await tester.pumpAndSettle();
      expect(repo.saved!.spaces.where((s) => s.isNew), hasLength(1));
      expect(
        repo.saved!.windows.map(
          (w) => '${w.dayOfWeek} ${w.startTime}-${w.endTime}',
        ),
        ['LUNDI 12:00-14:00', 'MARDI 12:00-14:00'],
      );
    });

    testWidgets(
      'refus 400 : les constats du serveur s’affichent sous le champ',
      (tester) async {
        await pump(
          tester,
          _state(),
          saveError: const ApiException(
            'La configuration contient des erreurs.',
            statusCode: 400,
            code: ReservationErrorCodes.invalid,
          ),
          check: const ReservationCheck(
            valid: false,
            effective: false,
            issues: [
              ReservationIssue(
                severity: 'ERROR',
                code: 'DUPLICATE_LABEL',
                field: 'spaces[1].label',
                message: 'Le nom « Comptoir » est déjà utilisé.',
              ),
            ],
            preview: null,
          ),
        );
        await tester.tap(find.byKey(const Key('res-save')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('res-error')), findsOneWidget);
        expect(
          find.text('Le nom « Comptoir » est déjà utilisé.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'refus 400 puis aperçu en échec : ne prétend pas avoir signalé les champs',
      (tester) async {
        final repo = await pump(
          tester,
          _state(),
          saveError: const ApiException(
            'La configuration contient des erreurs.',
            statusCode: 400,
            code: ReservationErrorCodes.invalid,
          ),
          previewError: const ApiException(
            'Trop de requêtes, réessayez dans un instant.',
            statusCode: 429,
          ),
        );
        await tester.tap(find.byKey(const Key('res-save')));
        await tester.pumpAndSettle();
        expect(repo.previews, 1);
        expect(find.textContaining('voir les champs signalés'), findsNothing);
        expect(
          find.textContaining('détail n’a pas pu être chargé'),
          findsOneWidget,
        );
      },
    );

    testWidgets('429 : message français, jamais le texte technique du serveur', (
      tester,
    ) async {
      await pump(
        tester,
        _state(),
        saveError: const ApiException(
          'ThrottlerException: Too Many Requests',
          statusCode: 429,
        ),
      );
      await tester.tap(find.byKey(const Key('res-save')));
      await tester.pumpAndSettle();
      expect(find.textContaining('ThrottlerException'), findsNothing);
      expect(
        find.text(
          'Trop de demandes rapprochées. Patientez une seconde, puis réessayez.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('409 : message serveur et bouton Recharger', (tester) async {
      await pump(
        tester,
        _state(),
        saveError: const ApiException(
          'La configuration a été modifiée entre-temps. Rechargez-la avant d’enregistrer.',
          statusCode: 409,
          code: ReservationErrorCodes.conflict,
        ),
      );
      await tester.tap(find.byKey(const Key('res-save')));
      await tester.pumpAndSettle();
      expect(find.textContaining('modifiée entre-temps'), findsOneWidget);
      expect(find.byKey(const Key('res-reload')), findsOneWidget);
    });

    testWidgets('403 Premium expiré entre-temps : message serveur affiché', (
      tester,
    ) async {
      await pump(
        tester,
        _state(),
        saveError: const ApiException(
          'Un abonnement Premium actif est nécessaire pour modifier la réservation sur place.',
          statusCode: 403,
          code: ReservationErrorCodes.premiumRequired,
        ),
      );
      await tester.tap(find.byKey(const Key('res-save')));
      await tester.pumpAndSettle();
      expect(find.textContaining('abonnement Premium actif'), findsWidgets);
    });

    testWidgets('alerte globale (tailles non couvertes) affichée en tête', (
      tester,
    ) async {
      await pump(
        tester,
        _state(
          issues: [
            {
              'severity': 'WARNING',
              'code': 'PARTY_SIZES_UNCOVERED',
              'field': 'spaces',
              'message':
                  'Aucune ressource n’accueille un groupe de 3 personne(s).',
              'partySizes': [3],
            },
          ],
        ),
      );
      expect(find.byKey(const Key('res-issues')), findsOneWidget);
      expect(find.textContaining('groupe de 3'), findsOneWidget);
    });
  });
}

class _FakeRepo implements ReservationSettingsRepository {
  _FakeRepo({this.saveError, this.check, this.previewError});

  final ApiException? saveError;
  final ReservationCheck? check;
  final ApiException? previewError;
  ReservationDraft? saved;
  int previews = 0;

  @override
  Future<ReservationState> mine() => throw UnimplementedError();

  @override
  Future<ReservationCheck> preview(ReservationDraft draft) async {
    previews++;
    if (previewError != null) throw previewError!;
    return check ??
        const ReservationCheck(
          valid: true,
          effective: false,
          issues: [],
          preview: null,
        );
  }

  @override
  Future<ReservationState> save(ReservationDraft draft) async {
    if (saveError != null) throw saveError!;
    saved = draft;
    return ReservationState.fromJson(_state());
  }
}

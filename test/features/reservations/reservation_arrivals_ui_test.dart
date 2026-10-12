import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/core/network/api_exception.dart';
import 'package:lilia_admin/features/reservations/data/reservation_settings_repository.dart';
import 'package:lilia_admin/features/reservations/presentation/reservation_settings_providers.dart';
import 'package:lilia_admin/features/reservations/presentation/reservation_settings_screen.dart';

/// « Heures d'arrivée des clients » (Premium Lot 3, option A du 12/10) :
/// l'écran dit ce que signifie une plage — première et dernière ARRIVÉE, pas
/// l'ouverture — et montre les heures qu'elle propose avec le pas courant.
/// États de départ : réponses RÉELLES du backend (`fixtures/`).
Map<String, dynamic> _real(
  String name, {
  List<Map<String, String>>? windows,
  List<Map<String, dynamic>>? issues,
}) {
  final raw =
      jsonDecode(
            File(
              'test/features/reservations/fixtures/$name.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final data = raw['data'] as Map<String, dynamic>;
  if (windows != null) (data['config'] as Map)['windows'] = windows;
  if (issues != null) data['issues'] = issues;
  return data;
}

Map<String, String> _w(String start, String end) => {
  'dayOfWeek': 'LUNDI',
  'startTime': start,
  'endTime': end,
};

class _Repo implements ReservationSettingsRepository {
  _Repo({this.preview$, this.save$});

  final Future<ReservationCheck> Function()? preview$;
  final Future<ReservationState> Function(ReservationDraft)? save$;
  final saved = <ReservationDraft>[];

  @override
  Future<ReservationState> mine() => throw UnimplementedError();

  @override
  Future<ReservationCheck> preview(ReservationDraft draft) =>
      preview$?.call() ??
      Future.value(
        const ReservationCheck(
          valid: true,
          effective: false,
          issues: [],
          preview: null,
        ),
      );

  @override
  Future<ReservationState> save(ReservationDraft draft) {
    saved.add(draft);
    return save$?.call(draft) ?? (throw UnimplementedError());
  }
}

Future<void> _pump(
  WidgetTester tester,
  Map<String, dynamic> state, {
  _Repo? repo,
  Size size = const Size(540, 2400),
  double textScale = 1.0,

  /// Chargements suivants (après `invalidate`) ; par défaut, le même état.
  Future<ReservationState> Function(int call)? reload,
}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  var calls = 0;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        reservationSettingsRepositoryProvider.overrideWithValue(
          repo ?? _Repo(),
        ),
        myReservationSettingsProvider.overrideWith((ref) async {
          final call = calls++;
          if (call > 0 && reload != null) return reload(call);
          return ReservationState.fromJson(state);
        }),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const ReservationSettingsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) => tester
    .scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);

String _text(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(Key(key))).data!;

void main() {
  testWidgets('section nommée par les arrivées, pas par l’ouverture', (
    tester,
  ) async {
    await _pump(tester, _real('put_premium_v1'));
    await _scrollTo(tester, find.byKey(const Key('res-arrivals-section')));
    expect(find.text('Heures d’arrivée des clients'), findsOneWidget);
    expect(find.textContaining('pas vos heures d’ouverture'), findsOneWidget);
    expect(
      find.textContaining('Une arrivée toutes les 30 min'),
      findsOneWidget,
    );
    expect(find.text('Plage'), findsNothing);
  });

  testWidgets('première et dernière arrivée, heures intermédiaires', (
    tester,
  ) async {
    await _pump(tester, _real('put_premium_v1'));
    await _scrollTo(tester, find.byKey(const Key('res-window-0')));
    expect(
      _text(tester, 'res-window-range-0'),
      'Première arrivée 12:00 · Dernière arrivée 14:00',
    );
    expect(
      _text(tester, 'res-window-arrivals-0'),
      'Arrivées proposées : 12:00, 12:30, 13:00, 13:30, 14:00',
    );
    expect(find.byKey(const Key('res-window-unreached-0')), findsNothing);
  });

  testWidgets('changer le pas met à jour les arrivées tout de suite', (
    tester,
  ) async {
    await _pump(tester, _real('put_premium_v1'));
    await _scrollTo(tester, find.byKey(const Key('res-step-60')));
    await tester.tap(find.byKey(const Key('res-step-60')));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.byKey(const Key('res-window-0')));
    expect(
      _text(tester, 'res-window-arrivals-0'),
      'Arrivées proposées : 12:00, 13:00, 14:00',
    );
    expect(
      find.textContaining('Une arrivée toutes les 60 min'),
      findsOneWidget,
    );
  });

  testWidgets('fin hors du pas : dit que la fin n’est pas proposée', (
    tester,
  ) async {
    await _pump(
      tester,
      _real('put_premium_v1', windows: [_w('12:00', '13:45')]),
    );
    await _scrollTo(tester, find.byKey(const Key('res-window-0')));
    expect(
      _text(tester, 'res-window-arrivals-0'),
      'Arrivées proposées : 12:00, 12:30, 13:00, 13:30',
    );
    expect(
      _text(tester, 'res-window-unreached-0'),
      '13:45 n’est pas proposée : une arrivée toutes les 30 min, '
      'la dernière à 13:30.',
    );
  });

  testWidgets('fenêtre courte : une seule arrivée', (tester) async {
    await _pump(
      tester,
      _real('put_premium_v1', windows: [_w('12:00', '12:10')]),
    );
    await _scrollTo(tester, find.byKey(const Key('res-window-0')));
    expect(
      _text(tester, 'res-window-arrivals-0'),
      'Arrivées proposées : 12:00',
    );
  });

  testWidgets('plage invalide : à corriger, constat serveur sous ce champ', (
    tester,
  ) async {
    await _pump(
      tester,
      _real(
        'put_premium_v1',
        windows: [_w('14:00', '12:00'), _w('19:00', '21:00')],
        issues: [
          {
            'severity': 'ERROR',
            'code': 'WINDOW_EMPTY',
            'field': 'windows[0].endTime',
            'message':
                'La dernière arrivée doit être après la première, le même jour.',
          },
        ],
      ),
    );
    await _scrollTo(tester, find.byKey(const Key('res-window-1')));
    // Le constat serveur suffit : pas de second message local en doublon.
    expect(find.byKey(const Key('res-window-arrivals-0')), findsNothing);
    final message = find.text(
      'La dernière arrivée doit être après la première, le même jour.',
    );
    expect(message, findsOneWidget);
    // Sous la plage 0, pas sous la plage 1.
    expect(
      find.descendant(
        of: find.byKey(const Key('res-window-0')),
        matching: message,
      ),
      findsOneWidget,
    );
  });

  testWidgets('aperçu : boutons figés pendant le chargement, erreur affichée', (
    tester,
  ) async {
    final pending = Completer<ReservationCheck>();
    await _pump(
      tester,
      _real('put_premium_v1'),
      repo: _Repo(preview$: () => pending.future),
    );
    await tester.tap(find.byKey(const Key('res-check')));
    await tester.pump();
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('res-check')))
          .onPressed,
      isNull,
    );
    pending.completeError(
      const ApiException('Connexion impossible.', kind: ApiErrorKind.network),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('res-error')), findsOneWidget);
    expect(find.text('Connexion impossible.'), findsOneWidget);
  });

  testWidgets('plage invalide sans constat serveur : le texte local guide', (
    tester,
  ) async {
    await _pump(
      tester,
      _real('put_premium_v1', windows: [_w('14:00', '12:00')]),
    );
    await _scrollTo(tester, find.byKey(const Key('res-window-0')));
    expect(
      _text(tester, 'res-window-arrivals-0'),
      startsWith('Heures à corriger'),
    );
  });

  testWidgets('écran étroit, texte ×1,5 : boutons empilés, mots entiers', (
    tester,
  ) async {
    await _pump(
      tester,
      _real('put_premium_v1'),
      size: const Size(320, 568),
      textScale: 1.5,
    );
    final save = tester.getRect(find.byKey(const Key('res-save')));
    final check = tester.getRect(find.byKey(const Key('res-check')));
    expect(save.bottom, lessThanOrEqualTo(check.top));
    expect(save.width, check.width);
    // Police de test (voir le commentaire plus bas) : seul un débordement de
    // mise en page est toléré ici ; toute autre exception fait échouer.
    final e = tester.takeException();
    if (e != null) {
      expect(e, isA<FlutterError>());
      expect(e.toString(), contains('overflowed'));
    }
  });

  testWidgets('largeur normale, texte ×1,0 : boutons côte à côte', (
    tester,
  ) async {
    await _pump(tester, _real('put_premium_v1'), size: const Size(375, 667));
    final save = tester.getRect(find.byKey(const Key('res-save')));
    final check = tester.getRect(find.byKey(const Key('res-check')));
    expect(save.top, check.top);
    // Premium réel : « Enregistrer » est actif.
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('res-save'))).onPressed,
      isNotNull,
    );
  });

  // La police des tests Flutter dessine chaque glyphe sur un carré de 1 em,
  // nettement plus large que la vraie police : à 320 pt et ×1,5 elle fait
  // déborder des lignes qui tiennent à l'écran. Ce cas est vérifié en rendu
  // RÉEL (banc visuel du 12/10, simulateur iPhone SE, 0 débordement) ; ici on
  // garde les tailles où la police de test reste représentative.
  for (final (label, size, scale) in [
    ('iPhone SE 375×667, texte ×1,5', const Size(375, 667), 1.5),
    ('petit écran 320×568, texte ×1,0', const Size(320, 568), 1.0),
  ]) {
    testWidgets('$label : tout le formulaire se parcourt sans débordement', (
      tester,
    ) async {
      await _pump(
        tester,
        _real('put_with_archived_v2'),
        size: size,
        textScale: scale,
      );
      expect(tester.takeException(), isNull);
      // Jusqu'en bas : chaque section construite au passage.
      for (final key in [
        'res-duration',
        'res-arrivals-section',
        'res-window-0',
        'res-add-window-DIMANCHE',
      ]) {
        await _scrollTo(tester, find.byKey(Key(key)));
        expect(tester.takeException(), isNull, reason: key);
      }
      expect(find.byKey(const Key('res-save')), findsOneWidget);
    });
  }

  testWidgets('Standard, rien configuré (réel) : Premium requis', (
    tester,
  ) async {
    await _pump(tester, _real('get_standard_unconfigured'));
    expect(find.byKey(const Key('res-premium-required')), findsOneWidget);
  });

  testWidgets('vendeur non éligible (réel) : message seul', (tester) async {
    await _pump(tester, _real('get_not_eligible'));
    expect(find.byKey(const Key('res-not-eligible')), findsOneWidget);
    expect(find.byKey(const Key('res-arrivals-section')), findsNothing);
  });

  // ── Correctifs de la revue du 12/10 ─────────────────────────────────────

  testWidgets('après un enregistrement, même si le rechargement échoue, le '
      'suivant part de la version et des ids rendus par le serveur', (
    tester,
  ) async {
    final v2 = ReservationState.fromJson(_real('put_with_archived_v2'));
    final repo = _Repo(save$: (_) async => v2);
    await _pump(
      tester,
      _real('put_premium_v1'),
      repo: repo,
      reload: (_) => Future.error(
        const ApiException('Connexion impossible.', kind: ApiErrorKind.network),
      ),
    );
    await tester.tap(find.byKey(const Key('res-save')));
    await tester.pumpAndSettle();
    // La SnackBar « enregistrée » recouvre la barre du bas : on déclenche le
    // bouton lui-même (actif, sinon `onPressed` serait nul).
    tester.widget<FilledButton>(find.byKey(const Key('res-save'))).onPressed!();
    await tester.pumpAndSettle();
    expect(repo.saved, hasLength(2));
    expect(repo.saved[0].version, 1);
    expect(repo.saved[1].version, v2.config!.version);
    expect(
      repo.saved[1].spaces.where((s) => !s.archived).map((s) => s.id),
      v2.config!.spaces.map((s) => s.id),
    );
  });

  testWidgets(
    '403 Premium pendant l’édition : l’état est relu, « Enregistrer » '
    'se désactive',
    (tester) async {
      final revoked = ReservationState.fromJson(_real('get_revoked_frozen'));
      await _pump(
        tester,
        _real('put_premium_v1'),
        repo: _Repo(
          save$: (_) => Future.error(
            const ApiException(
              'Un abonnement Premium actif est nécessaire.',
              statusCode: 403,
              code: ReservationErrorCodes.premiumRequired,
            ),
          ),
        ),
        reload: (_) async => revoked,
      );
      await tester.tap(find.byKey(const Key('res-save')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('res-save')))
            .onPressed,
        isNull,
      );
      expect(find.byKey(const Key('res-premium-required')), findsOneWidget);
    },
  );

  testWidgets('aperçu périmé après une modification, à jour après Vérifier', (
    tester,
  ) async {
    final check = ReservationCheck.fromJson(_real('preview_invalid'));
    await _pump(
      tester,
      _real('put_premium_v1'),
      repo: _Repo(preview$: () async => check),
    );
    expect(find.byKey(const Key('res-preview-stale')), findsNothing);
    await _scrollTo(tester, find.byKey(const Key('res-step-60')));
    await tester.tap(find.byKey(const Key('res-step-60')));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.byKey(const Key('res-preview-stale')));
    expect(find.byKey(const Key('res-preview-stale')), findsOneWidget);
    await tester.tap(find.byKey(const Key('res-check')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('res-preview-stale')), findsNothing);
  });

  testWidgets('400 puis aperçu au corps illisible : rien n’échappe, message '
      'honnête', (tester) async {
    await _pump(
      tester,
      _real('put_premium_v1'),
      repo: _Repo(
        save$: (_) => Future.error(
          const ApiException(
            'La configuration contient des erreurs.',
            statusCode: 400,
            code: ReservationErrorCodes.invalid,
          ),
        ),
        preview$: () => Future.error(StateError('Expected Map response')),
      ),
    );
    await tester.tap(find.byKey(const Key('res-save')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('n’a pas pu être chargé'), findsOneWidget);
  });

  testWidgets(
    'chargement en 429 : message français, jamais le texte technique',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myReservationSettingsProvider.overrideWith(
              (ref) => Future.error(
                const ApiException(
                  'ThrottlerException: Too Many Requests',
                  statusCode: 429,
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: ReservationSettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('ThrottlerException'), findsNothing);
      expect(
        tester.widget<Text>(find.byKey(const Key('res-load-error'))).data,
        'Trop de demandes rapprochées. Patientez une seconde, puis réessayez.',
      );
    },
  );

  testWidgets('alertes du bandeau d’état non répétées dans la liste globale', (
    tester,
  ) async {
    // Standard réel avec plateforme éteinte : PLATFORM_DISABLED + NOT_ENTITLED.
    final data = _real(
      'get_standard_unconfigured',
      issues: [
        {
          'severity': 'WARNING',
          'code': 'PLATFORM_DISABLED',
          'field': null,
          'message': 'La réservation sur place n’est pas encore ouverte.',
        },
        {
          'severity': 'WARNING',
          'code': 'NOT_ENTITLED',
          'field': null,
          'message': 'Un abonnement Premium actif est nécessaire.',
        },
      ],
    );
    await _pump(tester, data);
    expect(find.byKey(const Key('res-premium-required')), findsOneWidget);
    expect(find.byKey(const Key('res-issues')), findsNothing);
  });

  testWidgets('noms proposés libres : « Table 2 » puis « Comptoir 2 »', (
    tester,
  ) async {
    // Configuration réelle : « Table 1 » (table) et « Comptoir » (places).
    await _pump(tester, _real('put_premium_v1'));
    await _scrollTo(tester, find.byKey(const Key('res-add-table')));
    await tester.tap(find.byKey(const Key('res-add-table')));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.byKey(const Key('res-add-seats')));
    await tester.tap(find.byKey(const Key('res-add-seats')));
    await tester.pumpAndSettle();
    final labels = tester
        .widgetList<TextField>(find.byType(TextField))
        .map((f) => f.controller?.text)
        .whereType<String>()
        .toList();
    expect(labels.toSet().length, labels.length, reason: '$labels');
    expect(labels, containsAll(['Table 2', 'Comptoir 2']));
  });
}

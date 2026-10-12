import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/features/reservations/presentation/arrival_times.dart';

/// Heures d'arrivée d'une plage (affichage seulement : la validation reste
/// celle du serveur). Règle D3 : départs à début, début + pas… tant que
/// ≤ fin (dernière arrivée incluse).
void main() {
  group('arrivalTimes', () {
    test('12:00–14:00, pas 30 : cinq arrivées, fin incluse', () {
      expect(arrivalTimes('12:00', '14:00', 30), [
        '12:00',
        '12:30',
        '13:00',
        '13:30',
        '14:00',
      ]);
    });

    test('le pas change la liste', () {
      expect(arrivalTimes('12:00', '13:00', 15), [
        '12:00',
        '12:15',
        '12:30',
        '12:45',
        '13:00',
      ]);
      expect(arrivalTimes('12:00', '14:00', 60), ['12:00', '13:00', '14:00']);
    });

    test('fin hors du pas : la dernière arrivée réelle est avant la fin', () {
      expect(arrivalTimes('12:00', '13:45', 30), [
        '12:00',
        '12:30',
        '13:00',
        '13:30',
      ]);
    });

    test('fenêtre courte : une seule arrivée si la fin précède le 2e pas', () {
      expect(arrivalTimes('12:00', '12:10', 15), ['12:00']);
    });

    test('plage invalide ou heure illisible : liste vide', () {
      expect(arrivalTimes('14:00', '12:00', 30), isEmpty);
      expect(arrivalTimes('12:00', '12:00', 30), isEmpty);
      expect(arrivalTimes('midi', '14:00', 30), isEmpty);
      expect(arrivalTimes('12:00', '14:00', 0), isEmpty);
    });
  });

  group('arrivalSummary', () {
    test('liste courte : toutes les heures', () {
      expect(
        arrivalSummary(['12:00', '12:30', '13:00']),
        '12:00, 12:30, 13:00',
      );
    });

    test('liste longue : début … fin et le nombre', () {
      final all = arrivalTimes('09:00', '19:00', 15);
      expect(all.length, 41);
      expect(
        arrivalSummary(all),
        '09:00, 09:15, 09:30 … 18:45, 19:00 · 41 arrivées',
      );
    });
  });

  // Parité avec le moteur serveur : la réponse RÉELLE d'un PUT (plages du
  // lundi 12:00–14:00 et 19:00–21:00, pas 30) porte les créneaux calculés par
  // `evaluateReservationDraft`. L'affichage local doit donner les mêmes.
  test('parité avec les créneaux renvoyés par le serveur', () {
    final raw =
        jsonDecode(
              File(
                'test/features/reservations/fixtures/put_premium_v1.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final data = raw['data'] as Map<String, dynamic>;
    final config = data['config'] as Map<String, dynamic>;
    final step = config['slotStepMin'] as int;
    final windows = (config['windows'] as List).cast<Map<String, dynamic>>();
    final days = ((data['preview'] as Map)['days'] as List)
        .cast<Map<String, dynamic>>();
    expect(windows, isNotEmpty);
    for (final day in days) {
      final local = [
        for (final w in windows.where(
          (w) => w['dayOfWeek'] == day['dayOfWeek'],
        ))
          ...arrivalTimes(
            w['startTime'] as String,
            w['endTime'] as String,
            step,
          ),
      ]..sort();
      final server = [
        for (final s in (day['slots'] as List)) (s as Map)['time'] as String,
      ];
      expect(local, server, reason: '${day['dayOfWeek']}');
    }
  });
}

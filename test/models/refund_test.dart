import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/models/refund.dart';

/// Remboursements dus après annulation d'une commande payée.
///
/// Le point sensible est la machine à états : proposer à l'admin une
/// transition que le backend refusera (409) le fait buter sur une erreur sans
/// comprendre. Les états terminaux ne doivent donc offrir aucune action.
void main() {
  Map<String, dynamic> payload({String status = 'PENDING'}) => {
    'id': 'ref-1',
    'orderId': 'ckabcdef123456',
    'amount': 6400,
    'status': status,
    'reason': 'Annulation par le client',
    'createdAt': '2026-08-29T10:00:00.000Z',
    'order': {
      'paymentMethod': 'MTN_MOMO',
      'user': {'nom': 'Awa', 'phone': '060000000'},
      'restaurant': {'nom': 'Chez Awa'},
    },
  };

  group('désérialisation', () {
    test('aplatit le contexte commande servi par l’API', () {
      final r = Refund.fromJson(payload());

      expect(r.amount, 6400);
      expect(r.status, RefundStatus.pending);
      expect(r.clientNom, 'Awa');
      expect(r.clientPhone, '060000000');
      expect(r.restaurantNom, 'Chez Awa');
      expect(r.paymentMethod, 'MTN_MOMO');
    });

    test('un payload sans contexte commande ne plante pas', () {
      final r = Refund.fromJson({
        'id': 'ref-1',
        'orderId': 'o1',
        'amount': 1000,
        'status': 'PENDING',
        'reason': 'x',
        'createdAt': '2026-08-29T10:00:00.000Z',
      });

      expect(r.clientNom, isNull);
      expect(r.restaurantNom, isNull);
    });

    test('un statut inconnu retombe sur « à traiter »', () {
      // Un remboursement mal classé doit rester visible dans la file, pas
      // disparaître : le pire serait qu'il soit silencieusement ignoré.
      final r = Refund.fromJson(payload(status: 'UN_STATUT_FUTUR'));
      expect(r.status, RefundStatus.pending);
    });

    test('abrège la référence de commande comme le reste de l’app', () {
      final r = Refund.fromJson(payload());
      expect(r.shortOrderRef, '#123456');
    });
  });

  group('machine à états', () {
    test('à traiter → les trois suites possibles', () {
      expect(RefundStatus.pending.nextStates, [
        RefundStatus.processing,
        RefundStatus.completed,
        RefundStatus.rejected,
      ]);
    });

    test('en cours → clôture uniquement', () {
      expect(RefundStatus.processing.nextStates, [
        RefundStatus.completed,
        RefundStatus.rejected,
      ]);
    });

    test('les états terminaux n’offrent aucune action', () {
      // Le backend renvoie 409 sur un remboursement déjà clos : afficher un
      // bouton reviendrait à promettre une action qui échouera.
      expect(RefundStatus.completed.nextStates, isEmpty);
      expect(RefundStatus.rejected.nextStates, isEmpty);
    });

    test('isOpen distingue ce qui reste à faire', () {
      expect(RefundStatus.pending, isNotNull);
      final open = Refund.fromJson(payload());
      final closed = Refund.fromJson(payload(status: 'COMPLETED'));

      expect(open.isOpen, isTrue);
      expect(closed.isOpen, isFalse);
    });
  });

  group('contrat API', () {
    test('chaque statut sérialise vers la valeur attendue par le backend', () {
      expect(RefundStatus.pending.toApiString(), 'PENDING');
      expect(RefundStatus.processing.toApiString(), 'PROCESSING');
      expect(RefundStatus.completed.toApiString(), 'COMPLETED');
      expect(RefundStatus.rejected.toApiString(), 'REJECTED');
    });

    test('l’aller-retour est stable', () {
      for (final s in RefundStatus.values) {
        expect(RefundStatusX.fromString(s.toApiString()), s, reason: s.name);
      }
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/models/restaurant.dart';

/// Champs de la fiche vendeur ajoutés en septembre 2026 (Phase 3).
///
/// Les trois répondent à des questions que l'administration ne pouvait pas
/// poser depuis cette application :
///
///  · `payoutPhoneNumber` / `payoutProvider` — « peut-on payer ce vendeur ? »
///    Les six vendeurs de production étaient à `null`, onze commandes
///    encaissées et zéro reversement possible ;
///  · `isFeatured` — resté `false` partout, la page d'accueil du site n'a
///    jamais affiché un seul vendeur ;
///  · `displayOrder` — le rang existait côté serveur, sans aucune interface
///    mobile pour le poser.
Map<String, dynamic> _base() => {
      'id': 'r1',
      'nom': 'Chez Maman Lili',
      'adresse': 'Poto-Poto',
      'ownerId': 'u1',
    };

void main() {
  group('Restaurant — compte de reversement', () {
    test('lit le numéro et l’opérateur', () {
      final r = Restaurant.fromJson({
        ..._base(),
        'payoutPhoneNumber': '242060000001',
        'payoutProvider': 'MTN_MOMO',
      });
      expect(r.payoutPhoneNumber, '242060000001');
      expect(r.payoutProvider, 'MTN_MOMO');
      expect(r.isPayable, isTrue);
    });

    test('un vendeur sans compte n’est pas payable', () {
      final r = Restaurant.fromJson(_base());
      expect(r.payoutPhoneNumber, isNull);
      expect(r.isPayable, isFalse);
    });

    test('un numéro sans opérateur ne suffit pas', () {
      // Les deux sont requis par `checkEligibility` côté serveur : rendre
      // `isPayable` vrai ici afficherait un vendeur payable qui ne l'est pas.
      final r = Restaurant.fromJson({
        ..._base(),
        'payoutPhoneNumber': '242060000001',
      });
      expect(r.isPayable, isFalse);
    });

    test('des chaînes vides valent une absence', () {
      final r = Restaurant.fromJson({
        ..._base(),
        'payoutPhoneNumber': '',
        'payoutProvider': '',
      });
      expect(r.isPayable, isFalse);
    });
  });

  group('Restaurant — vitrine', () {
    test('lit le rang et la mise en avant', () {
      final r = Restaurant.fromJson({
        ..._base(),
        'displayOrder': 2,
        'isFeatured': true,
      });
      expect(r.displayOrder, 2);
      expect(r.isFeatured, isTrue);
    });

    test('défauts alignés sur le serveur : rang 1000, pas en vedette', () {
      // 1000 = « pas encore classé ». C'est ce qui rend l'ajout de la colonne
      // invisible tant que personne n'a rien rangé.
      final r = Restaurant.fromJson(_base());
      expect(r.displayOrder, 1000);
      expect(r.isFeatured, isFalse);
    });

    test('la vedette ne rend pas visible à elle seule', () {
      // `isFeatured` est une mise en avant, jamais une publication : un vendeur
      // en `DRAFT` mis en vedette reste invisible des clients.
      final r = Restaurant.fromJson({
        ..._base(),
        'isFeatured': true,
        'onboardingStatus': 'DRAFT',
        'adminApproved': true,
        'isActive': true,
      });
      expect(r.isFeatured, isTrue);
      expect(r.isVisibleToClients, isFalse);
      expect(r.isDraft, isTrue);
    });
  });
}

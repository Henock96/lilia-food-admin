import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/models/order.dart';
import 'package:lilia_admin/models/order_transitions.dart';
import 'package:lilia_admin/models/role.dart';

/// Ce que l'interface a le droit de proposer.
///
/// ## Pourquoi ce fichier existe
///
/// Le serveur porte **une** vérité — `ORDER_TRANSITION_MATRIX` dans
/// `order-state.machine.ts`, plus deux gardes de cohérence terrain dans
/// `OrderLifecycleService.assertStatusMatchesGround`. Cette application en
/// portait une **copie écrite à la main**, dupliquée dans deux écrans, et les
/// trois avaient divergé. Audit du 22/09/2026 :
///
/// ```
/// EN_ATTENTE → EN_PREPARATION   RESTAURATEUR   400 (transition inexistante)
/// EN_ATTENTE → PAYER            RESTAURATEUR   403 (réservée ADMIN)
/// PRET       → LIVRER           RESTAURATEUR   400 si la commande est à livrer
/// ```
///
/// Les deux premières étaient proposées par les deux écrans, la troisième par
/// l'écran de liste seulement — l'écran de détail la conditionnait déjà
/// correctement. Un vendeur voyait donc « En préparation » sur une commande non
/// payée, et recevait une erreur. Répété, il cesse de croire l'interface — et
/// cessera aussi de croire les erreurs qui comptent.
///
/// ## Ce que ces tests verrouillent
///
/// Chaque ligne ci-dessous est écrite **à la main** depuis la matrice serveur,
/// jamais dérivée du code qu'elle teste. Un test qui dériverait ses attentes de
/// `availableOrderTransitions` vérifierait seulement que la fonction sait se
/// lire elle-même — c'est exactement le défaut qui avait laissé passer B-1 côté
/// backend, où la spec « exhaustive » dérivait de la matrice.
void main() {
  group('EN_ATTENTE', () {
    test('ne propose jamais EN_PREPARATION : la transition n’existe pas', () {
      for (final role in [Role.admin, Role.restaurateur]) {
        expect(
          availableOrderTransitions(
            current: OrderStatus.enattente,
            role: role,
            isDelivery: true,
          ),
          isNot(contains(OrderStatus.enpreparation)),
          reason: 'le serveur répond 400 — la transition est absente de la matrice',
        );
      }
    });

    test('ne propose PAYER à personne — « payée » ne se déclare pas (F-07)', () {
      // Le serveur refuse EN_ATTENTE → PAYER sur la route de statut, même à
      // l'ADMIN : la confirmation passe par l'écran Paiements.
      expect(
        availableOrderTransitions(
          current: OrderStatus.enattente,
          role: Role.admin,
          isDelivery: true,
        ),
        isNot(contains(OrderStatus.payer)),
      );
      expect(
        availableOrderTransitions(
          current: OrderStatus.enattente,
          role: Role.restaurateur,
          isDelivery: true,
        ),
        isNot(contains(OrderStatus.payer)),
      );
    });

    test('laisse annuler au vendeur comme à l’admin', () {
      for (final role in [Role.admin, Role.restaurateur]) {
        expect(
          availableOrderTransitions(
            current: OrderStatus.enattente,
            role: role,
            isDelivery: true,
          ),
          contains(OrderStatus.annuler),
        );
      }
    });
  });

  group('PAYER', () {
    test('ouvre la préparation au vendeur', () {
      expect(
        availableOrderTransitions(
          current: OrderStatus.payer,
          role: Role.restaurateur,
          isDelivery: true,
        ),
        containsAll([OrderStatus.enpreparation, OrderStatus.annuler]),
      );
    });
  });

  group('PRET', () {
    test('propose « livrée » sur un retrait au comptoir', () {
      expect(
        availableOrderTransitions(
          current: OrderStatus.pret,
          role: Role.restaurateur,
          isDelivery: false,
        ),
        contains(OrderStatus.livrer),
      );
    });

    test('ne propose PAS « livrée » sur une commande à livrer', () {
      // `assertStatusMatchesGround` : seul le livreur constate une livraison.
      // Le raccourci comptoir clôturerait la commande — et créditerait les
      // points de fidélité — alors que le client n'a rien reçu.
      for (final role in [Role.admin, Role.restaurateur]) {
        expect(
          availableOrderTransitions(
            current: OrderStatus.pret,
            role: role,
            isDelivery: true,
          ),
          isNot(contains(OrderStatus.livrer)),
        );
      }
    });

    test('ne propose jamais EN_ROUTE : c’est le geste du livreur', () {
      // La matrice l'ouvre à LIVREUR et ADMIN, mais le seul chemin vers une
      // `Delivery` EN_TRANSIT — `PATCH /deliveries/:id/pickup` — bascule déjà la
      // commande lui-même. Le bouton serait donc inatteignable par construction.
      for (final role in [Role.admin, Role.restaurateur]) {
        expect(
          availableOrderTransitions(
            current: OrderStatus.pret,
            role: role,
            isDelivery: true,
          ),
          isNot(contains(OrderStatus.enRoute)),
        );
      }
    });
  });

  group('EN_ROUTE', () {
    test('ne propose rien au vendeur : il n’a plus la main', () {
      expect(
        availableOrderTransitions(
          current: OrderStatus.enRoute,
          role: Role.restaurateur,
          isDelivery: true,
        ),
        isEmpty,
      );
    });

    test('laisse l’admin annuler, et lui seul', () {
      expect(
        availableOrderTransitions(
          current: OrderStatus.enRoute,
          role: Role.admin,
          isDelivery: true,
        ),
        contains(OrderStatus.annuler),
      );
    });
  });

  group('états terminaux', () {
    test('ne proposent plus rien', () {
      for (final terminal in [OrderStatus.livrer, OrderStatus.annuler]) {
        for (final role in [Role.admin, Role.restaurateur]) {
          expect(
            availableOrderTransitions(
              current: terminal,
              role: role,
              isDelivery: true,
            ),
            isEmpty,
          );
        }
      }
    });
  });

  group('robustesse', () {
    test('ne propose rien sur un statut que cette version ne connaît pas', () {
      // `OrderStatus.unknown` est ce que rend le parseur sur une valeur
      // inconnue. Proposer une transition depuis un état qu'on ne comprend pas
      // reviendrait à deviner.
      expect(
        availableOrderTransitions(
          current: OrderStatus.unknown,
          role: Role.admin,
          isDelivery: true,
        ),
        isEmpty,
      );
    });

    test('ne propose rien à un rôle sans écriture sur les commandes', () {
      for (final role in [Role.client, Role.livreur, Role.unknown]) {
        expect(
          availableOrderTransitions(
            current: OrderStatus.payer,
            role: role,
            isDelivery: true,
          ),
          isEmpty,
          reason: 'cette application ne sert que le vendeur et l’administrateur',
        );
      }
    });
  });
}

import 'order.dart';
import 'role.dart';

/// Transitions de statut que l'interface a le droit de proposer.
///
/// ## Pourquoi cette fonction existe
///
/// Le serveur porte **une** vérité : `ORDER_TRANSITION_MATRIX`
/// (`order-state.machine.ts`), complétée par deux gardes de cohérence terrain
/// dans `OrderLifecycleService.assertStatusMatchesGround`. Cette application en
/// portait une **copie écrite à la main**, dupliquée dans deux écrans — et les
/// trois avaient divergé.
///
/// Relevé par l'audit du 22/09/2026, en évaluant la matrice serveur :
///
/// ```
/// EN_ATTENTE → EN_PREPARATION   RESTAURATEUR   400 (transition inexistante)
/// EN_ATTENTE → PAYER            RESTAURATEUR   403 (réservée ADMIN)
/// PRET       → LIVRER           RESTAURATEUR   400 si la commande est à livrer
/// ```
///
/// Les deux premières étaient proposées par les deux écrans ; la troisième par
/// l'écran de liste seulement, alors que l'écran de détail la conditionnait
/// déjà correctement. Deux écrans de la même application, deux règles.
///
/// ## Ce que ce n'est pas
///
/// **Pas un contrôle d'accès.** Le serveur reste seul juge : il revérifie la
/// matrice, le rôle et l'état du terrain à chaque appel. Cette fonction évite
/// seulement de promettre un geste qui échouera — ce qui est une question
/// d'honnêteté de l'interface, pas de sécurité.
///
/// ## Ce qui la garde honnête
///
/// `test/models/order_transitions_test.dart` écrit chaque règle **à la main**
/// depuis la matrice serveur. Un test qui dériverait ses attentes d'ici
/// vérifierait seulement que la fonction sait se lire elle-même — le défaut
/// exact qui avait laissé passer B-1 côté backend.
///
/// ⚠️ Toute évolution de `ORDER_TRANSITION_MATRIX` doit être répercutée ici
/// **et** dans ce test, dans le même changement.
List<OrderStatus> availableOrderTransitions({
  required OrderStatus current,
  required Role role,
  required bool isDelivery,
}) {
  // Cette application ne sert que le vendeur et l'administrateur. Un autre rôle
  // ne devrait jamais y arriver ; s'il y arrive, il ne propose rien plutôt que
  // de proposer au hasard.
  if (role != Role.admin && role != Role.restaurateur) return const [];
  final isAdmin = role == Role.admin;

  switch (current) {
    case OrderStatus.enattente:
      // `EN_ATTENTE → PAYER` n'est plus proposé, même à l'ADMIN (Master Audit
      // v1, F-07) : le serveur le refuse sur la route de statut. « Payée » est
      // la conséquence d'un encaissement confirmé, pas un statut qu'on
      // déclare — un virement manuel se confirme depuis l'écran Paiements.
      return const [OrderStatus.annuler];

    case OrderStatus.payer:
      return [OrderStatus.enpreparation, OrderStatus.annuler];

    case OrderStatus.acceptee:
      // Jamais rendu par un serveur antérieur à la Phase 3 (seul cas où ce
      // repli sert) ; traité pour que le `switch` reste exhaustif.
      return [OrderStatus.enpreparation, OrderStatus.annuler];

    case OrderStatus.enpreparation:
      return [OrderStatus.pret, OrderStatus.annuler];

    case OrderStatus.pret:
      return [
        // Retrait au comptoir : le vendeur remet le sac en main propre, il est
        // le mieux placé pour clôturer. Sur une livraison, c'est le livreur qui
        // constate — `assertStatusMatchesGround` refuse le raccourci, qui
        // clôturerait la commande et créditerait les points de fidélité alors
        // que le client n'a rien reçu.
        if (!isDelivery) OrderStatus.livrer,
        OrderStatus.annuler,
      ];

    case OrderStatus.enRoute:
      // Le livreur roule : le vendeur n'a plus la main. La matrice ouvre
      // `EN_ROUTE → LIVRER` au LIVREUR et à l'ADMIN ; l'admin le fait depuis la
      // fiche de livraison, pas depuis la file des commandes.
      return [if (isAdmin) OrderStatus.annuler];

    // `PRET → EN_ROUTE` n'apparaît nulle part ci-dessus, et c'est délibéré.
    // La matrice l'ouvre à LIVREUR et ADMIN, mais le seul chemin vers une
    // `Delivery` en `EN_TRANSIT` — `PATCH /deliveries/:id/pickup` — bascule
    // déjà la commande lui-même. Le bouton serait inatteignable par
    // construction : 403 pour le vendeur, 400 pour l'admin.
    case OrderStatus.livrer:
    case OrderStatus.annuler:
    case OrderStatus.echecLivraison:
      return const []; // terminaux

    case OrderStatus.unknown:
      // Valeur que cette version ne connaît pas. Proposer une transition
      // depuis un état qu'on ne comprend pas reviendrait à deviner.
      return const [];
  }
}

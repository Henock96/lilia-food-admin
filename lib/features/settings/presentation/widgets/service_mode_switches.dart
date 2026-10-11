import 'package:flutter/material.dart';

/// Modes de service proposés aux clients : livraison, retrait sur place, ou
/// les deux.
///
/// Le serveur refuse qu'aucun mode ne reste actif (`PATCH /vendors/:id/delivery`,
/// « au moins la livraison ou le retrait ») : l'interface ne fait que
/// l'annoncer avant, en verrouillant l'interrupteur du dernier mode actif.
/// Elle ne remplace pas ce contrôle.
class ServiceModeSwitches extends StatelessWidget {
  const ServiceModeSwitches({
    super.key,
    required this.delivery,
    required this.pickup,
    required this.onChanged,
    this.enabled = true,
  });

  final bool delivery;
  final bool pickup;
  final bool enabled;

  /// Nouvel état des deux modes (livraison, retrait).
  final void Function(bool delivery, bool pickup) onChanged;

  @override
  Widget build(BuildContext context) {
    // Le dernier mode actif ne peut pas être coupé.
    final deliveryLocked = delivery && !pickup;
    final pickupLocked = pickup && !delivery;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          key: const Key('service-mode-delivery'),
          value: delivery,
          onChanged: !enabled || deliveryLocked
              ? null
              : (v) => onChanged(v, pickup),
          title: const Text(
            'Proposer la livraison',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            delivery
                ? 'Les clients peuvent se faire livrer.'
                : 'Les clients ne peuvent pas choisir la livraison.',
          ),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          key: const Key('service-mode-pickup'),
          value: pickup,
          onChanged: !enabled || pickupLocked
              ? null
              : (v) => onChanged(delivery, v),
          title: const Text(
            'Proposer le retrait sur place',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            pickup
                ? 'Les clients peuvent venir chercher leur commande.'
                : 'Les clients ne peuvent pas choisir le retrait.',
          ),
          contentPadding: EdgeInsets.zero,
        ),
        if (deliveryLocked || pickupLocked)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Au moins un mode doit rester actif : activez '
                    '${deliveryLocked ? 'le retrait' : 'la livraison'} pour '
                    'pouvoir désactiver '
                    '${deliveryLocked ? 'la livraison' : 'le retrait'}.',
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Saisie des modes de service dans un formulaire qui enregistre aussi
/// d'autres réglages (frais, délais).
///
/// Les modes ne partent au serveur que si le vendeur a touché un
/// interrupteur. Renvoyer à chaque enregistrement les valeurs lues à
/// l'ouverture de l'écran écraserait en silence un changement plus récent —
/// fait par un administrateur, ou depuis un autre appareil — alors que le
/// vendeur ne voulait corriger que ses frais.
class ServiceModeDraft {
  const ServiceModeDraft._({
    required this.delivery,
    required this.pickup,
    required this.touched,
  });

  /// Valeurs du serveur, non modifiées.
  const ServiceModeDraft.fromServer({
    required bool delivery,
    required bool pickup,
  }) : this._(delivery: delivery, pickup: pickup, touched: false);

  final bool delivery;
  final bool pickup;

  /// Le vendeur a basculé au moins un interrupteur depuis la dernière
  /// lecture du serveur.
  final bool touched;

  ServiceModeDraft edit({required bool delivery, required bool pickup}) =>
      ServiceModeDraft._(delivery: delivery, pickup: pickup, touched: true);

  /// Nouvelle lecture du serveur : adoptée tant que le vendeur n'a rien
  /// touché ; une saisie en cours, elle, n'est jamais effacée.
  ServiceModeDraft syncWith({required bool delivery, required bool pickup}) =>
      touched
      ? this
      : ServiceModeDraft.fromServer(delivery: delivery, pickup: pickup);

  /// Ce qu'il faut envoyer : rien (`null`) si les modes n'ont pas été
  /// touchés — le serveur garde alors sa valeur.
  ({bool? delivery, bool? pickup}) get payload => touched
      ? (delivery: delivery, pickup: pickup)
      : (delivery: null, pickup: null);
}

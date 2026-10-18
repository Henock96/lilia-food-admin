/// Motif d'un arbitrage de remise par l'ADMIN (1B, ADM-03).
///
/// Clôturer un retrait à la place du client pose `PICKUP_ADMIN_OVERRIDE`, qui
/// ouvre le versement du vendeur : le geste dit pourquoi, dans la liste fermée
/// du serveur (`PICKUP_ARBITRATION_REASONS`). La précision voyage à part
/// (`note`), obligatoire pour [other].
enum PickupArbitrationReason {
  customerCollectedNoCode(
    'CUSTOMER_COLLECTED_NO_CODE',
    'Le client a récupéré sa commande sans son code',
  ),
  customerConfirmedToSupport(
    'CUSTOMER_CONFIRMED_TO_SUPPORT',
    'Le client a confirmé la remise au support',
  ),
  vendorCouldNotRecord(
    'VENDOR_COULD_NOT_RECORD',
    'Le vendeur n’a pas pu enregistrer la remise',
  ),
  other('OTHER', 'Autre raison (à préciser)');

  const PickupArbitrationReason(this.wire, this.label);
  final String wire;
  final String label;

  /// Mêmes bornes que le DTO serveur : note 5–300 pour [other], 300 au plus
  /// sinon.
  bool acceptsNote(String note) {
    final trimmed = note.trim();
    if (trimmed.length > 300) return false;
    return this != other || trimmed.length >= 5;
  }
}

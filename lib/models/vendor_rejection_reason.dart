/// Motif d'un refus de commande par le vendeur (Phase 3, F3-01).
///
/// Liste fermée, identique à l'enum serveur `VendorRejectionReason` : un texte
/// libre dans une pièce financière devient illisible en agrégat. La précision
/// libre, facultative, voyage à part (`note`).
enum VendorRejectionReason {
  outOfStock('OUT_OF_STOCK', 'Rupture de stock'),
  tooBusy('TOO_BUSY', 'Trop de commandes en cours'),
  closing('CLOSING', 'Fermeture imminente'),
  outOfZone('OUT_OF_ZONE', 'Adresse hors de ma zone'),
  other('OTHER', 'Autre raison');

  const VendorRejectionReason(this.wire, this.label);
  final String wire;
  final String label;
}

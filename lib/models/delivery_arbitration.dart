/// Clôture d'une livraison par l'ADMIN, sans le livreur (15/11/2026).
///
/// Cas type : le client refuse une commande qu'il a payée. La commande passe
/// « livrée » (preuve `DELIVERY_ADMIN_OVERRIDE`), le versement du vendeur
/// s'ouvre, le client n'est pas remboursé et ne gagne pas de points ; un
/// avoir peut lui être offert. Motifs = liste fermée du serveur
/// (`DELIVERY_ARBITRATION_REASONS`), précision obligatoire pour [other].
enum DeliveryArbitrationReason {
  customerRefused('CUSTOMER_REFUSED', 'Le client a refusé la commande'),
  driverDidNotConfirm(
    'DRIVER_DID_NOT_CONFIRM',
    'Livrée, mais le livreur ne l’a pas enregistré',
  ),
  deliveredOutsideApp(
    'DELIVERED_OUTSIDE_APP',
    'Remise hors de l’application',
  ),
  other('OTHER', 'Autre raison (à préciser)');

  const DeliveryArbitrationReason(this.wire, this.label);
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

/// Bornes de l'avoir, identiques au DTO serveur.
const int voucherMinXaf = 100;
const int voucherMaxXaf = 100000;

/// Montant d'avoir saisi. Vide : `(ok: true, amount: null)` (aucun avoir).
/// Invalide (non entier, hors bornes, supérieur au total payé) : `ok: false`.
({bool ok, int? amount}) parseVoucherAmount(String raw, num orderTotal) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return (ok: true, amount: null);
  if (!RegExp(r'^\d+$').hasMatch(trimmed)) return (ok: false, amount: null);
  final amount = int.parse(trimmed);
  if (amount < voucherMinXaf || amount > voucherMaxXaf || amount > orderTotal) {
    return (ok: false, amount: null);
  }
  return (ok: true, amount: amount);
}

/// Avoir émis par la clôture : le code sert à l'opérateur au téléphone.
class IssuedVoucher {
  const IssuedVoucher({required this.code, required this.amountXaf});
  final String code;
  final int amountXaf;

  /// Lit `data.voucher` de la réponse ; `null` si aucun avoir.
  static IssuedVoucher? fromResponse(Object? body) {
    final data = body is Map ? body['data'] : null;
    final voucher = data is Map ? data['voucher'] : null;
    if (voucher is! Map) return null;
    final code = voucher['code'];
    final amount = voucher['amountXaf'];
    if (code is! String || amount is! num) return null;
    return IssuedVoucher(code: code, amountXaf: amount.toInt());
  }
}

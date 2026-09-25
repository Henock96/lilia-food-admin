/// F3-08 — un geste soumis à deux administrateurs rend
/// `{ data: { approvalRequired: true, approval } }` : rien n'a encore changé,
/// et l'interface ne doit surtout pas afficher « enregistré ».
bool isApprovalRequested(Object? body) {
  final data = body is Map && body['data'] is Map ? body['data'] as Map : body;
  return data is Map && data['approvalRequired'] == true;
}

/// Message à afficher quand un changement de numéro attend un second admin.
const payoutChangePendingMessage =
    'Demande envoyée : un second administrateur doit approuver ce changement '
    'de numéro (admin web, écran Approbations). Rien ne change d’ici là.';

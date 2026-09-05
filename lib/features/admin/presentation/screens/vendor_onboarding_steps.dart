import '../../../../models/onboarding_report.dart';

/// Une étape de l'assistant et les cases de la checklist serveur qu'elle porte.
///
/// Sortie de `vendor_onboarding_screen.dart` pour être testable : la règle
/// « peut-on quitter cette étape ? » vivait dans une méthode privée d'un
/// `State`, donc hors de portée de tout test — et elle était fausse.
class VendorOnboardingStep {
  final String title;
  final List<String> checkKeys;

  const VendorOnboardingStep(this.title, this.checkKeys);
}

/// Les huit étapes, dans l'ordre.
///
/// ⚠️ « Commercial » porte **deux** formulaires : les paramètres commerciaux
/// (commission, minimum de commande) et le compte de reversement. C'est la
/// seule étape dans ce cas, et c'est elle qui a révélé le défaut d'avance
/// automatique.
const vendorOnboardingSteps = <VendorOnboardingStep>[
  VendorOnboardingStep('Identité', ['identity', 'description']),
  VendorOnboardingStep('Visuels', ['logo', 'cover']),
  VendorOnboardingStep('Localisation', ['location', 'gps']),
  VendorOnboardingStep('Horaires', ['hours']),
  VendorOnboardingStep('Livraison', ['delivery']),
  // `payout` est bloquant : sans compte de reversement, le vendeur
  // encaisserait des commandes sans qu'on puisse jamais le payer. Il doit
  // donc être rattaché à une étape, sinon la checklist signalerait un
  // manque que l'assistant ne saurait pas où corriger.
  VendorOnboardingStep('Commercial', ['commerce', 'payout']),
  VendorOnboardingStep('Catalogue', ['catalog']),
  VendorOnboardingStep('Vérification', []),
];

/// L'assistant peut-il passer à l'étape suivante ?
///
/// **Le défaut corrigé.** L'avance était inconditionnelle : tout enregistrement
/// réussi faisait `_step++`. Le raccourci tient tant qu'une étape porte un seul
/// formulaire. « Commercial » en porte deux — enregistrer les paramètres
/// commerciaux projetait donc l'administrateur sur « Catalogue », et le champ
/// **compte de reversement** disparaissait après s'être affiché une fois.
/// D'autant plus trompeur que `payout` est une case bloquante : la checklist
/// réclamait un compte que l'assistant venait d'escamoter.
///
/// La règle suit désormais la même autorité que le reste de l'écran — la
/// checklist du serveur : on ne quitte une étape que si plus aucune de ses
/// cases **bloquantes** n'est en défaut. Les cases facultatives (description,
/// couverture, paramètres commerciaux) ne retiennent personne : elles sont
/// signalées, jamais exigées.
///
/// Une case absente du rapport compte comme **non satisfaite**. Un backend plus
/// ancien, ou une clé renommée, ne doit pas faire passer une étape pour
/// terminée : le coût d'une étape à reparcourir est nul, celui d'un vendeur
/// publié sans compte de reversement ne l'est pas.
bool canLeaveStep(VendorOnboardingStep step, OnboardingReport? report) {
  if (step.checkKeys.isEmpty) return true;
  if (report == null) return false;
  return step.checkKeys.every((key) {
    final check = report.checkFor(key);
    if (check == null) return false;
    return !check.blocking || check.isOk;
  });
}

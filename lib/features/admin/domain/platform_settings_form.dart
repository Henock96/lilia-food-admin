/// Formulaire « Paramètres plateforme » — logique pure, testable.
///
/// Symétrique de `lilia-food-web/apps/admin/lib/platform-settings-form.ts`.
///
/// * **R-09 — aucun réglage d'argent.** Frais de service, commission, points,
///   parrainage : ils fixent de l'argent, se demandent depuis l'admin web et
///   s'approuvent à deux administrateurs. Le serveur les refuse dans le PATCH
///   (409 `FINANCIAL_SETTING_REQUIRES_APPROVAL`) ; cette app les affiche sans
///   les modifier, et ne les envoie jamais.
/// * **Le PATCH ne porte que ce qui a changé (SET-001)**, plus l'`updatedAt`
///   chargé. L'écran renvoyait les treize champs à chaque enregistrement : un
///   formulaire ouvert depuis un moment pouvait effacer un blocage de sécurité
///   posé entre-temps par un autre administrateur. Le serveur répond 409 si la
///   configuration a bougé depuis le chargement.
library;

import 'package:lilia_admin/core/network/api_exception.dart';
import 'package:lilia_admin/features/admin/domain/app_update_rules.dart';
import 'package:lilia_admin/models/platform_settings.dart';

/// Valeurs saisies à l'écran, telles quelles.
class SettingsFormValues {
  const SettingsFormValues({
    required this.maintenanceMode,
    required this.maintenanceMessage,
    required this.minAppVersion,
    required this.latestAppVersion,
    required this.updateUrlAndroid,
    required this.updateUrlIos,
    required this.updateMessage,
    required this.blockConfirmation,
  });

  final bool maintenanceMode;
  final String maintenanceMessage;
  final String minAppVersion;
  final String latestAppVersion;
  final String updateUrlAndroid;
  final String updateUrlIos;
  final String updateMessage;
  final String blockConfirmation;
}

/// D-4 — texte du champ pour un taux chargé : 500 bps → « 5 », 750 → « 7.5 »,
/// non posé → vide.
String groceryServiceFeeText(PlatformSettings s) {
  final bps = s.groceryServiceFeeBps;
  if (bps == null) return '';
  final percent = bps / 100;
  return percent == percent.roundToDouble()
      ? percent.toStringAsFixed(0)
      : percent.toString();
}

class SettingsPatchResult {
  const SettingsPatchResult({required this.errors, required this.patch});

  /// Refus à afficher. Non vide ⇒ ne rien envoyer.
  final List<String> errors;

  /// Champs modifiés, plus `expectedUpdatedAt` quand il est connu.
  final Map<String, dynamic> patch;

  bool get ok => errors.isEmpty;

  /// Au moins un champ réel à écrire (le verrou seul ne compte pas).
  bool get changed => patch.keys.any((k) => k != 'expectedUpdatedAt');
}

String? _textOrNull(String? raw) {
  final t = raw?.trim() ?? '';
  return t.isEmpty ? null : t;
}

/// Construit le PATCH à partir de la saisie et de la configuration **telle
/// qu'elle a été chargée**.
SettingsPatchResult buildSettingsPatch(
  SettingsFormValues form,
  PlatformSettings loaded,
) {
  final errors = <String>[];
  final patch = <String, dynamic>{
    if (loaded.updatedAtRaw != null) 'expectedUpdatedAt': loaded.updatedAtRaw,
  };

  if (form.maintenanceMode != loaded.maintenanceMode) {
    patch['maintenanceMode'] = form.maintenanceMode;
  }
  final maintenanceMessage = _textOrNull(form.maintenanceMessage);
  if (maintenanceMessage != _textOrNull(loaded.maintenanceMessage)) {
    patch['maintenanceMessage'] = maintenanceMessage;
  }

  // Toute la section de mise à jour est jugée, même non modifiée : un état
  // hérité incohérent doit être corrigé avant tout autre enregistrement.
  errors.addAll(validateAppUpdate(
    minVersion: form.minAppVersion,
    latestVersion: form.latestAppVersion,
    urlAndroid: form.updateUrlAndroid,
    urlIos: form.updateUrlIos,
  ));
  if ((_textOrNull(form.updateMessage)?.length ?? 0) > 300) {
    errors.add('Le message de mise à jour ne doit pas dépasser 300 caractères.');
  }
  if (requiresBlockConfirmation(
        minVersion: form.minAppVersion,
        savedMinVersion: loaded.minAppVersion,
      ) &&
      form.blockConfirmation.trim().toUpperCase() != 'BLOQUER') {
    errors.add(
      'Vous êtes sur le point de bloquer le parc : tapez BLOQUER dans le '
      'champ de confirmation.',
    );
  }

  final update = buildAppUpdatePatch(
    minVersion: form.minAppVersion,
    latestVersion: form.latestAppVersion,
    urlAndroid: form.updateUrlAndroid,
    urlIos: form.updateUrlIos,
    message: form.updateMessage,
  );
  final saved = <String, String?>{
    'minAppVersion': _textOrNull(loaded.minAppVersion),
    'latestAppVersion': _textOrNull(loaded.latestAppVersion),
    'updateUrlAndroid': _textOrNull(loaded.updateUrlAndroid),
    'updateUrlIos': _textOrNull(loaded.updateUrlIos),
    'updateMessage': _textOrNull(loaded.updateMessage),
  };
  update.forEach((key, value) {
    if (value != saved[key]) patch[key] = value;
  });

  return SettingsPatchResult(errors: errors, patch: patch);
}

/// Ce refus est-il le verrou optimiste perdu (« rechargez ») ?
///
/// Le code `SETTINGS_STALE` fait foi ; le texte exact du conflit reste
/// reconnu pour un serveur antérieur au code.
bool isStaleSettingsConflict(ApiException e) {
  if (e.statusCode != 409) return false;
  if (e.code != null) return e.code == 'SETTINGS_STALE';
  return e.message.startsWith(
    'La configuration a été modifiée par un autre administrateur',
  );
}

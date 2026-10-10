/// Formulaire « Paramètres plateforme » — logique pure, testable.
///
/// Symétrique de `lilia-food-web/apps/admin/lib/platform-settings-form.ts`.
/// Deux garanties :
///
/// * **Aucun faux succès sur une saisie numérique (SET-003).** L'écran faisait
///   `double.tryParse(saisie) ?? ancienneValeur` : « 12,5 » (virgule décimale
///   française), « abc » ou un champ vidé renvoyaient **en silence** l'ancienne
///   valeur, et le snackbar vert « Configuration enregistrée » s'affichait. La
///   saisie illisible bloque désormais l'envoi, avec le nom du champ.
/// * **Le PATCH ne porte que ce qui a changé (SET-001)**, plus l'`updatedAt`
///   chargé. L'écran renvoyait les treize champs à chaque enregistrement : un
///   formulaire ouvert depuis un moment pouvait effacer un blocage de sécurité
///   posé entre-temps par un autre administrateur. Le serveur répond 409 si la
///   configuration a bougé depuis le chargement.
library;

import 'package:lilia_admin/core/network/api_exception.dart';
import 'package:lilia_admin/features/admin/domain/app_update_rules.dart';
import 'package:lilia_admin/models/platform_settings.dart';

class NumberFieldSpec {
  const NumberFieldSpec(this.label, {required this.integer});
  final String label;
  final bool integer;
}

/// Clés numériques du DTO, dans l'ordre de l'écran.
const numberFieldSpecs = <String, NumberFieldSpec>{
  'serviceFeePercent': NumberFieldSpec('Frais de service', integer: false),
  'restaurantCommissionPercent':
      NumberFieldSpec('Commission vendeur', integer: false),
  'loyaltyPointsPerOrder':
      NumberFieldSpec('Points / commande livrée', integer: true),
  'loyaltyPointValueXaf': NumberFieldSpec("Valeur d'un point", integer: true),
  'loyaltyMinRedemption':
      NumberFieldSpec("Seuil minimum d'utilisation", integer: true),
  'referrerBonusPoints': NumberFieldSpec('Bonus parrain', integer: true),
};

final _decimal = RegExp(r'^\d+(\.\d+)?$');
final _integer = RegExp(r'^\d+$');
final _virguleDecimale = RegExp(r'^\d+,\d+$');

/// La valeur, ou le refus prêt à afficher. Jamais de repli.
({num? value, String? error}) parseNumberField(String raw, NumberFieldSpec spec) {
  final t = raw.trim();
  if (t.isEmpty) return (value: null, error: '${spec.label} : champ obligatoire.');
  if (!spec.integer && _virguleDecimale.hasMatch(t)) {
    return (
      value: null,
      error: '${spec.label} : utilisez un point pour les décimales (ex : 12.5).',
    );
  }
  if (!(spec.integer ? _integer : _decimal).hasMatch(t)) {
    return (
      value: null,
      error: spec.integer
          ? '${spec.label} : nombre entier attendu (« $t » n\'en est pas un).'
          : '${spec.label} : nombre attendu (« $t » n\'en est pas un).',
    );
  }
  return (value: spec.integer ? int.parse(t) : double.parse(t), error: null);
}

/// Valeurs saisies à l'écran, telles quelles.
class SettingsFormValues {
  const SettingsFormValues({
    required this.numbers,
    required this.maintenanceMode,
    required this.maintenanceMessage,
    required this.minAppVersion,
    required this.latestAppVersion,
    required this.updateUrlAndroid,
    required this.updateUrlIos,
    required this.updateMessage,
    required this.blockConfirmation,
    this.groceryServiceFeePercent = '',
  });

  /// Clé du DTO → texte saisi.
  final Map<String, String> numbers;
  final bool maintenanceMode;
  final String maintenanceMessage;
  final String minAppVersion;
  final String latestAppVersion;
  final String updateUrlAndroid;
  final String updateUrlIos;
  final String updateMessage;
  final String blockConfirmation;

  /// D-4 — frais de service des épiceries, saisis en %. Vide = taux général.
  final String groceryServiceFeePercent;
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

final _percentDeuxDecimales = RegExp(r'^\d+(\.\d{1,2})?$');

/// D-4 — taux épicerie saisi en % (0 à 100, deux décimales au plus), converti
/// en points de base entiers. Vide → `null` (taux général).
({int? bps, String? error}) parseGroceryServiceFee(String raw) {
  const label = 'Frais de service épiceries';
  final t = raw.trim();
  if (t.isEmpty) return (bps: null, error: null);
  if (_virguleDecimale.hasMatch(t)) {
    return (
      bps: null,
      error: '$label : utilisez un point pour les décimales (ex : 7.5).',
    );
  }
  if (!_percentDeuxDecimales.hasMatch(t)) {
    return (
      bps: null,
      error: '$label : pourcentage attendu, deux décimales au plus (« $t »).',
    );
  }
  final percent = double.parse(t);
  if (percent > 100) return (bps: null, error: '$label : 100 % au plus.');
  return (bps: (percent * 100).round(), error: null);
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

num _loadedNumber(PlatformSettings s, String key) => switch (key) {
      'serviceFeePercent' => s.serviceFeePercent,
      'restaurantCommissionPercent' => s.restaurantCommissionPercent,
      'loyaltyPointsPerOrder' => s.loyaltyPointsPerOrder,
      'loyaltyPointValueXaf' => s.loyaltyPointValueXaf,
      'loyaltyMinRedemption' => s.loyaltyMinRedemption,
      'referrerBonusPoints' => s.referrerBonusPoints,
      _ => throw ArgumentError.value(key, 'key', 'champ numérique inconnu'),
    };

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

  for (final entry in numberFieldSpecs.entries) {
    final parsed = parseNumberField(form.numbers[entry.key] ?? '', entry.value);
    if (parsed.error != null) {
      errors.add(parsed.error!);
    } else if (parsed.value != _loadedNumber(loaded, entry.key)) {
      patch[entry.key] = parsed.value;
    }
  }

  // D-4 — seulement si le serveur connaît le réglage.
  if (loaded.knowsGroceryServiceFee) {
    final grocery = parseGroceryServiceFee(form.groceryServiceFeePercent);
    if (grocery.error != null) {
      errors.add(grocery.error!);
    } else if (grocery.bps != loaded.groceryServiceFeeBps) {
      patch['groceryServiceFeeBps'] = grocery.bps;
    }
  }

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

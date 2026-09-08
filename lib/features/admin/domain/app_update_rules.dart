/// Règles du canal de mise à jour du parc client — logique pure, testable.
///
/// ## Pourquoi ce fichier existe
///
/// Le `CLAUDE.md` de ce dépôt pose la règle : un service qui touche Firebase
/// dès sa construction n'est pas instanciable en test, donc toute logique
/// décidable en est extraite (`notification_router`, `fcm_token_registrar`).
/// Un `StatefulWidget` pose le même problème, et ces règles-ci méritent d'être
/// testées : une erreur ici **bloque l'application de tous les clients**.
library;

/// Version applicative comparable.
///
/// Grammaire identique aux deux autres implémentations — `APP_VERSION_PATTERN`
/// côté backend, `AppVersion` dans `lilia-app`. Strict : `1.2` rend `null`, il
/// n'est jamais promu en `1.2.0`. Une saisie approximative de l'administrateur
/// ne doit pas produire un seuil valide à partir d'une faute de frappe.
class AppVersionRef implements Comparable<AppVersionRef> {
  final int major;
  final int minor;
  final int patch;

  /// `null` = information **absente**, pas build zéro. La distinction compte
  /// dans [compareTo].
  final int? buildNumber;

  const AppVersionRef({
    required this.major,
    required this.minor,
    required this.patch,
    this.buildNumber,
  });

  static final _pattern = RegExp(r'^(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?$');

  static AppVersionRef? tryParse(String? input) {
    if (input == null) return null;
    var sanitized = input.trim();
    if (sanitized.isEmpty) return null;
    if (sanitized.startsWith('v') || sanitized.startsWith('V')) {
      sanitized = sanitized.substring(1);
    }

    final match = _pattern.firstMatch(sanitized);
    if (match == null) return null;

    final major = int.tryParse(match.group(1)!);
    final minor = int.tryParse(match.group(2)!);
    final patch = int.tryParse(match.group(3)!);
    if (major == null || minor == null || patch == null) return null;

    final buildStr = match.group(4);
    final buildNumber = buildStr == null ? null : int.tryParse(buildStr);
    if (buildStr != null && buildNumber == null) return null;

    return AppVersionRef(
      major: major,
      minor: minor,
      patch: patch,
      buildNumber: buildNumber,
    );
  }

  /// Ordre : majeure, mineure, correctif, puis build.
  ///
  /// ⚠️ Le build ne départage que si les **deux** versions en portent un.
  /// Recopie exacte de `lilia-app/lib/core/update/app_version.dart` : c'est ce
  /// code-là qui appliquera réellement le seuil, et une règle admin plus
  /// permissive ou plus stricte produirait un réglage accepté ici et
  /// interprété autrement là-bas.
  @override
  int compareTo(AppVersionRef other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);

    final a = buildNumber;
    final b = other.buildNumber;
    if (a == null || b == null) return 0;
    return a.compareTo(b);
  }

  bool operator <(AppVersionRef other) => compareTo(other) < 0;
  bool operator <=(AppVersionRef other) => compareTo(other) <= 0;
  bool operator >(AppVersionRef other) => compareTo(other) > 0;
  bool operator >=(AppVersionRef other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppVersionRef &&
          runtimeType == other.runtimeType &&
          major == other.major &&
          minor == other.minor &&
          patch == other.patch &&
          buildNumber == other.buildNumber;

  @override
  int get hashCode => Object.hash(major, minor, patch, buildNumber);

  @override
  String toString() => buildNumber != null
      ? '$major.$minor.$patch+$buildNumber'
      : '$major.$minor.$patch';
}

const _formatAttendu = 'au format 1.3.0 ou 1.3.0+34';

/// Les refus, en français, prêts à afficher. Liste vide = saisie acceptable.
///
/// Les URLs sont revalidées ici alors que le DTO les valide déjà : le but
/// n'est pas de s'y substituer mais d'éviter un aller-retour pour une erreur
/// que l'écran peut montrer tout de suite.
List<String> validateAppUpdate({
  required String minVersion,
  required String latestVersion,
  required String urlAndroid,
  required String urlIos,
}) {
  final refus = <String>[];

  final min = minVersion.trim();
  final latest = latestVersion.trim();

  final minParsed = min.isEmpty ? null : AppVersionRef.tryParse(min);
  final latestParsed = latest.isEmpty ? null : AppVersionRef.tryParse(latest);

  if (min.isNotEmpty && minParsed == null) {
    refus.add('La version minimale doit être $_formatAttendu.');
  }
  if (latest.isNotEmpty && latestParsed == null) {
    refus.add('La dernière version publiée doit être $_formatAttendu.');
  }

  if (minParsed != null && latestParsed == null && latest.isEmpty) {
    refus.add(
      'Renseignez d\'abord la dernière version publiée : sans elle, '
      'impossible de vérifier que le blocage est installable.',
    );
  }

  if (minParsed != null && latestParsed != null) {
    // Détecte l'asymétrie de build : si l'une des deux versions a un build et
    // l'autre pas, compareTo neutralise le build (rend égales 1.3.0 et 1.3.0+34).
    // Donc minParsed > latestParsed est faux, mais le seuil est indécidable :
    // le client en 1.3.0+34 < 1.3.0+40 serait bloqué, alors que la règle
    // prétendait pouvoir vérifier.
    final minHasBuild = minParsed.buildNumber != null;
    final latestHasBuild = latestParsed.buildNumber != null;
    if (minHasBuild != latestHasBuild) {
      refus.add(
        'Impossible de vérifier que le blocage est installable : '
        'l\'une des deux versions a un build et l\'autre pas. '
        'Renseignez les deux avec ou sans build.',
      );
    } else if (minParsed > latestParsed) {
      refus.add(
        'Vous exigeriez une version que personne ne peut installer : la version '
        'minimale ($minParsed) dépasse la dernière version publiée '
        '($latestParsed).',
      );
    }
  }

  refus.addAll(_validerUrl(
    urlAndroid,
    const ['https', 'market'],
    'L\'URL Android doit commencer par https:// ou market://.',
  ));
  refus.addAll(_validerUrl(
    urlIos,
    const ['https', 'itms-apps'],
    'L\'URL iOS doit commencer par https:// ou itms-apps://.',
  ));

  return refus;
}

List<String> _validerUrl(String raw, List<String> schemes, String message) {
  final url = raw.trim();
  if (url.isEmpty) return const [];
  final uri = Uri.tryParse(url);
  if (uri == null || !schemes.contains(uri.scheme) || uri.host.isEmpty) {
    return [message];
  }
  return const [];
}

/// La portion de DTO du canal de mise à jour.
///
/// ⚠️ Un champ vidé part en **`null`**, jamais en `""`. `""` échouerait le
/// `@Matches` du DTO ; `null` traverse la `ValidationPipe`
/// (`whitelist: true`, `forbidNonWhitelisted: false`) jusqu'au
/// `update: { ...dto }` de Prisma et **efface** la colonne. C'est la seule
/// façon de lever un blocage posé par erreur.
Map<String, dynamic> buildAppUpdatePatch({
  required String minVersion,
  required String latestVersion,
  required String urlAndroid,
  required String urlIos,
  required String message,
}) {
  String? nullSiVide(String raw) {
    final v = raw.trim();
    return v.isEmpty ? null : v;
  }

  String? normalizeVersion(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return null;
    // Normalise le préfixe v/V en sérialisant la version parsée, sinon retombe
    // sur la valeur trimée (le serveur la rejettera avec un @Matches, ce qui
    // est mieux qu'une 400 silencieuse).
    final parsed = AppVersionRef.tryParse(v);
    return parsed?.toString() ?? v;
  }

  return <String, dynamic>{
    'minAppVersion': normalizeVersion(minVersion),
    'latestAppVersion': normalizeVersion(latestVersion),
    'updateUrlAndroid': nullSiVide(urlAndroid),
    'updateUrlIos': nullSiVide(urlIos),
    'updateMessage': nullSiVide(message),
  };
}

/// Faut-il exiger la saisie du mot de confirmation ?
///
/// Seulement quand le geste **pose ou modifie** un blocage. Lever un blocage
/// ou laisser la valeur inchangée n'en demande pas : l'obstacle doit être sur
/// le chemin qui casse, jamais sur celui qui répare.
bool requiresBlockConfirmation({
  required String minVersion,
  required String? savedMinVersion,
}) {
  final saisi = minVersion.trim();
  if (saisi.isEmpty) return false;
  return saisi != (savedMinVersion?.trim() ?? '');
}

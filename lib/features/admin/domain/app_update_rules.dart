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

    final build = match.group(4);
    return AppVersionRef(
      major: int.parse(match.group(1)!),
      minor: int.parse(match.group(2)!),
      patch: int.parse(match.group(3)!),
      buildNumber: build == null ? null : int.parse(build),
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

  if (minParsed != null && latestParsed != null && minParsed > latestParsed) {
    refus.add(
      'Vous exigeriez une version que personne ne peut installer : la version '
      'minimale ($minParsed) dépasse la dernière version publiée '
      '($latestParsed).',
    );
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
  if (uri == null || !schemes.contains(uri.scheme) || !uri.hasAuthority) {
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

  return <String, dynamic>{
    'minAppVersion': nullSiVide(minVersion),
    'latestAppVersion': nullSiVide(latestVersion),
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

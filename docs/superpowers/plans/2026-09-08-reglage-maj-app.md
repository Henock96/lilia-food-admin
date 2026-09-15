# Réglage de la mise à jour de l'app client — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Permettre à un ADMIN de régler, depuis l'écran « Paramètres plateforme » existant, les cinq champs du canal de mise à jour de l'app client — sans pouvoir bloquer le parc par accident.

**Architecture:** Trois unités. Le modèle `PlatformSettings` gagne cinq champs. Un fichier **pur** `app_update_rules.dart` porte le parsing de version, les règles de cohérence et la construction du patch. L'écran existant gagne une section qui ne fait qu'afficher ce que les règles rendent. Aucun changement backend.

**Tech Stack:** Flutter, Riverpod (`flutter_riverpod` ^3.3.2), `flutter_test`. Pas de nouvelle dépendance.

**Spec:** `docs/superpowers/specs/2026-09-08-reglage-maj-app-design.md`

## Global Constraints

- **Aucun changement backend.** `UpdatePlatformSettingsDto` valide déjà les cinq champs ; `updateSettings` fait `update: { ...dto }`, donc `null` efface déjà la colonne.
- **Grammaire de version, identique aux trois implémentations :** `^(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?$`, avec `v`/`V` initial et espaces tolérés. Strict : `1.2` rend `null`, jamais `1.2.0`.
- **Comparaison :** majeure, mineure, correctif, puis build — **et le build ne départage que si les deux versions en portent un**. `1.3.0` et `1.3.0+34` sont équivalentes. Recopie exacte de `lilia-app/lib/core/update/app_version.dart:92-101`.
- **Un champ vidé part en `null`, jamais en `""`.** `""` échouerait le `@Matches` du DTO ; `null` efface la colonne, c'est la sortie de secours d'un blocage.
- **Invariant :** `minAppVersion ≤ latestAppVersion`, et `minAppVersion` non vide exige `latestAppVersion` non vide.
- **Langue :** tous les libellés et messages en français, avec accents.
- **Ne jamais poser `minAppVersion` en vérification manuelle** : cette route sert la production, ce serait bloquer de vrais clients.

## File Structure

| Fichier | Responsabilité |
|---|---|
| `lib/models/platform_settings.dart` *(modifier)* | porter les 5 champs et les lire dans `fromJson` |
| `lib/features/admin/domain/app_update_rules.dart` *(créer)* | pur : parser, comparer, valider, construire le patch |
| `test/features/admin/app_update_rules_test.dart` *(créer)* | couvrir les règles |
| `test/models/platform_settings_test.dart` *(créer)* | couvrir le parsing des 5 champs |
| `lib/features/admin/presentation/screens/platform_settings_screen.dart` *(modifier)* | afficher, collecter, appeler les règles |

---

### Task 1 : le modèle porte les cinq champs

**Files:**
- Modify: `lib/models/platform_settings.dart`
- Test: `test/models/platform_settings_test.dart` (créer)

**Interfaces:**
- Consomme : rien.
- Produit : `PlatformSettings.minAppVersion`, `.latestAppVersion`, `.updateUrlAndroid`, `.updateUrlIos`, `.updateMessage` — toutes `String?`, `null` quand absentes ou non-chaînes.

- [ ] **Step 1: Écrire le test qui échoue**

Créer `test/models/platform_settings_test.dart` :

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/models/platform_settings.dart';

void main() {
  group('PlatformSettings.fromJson — canal de mise à jour', () {
    test('lit les cinq champs quand ils sont présents', () {
      final s = PlatformSettings.fromJson({
        'id': 'singleton',
        'minAppVersion': '1.3.0',
        'latestAppVersion': '1.4.0+41',
        'updateUrlAndroid': 'https://play.google.com/store/apps/details?id=x',
        'updateUrlIos': 'https://apps.apple.com/app/id123',
        'updateMessage': 'Nouveautés du panier',
      });

      expect(s.minAppVersion, '1.3.0');
      expect(s.latestAppVersion, '1.4.0+41');
      expect(s.updateUrlAndroid,
          'https://play.google.com/store/apps/details?id=x');
      expect(s.updateUrlIos, 'https://apps.apple.com/app/id123');
      expect(s.updateMessage, 'Nouveautés du panier');
    });

    // C'est l'état réel de la production au 08/09/2026 : les colonnes
    // existent, aucune n'est renseignée. L'écran doit s'ouvrir dessus.
    test('rend null sur les cinq quand la réponse ne les porte pas', () {
      final s = PlatformSettings.fromJson({'id': 'singleton'});

      expect(s.minAppVersion, isNull);
      expect(s.latestAppVersion, isNull);
      expect(s.updateUrlAndroid, isNull);
      expect(s.updateUrlIos, isNull);
      expect(s.updateMessage, isNull);
    });

    // `as String?` sur un nombre lèverait ; une app à jour contre un backend
    // qui renverrait n'importe quoi ne doit pas planter l'écran de réglages.
    test('rend null plutôt que de lever sur une valeur non-chaîne', () {
      final s = PlatformSettings.fromJson({
        'id': 'singleton',
        'minAppVersion': 130,
      });

      expect(s.minAppVersion, isNull);
    });

    test('ne casse pas les champs existants', () {
      final s = PlatformSettings.fromJson({
        'id': 'singleton',
        'serviceFeePercent': 15,
        'loyaltyPointValueXaf': 50,
        'maintenanceMode': true,
      });

      expect(s.serviceFeePercent, 15);
      expect(s.loyaltyPointValueXaf, 50);
      expect(s.maintenanceMode, isTrue);
    });
  });
}
```

- [ ] **Step 2: Lancer le test, vérifier qu'il échoue**

```bash
cd lilia-food-admin
flutter test test/models/platform_settings_test.dart
```

Attendu : ÉCHEC à la compilation — `The getter 'minAppVersion' isn't defined for the type 'PlatformSettings'`.

- [ ] **Step 3: Ajouter les cinq champs**

Dans `lib/models/platform_settings.dart`, après `final String? maintenanceMessage;` et avant `final DateTime updatedAt;` :

```dart
  // ── Canal de mise à jour du parc client ──────────────────────────────────
  //
  // Réglages de `lilia-app`, pas de cette application-ci. Servis par la route
  // publique `GET /platform-settings` et lus au démarrage du client.

  /// Seuil **bloquant** : en dessous, le client ne peut plus commander.
  /// ⚠️ Seul réglage de la plateforme capable de rendre l'application
  /// inutilisable pour l'intégralité du parc installé.
  final String? minAppVersion;

  /// Dernière version publiée. Sous ce seuil, le client reçoit une invitation
  /// **reportable**. Sert aussi de plafond à [minAppVersion].
  final String? latestAppVersion;

  final String? updateUrlAndroid;
  final String? updateUrlIos;
  final String? updateMessage;
```

Ajouter au constructeur, après `this.maintenanceMessage,` :

```dart
    this.minAppVersion,
    this.latestAppVersion,
    this.updateUrlAndroid,
    this.updateUrlIos,
    this.updateMessage,
```

Dans `fromJson`, après la ligne `maintenanceMessage:` :

```dart
      // `as String?` lèverait sur un nombre ; on ne veut pas qu'une valeur
      // inattendue empêche d'ouvrir l'écran de réglages.
      minAppVersion: json['minAppVersion'] is String
          ? json['minAppVersion'] as String
          : null,
      latestAppVersion: json['latestAppVersion'] is String
          ? json['latestAppVersion'] as String
          : null,
      updateUrlAndroid: json['updateUrlAndroid'] is String
          ? json['updateUrlAndroid'] as String
          : null,
      updateUrlIos: json['updateUrlIos'] is String
          ? json['updateUrlIos'] as String
          : null,
      updateMessage: json['updateMessage'] is String
          ? json['updateMessage'] as String
          : null,
```

- [ ] **Step 4: Lancer le test, vérifier qu'il passe**

```bash
flutter test test/models/platform_settings_test.dart
```

Attendu : 4 tests verts.

- [ ] **Step 5: Commit**

```bash
git add lib/models/platform_settings.dart test/models/platform_settings_test.dart
git commit -m "Le modèle plateforme porte le canal de mise à jour

Les cinq colonnes existent en base depuis le 07/09/2026 et sont servies
par GET /platform-settings, mais le modèle Dart s'arrêtait à
maintenanceMessage : l'écran ne pouvait rien en afficher.

Lecture défensive par \`is String\` plutôt que \`as String?\` — ce dernier
lève sur un nombre, et une valeur inattendue ne doit pas empêcher
d'ouvrir l'écran de réglages."
```

---

### Task 2 : les règles pures

**Files:**
- Create: `lib/features/admin/domain/app_update_rules.dart`
- Test: `test/features/admin/app_update_rules_test.dart` (créer)

**Interfaces:**
- Consomme : `PlatformSettings` (Task 1) — pour rien d'autre que le contexte ; ce fichier ne l'importe pas.
- Produit :
  - `class AppVersionRef implements Comparable<AppVersionRef>` avec `static AppVersionRef? tryParse(String? input)`, les champs `major`/`minor`/`patch`/`buildNumber`, les opérateurs `<` `<=` `>` `>=`, et `toString()`.
  - `List<String> validateAppUpdate({required String minVersion, required String latestVersion, required String urlAndroid, required String urlIos})`
  - `Map<String, dynamic> buildAppUpdatePatch({required String minVersion, required String latestVersion, required String urlAndroid, required String urlIos, required String message})`
  - `bool requiresBlockConfirmation({required String minVersion, required String? savedMinVersion})`

- [ ] **Step 1: Écrire le test qui échoue**

Créer `test/features/admin/app_update_rules_test.dart` :

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/features/admin/domain/app_update_rules.dart';

void main() {
  group('AppVersionRef.tryParse', () {
    test('accepte major.minor.patch avec et sans build', () {
      expect(AppVersionRef.tryParse('1.3.0').toString(), '1.3.0');
      expect(AppVersionRef.tryParse('1.3.0+34').toString(), '1.3.0+34');
      expect(AppVersionRef.tryParse('  v1.3.0  ').toString(), '1.3.0');
    });

    // Une saisie approximative ne doit jamais devenir un seuil valide : ce
    // champ peut bloquer tout le parc.
    test('refuse tout le reste', () {
      expect(AppVersionRef.tryParse('1.2'), isNull);
      expect(AppVersionRef.tryParse('1.3.x'), isNull);
      expect(AppVersionRef.tryParse('v2 beta'), isNull);
      expect(AppVersionRef.tryParse('1.3.0-rc1'), isNull);
      expect(AppVersionRef.tryParse(''), isNull);
      expect(AppVersionRef.tryParse('   '), isNull);
      expect(AppVersionRef.tryParse(null), isNull);
    });
  });

  group('AppVersionRef.compareTo', () {
    test('ordonne numériquement, pas lexicographiquement', () {
      final v1_3_0 = AppVersionRef.tryParse('1.3.0')!;
      final v1_10_0 = AppVersionRef.tryParse('1.10.0')!;
      expect(v1_3_0 < v1_10_0, isTrue);
      expect(v1_10_0 > v1_3_0, isTrue);
    });

    test('départage par build quand les deux en portent un', () {
      final a = AppVersionRef.tryParse('1.3.0+34')!;
      final b = AppVersionRef.tryParse('1.3.0+35')!;
      expect(a < b, isTrue);
    });

    // Parité stricte avec lilia-app/lib/core/update/app_version.dart:92-101.
    // Le serveur publie souvent « 1.3.0 » sans build ; s'en servir pour
    // départager rendrait la version sans build artificiellement plus
    // ancienne, et le plafond laisserait passer ce qu'il doit refuser.
    test('ne départage pas sur le build quand l\'une n\'en a pas', () {
      final sans = AppVersionRef.tryParse('1.3.0')!;
      final avec = AppVersionRef.tryParse('1.3.0+34')!;
      expect(sans.compareTo(avec), 0);
      expect(avec.compareTo(sans), 0);
      expect(sans <= avec, isTrue);
      expect(avec <= sans, isTrue);
    });
  });

  group('validateAppUpdate', () {
    List<String> run({
      String min = '',
      String latest = '',
      String android = '',
      String ios = '',
    }) =>
        validateAppUpdate(
          minVersion: min,
          latestVersion: latest,
          urlAndroid: android,
          urlIos: ios,
        );

    test('tout vide est acceptable — c\'est l\'état de départ', () {
      expect(run(), isEmpty);
    });

    test('refuse un format de version invalide', () {
      expect(run(latest: '1.2'), hasLength(1));
      expect(run(latest: '1.2').first, contains('dernière version'));
      expect(run(min: '1.2', latest: '1.3.0').first, contains('minimale'));
    });

    test('refuse minVersion au-dessus de latestVersion', () {
      final refus = run(min: '1.4.0', latest: '1.3.0');
      expect(refus, hasLength(1));
      expect(refus.first, contains('personne ne peut installer'));
    });

    test('accepte minVersion égale à latestVersion', () {
      expect(run(min: '1.3.0', latest: '1.3.0'), isEmpty);
    });

    test('accepte minVersion sous latestVersion', () {
      expect(run(min: '1.2.0', latest: '1.3.0'), isEmpty);
    });

    test('refuse minVersion sans latestVersion', () {
      final refus = run(min: '1.3.0');
      expect(refus, hasLength(1));
      expect(refus.first, contains('Renseignez d\'abord'));
    });

    test('latestVersion seule est acceptable', () {
      expect(run(latest: '1.3.0'), isEmpty);
    });

    test('valide les protocoles d\'URL', () {
      expect(run(android: 'http://play.google.com'), hasLength(1));
      expect(run(android: 'https://play.google.com'), isEmpty);
      expect(run(android: 'market://details?id=x'), isEmpty);
      expect(run(ios: 'market://details?id=x'), hasLength(1));
      expect(run(ios: 'https://apps.apple.com/app/id1'), isEmpty);
      expect(run(ios: 'itms-apps://apps.apple.com/app/id1'), isEmpty);
    });

    test('cumule les refus', () {
      expect(run(min: '1.2', android: 'http://x'), hasLength(2));
    });
  });

  group('buildAppUpdatePatch', () {
    // C'est `null` qui efface la colonne côté serveur ; `""` échouerait le
    // @Matches du DTO. C'est la sortie de secours d'un blocage posé par erreur.
    test('un champ vidé part en null, pas en chaîne vide', () {
      final patch = buildAppUpdatePatch(
        minVersion: '',
        latestVersion: '   ',
        urlAndroid: '',
        urlIos: '',
        message: '',
      );

      expect(patch['minAppVersion'], isNull);
      expect(patch['latestAppVersion'], isNull);
      expect(patch['updateUrlAndroid'], isNull);
      expect(patch['updateUrlIos'], isNull);
      expect(patch['updateMessage'], isNull);
      expect(patch.containsKey('minAppVersion'), isTrue);
    });

    test('trim les valeurs renseignées', () {
      final patch = buildAppUpdatePatch(
        minVersion: ' 1.2.0 ',
        latestVersion: '1.3.0',
        urlAndroid: ' https://play.google.com ',
        urlIos: '',
        message: '  Nouveautés  ',
      );

      expect(patch['minAppVersion'], '1.2.0');
      expect(patch['latestAppVersion'], '1.3.0');
      expect(patch['updateUrlAndroid'], 'https://play.google.com');
      expect(patch['updateUrlIos'], isNull);
      expect(patch['updateMessage'], 'Nouveautés');
    });

    test('ne porte que les cinq clés du canal de mise à jour', () {
      final patch = buildAppUpdatePatch(
        minVersion: '',
        latestVersion: '',
        urlAndroid: '',
        urlIos: '',
        message: '',
      );

      expect(patch.keys, hasLength(5));
      expect(patch.containsKey('serviceFeePercent'), isFalse);
    });
  });

  group('requiresBlockConfirmation', () {
    test('exigée quand on pose un blocage', () {
      expect(
        requiresBlockConfirmation(minVersion: '1.3.0', savedMinVersion: null),
        isTrue,
      );
    });

    test('exigée quand on change un blocage existant', () {
      expect(
        requiresBlockConfirmation(
            minVersion: '1.4.0', savedMinVersion: '1.3.0'),
        isTrue,
      );
    });

    // L'obstacle doit être sur le chemin qui casse, jamais sur celui qui répare.
    test('pas exigée pour lever un blocage', () {
      expect(
        requiresBlockConfirmation(minVersion: '', savedMinVersion: '1.3.0'),
        isFalse,
      );
    });

    test('pas exigée quand rien ne change', () {
      expect(
        requiresBlockConfirmation(
            minVersion: ' 1.3.0 ', savedMinVersion: '1.3.0'),
        isFalse,
      );
    });
  });
}
```

- [ ] **Step 2: Lancer le test, vérifier qu'il échoue**

```bash
flutter test test/features/admin/app_update_rules_test.dart
```

Attendu : ÉCHEC à la compilation — `Target of URI doesn't exist: 'package:lilia_admin/features/admin/domain/app_update_rules.dart'`.

- [ ] **Step 3: Écrire l'implémentation**

Créer `lib/features/admin/domain/app_update_rules.dart` :

```dart
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
```

- [ ] **Step 4: Lancer le test, vérifier qu'il passe**

```bash
flutter test test/features/admin/app_update_rules_test.dart
```

Attendu : tous verts (23 tests).

- [ ] **Step 5: Vérifier l'analyse**

```bash
flutter analyze
```

Attendu : `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/features/admin/domain/app_update_rules.dart test/features/admin/app_update_rules_test.dart
git commit -m "Règles du canal de mise à jour, pures et testées

minAppVersion est le seul réglage capable de rendre l'app inutilisable
pour tout le parc, et son format valide ne dit rien de sa cohérence :
1.4.0 est un format parfait qui verrouille 100% des clients quand la
dernière version publiée est 1.3.0.

D'où l'invariant minAppVersion <= latestAppVersion, vérifiable sans
connaître la version du client — qui est une autre application,
versionnée indépendamment.

La comparaison recopie exactement lilia-app : le build ne départage que
si les deux versions en portent un. Le serveur publie souvent « 1.3.0 »
sans build ; s'en servir pour départager rendrait cette version
artificiellement plus ancienne et le plafond laisserait passer ce qu'il
doit refuser.

Un champ vidé part en null, jamais en chaîne vide : c'est null qui
efface la colonne, donc qui lève un blocage posé par erreur."
```

---

### Task 3 : la section dans l'écran

**Files:**
- Modify: `lib/features/admin/presentation/screens/platform_settings_screen.dart`

**Interfaces:**
- Consomme : `PlatformSettings.minAppVersion` etc. (Task 1) ; `validateAppUpdate`, `buildAppUpdatePatch`, `requiresBlockConfirmation` (Task 2).
- Produit : rien (feuille de l'arbre).

- [ ] **Step 1: Ajouter les imports et les contrôleurs**

En tête de `platform_settings_screen.dart`, après l'import de `platform_settings.dart` :

```dart
import 'package:lilia_admin/features/admin/domain/app_update_rules.dart';
```

Dans `_PlatformSettingsFormState`, après `late final TextEditingController _maintenanceMessage;` :

```dart
  late final TextEditingController _minAppVersion;
  late final TextEditingController _latestAppVersion;
  late final TextEditingController _updateUrlAndroid;
  late final TextEditingController _updateUrlIos;
  late final TextEditingController _updateMessage;
  late final TextEditingController _blockConfirmation;

  /// Déplié d'office si un blocage est déjà actif : un blocage en vigueur ne
  /// doit pas être caché derrière un repli devant l'administrateur qui vient
  /// précisément le lever.
  late bool _blocageDeplie;
```

Dans `initState()`, après `_maintenanceMode = s.maintenanceMode;` :

```dart
    _minAppVersion = TextEditingController(text: s.minAppVersion ?? '');
    _latestAppVersion = TextEditingController(text: s.latestAppVersion ?? '');
    _updateUrlAndroid = TextEditingController(text: s.updateUrlAndroid ?? '');
    _updateUrlIos = TextEditingController(text: s.updateUrlIos ?? '');
    _updateMessage = TextEditingController(text: s.updateMessage ?? '');
    _blockConfirmation = TextEditingController();
    _blocageDeplie = (s.minAppVersion ?? '').isNotEmpty;
```

Dans `dispose()`, avant `super.dispose();` :

```dart
    _minAppVersion.dispose();
    _latestAppVersion.dispose();
    _updateUrlAndroid.dispose();
    _updateUrlIos.dispose();
    _updateMessage.dispose();
    _blockConfirmation.dispose();
```

- [ ] **Step 2: Brancher les règles dans `_save()`**

Dans `_save()`, **avant** `setState(() => _saving = true);`, insérer :

```dart
    final refus = validateAppUpdate(
      minVersion: _minAppVersion.text,
      latestVersion: _latestAppVersion.text,
      urlAndroid: _updateUrlAndroid.text,
      urlIos: _updateUrlIos.text,
    );

    if (requiresBlockConfirmation(
          minVersion: _minAppVersion.text,
          savedMinVersion: s.minAppVersion,
        ) &&
        _blockConfirmation.text.trim().toUpperCase() != 'BLOQUER') {
      refus.add(
        'Vous êtes sur le point de bloquer le parc : tapez BLOQUER dans le '
        'champ de confirmation.',
      );
    }

    if (refus.isNotEmpty) {
      setState(() => _blocageDeplie = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(refus.join('\n')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
      return;
    }
```

Puis, dans la construction du `dto`, après `'maintenanceMessage': _maintenanceMessage.text.trim(),` :

```dart
      ...buildAppUpdatePatch(
        minVersion: _minAppVersion.text,
        latestVersion: _latestAppVersion.text,
        urlAndroid: _updateUrlAndroid.text,
        urlIos: _updateUrlIos.text,
        message: _updateMessage.text,
      ),
```

Enfin, dans le bloc de succès, après `ref.invalidate(platformSettingsProvider);` :

```dart
      _blockConfirmation.clear();
```

- [ ] **Step 3: Ajouter la section dans `build()`**

Dans le `ListView`, entre la section `'Maintenance'` et le `const SizedBox(height: 16)` qui précède le bouton :

```dart
        _section('Mise à jour de l\'application', [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Réglages de l\'application cliente, pas de celle-ci. '
              'Laisser un champ vide efface la valeur.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
          _textField(
            _latestAppVersion,
            'Dernière version publiée',
            '1.3.0 ou 1.3.0+34',
          ),
          _textField(
            _updateMessage,
            'Message affiché au client',
            'Nouveautés du panier…',
          ),
          _textField(
            _updateUrlAndroid,
            'URL Android',
            'https://play.google.com/…',
          ),
          _textField(_updateUrlIos, 'URL iOS', 'https://apps.apple.com/…'),
          if (_updateUrlIos.text.trim().isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                '⚠️ Sans URL iOS, le client retombe sur un lien placeholder '
                '(id6740000000) : les utilisateurs iPhone atterriraient sur '
                'une fiche App Store inexistante.',
                style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
              ),
            ),
          ExpansionTile(
            initiallyExpanded: _blocageDeplie,
            onExpansionChanged: (v) => setState(() => _blocageDeplie = v),
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: const Text(
              '⚠ Blocage du parc (avancé)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'En dessous de cette version, les clients ne peuvent plus '
                  'commander du tout. Réservé à une faille de sécurité ou une '
                  'rupture de contrat d\'API. Pour pousser une nouveauté, '
                  'utilisez « Dernière version publiée » ci-dessus, qui laisse '
                  'reporter.',
                  style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                ),
              ),
              _textField(
                _minAppVersion,
                'Version minimale',
                'vide = aucun blocage',
              ),
              _textField(
                _blockConfirmation,
                'Tapez BLOQUER pour confirmer',
                'BLOQUER',
              ),
            ],
          ),
        ]),
```

- [ ] **Step 4: Ajouter le helper `_textField`**

Après la méthode `_numberField`, dans la même classe :

```dart
  /// Champ texte pleine largeur. `_numberField` place son libellé à gauche
  /// d'une case étroite, ce qui convient à un pourcentage mais tronquerait une
  /// URL.
  Widget _textField(
      TextEditingController controller, String label, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
```

Le `onChanged: (_) => setState(() {})` existe pour que l'avertissement iOS apparaisse et disparaisse au fil de la saisie.

- [ ] **Step 5: Vérifier analyse et suite complète**

```bash
flutter analyze
flutter test
```

Attendu : `No issues found!` et tous les tests verts (20 fichiers existants + les 2 ajoutés).

- [ ] **Step 6: Lancer l'app et ouvrir l'écran**

```bash
flutter run
```

Se connecter en ADMIN, ouvrir Paramètres plateforme. Vérifier :
1. la section « Mise à jour de l'application » apparaît sous « Maintenance » ;
2. les cinq champs sont vides (état réel de la production) ;
3. l'avertissement iOS est visible ;
4. « ⚠ Blocage du parc » est **replié** ;
5. saisir `1.4.0` en version minimale sans dernière version publiée → « Enregistrer » refuse avec le message V3, et le bloc se déplie tout seul.

⚠️ **Ne pas enregistrer de `minAppVersion` réelle** : cette route sert la production.

- [ ] **Step 7: Commit**

```bash
git add lib/features/admin/presentation/screens/platform_settings_screen.dart
git commit -m "L'admin peut enfin régler la mise à jour de l'app client

Le canal était déployé et inerte depuis le 07/09/2026 : cinq colonnes en
base, servies par GET /platform-settings, toutes à null, et aucune
interface pour les poser — ni ici, ni dans le web. Le seul moyen était un
PATCH au curl.

Les quatre champs sûrs sont directement accessibles. minAppVersion vit
derrière un repli « Blocage du parc » qui exige la saisie du mot BLOQUER,
et seulement quand le geste pose ou modifie un blocage : lever un blocage
n'a pas à franchir l'obstacle qui protège de l'action inverse.

Le repli s'ouvre d'office si un blocage est déjà actif, et à chaque refus
de validation — sinon l'administrateur lirait un message parlant d'un
champ qu'il ne voit pas.

L'écran signale aussi que l'URL iOS de repli codée dans lilia-app est un
placeholder : sans updateUrlIos, les clients iPhone atterrissent sur une
fiche App Store inexistante."
```

---

### Task 4 : documentation

**Files:**
- Modify: `CLAUDE.md` (racine de `lilia-food-admin`)

**Interfaces:** aucune.

- [ ] **Step 1: Documenter la section**

Dans `CLAUDE.md`, dans « Features implémentées », après le bloc « ### Admin (admin/) — onboarding vendeur (30/08/2026) » :

```markdown
### Canal de mise à jour de l'app client (08/09/2026)

`platform_settings_screen.dart` règle les cinq champs de `PlatformSettings`
que lit `lilia-app` au démarrage (`lib/core/update/`). Ils étaient déployés
depuis le 07/09/2026 et **tous à `null`**, faute d'interface pour les poser.

⚠️ `minAppVersion` **bloque** : en dessous, le client ne peut plus commander.
Les règles vivent dans `features/admin/domain/app_update_rules.dart` — pur et
testé, comme `notification_router` :

- **`minAppVersion ≤ latestAppVersion`**, sans quoi on exigerait une version
  que personne ne peut installer. L'admin ne connaît pas la version du client
  (autre app, versionnée à part) : `latestAppVersion` sert donc de plafond.
- **Le build ne départage que si les deux versions en portent un.** Recopie
  exacte de `lilia-app` — le serveur publie souvent `1.3.0` sans build.
- **Un champ vidé part en `null`, jamais en `""`.** `""` échoue le `@Matches`
  du DTO ; `null` efface la colonne. C'est la sortie de secours d'un blocage.
- Confirmation par le mot `BLOQUER`, exigée seulement quand on **pose ou
  modifie** un blocage — jamais pour le lever.

⚠️ `lilia-food-admin` et `lilia_food_delivery` n'ont **aucun** mécanisme de
mise à jour : cet écran ne pilote que l'app client.
```

- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "CLAUDE.md : le canal de mise à jour et ses deux pièges

Le plafond par latestAppVersion et la sémantique du build ne se devinent
pas à la lecture de l'écran, et se réinventeraient de travers."
```

---

## Auto-relecture

**Couverture de la spec** — §1 pourquoi : Task 1+3 (le manque comblé). §2 périmètre : respecté, aucun fichier backend ni `lilia-app` touché. §3.1 plafond : Task 2, `validateAppUpdate`. §3.2 confirmation séparée : Task 2 `requiresBlockConfirmation` + Task 3 `ExpansionTile`. §4.1 fichier pur : Task 2. §4.2 trois unités : Tasks 1/2/3. §4.3 API + parité : Task 2. §4.4 `null` : Task 2 `buildAppUpdatePatch`. §5 V1–V5 : Task 2 (V1–V4) et Task 3 (V5, qui a besoin de la valeur enregistrée). §6 avertissement iOS : Task 3. §7 flux : Task 3. §8 tests 1–7 : Task 2 (1–6) et Task 1 (7, non-régression du modèle). §9 critères : Task 3 steps 5–6.

**Placeholders** — aucun « TBD », aucune étape sans code. Le seul point non scriptable est le step 6 de la Task 3, une vérification manuelle à l'écran ; ses cinq points sont énumérés.

**Cohérence des types** — `AppVersionRef` est le nom utilisé partout (jamais `AppVersion`, qui est la classe de `lilia-app`). `validateAppUpdate` rend `List<String>` dans sa définition, son test et son appel. `buildAppUpdatePatch` rend `Map<String, dynamic>`, étalé par `...` dans le `dto` de `_save()`. `requiresBlockConfirmation` prend `savedMinVersion` en `String?`, alimenté par `s.minAppVersion` (`String?` depuis la Task 1) : cohérent.

**Correction appliquée à la relecture** — le step 3 de la Task 3 contenait une ligne `Theme.of(context).useMaterial3 ? ... : ...` sans effet, vestige de rédaction. Elle a été **retirée du plan** plutôt que laissée avec une consigne de ne pas la recopier : une instruction qu'il faut penser à ne pas suivre finit par être suivie.

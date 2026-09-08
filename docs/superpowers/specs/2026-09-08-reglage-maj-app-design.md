# Réglage de la mise à jour de l'app client — écran admin

**Date** : 08/09/2026
**Dépôt** : `lilia-food-admin`
**Statut** : spec validée, prête pour le plan d'implémentation

---

## 1. POURQUOI

Le mécanisme de mise à jour du parc mobile a été livré le 07/09/2026 : cinq
colonnes sur `PlatformSettings` (`minAppVersion`, `latestAppVersion`,
`updateUrlAndroid`, `updateUrlIos`, `updateMessage`), servies par la route
publique `GET /platform-settings`, consommées par `lilia-app`
(`lib/core/update/`) qui affiche une modale bloquante ou facultative.

**Il est déployé et inerte.** Vérifié le 08/09/2026 contre la production :
`GET /platform-settings` répond 200 et porte les cinq champs — la migration
`20260907200000_app_update_channel` est bien appliquée — mais **les cinq valeurs
sont `null`**. Aucun client ne verra jamais de proposition de mise à jour.

La cause est qu'**aucune interface ne permet de les régler**. Recherche faite
dans `lilia-food-admin/lib` et dans `lilia-food-web` : zéro occurrence de
`minAppVersion`. Le seul moyen aujourd'hui est un `PATCH
/admin/platform-settings` au curl avec un jeton ADMIN.

Cette spec comble ce manque.

### Prérequis, résolu le 08/09/2026

`AppVersion.current` dans `lilia-app` valait `1.2.7+32` alors que
`pubspec.yaml` déclarait `1.3.0+34` : la constante avait été laissée derrière
lors d'une montée de version, et `app_version_matches_pubspec_test` était au
rouge. C'est le nombre auquel le seuil se compare — un client réellement en
`1.3.0+34` se déclarait en `1.2.7+32`. Poser `latestAppVersion = 1.3.0` depuis
le nouvel écran aurait donc invité à mettre à jour des clients déjà à jour, et
un `minAppVersion` à `1.3.0` les aurait tous bloqués sur une version qu'ils
avaient pourtant installée.

Corrigé (`lilia-app`, commit `712ead8`). **Le réglage n'a de sens que sur un
parc qui dit la vérité sur sa version** : si la suite `lilia-app` repasse au
rouge sur ce test, ce n'est pas un détail de métadonnée, c'est le seuil de
blocage qui devient faux.

---

## 2. PÉRIMÈTRE

### Dans le périmètre

Étendre l'écran **existant** `features/admin/presentation/screens/
platform_settings_screen.dart` (275 lignes, sections Frais de service /
Fidélité / Parrainage / Maintenance) d'une section « Mise à jour de
l'application », et le modèle Dart qui l'alimente.

### Hors périmètre, et pourquoi

- **Aucun changement backend.** `UpdatePlatformSettingsDto` valide déjà les
  cinq champs (format de version strict, protocoles d'URL), et
  `updateSettings` fait `update: { ...dto }` : envoyer `null` efface déjà la
  colonne. Rien ne manque côté serveur.
- **Pas de mécanisme de mise à jour pour `lilia-food-admin` ni
  `lilia_food_delivery`.** Vérifié : aucune des deux n'a d'équivalent de
  `lib/core/update/`. Les doter est un chantier distinct, qui ne se règle pas
  depuis cet écran.
- **Pas de correction du placeholder iOS** dans `lilia-app` (voir §6) : cette
  spec ne touche pas au dépôt client.

---

## 3. LA CONTRAINTE QUI STRUCTURE TOUT

`minAppVersion` est **le seul réglage de la plateforme capable de rendre
l'application inutilisable pour l'intégralité du parc installé**. En dessous de
ce seuil, le client reçoit une modale bloquante et ne peut plus commander.

Le format est validé des deux côtés (`^\d+\.\d+\.\d+(\+\d+)?$`), mais le format
ne dit rien de la **cohérence** : saisir `1.4.0` alors que la dernière version
publiée est `1.3.0` est un format parfaitement valide qui verrouille 100 % des
clients — y compris ceux qui viennent de mettre à jour. Et la sortie de secours
passe par ce même écran.

Deux décisions en découlent.

### 3.1 Le plafond est `latestAppVersion`

L'écran ne peut pas connaître la version publiée de `lilia-app` : c'est une
**autre application**, versionnée indépendamment (`lilia-app` est en `1.3.0+34`,
`lilia-food-admin` en `1.0.4+5`). Trois sources étaient possibles ; celle
retenue est `latestAppVersion` lui-même.

**Invariant : `minAppVersion ≤ latestAppVersion`.**

C'est la traduction exacte de « ne pas exiger une version que personne ne peut
installer ». Elle ne coûte aucun champ supplémentaire, aucune migration, et
aucune donnée à tenir synchronisée entre deux dépôts. Les deux alternatives ont
été écartées : un nouveau champ backend serait une colonne de plus à maintenir
sans garantie d'être plus juste que `latestAppVersion` ; une constante en dur
dans l'admin serait fausse dès la release suivante du client.

**Conséquence acceptée** : pour poser un blocage, il faut d'abord déclarer la
dernière version publiée. C'est de toute façon le premier geste raisonnable.

### 3.2 Le blocage est séparé et demande une confirmation écrite

Les quatre champs sûrs sont directement accessibles. `minAppVersion` vit dans un
`ExpansionTile` intitulé « ⚠ Blocage du parc », qui rappelle le plafond en
vigueur et exige la saisie du mot `BLOQUER`.

Il est **replié par défaut, sauf si `minAppVersion` est déjà renseignée** —
auquel cas il s'ouvre d'office. Un blocage actif ne doit jamais être caché
derrière un repli : l'admin qui vient précisément le lever doit le voir en
arrivant.

La confirmation n'est exigée que si la valeur **bloque effectivement** :
non vide, et différente de celle déjà enregistrée. Corriger une faute de frappe
sur un blocage déjà actif, ou vider le champ pour lever le blocage, ne la
demande pas — l'obstacle doit être sur le chemin qui casse, jamais sur celui qui
répare.

---

## 4. ARCHITECTURE

### 4.1 Où vivent les règles

Fichier **pur**, sans dépendance Flutter :
`lib/features/admin/domain/app_update_rules.dart`.

C'est la convention déjà établie dans ce dépôt. `notification_router.dart` et
`fcm_token_registrar.dart` existent pour la raison écrite dans le `CLAUDE.md` :
*« le service touche `FirebaseMessaging.instance` dès sa construction, donc il
n'est pas instanciable en test unitaire. Toute logique décidable en est
extraite. »* Un `StatefulWidget` pose le même problème, et ces règles-ci
méritent d'être testées puisqu'une erreur bloque le parc.

Les deux alternatives ont été écartées : valider en ligne dans `_save()` rendrait
l'invariant du §3.1 intestable sans `pumpWidget` ; s'en remettre au backend ne
marcherait pas, puisqu'il valide le format mais **ignore** la cohérence entre les
deux versions.

### 4.2 Les trois unités

| Unité | Fait quoi | Dépend de |
|---|---|---|
| `models/platform_settings.dart` | porte les 5 champs, les lit dans `fromJson` | rien |
| `features/admin/domain/app_update_rules.dart` | parse, compare, valide, construit le patch | rien (pur Dart) |
| `platform_settings_screen.dart` | affiche, collecte, appelle les règles | les deux ci-dessus |

L'écran ne décide de rien : il affiche ce que les règles rendent.

### 4.3 API du fichier de règles

```dart
/// Version applicative comparable. Grammaire identique aux deux autres
/// implémentations (backend `APP_VERSION_PATTERN`, client `AppVersion`).
/// Strict : « 1.2 » est refusé, jamais promu en « 1.2.0 » — une faute de
/// frappe ne doit pas devenir un seuil valide.
class AppVersionRef implements Comparable<AppVersionRef> {
  static AppVersionRef? tryParse(String? raw);
}
```

**Parité obligatoire avec `lilia-app/lib/core/update/app_version.dart`** — c'est
le code qui appliquera réellement le seuil ; une règle admin plus permissive ou
plus stricte que lui produirait un réglage accepté ici et interprété autrement
là-bas. Trois points à recopier, pas à réinventer :

1. le `+build` est **facultatif**, et `null` signifie « absent », pas « build 0 » ;
2. **quand l'une des deux versions n'a pas de build, la comparaison ne se
   départage pas dessus** — `1.3.0` et `1.3.0+34` sont alors équivalentes ;
3. un `v` initial et les espaces sont tolérés (`v1.3.0` est accepté).

/// Les refus, en français, prêts à afficher. Vide = la saisie est acceptable.
List<String> validateAppUpdate({
  required String minVersion,
  required String latestVersion,
  required String urlAndroid,
  required String urlIos,
});

/// La portion de DTO à envoyer. Un champ vidé part en `null`.
Map<String, dynamic> buildAppUpdatePatch({
  required String minVersion,
  required String latestVersion,
  required String urlAndroid,
  required String urlIos,
  required String message,
});
```

### 4.4 Vide signifie `null`, jamais `""`

`buildAppUpdatePatch` `trim()` chaque champ et envoie **`null`** quand le
résultat est vide.

Ce n'est pas un détail de style. `""` échouerait le `@Matches` du DTO (400), et
surtout : `null` est ce qui **efface** la colonne côté serveur —
`update: { ...dto }` avec `whitelist: true` et `forbidNonWhitelisted: false`
laisse passer `null` jusqu'à Prisma. C'est la sortie de secours d'un blocage
posé par erreur.

---

## 5. RÈGLES DE VALIDATION

| # | Règle | Message |
|---|---|---|
| V1 | format `major.minor.patch(+build)` sur les deux versions | « La version minimale doit être au format 1.3.0 ou 1.3.0+34. » |
| V2 | `minAppVersion ≤ latestAppVersion` | « Vous exigeriez une version que personne ne peut installer : la version minimale (X) dépasse la dernière version publiée (Y). » |
| V3 | `minAppVersion` renseignée ⇒ `latestAppVersion` renseignée | « Renseignez d'abord la dernière version publiée : sans elle, impossible de vérifier que le blocage est installable. » |
| V4 | URLs — `https` ou `market` (Android), `https` ou `itms-apps` (iOS) | miroir du DTO, pour que l'admin voie l'erreur avant l'aller-retour |
| V5 | confirmation `BLOQUER` si `minAppVersion` non vide **et** modifiée | « Tapez BLOQUER pour confirmer. » |

V4 double une validation serveur : le but n'est pas de s'y substituer mais
d'éviter un 400 après coup, dans le même esprit que le refus strict du format
côté backend — « permettre à l'administrateur de voir son erreur au lieu d'un
réglage sans effet ».

---

## 6. L'AVERTISSEMENT iOS

Si `updateUrlIos` est vide, l'écran affiche un avertissement **non bloquant** :
le repli codé dans `lilia-app`
(`app_update_service.dart:42` → `https://apps.apple.com/app/lilia-food/id6740000000`)
est un **placeholder**. Les clients iOS recevraient la modale puis atterriraient
sur une fiche App Store inexistante.

Non bloquant délibérément : l'app iOS n'est peut-être pas encore publiée, et
rien ne justifie d'empêcher de régler le canal Android pour autant. Le repli
Android, lui, est correct — `com.dreesis.lilia.lilia_app` est bien
l'`applicationId` réel.

---

## 7. FLUX

```
ouverture
  └─ platformSettingsProvider → PlatformSettings (5 champs inclus)
       └─ _PlatformSettingsForm : 5 contrôleurs de plus, initialisés depuis le modèle

saisie
  └─ ExpansionTile « Blocage du parc » replié par défaut,
     déplié d'office si minAppVersion est déjà renseignée (sinon un blocage
     actif serait invisible)

« Enregistrer »
  ├─ validateAppUpdate(...) → refus ? → SnackBar rouge, rien n'est envoyé
  ├─ blocage nouveau ou modifié et « BLOQUER » non saisi ? → refus V5
  ├─ buildAppUpdatePatch(...) fusionné au DTO existant
  ├─ PATCH /admin/platform-settings
  └─ succès → invalidate(platformSettingsProvider) + SnackBar verte
     échec  → SnackBar rouge avec le message serveur (comportement existant)
```

Le `_save()` actuel affiche déjà `e.toString().replaceFirst('Exception: ', '')`
en SnackBar rouge : rien à changer sur la gestion d'erreur.

---

## 8. TESTS

`test/features/admin/app_update_rules_test.dart` — unitaires, sans widget :

1. `tryParse` accepte `1.3.0` et `1.3.0+34`, **refuse** `1.2`, `1.3.x`,
   `v2 beta`, `""` et `null`.
2. Comparaison : `1.3.0 < 1.10.0` (ordre numérique, pas lexicographique) ;
   `1.3.0+34 < 1.3.0+35` (départagées par le build) ; **`1.3.0` et `1.3.0+34`
   sont équivalentes** (l'une n'a pas de build, on ne se départage pas dessus) —
   parité stricte avec le client, cf. §4.3.
3. V2 : `min = 1.4.0`, `latest = 1.3.0` → refusé ; `min = latest` → accepté.
4. V3 : `min` renseignée et `latest` vide → refusé.
5. V4 : `http://` refusé, `market://` et `itms-apps://` acceptés.
6. Patch : champ vide → `null` (et **pas** `""`) ; champs remplis → valeurs
   `trim()`.
7. Non-régression : le patch conserve les sept réglages existants
   (frais, fidélité ×3, parrainage, maintenance ×2).

Le point 2 mérite son test : une comparaison de chaînes ferait passer `1.10.0`
pour antérieure à `1.3.0`, et le plafond V2 laisserait alors passer exactement
ce qu'il doit refuser.

---

## 9. CRITÈRES DE SORTIE

- `flutter analyze` : 0 problème.
- Suite de tests verte, `app_update_rules_test.dart` inclus.
- L'écran affiche les valeurs de production (les cinq à `null` aujourd'hui, donc
  cinq champs vides et l'`ExpansionTile` replié).
- Un aller-retour réel : poser `latestAppVersion`, vérifier la valeur dans
  `GET /platform-settings`, puis la vider et vérifier le retour à `null`.
  ⚠️ À faire en connaissance de cause — cette route sert la production.
- Ne **jamais** poser `minAppVersion` en vérification : ce serait bloquer de
  vrais clients.

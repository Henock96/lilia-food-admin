# Admin Flutter — Application du thème de l'app client — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remplacer le thème trivial de l'app admin (`ColorScheme.fromSeed(seedColor: Colors.deepPurple)`) par le système de thème de l'app client (`lilia-app`) — identité de marque orange, Material 3, polices Google Fonts, composants thémés.

**Architecture:** Le thème de `lilia-app/lib/theme/` (`lilia_tokens.dart` + `app_theme.dart`) est porté à l'identique dans `lilia-food-admin/lib/theme/`. `main.dart` consomme `AppTheme.light` en mode clair forcé. Le `_AppColors` violet de `settings_screen.dart` est raccordé aux tokens Lilia pour la cohérence visuelle.

**Tech Stack:** Flutter, Material 3, `google_fonts`. Vérification : `flutter analyze` + revue.

**Périmètre :** Thème **clair** uniquement, mode clair forcé (`themeMode: ThemeMode.light`). Le **mode sombre est hors périmètre** : les écrans de l'app admin ont des fonds clairs codés en dur (`Colors.white`, `_AppColors`) et ne sont pas prêts pour le sombre — `theme_mode_provider.dart` du client n'est donc **pas** porté.

**Prérequis :** Exécuter sur une branche/worktree propre (la branche `dev` a des modifications non commitées touchant `lib/main.dart` ; chaque `git add` doit ne capturer que les changements de ce chantier).

---

## Contexte du code existant

- **App client `lilia-app/lib/theme/`** (source à porter) :
  - `lilia_tokens.dart` (234 lignes) — primitives `LiliaColors` (orange `#E8541F`, cream, charcoal, bleu, sémantiques), `LiliaSemantics` (tokens light/dark), `LiliaThemeTokens`, `LiliaSpacing`, `LiliaRadius`, `LiliaOrderStatus`, `liliaFormatPrice`. **N'importe que `flutter/material`** → copiable tel quel.
  - `app_theme.dart` (436 lignes) — `AppTheme.light` / `AppTheme.dark`, Material 3, `GoogleFonts` (oswald/fraunces/girassol/inter), tous les composants thémés. **Importe `google_fonts` et `'lilia_tokens.dart'` (relatif, même dossier)** → copiable tel quel une fois `google_fonts` ajouté.
  - `theme_mode_provider.dart` — **non porté** (mode sombre hors périmètre).
- **App admin `lilia-food-admin`** :
  - `lib/main.dart` — `MyApp` applique `theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple))`. Pas de `lib/theme/`.
  - `pubspec.yaml` — pas de `google_fonts`. Nom du package : `lilia_admin`.
  - `lib/features/settings/presentation/screens/settings_screen.dart` — déclare un `_AppColors` privé avec des couleurs en dur, dont `primary = Color(0xFF6C63FF)` (violet) qui jurera avec la marque orange. Les autres fichiers d'écran n'utilisent que `Colors.white` (neutre, compatible thème clair) — pas de raccord nécessaire ailleurs.
- Les valeurs `LiliaColors.*` sont toutes des `static const Color` → utilisables dans les contextes `const` (`_AppColors` reste entièrement `const`).

---

## File Structure

| Fichier | Rôle | Action |
|---|---|---|
| `pubspec.yaml` | Dépendance `google_fonts` | Modifier |
| `lib/theme/lilia_tokens.dart` | Tokens de design (copie de `lilia-app`) | Créer |
| `lib/theme/app_theme.dart` | `AppTheme.light` / `.dark` (copie de `lilia-app`) | Créer |
| `lib/main.dart` | Consommer `AppTheme.light` | Modifier |
| `lib/features/settings/presentation/screens/settings_screen.dart` | Raccord `_AppColors` → tokens Lilia | Modifier |

---

## Task 1: Dépendance `google_fonts`

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Ajouter la dépendance**

Dans `pubspec.yaml`, section `dependencies:`, après la ligne `  url_launcher: ^6.3.1`, ajouter :

```yaml
  google_fonts: ^8.1.0
```

- [ ] **Step 2: Installer**

Run: `cd /Users/henokmipoks/Desktop/code/lilia-food-admin && flutter pub get`
Expected: `Got dependencies!` — `google_fonts` résolu, `pubspec.lock` mis à jour.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore(admin): add google_fonts dependency"
```

---

## Task 2: Porter `lilia_tokens.dart`

Le fichier `lilia-app/lib/theme/lilia_tokens.dart` n'a aucune dépendance propre au package client — il est copié à l'identique.

**Files:**
- Create: `lib/theme/lilia_tokens.dart`

- [ ] **Step 1: Copier le fichier**

Run:
```bash
cd /Users/henokmipoks/Desktop/code
mkdir -p lilia-food-admin/lib/theme
cp "lilia-app/lib/theme/lilia_tokens.dart" "lilia-food-admin/lib/theme/lilia_tokens.dart"
```
Expected: `lilia-food-admin/lib/theme/lilia_tokens.dart` créé, identique à la source.

- [ ] **Step 2: Vérifier que le fichier n'a pas d'import du package client**

Run: `cd /Users/henokmipoks/Desktop/code/lilia-food-admin && grep -n "package:lilia_app" lib/theme/lilia_tokens.dart || echo "OK - aucun import lilia_app"`
Expected: `OK - aucun import lilia_app` (le fichier n'importe que `package:flutter/material.dart`).

- [ ] **Step 3: Vérifier l'analyse statique**

Run: `cd /Users/henokmipoks/Desktop/code/lilia-food-admin && flutter analyze lib/theme/lilia_tokens.dart`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/theme/lilia_tokens.dart
git commit -m "feat(admin): port Lilia design tokens from client app"
```

---

## Task 3: Porter `app_theme.dart`

Le fichier `lilia-app/lib/theme/app_theme.dart` n'importe que `flutter/material`, `google_fonts` et `'lilia_tokens.dart'` (relatif, même dossier) — il est copié à l'identique.

**Files:**
- Create: `lib/theme/app_theme.dart`

- [ ] **Step 1: Copier le fichier**

Run:
```bash
cd /Users/henokmipoks/Desktop/code
cp "lilia-app/lib/theme/app_theme.dart" "lilia-food-admin/lib/theme/app_theme.dart"
```
Expected: `lilia-food-admin/lib/theme/app_theme.dart` créé, identique à la source.

- [ ] **Step 2: Vérifier que le fichier n'a pas d'import du package client**

Run: `cd /Users/henokmipoks/Desktop/code/lilia-food-admin && grep -n "package:lilia_app" lib/theme/app_theme.dart || echo "OK - aucun import lilia_app"`
Expected: `OK - aucun import lilia_app` (imports attendus : `package:flutter/material.dart`, `package:google_fonts/google_fonts.dart`, `'lilia_tokens.dart'`).

- [ ] **Step 3: Vérifier l'analyse statique**

Run: `cd /Users/henokmipoks/Desktop/code/lilia-food-admin && flutter analyze lib/theme/`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/theme/app_theme.dart
git commit -m "feat(admin): port AppTheme (light/dark) from client app"
```

---

## Task 4: Câbler le thème dans `main.dart`

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Ajouter l'import**

Dans `lib/main.dart`, après la ligne :

```dart
import 'package:lilia_admin/services/notification_service.dart';
```

ajouter :

```dart
import 'package:lilia_admin/theme/app_theme.dart';
```

- [ ] **Step 2: Remplacer le `ThemeData` du `MaterialApp.router`**

Dans `lib/main.dart`, remplacer :

```dart
    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      title: 'Lilia Food Admin',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
    );
```

par :

```dart
    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      title: 'Lilia Food Admin',
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
    );
```

`themeMode: ThemeMode.light` force le mode clair (le mode sombre est hors périmètre — voir l'en-tête du plan).

- [ ] **Step 3: Vérifier l'analyse statique**

Run: `cd /Users/henokmipoks/Desktop/code/lilia-food-admin && flutter analyze lib/main.dart`
Expected: `No issues found!` (l'import `package:flutter/material.dart` déjà présent couvre `ThemeMode`).

- [ ] **Step 4: Commit**

```bash
git add lib/main.dart
git commit -m "feat(admin): apply client AppTheme (light, brand orange)"
```

---

## Task 5: Raccorder `_AppColors` aux tokens Lilia

Le `_AppColors` de `settings_screen.dart` garde ses noms de champs (toutes les références internes au fichier restent valides) mais ses valeurs pointent vers les tokens Lilia — le violet `#6C63FF` devient l'orange de marque. Les variantes « light » sémantiques (vert/rouge/ambre pâle) restent des littéraux `const` neutres, faute de token Lilia exact et pour préserver les contextes `const`.

**Files:**
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart`

- [ ] **Step 1: Ajouter l'import des tokens**

Dans `lib/features/settings/presentation/screens/settings_screen.dart`, après la ligne :

```dart
import '../../../../models/restaurant.dart';
```

ajouter :

```dart
import 'package:lilia_admin/theme/lilia_tokens.dart';
```

- [ ] **Step 2: Remplacer la classe `_AppColors`**

Remplacer intégralement la classe `_AppColors` :

```dart
class _AppColors {
  static const primary = Color(0xFF6C63FF);
  static const primaryLight = Color(0xFFEEEDFF);
  static const success = Color(0xFF22C55E);
  static const successLight = Color(0xFFDCFCE7);
  static const danger = Color(0xFFEF4444);
  static const dangerLight = Color(0xFFFEE2E2);
  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFEF3C7);
  static const surface = Color(0xFFF8FAFC);
  static const cardBg = Colors.white;
  static const textPrimary = Color(0xFF1E293B);
  static const textSecondary = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
}
```

par :

```dart
class _AppColors {
  // Raccordé aux tokens de marque Lilia (cf. lib/theme/lilia_tokens.dart).
  static const primary = LiliaColors.orange500;
  static const primaryLight = LiliaColors.orange50;
  static const success = LiliaColors.green400;
  static const successLight = Color(0xFFDCFCE7);
  static const danger = LiliaColors.red400;
  static const dangerLight = Color(0xFFFEE2E2);
  static const warning = LiliaColors.amber400;
  static const warningLight = Color(0xFFFEF3C7);
  static const surface = LiliaColors.cream100;
  static const cardBg = Colors.white;
  static const textPrimary = LiliaColors.charcoal700;
  static const textSecondary = LiliaColors.charcoal500;
  static const border = LiliaColors.charcoal100;
}
```

- [ ] **Step 3: Vérifier l'analyse statique**

Run: `cd /Users/henokmipoks/Desktop/code/lilia-food-admin && flutter analyze lib/features/settings/presentation/screens/settings_screen.dart`
Expected: `No issues found!` (tous les champs restent `const` ; les références `_AppColors.X` du fichier sont inchangées).

- [ ] **Step 4: Commit**

```bash
git add lib/features/settings/presentation/screens/settings_screen.dart
git commit -m "feat(admin): map settings _AppColors to Lilia brand tokens"
```

---

## Task 6: Vérification finale

- [ ] **Step 1: Analyse statique complète**

Run: `cd /Users/henokmipoks/Desktop/code/lilia-food-admin && flutter analyze`
Expected: aucune nouvelle erreur dans `lib/theme/`, `lib/main.dart` ou `lib/features/settings/`. (Des avertissements préexistants ailleurs dans le projet sont hors périmètre.)

- [ ] **Step 2: Vérification visuelle**

Lancer l'app sur un émulateur :
- L'AppBar, les boutons, les onglets et les champs adoptent l'identité de marque (orange `#E8541F`, polices Oswald/Inter, coins arrondis).
- L'écran Paramètres (restaurateur et admin) n'affiche plus d'accent violet — les éléments `_AppColors.primary` sont orange.
- Le fond des écrans est le cream clair de la marque ; aucun écran ne passe en sombre même si l'appareil est en mode sombre.
- Aucun écran ne présente de texte illisible ni de zone manifestement cassée.

---

## Self-Review

**Couverture du périmètre :**
- Système de thème client porté (`lilia_tokens.dart` + `app_theme.dart`) → Tasks 2-3 ✅
- Dépendance `google_fonts` ajoutée → Task 1 ✅
- `main.dart` consomme `AppTheme.light`, mode clair forcé → Task 4 ✅
- Raccord des couleurs en dur (violet → orange) → Task 5 ✅

**Cohérence :** `app_theme.dart` dépend de `lilia_tokens.dart` (Task 3 après Task 2) et de `google_fonts` (Task 3 après Task 1). `main.dart` consomme `AppTheme` (Task 4 après Task 3). `settings_screen.dart` consomme `LiliaColors` (Task 5 après Task 2). Tous les champs de `_AppColors` restent `const` → pas de rupture dans les contextes `const` du fichier (ex. `const BoxDecoration(color: _AppColors.dangerLight)`).

**Hors périmètre :** mode sombre (`theme_mode_provider.dart` non porté, `themeMode` forcé à `light`) — les écrans admin ne sont pas prêts pour le sombre. Refonte des écrans pour exploiter pleinement les composants thémés (retrait des styles locaux redondants) — amélioration ultérieure, non requise pour appliquer le thème.

**Interaction avec le plan chantier 4** (`2026-05-22-lil79-flutter-pages.md`) : les deux plans modifient `settings_screen.dart` sur des zones distinctes (ce plan : la classe `_AppColors` ; chantier 4 : le `body` admin + le widget `_AdminMenuTile`). Aucun conflit. Exécuter ce plan **avant** le chantier 4 fait que les nouveaux écrans s'affichent directement avec l'identité de marque.

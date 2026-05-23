# lilia_admin

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Google Maps setup

L'application admin utilise `google_maps_flutter` pour afficher la position
des livreurs (écran de tracking — voir LIL-86). Les clés Google Maps ne sont
jamais commitées : seuls des placeholders sont versionnés. Chaque dev doit
configurer ses propres clés localement.

### 1. Créer les clés API dans Google Cloud Console

Dans [Google Cloud Console](https://console.cloud.google.com/) (projet Lilia) :

1. Activer **Maps SDK for Android** et **Maps SDK for iOS**.
2. Créer **deux clés API distinctes** (une Android, une iOS) — ne jamais
   partager une seule clé entre les deux plateformes.

### 2. Restrictions à appliquer aux clés

**Clé Android :**
- Restriction d'application : *Android apps*.
- Nom de package : `com.dreesis.lilia_admin`.
- Empreinte SHA-1 du certificat de signature (debug et release).

**Clé iOS :**
- Restriction d'application : *iOS apps*.
- Bundle ID : celui de `ios/Runner` (vérifier dans Xcode → Runner → General).

Restreindre aussi chaque clé aux APIs strictement nécessaires :
*Maps SDK for Android* / *Maps SDK for iOS*.

### 3. Coller la clé Android

Éditer `android/app/src/main/res/values/google_maps_key.xml` :

```xml
<string name="google_maps_key" translatable="false">VOTRE_VRAIE_CLE_ANDROID</string>
```

Ce fichier est dans `.gitignore` — la vraie clé ne sera jamais commitée.

### 4. Coller la clé iOS

Éditer `ios/Runner/AppDelegate.swift`, remplacer la chaîne placeholder :

```swift
GMSServices.provideAPIKey("VOTRE_VRAIE_CLE_IOS")
```

> Note : le placeholder dans `AppDelegate.swift` est versionné car le fichier
> contient aussi de la logique d'initialisation Flutter. Ne pas commiter de
> vraie clé ici — utiliser `.env` / Xcode build settings si nécessaire en
> production.

### 5. Vérification

```bash
flutter pub get
flutter run        # Android et iOS — une carte vide doit s'afficher
```

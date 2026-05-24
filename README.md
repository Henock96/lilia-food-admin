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

Créer (s'il n'existe pas) `android/app/src/main/res/values/google_maps_key.xml` :

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="google_maps_key" translatable="false">VOTRE_VRAIE_CLE_ANDROID</string>
</resources>
```

Ce fichier est dans `.gitignore` — la vraie clé ne sera jamais commitée.

### 4. Coller la clé iOS

La clé iOS est lue à partir d'`Info.plist` → `GoogleMapsApiKey`, dont la
valeur est injectée au build via la variable `GOOGLE_MAPS_API_KEY` définie
dans un xcconfig gitignored.

Copier le template puis renseigner la vraie clé :

```bash
cp ios/Flutter/Maps.xcconfig.example ios/Flutter/Maps.xcconfig
# puis éditer ios/Flutter/Maps.xcconfig :
# GOOGLE_MAPS_API_KEY = VOTRE_VRAIE_CLE_IOS
```

Plomberie : `Maps.xcconfig` est inclus depuis `Debug.xcconfig` et
`Release.xcconfig` ; `Info.plist` expose `GoogleMapsApiKey = $(GOOGLE_MAPS_API_KEY)` ;
`AppDelegate.swift` lit cette clé via `Bundle.main` puis appelle
`GMSServices.provideAPIKey(...)`. Si `Maps.xcconfig` est absent ou contient
encore le placeholder, l'app démarre mais log un warning et n'initialise pas
les Maps (utile en CI).

> ⚠️ Ne jamais coller la clé dans `AppDelegate.swift` (fichier versionné).

### 5. Vérification

```bash
flutter pub get
cd ios && pod install && cd ..
flutter run        # Android et iOS — une carte vide doit s'afficher
```

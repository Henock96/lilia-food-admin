# LIL-80 — Suivi du livreur en mission + fiche livreur détaillée — Design

> Spec · 2026-05-22 · ticket Linear **LIL-80**
> Périmètre : app admin `lilia-food-admin` (Flutter) + 2 endpoints de support dans `lilia-backend` (NestJS).

## 1. Objectif

Permettre à un administrateur, depuis l'app admin :
1. de consulter une **fiche livreur détaillée** (identité, contact, statistiques, historique des livraisons) ;
2. de **suivre en direct sur une carte** la position d'un livreur lorsqu'il est en mission.

Aujourd'hui l'admin peut seulement assigner un livreur à une commande (`PATCH /deliveries/by-order/:orderId/assign`) et voir la liste des livreurs (écran Livreurs livré au chantier 4 de LIL-79). Aucune visibilité sur le livreur une fois en route.

## 2. Décisions de cadrage (validées)

| Sujet | Décision |
|---|---|
| Périmètre | Les deux volets (fiche livreur **et** suivi carte) sont livrés ensemble. |
| Points d'entrée du suivi | Bouton « Suivre en direct » dans la fiche livreur **et** bouton « Suivre la livraison » dans le détail commande. |
| Mono / multi livreur | Suivi d'**un** livreur (une livraison) à la fois. **Pas** de carte superviseur multi-livreurs (hors périmètre, éventuel ticket futur). |
| Contenu fiche livreur | Entête + contact, statistiques, mission en cours, **historique complet paginé** des livraisons. |
| Approche technique | Adapter le tracking de l'app client `lilia-app` en version simplifiée (un seul `order:watch` à la fois). Pas de package partagé (refactoring hors proportion). |

## 3. Contexte technique existant

- **Backend tracking** : namespace Socket.io `/tracking` (`tracking.gateway.ts`). Le client émet `order:watch { orderId }` → rejoint la room `order:${orderId}` et reçoit `driver:position { lat, lng, eta, timestamp }`. Event `order:status { status }` également diffusé.
- **Modèle `Delivery`** (`prisma/schema.prisma`) : `id`, `orderId` (unique), `delivererId?`, `status: DeliveryStatus` (défaut `EN_ATTENTE`), `createdAt`, `updatedAt`, `estimatedArrival?`, `pickedUpAt?`, `deliveredAt?`, `lastLatitude?`, `lastLongitude?`, `lastPositionAt?`, relation `locations DeliveryLocation[]`. Index `@@index([delivererId, status])`.
- **App client `lilia-app`** : tracking complet déjà en place — `TrackingSocketService` (Socket.io, rooms par commande, reconnexion auto, `socket_io_client`), `DriverLocationController`, `DriverTrackingMap` (`google_maps_flutter`, marqueurs + ETA). Sert de référence à porter.
- **App admin `lilia-food-admin`** : Flutter + Riverpod (code generation). **Ne contient ni `google_maps_flutter`, ni `socket_io_client`, ni `geolocator`.** Temps réel = FCM uniquement. L'écran Livreurs (`lib/features/admin/presentation/screens/deliverers_screen.dart`) liste les livreurs via `GET /admin/deliverers` (modèle `AdminDeliverer` : `id, email, nom, phone, imageUrl, createdAt, recentDeliveries, totalDeliveries`).
- **Endpoints existants réutiles** : `GET /admin/deliverers` (liste paginée), `GET /deliveries/by-order/:orderId`, `GET /deliveries/:id`.

## 4. Architecture

### 4.1 Backend — 2 nouveaux endpoints ADMIN

Ajoutés sur `AdminController` (`@Controller('admin') @Roles('ADMIN')`), implémentés dans `admin.service.ts`.

**`GET /admin/deliverers/:id`** → `{ data: DelivererDetail }`

```
DelivererDetail {
  id, email, nom, phone, imageUrl, createdAt,
  stats: { total, delivered, cancelled, inProgress },
  currentMission: CurrentMission | null
}
CurrentMission {
  orderId, deliveryId, deliveryStatus, orderStatus,
  restaurant: { nom, adresse, latitude, longitude },
  deliveryAddress, deliveryLatitude, deliveryLongitude,
  estimatedArrival, lastLatitude, lastLongitude, lastPositionAt
}
```

- `stats` : agrégats sur les `Delivery` du livreur (`delivererId`), comptage par statut.
- `currentMission` : la `Delivery` du livreur dont le statut est **en cours** (ni livré, ni annulé). S'il y en a plusieurs, prendre la plus récente. `null` si aucune.
- `404` si le livreur (`User` de rôle `LIVREUR`) est introuvable.

**`GET /admin/deliverers/:id/deliveries?page=&limit=`** → `{ data: DelivererDeliveryItem[], total, page, limit }`

```
DelivererDeliveryItem {
  id, orderId, status, createdAt, deliveredAt,
  order: { id, total, status, restaurant: { nom }, deliveryAddress }
}
```

- Historique paginé (limit défaut 20), trié `createdAt desc`.

### 4.2 Backend — accès admin au tracking

Vérifier que le handler `order:watch` de `tracking.gateway.ts` autorise un **admin** à observer n'importe quelle commande. Si l'observation est restreinte au propriétaire de la commande, ajouter une autorisation pour le rôle `ADMIN`. (Point à confirmer dès la première tâche du plan.)

### 4.3 Flutter — infrastructure de suivi temps réel

- **Dépendances ajoutées** au `pubspec.yaml` admin : `socket_io_client`, `google_maps_flutter` (versions alignées sur `lilia-app`).
- **`lib/services/tracking_socket_service.dart`** — portage simplifié de `TrackingSocketService` de `lilia-app` :
  - Connexion à `${AppConstants.baseUrl}/tracking`, `auth: { token: <firebaseIdToken> }`, transports `['websocket', 'polling']`.
  - `watch(String orderId)` → émet `order:watch`, expose un `Stream<DriverPosition>` ; `unwatch(orderId)` ferme la room/stream.
  - Reconnexion automatique ; ré-`watch` après reconnexion ; `reconnect()` après rafraîchissement du token Firebase.
  - **Simplification vs client** : un seul `orderId` suivi à la fois (pas de gestion multi-room) ; pas de fallback HTTP 30 s dans la v1 (la dernière position connue de la mission sert d'état initial).
- **Modèle `DriverPosition { double lat, double lng, int? eta, DateTime timestamp }`**.

### 4.4 Flutter — fiche livreur

- **`DelivererDetailScreen`** (`lib/features/admin/presentation/screens/`).
- **Modèles** : `DelivererDetail`, `DelivererMission`, `DelivererDeliveryItem`, `PaginatedDelivererDeliveries` (`lib/models/`).
- **Repository** : méthodes ajoutées à `AdminOperationsRepository` (chantier 4) — `fetchDelivererDetail(id)`, `fetchDelivererDeliveries(id, page)`.
- **Providers `@riverpod`** : `delivererDetail(id)`, `delivererDeliveries(id, page)` dans `admin_operations_provider.dart`.
- **Écran** :
  - Entête : photo (ou initiale), nom, email, téléphone + boutons **Appeler** / **SMS** (`url_launcher`, déjà dépendance du projet).
  - Ligne de statistiques : total / livrées / annulées / en cours.
  - Carte « Mission en cours » : restaurant, adresse, statut, ETA + bouton **Suivre en direct** → ouvre l'écran de suivi. Masquée si `currentMission == null`.
  - Historique paginé des livraisons (commande, restaurant, statut, date) avec pagination par boutons (pattern de l'écran Livreurs du chantier 4).
  - États `loading` / `erreur` / `vide` standard.
- **Accès** : dans `deliverers_screen.dart`, rendre chaque carte livreur tappable → `context.goNamed('deliverer-detail', ...)`.

### 4.5 Flutter — écran de suivi

- **`DeliveryTrackingScreen`** (`lib/features/admin/presentation/screens/`) — paramètres : `orderId` + position initiale optionnelle (`lastLatitude/lastLongitude` de la mission).
- Carte `google_maps_flutter`. Chaque marqueur porte une **`InfoWindow`** (titre + détail, affichée au tap du marqueur) :
  - Marqueur **livreur** — position mise à jour en direct depuis le `Stream<DriverPosition>` du `TrackingSocketService`. `InfoWindow` : nom du livreur, téléphone, ETA.
  - Marqueur **restaurant** (point de retrait) — `InfoWindow` : nom et adresse du restaurant.
  - Marqueur **destination client** — `InfoWindow` : adresse de livraison.
  - Les marqueurs restaurant et destination ne sont placés que si des coordonnées sont disponibles (**à confirmer au plan** : `Restaurant` et l'adresse de livraison exposent-ils lat/lng ?) ; sinon ils sont omis et la carte se centre sur le livreur.
  - Badge **ETA** (« Arrive dans X min ») alimenté par `DriverPosition.eta`.
  - Caméra initiale centrée sur la dernière position connue passée en paramètre.
- **Accès** :
  - Fiche livreur → bouton « Suivre en direct » (passe l'`orderId` de `currentMission`).
  - Détail commande (`order_detail_screen.dart`) → bouton « Suivre la livraison », visible quand la commande a une livraison **assignée et en cours**.
- **Routes go_router** ajoutées (`app_router.dart`) : `deliverer-detail`, `delivery-tracking`. Atteignables via `goNamed` depuis les branches `/settings` (fiche) et `/commandes` (détail commande).

## 5. Flux de données

**Fiche livreur** : tap carte livreur → `DelivererDetailScreen(id)` → `delivererDetailProvider(id)` (`GET /admin/deliverers/:id`) + `delivererDeliveriesProvider(id, page)` (`GET /admin/deliverers/:id/deliveries`).

**Suivi** : bouton Suivre (fiche ou détail commande) → `DeliveryTrackingScreen(orderId, posInitiale)` → `TrackingSocketService.watch(orderId)` → événements `driver:position` → mise à jour du marqueur livreur + badge ETA. À la fermeture de l'écran → `unwatch(orderId)` + fermeture du socket si plus rien à suivre.

## 6. Gestion d'erreurs

- Écrans : `AsyncValue.when` loading / erreur (message + Réessayer) / vide — pattern du chantier 4.
- Socket : reconnexion automatique. Si le WebSocket est indisponible, l'écran de suivi affiche la **dernière position connue** (état initial) + un indicateur « hors ligne / position non actualisée ». Pas de plantage.
- Carte : si la clé Google Maps est absente ou invalide, la carte ne s'affiche pas — c'est le prérequis identifié (§8).
- Backend : `404` livreur introuvable ; les agrégats gèrent le cas « aucune livraison » (stats à 0, `currentMission` null).

## 7. Tests / vérification

- **App admin** : pas de framework de test (cohérent avec le projet) → vérification par `flutter analyze` + `dart run build_runner build` + test manuel sur appareil/émulateur.
- **Backend** : le projet a une suite de tests (`npm run test`, `npm run test:e2e`). Ajouter des tests pour les 2 nouveaux endpoints (`/admin/deliverers/:id`, `/admin/deliverers/:id/deliveries`) en suivant le pattern existant des tests admin.
- Vérification manuelle de bout en bout : ouvrir la fiche d'un livreur en mission, lancer le suivi, constater le déplacement du marqueur.

## 8. Prérequis & risques

| Élément | Détail |
|---|---|
| **Clés Google Maps** (prérequis bloquant) | Clé API à configurer dans `android/app/src/main/AndroidManifest.xml` et `ios/Runner/AppDelegate.swift` de l'app admin, SDK Maps Android + iOS activés en Google Cloud Console. **Fournies par l'équipe.** Sans clé, la carte ne s'affiche pas sur appareil. |
| Autorisation admin sur `/tracking` | Vérifier que `order:watch` accepte un admin sur toute commande (cf. §4.2). |
| Coordonnées restaurant & adresse de livraison | À confirmer : disponibilité de lat/lng sur `Restaurant` et sur l'adresse de livraison, pour placer les marqueurs restaurant et destination. Dégradation gracieuse si absentes. |
| Rebuild natif | L'ajout de `google_maps_flutter` impose un rebuild natif (pas de hot reload) et la config natif Android/iOS. |
| Backend déployé | Nécessaire pour la vérification manuelle sur appareil. |

## 9. Découpage prévisionnel (pour le plan d'implémentation)

1. **Backend** — 2 endpoints `/admin/deliverers/:id` et `/:id/deliveries` + vérification du guard `/tracking` + tests.
2. **Flutter — fiche livreur** — modèles, repository, providers, `DelivererDetailScreen`, accès depuis l'écran Livreurs, routing.
3. **Flutter — suivi temps réel** — dépendances + config native Maps, `TrackingSocketService`, `DeliveryTrackingScreen`, branchement des 2 points d'entrée (fiche + détail commande), routing.

Le volet 1 (backend) est prérequis du volet 2. Le volet 3 dépend du volet 2 pour le point d'entrée « fiche livreur ». Le plan d'implémentation pourra être unique ou scindé backend / Flutter.

## 10. Hors périmètre

- Carte superviseur affichant tous les livreurs actifs simultanément (éventuel ticket futur).
- Package Flutter partagé entre `lilia-app` et `lilia-food-admin` pour le tracking.
- Fallback HTTP périodique de la position (la v1 s'appuie sur le WebSocket + dernière position connue).
- Suivi de plusieurs livraisons en parallèle.

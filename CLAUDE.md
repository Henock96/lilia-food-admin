# CLAUDE.md — Lilia Admin

App Flutter pour les **vendeurs** (restaurateurs, cuisines maison, boulangeries,
pâtisseries…) et **administrateurs** de la plateforme Lilia Food (Brazzaville,
Congo).

Lilia Food est devenue une **marketplace locale multi-vendeurs** : un vendeur
est un `Restaurant` typé par `vendorType`. L'admin valide les nouveaux vendeurs
non-RESTAURANT avant qu'ils n'apparaissent au catalogue.

**Backend URL** : `AppConstants.baseUrl` (défaut `https://lilia-backend.onrender.com`,
override via `--dart-define=API_URL=...`)
**Rôles** : `RESTAURATEUR` (son vendeur) + `ADMIN` (tous les vendeurs, vue globale)

## Écosystème

| Composant | Stack | Dossier |
|-----------|-------|---------|
| Backend API | NestJS + Prisma | `lilia-backend/` |
| Client mobile | Flutter + Riverpod | `lilia-app/` |
| **Admin dashboard** | **Flutter + Riverpod** | **`lilia-food-admin/`** |
| App livreur | Flutter + Riverpod | `lilia_food_delivery/` (com.dreesis) |

---

## Commandes essentielles

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart run build_runner watch --delete-conflicting-outputs
flutter run
flutter analyze
```

---

## Architecture

### Structure features

```
lib/
├── features/
│   ├── auth/           Firebase Auth + sync backend
│   │   ├── controller/ auth_controller.dart
│   │   ├── repository/ firebase_auth_repository.dart
│   │   └── user_sync_provider.dart    # currentUserProfileProvider
│   ├── admin/          ADMIN only — création vendeurs + validation marketplace
│   │   ├── data/admin_vendors_service.dart
│   │   └── presentation/
│   │       ├── screens/create_restaurant_screen.dart
│   │       ├── screens/admin_vendors_screen.dart   # liste / pending / approve / suspend
│   │       └── screens/payments_screen.dart
│   │       └── providers/admin_vendors_provider.dart
│   ├── banners/        CRUD bannières (ReorderableListView → displayOrder)
│   ├── categories/     CRUD catégories produits
│   ├── clients/        Liste + détail (role-aware)
│   ├── dashboard/      7 endpoints analytics (role-aware)
│   ├── deliveries/     Assignation livreur aux commandes
│   ├── home/           Commandes temps réel + détail
│   ├── menus/          CRUD COMBO + PLAT_SPECIAL
│   ├── products/       CRUD + stock quotidien
│   ├── restaurant/     Provider info restaurant courant
│   ├── settings/       4 tabs (Général, Livraison, Horaires, Déconnexion)
│   ├── users/          Profil + upload Cloudinary
│   └── zones/          CRUD zones livraison par quartier
├── models/             order.dart, product.dart, app_user.dart…
├── routing/            app_router.dart (go_router role-aware)
├── services/
│   ├── notification_service.dart   # FCM — colle Firebase
│   ├── notification_router.dart    # payload FCM → action (pur, testé)
│   └── fcm_token_registrar.dart    # cycle de vie du token (pur, testé)
└── main.dart
```

### Navigation
`StatefulShellRoute` avec branches selon rôle :
1. `/` → `DashboardScreen`
2. `/commandes` → `RestaurantOrdersScreen` + `/commandes/:id` → `OrderDetailScreen`
3. Onglets selon rôle : `/clients`, `/settings`, `/admin`…

### Pattern Role-Aware

```dart
final userProfile = ref.watch(currentUserProfileProvider);
final isAdmin = userProfile?.role == Role.admin;
```

`currentUserProfileProvider` (depuis `user_sync_provider.dart`) + modèle `Role`.

---

## Features implémentées

### Commandes (home/)

**Temps réel via FCM uniquement** (mai 2026) :
- `notification_router.dart` traduit le push en action, `notification_service.dart::_handleNotificationData` l'applique
- Tout payload portant un `orderId` → invalidate `restaurantOrdersProvider`
- Plus de SSE (endpoint supprimé du backend, package `flutter_client_sse` retiré du pubspec)

- `restaurant_orders_screen.dart` : tabs par statut (Toutes / En attente / Payée / En préparation / Prête / Livrée / Annulée)
- `OrderService` + `orderControllerProvider`
- **Détail commande** (`order_detail_screen.dart`) : client (nom/tel/email), adresse, articles + variantes, récap prix, mode paiement, boutons statut
- **Assignation livreur** : depuis le détail → `PATCH /deliveries/by-order/:orderId/assign`
- ADMIN : voit toutes les commandes avec nom du restaurant affiché
- Pull-to-refresh manuel disponible pour forcer un fetch

### Dashboard (dashboard/)
- `GET /dashboard/overview` — today/week/month/total
- `GET /dashboard/orders` — répartition par statut
- `GET /dashboard/top-products` — top 10
- `GET /dashboard/revenue` — 30 jours
- `GET /dashboard/clients` — nouveaux / récurrents / top dépensiers
- `GET /dashboard/peak-hours`
- `GET /dashboard/restaurants` — ADMIN uniquement
- Filtres par période (`period` param)

### Produits (products/)
- CRUD : `products_screen.dart` + `product_form_screen.dart`
- Champ `stockQuotidien` (optionnel)
- Indicateur stock restant dans la liste (`Stock: X/Y` ou `Épuisé`)
- Suppression avec confirmation

### Catégories (categories/)
- CRUD via dialog inline
- `CategoryService` → `/categories/*`
- `categoriesProvider` (AsyncNotifier)

### Menus (menus/)
- CRUD COMBO + PLAT_SPECIAL
- `MenuService` → `/menus/*`

### Bannières (banners/)
- CRUD avec `ReorderableListView` → `displayOrder`
- `BannerService` + `bannersProvider`
- Gotcha : `newIndex` à décrémenter si `newIndex > oldIndex`

### Clients (clients/)
- Recherche (nom/email/tel) + pull-to-refresh
- Détail : stats (commandes, livrées, annulées, total) + historique
- Actions : appeler, SMS, copier contact
- ADMIN : `GET /admin/clients` via `allClientsProvider`
- RESTAURATEUR : clients de son restaurant uniquement

### Zones de livraison (zones/ + settings/)
- Toggle `FIXED` / `ZONE_BASED` dans Settings > Livraison
- CRUD zones (nom, tarif, quartiers via checkbox)
- 30+ quartiers Brazzaville préchargés
- `ZonesService` → `/quartiers/*`

### Settings (settings/)
- 4 tabs : Général / Livraison / Horaires / Déconnexion
- Resto : ouvert/fermé (manualOverride), frais livraison, min commande, temps estimé
- Mode livraison : FIXED / ZONE_BASED + lien vers Zones
- ADMIN voit "Espace Administrateur"

### Profil / Users (users/)
- `user_screen.dart` + `profile_controller.dart`
- Upload photo via **Cloudinary** (`cloudinary_service.dart`)
- `UserRepository` : `GET/PATCH /users/me`

### Admin (admin/) — onboarding vendeur (30/08/2026)

**Créé ≠ prêt ≠ ouvert.** Une boutique naît `DRAFT`, invisible et fermée ;
l'activation est un geste explicite, refusé tant que la checklist serveur n'est
pas satisfaite.

- `create_restaurant_screen.dart` — étape 1 : compte + boutique. **Aucun champ
  mot de passe** : le backend envoie une invitation d'activation, le vendeur
  choisit son secret. `Idempotency-Key` par écran contre le double-envoi.
- `vendor_onboarding_screen.dart` — les 8 étapes (identité, visuels,
  localisation, horaires, livraison, commercial, catalogue, vérification).
  L'état vit **en base** : fermer l'écran ne perd rien.
- `vendor_onboarding_service.dart` → `POST /admin/vendors`,
  `PATCH /vendors/:id/*`, `POST /admin/vendors/:id/activate`.
- La progression et le droit d'activer viennent de `GET /vendors/:id/onboarding`.
  **Ne jamais recalculer `isReady` côté Flutter** : c'est le serveur qui accepte
  ou refuse, et une interface qui déciderait seule proposerait un bouton menant
  à un 409.

⚠️ `PATCH /admin/vendors/:id/unsuspend` lève une suspension ;
`POST /admin/vendors/:id/activate` publie une boutique configurée. Deux gestes
distincts — l'ancien `/activate` en `PATCH` a été renommé.
- **Validation marketplace** : `admin_vendors_screen.dart` + `admin_vendors_service.dart`
  - `GET /admin/vendors?vendorType=&adminApproved=&isActive=` — vue complète
  - `GET /admin/vendors/pending` — badge « à valider »
  - `PATCH /admin/vendors/:id/approve` — approuve un vendeur non-RESTAURANT
  - `PATCH /admin/vendors/:id/suspend { reason }` — `isActive=false` réversible
- Dashboard vendeurs : `GET /dashboard/vendors` (total / pending / suspended / byType)

### Marketplace — modèles (`lib/models/`)
- `vendor_type.dart` — enum `VendorType` : RESTAURANT 🍽️ / HOME_COOK (Cuisine maison) 🥧 /
  BAKERY (Boulangerie) 🥐 / BEVERAGE_SHOP (Boissons) 🥤 / GROCERY (Épicerie) 🛒
- `product_type.dart` — `ProductType` (FOOD, BEVERAGE, ALCOHOL, PASTRY, GROCERY) +
  **matrice `VendorType ↔ ProductType` autorisés** (ex : BAKERY → PASTRY+BEVERAGE).
  `ALCOHOL` présent mais rejeté (pas de vente d'alcool au lancement).
- `stock_mode.dart` — `StockMode` (DAILY…) ; le reset stock quotidien backend
  n'affecte que `stockMode == DAILY`.
- `product_form_screen.dart` étendu : `productType`, `stockMode`, fenêtre de
  disponibilité, options sur-commande selon le `vendorType` du vendeur.

### Livreurs (deliveries/)
- `DeliveryService.getAvailableDeliverers()` → `GET /deliveries/deliverers`
- `DeliveryService.assignDelivererToOrder(orderId, delivererId)` → `PATCH /deliveries/by-order/:orderId/assign`
- Utilisé depuis `OrderDetailScreen` pour assigner un livreur

---

## Order Flow — Côté admin

```
1. RESTAURATEUR reçoit FCM "🔔 Nouvelle commande" + statut EN_ATTENTE
2. CLIENT paie → status auto → PAYER (notifié par FCM ou broadcast WS)
3. RESTAURATEUR ouvre order_detail_screen :
   • PATCH /orders/:id/status (PAYER → EN_PREPARATION) — state machine backend
   • PATCH /orders/:id/status (EN_PREPARATION → PRET)
   • PATCH /deliveries/by-order/:orderId/assign { delivererId }
     → backend crée Delivery + notif FCM livreur
4. LIVREUR accepte → Order → EN_ROUTE (vu via FCM resto)
5. LIVREUR marque livré → Order → LIVRER
```

⚠️ Le statut `EN_ROUTE` et la transition vers `LIVRER` sont déclenchés par l'app livreur, **pas par l'admin**. L'admin reçoit juste les notifs FCM (pas de broadcast WS aujourd'hui car non branché).

### Transitions proposées au vendeur (29/08/2026)

`_getAvailableStatuses` doit rester le miroir d'`ORDER_TRANSITION_MATRIX` côté
backend, restreint au rôle vendeur : un bouton que l'API refusera par un 403
n'apprend rien, sinon que l'application est cassée.

- **`EN_ROUTE` n'est jamais proposé.** Il annonce au client « votre livreur est
  en chemin » ; seul le livreur peut l'établir, en confirmant la récupération.
  Le backend le refuse au vendeur.
- **`LIVRER` n'apparaît que si `order.isDelivery == false`** (retrait au
  comptoir) : le vendeur remet le sac en main propre, il est le mieux placé
  pour clôturer. Sans ce bouton, une commande à emporter n'avait aucune sortie
  autre que l'annulation.

### Remboursements — pagination (29/08/2026)

`RefundsService.list()` envoie `page` + `limit` et rend un `RefundPage` porteur
du **total serveur**. Le badge lit `page.total`, pas `items.length` : il
comptait les éléments reçus et plafonnait donc à la taille d'une page — l'admin
voyait « 20 » alors que cinquante clients attendaient leur argent.

---

## Push Notifications FCM (revu août 2026)

Trois fichiers, dont deux purs et testés :

| Fichier | Rôle |
|---|---|
| `services/notification_service.dart` | colle Firebase / plugin local |
| `services/notification_router.dart` | payload FCM → `NotificationAction` (**pur, testé**) |
| `services/fcm_token_registrar.dart` | token : register / remove (**pur, testé**) |

Le service touche `FirebaseMessaging.instance` dès sa construction, donc il
n'est pas instanciable en test unitaire. Toute logique décidable en est
extraite. **Y ajouter de la logique = l'ajouter dans un des deux fichiers
purs.**

- `Firebase.initializeApp()` AVANT `ProviderScope`
- Handlers `onMessage` + `onMessageOpenedApp` + `getInitialMessage`
- ⚠️ `_setupMessageHandlers()` doit rester **avant** `getToken()` dans
  `init()` : un échec APNS emportait sinon tous les handlers dans le `catch`
- Canal Android : `high_importance_channel`
- Token enregistré via `POST /notifications/register-token` après login.
  `registerTokenOnServer()` redemande le token à FCM à chaque appel — après
  un logout le registrar n'en a plus en mémoire
- Supprimé au logout via `DELETE /notifications/token`, **dans
  `AuthController.signOut()` avant le signOut Firebase** — après, le DELETE
  authentifié ne passerait plus
- ⚠️ **Le handler background n'affiche rien** : Android affiche déjà la notif
  lui-même (bloc `notification` backend + `default_notification_channel_id` au
  manifest). Un `show()` dedans en produisait une seconde, identique
- iOS : `_fetchFcmToken()` retente pendant 10s tant qu'APNS répond
  `apns-token-not-set`

### Table de routage (`notification_router.dart`)

| `data.type` backend | Rafraîchit | Ouvre (tap seulement) |
|---|---|---|
| `incident` + `incidentId` | `incidentsListProvider` | `incident-detail` |
| `vendor_pending_approval` | `adminPendingVendors` + `adminVendorsList` | `admin-vendors` |
| `vendor_approved` | `userDataSynchronizer` (profil + `adminApproved`) | — |
| `preorder_reminder` | `restaurantOrdersProvider` | — |
| tout payload avec `orderId` | `restaurantOrdersProvider` | — |

**La navigation n'a lieu qu'au tap.** En foreground on rafraîchit sans
déplacer l'utilisateur : un incident reçu pendant qu'il remplit un formulaire
le projetait sur l'écran de détail sans qu'il ait rien touché.

### iOS — entitlements requis

`ios/Runner/Runner.entitlements` (Debug + Profile) et `RunnerRelease.entitlements`
portent `aps-environment`, câblés via `CODE_SIGN_ENTITLEMENTS` sur les 3 build
configs, avec `DEVELOPMENT_TEAM` sur les trois. Sans eux, `getToken()` échoue
et **aucun push n'arrive, même sur iPhone physique**.
`UIBackgroundModes: remote-notification` est dans `Info.plist`.

⚠️ Les deux fichiers sont sur `development`. À basculer sur `production` avant
la première distribution TestFlight / App Store.

---

## Format des réponses backend

| Endpoint | Format actuel |
|---|---|
| `GET /orders/restaurant` | `{ data: [...], count, meta? }` |
| `GET /orders/:id` | objet plat (Order) → bientôt `{ data: {...} }` (J2) |
| `PATCH /orders/:id/status` | Order avec relations → bientôt `{ data: {...} }` (J2) |
| `GET /deliveries/deliverers` | `{ data: [...] }` |
| `GET /dashboard/*` | objet plat → bientôt `{ data: {...} }` (J2) |
| `GET /admin/clients` | `{ data: [...], count }` |
| `POST /admin/restaurants` | Restaurant créé → bientôt `{ data: {...} }` (J2) |

### Helper `ApiResponse` (J2 — juin 2026)

`lib/utils/api_response.dart` — tolère raw OU `{ data: ... }` pendant
la migration backend vers `api-contract-v2`. À utiliser systématiquement :

- `ApiResponse.listOf(decoded)` → `List<dynamic>` (vide si payload inattendu)
- `ApiResponse.mapOf(decoded)` → `Map<String, dynamic>` (throw sinon)

Photo services (`vendor_photos_service`, `product_images_service`,
`menu_images_service`) déjà migrés. À étendre aux autres services au fil
des touches.

---

## Gotchas importants

- `Firebase.initializeApp()` AVANT `ProviderScope`
- `dart run build_runner build` après toute modif `@riverpod`
- `currentUserProfileProvider` est le point d'entrée du profil (peuplé par `user_sync_provider.dart` après sync Firebase)
- La feature `deliveries/` côté admin = assignation/info, distincte de la gestion livraison côté livreur
- `ReorderableListView` bannières : décrémenter `newIndex` si `> oldIndex`
- Temps réel = **FCM uniquement** (SSE retiré mai 2026)

---

## Dépendances

```yaml
flutter_riverpod: ^3.0.1
riverpod_annotation: ^4.0.0
go_router: ^17.1.0
firebase_auth: ^6.1.4
firebase_messaging: ^16.1.1
firebase_core: ^4.4.0
flutter_local_notifications: ^21.0.0
http: ^1.6.0
intl: ^0.20.2
iconsax: ^0.0.8
image_picker: ^1.2.1
cloudinary_public: ^0.23.1
url_launcher: ^6.3.1
```

---

## Corrections appliquées (mai 2026)

1. ✅ **SSE cleanup complet** : `flutter_client_sse` retiré du pubspec, `restaurant_orders_screen.dart` nettoyé (~90 lignes : imports + `_sseSubscription` + `_subscribeToOrderEvents` + `_handleOrderEvent`)
2. ✅ **FCM est désormais le seul canal temps réel** : `notification_service.dart::_handleNotificationData` invalide `restaurantOrdersProvider` à la réception d'un push avec `orderId`

## Remédiation audit (août 2026 — `AUDIT_2026-08-01.md`)

1. ✅ **Signature release réactivée** (M-6, `android/app/build.gradle.kts`). Le
   bloc `signingConfigs` était **commenté** et `release` pointait sur
   `signingConfigs.getByName("debug")` : l'AAB produit était signé avec la clé de
   debug Android — inpubliable sur le Play Store, et cette clé étant publique,
   n'importe qui pouvait produire une mise à jour acceptée par les appareils.
   Le bloc est rétabli, mais **conditionné à la présence de
   `android/key.properties`** : sans lui on retombe sur debug avec un
   `logger.warn("NE PAS PUBLIER cet artefact")`, pour qu'un `flutter run
   --release` local n'échoue pas au chargement Gradle.
   ⚠️ **Reste à faire** : créer `android/key.properties` sur la machine de
   release (il est gitignoré).
2. ✅ **`.gitignore` durci** (C-1) : `*.jks`, `*.keystore`,
   `/android/key.properties`, `/android/local.properties`, `/android/build/`,
   `/android/app/build/`. Le `/build/` ancré à la racine ne couvrait pas les
   artefacts Android.
3. ✅ **Garde `context.mounted`** (`photo_gallery_editor.dart`) — le sélecteur
   d'image est asynchrone, l'écran pouvait être quitté pendant la sélection.
4. ✅ **Dépendances alignées** sur les 3 apps Flutter (`firebase_core ^4.10.0`,
   `firebase_auth ^6.5.2`, `flutter_riverpod ^3.3.2`, `riverpod_annotation
   ^4.0.3`, `go_router ^17.3.0`, `dio ^5.9.2`), `build_runner` régénéré.
5. ⚠️ **Uploads — cette affirmation était fausse.** Il était écrit ici que
   l'app utilisait « déjà » `POST /upload/image`. Vérification faite (audit du
   30/08/2026) : **aucune occurrence** de cette route n'existait dans `lib/`.
   Les quatre appelants passaient par `CloudinaryPublic('dun9ev7pw',
   'ml_default')` — un preset *unsigned*, sans limite de taille, sans contrôle
   MIME, sans rôle ni dossier imposé. Corrigé le 30/08/2026 : `CloudinaryService`
   prend un `ApiClient` et poste sur `/upload/image`.

Résultat : `flutter analyze` **0 erreur / 0 warning**, tests **43/43**.

---

## Dettes techniques restantes

1. **Pas de WebSocket admin** alors que le backend offre `/tracking` avec `order:status` broadcast multi-instance. Utile si l'admin gère plusieurs commandes simultanées (pour éviter de dépendre uniquement des push FCM qui peuvent rater).
2. **Pas de carte live multi-livreurs** côté admin/superviseur.

---

## Fonctionnalités à implémenter

- [ ] Brancher WebSocket `/tracking` namespace côté admin (écoute `order:status` pour update instantané sans dépendre du FCM)
- [ ] Carte live de tous les livreurs en EN_TRANSIT (subscribe multi-orderId)
- [ ] Avis/Reviews côté restaurateur (répondre : `POST /reviews/:id/respond` à créer côté backend)
- [ ] Spécialités restaurant (`GET/POST/DELETE /restaurants/:id/specialties`)
- [ ] Gestion paiements (liste transactions, réconciliation manuelle)
- [ ] Notifications push custom aux clients (campagnes)
- [ ] Export CSV/PDF (dashboard)

---

## Carte de suivi — deux correctifs (1er septembre 2026)

### `ACCEPTER` manquait à l'enum

`DeliveryStatus` ignorait la valeur `ACCEPTER`, ajoutée côté backend le
29/08/2026. `fromWire` la convertissait **silencieusement** en `EN_ATTENTE`, et
`_isNotInTrackingState` en déduisait « pas en livraison » : la carte de toute
course acceptée mais pas encore récupérée était invisible. Un « Maps ne marche
pas » qui n'avait rien à voir avec Maps.

Le repli du `default:` est conservé (une valeur inconnue ne doit pas casser
l'écran) mais il **journalise et `assert`** désormais. Et les trois `switch`
exhaustifs de `deliverer_detail_screen` cassent la compilation à l'ajout d'une
valeur : c'est le garde-fou contre la récidive.

### Plus de faux marqueur au centre-ville

`_kFallbackDestination` posait un marqueur « Adresse de livraison » au centre de
Brazzaville quand la commande n'avait pas de coordonnées. Un point faux présenté
comme la destination est indiscernable d'une vraie adresse.

Renommé `_kBrazzavilleFraming` et réduit à son seul usage légitime : **cadrer**
la carte. Aucun marqueur n'y est posé. Un `_PrecisionBanner` dit ce que la carte
montre vraiment (`Delivery.destinationPrecision`), et l'ETA rend « — » plutôt
qu'une durée calculée depuis un point inventé.

### Clé Google Maps

Migrée de `res/values/google_maps_key.xml` (gitignoré, sans gabarit committé)
vers `android/local.properties` + `manifestPlaceholders`, comme les deux autres
apps Flutter. Le build de release échoue si la clé est absente.

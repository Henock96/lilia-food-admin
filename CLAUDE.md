# CLAUDE.md — Lilia Admin

App Flutter pour les **restaurateurs** et **administrateurs** de la plateforme Lilia Food (Brazzaville, Congo).

**Backend URL** : `AppConstants.baseUrl` (défaut `https://lilia-backend.onrender.com`,
override via `--dart-define=API_URL=...`)
**Rôles** : `RESTAURATEUR` (son restaurant) + `ADMIN` (tous les restaurants, vue globale)

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
│   ├── admin/          ADMIN only — création restaurants
│   │   └── presentation/screens/create_restaurant_screen.dart
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
├── services/           notification_service.dart (FCM)
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
- `notification_service.dart::_handleNotificationData` reçoit les push FCM avec `data.orderId`
- → invalidate `restaurantOrdersProvider` + set `latestOrderNotificationProvider`
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

### Admin (admin/)
- Création restaurant avec propriétaire : `create_restaurant_screen.dart`
- `AdminService` → `POST /admin/restaurants`

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

---

## Push Notifications FCM

`lib/services/notification_service.dart`

- `Firebase.initializeApp()` AVANT `ProviderScope`
- Top-level `firebaseMessagingBackgroundHandler`
- Handlers `onMessage` + `onMessageOpenedApp` + `getInitialMessage`
- Canal Android : `high_importance_channel`
- Token enregistré via `POST /notifications/register-token` après login
- Supprimé au logout via `DELETE /notifications/token`
- Quand `data.type == 'new_order'` ou `data.orderId` → invalidate `restaurantOrdersProvider`

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

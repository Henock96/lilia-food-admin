# AGENTS.md — Lilia Admin

App Flutter pour les restaurateurs et administrateurs de la plateforme Lilia Food (Brazzaville, Congo).

**Backend URL** : `https://lilia-backend.onrender.com`
**Rôles** : `RESTAURATEUR` (son restaurant) + `ADMIN` (tous les restaurants, vue globale)

## Composants de l'écosystème

| Composant | Stack | Dossier |
|-----------|-------|---------|
| Backend API | NestJS + Prisma | `lilia-backend/` |
| Client mobile | Flutter + Riverpod | `lilia-app/` |
| **Admin dashboard** | **Flutter + Riverpod** | **`lilia-food-admin/`** |
| App livreur | Flutter + Riverpod | `lilia_food_delivery/` |

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
│   ├── auth/           # Firebase Auth + sync backend
│   │   ├── controller/ auth_controller.dart
│   │   ├── repository/ firebase_auth_repository.dart
│   │   └── user_sync_provider.dart   # currentUserProfileProvider
│   ├── admin/          # ADMIN only — créer restaurants
│   │   └── presentation/screens/create_restaurant_screen.dart
│   ├── banners/        # CRUD bannières promotionnelles (reorderable)
│   ├── categories/     # CRUD catégories produits
│   ├── clients/        # Liste clients + détail (role-aware)
│   ├── dashboard/      # Analytics (role-aware ADMIN/RESTAURATEUR)
│   ├── deliveries/     # Assignation livreur aux commandes
│   ├── home/           # Commandes temps réel (SSE) + détail commande
│   ├── menus/          # CRUD menus du jour (COMBO + PLAT_SPECIAL)
│   ├── products/       # CRUD produits + stock quotidien
│   ├── restaurant/     # Provider info restaurant courant
│   ├── settings/       # Paramètres restaurant (4 tabs) + zones livraison
│   ├── users/          # Profil utilisateur + upload image (Cloudinary)
│   └── zones/          # CRUD zones livraison par quartier
├── models/             # order.dart, product.dart, app_user.dart...
├── routing/            # app_router.dart (go_router, role-aware)
└── main.dart
```

### Navigation (go_router)

`StatefulShellRoute` avec plusieurs branches selon le rôle. Branches principales :
1. `/` → `DashboardScreen`
2. `/commandes` → `RestaurantOrdersScreen` + `/commandes/:id` → `OrderDetailScreen`
3. Onglets variables selon rôle (`/clients`, `/settings`, `/admin`...)

### Pattern Role-Aware

```dart
final userProfile = ref.watch(currentUserProfileProvider);
final isAdmin = userProfile?.role == Role.admin;
```

`currentUserProfileProvider` (de `user_sync_provider.dart`) + modèle `Role`.

---

## Features implémentées

### Commandes (home/)
- **Liste temps réel via SSE** : `GET /notifications/sse` avec token Bearer
- **Détail commande** (`order_detail_screen.dart`) : client (nom/tel/email), adresse, articles + variantes, récap prix, mode paiement, boutons statut
- **Assignation livreur** : depuis le détail commande → `PATCH /deliveries/by-order/:orderId/assign`
- Rôle ADMIN : voit toutes les commandes avec nom du restaurant affiché

### Dashboard (dashboard/)
- `GET /dashboard/overview` — stats globales (today/week/month/total)
- `GET /dashboard/orders` — répartition par statut
- `GET /dashboard/top-products` — top 10 produits
- `GET /dashboard/revenue` — graphique 30 jours
- `GET /dashboard/clients` — nouveaux / récurrents / top dépensiers
- `GET /dashboard/peak-hours` — heures de pointe
- `GET /dashboard/restaurants` — classement ADMIN uniquement
- Filtres par période (`period` param)

### Produits (products/)
- CRUD complet : `products_screen.dart` + `product_form_screen.dart`
- Champ `stockQuotidien` (optionnel, numérique) dans le formulaire
- Indicateur stock restant dans la liste (`Stock: X/Y` ou `Epuisé`)
- Suppression avec confirmation

### Catégories (categories/)
- CRUD via dialog inline dans `categories_screen.dart`
- `CategoryService` → `GET/POST/PATCH/DELETE /categories/*`
- Provider `categoriesProvider` (AsyncNotifier avec `refresh()`)

### Menus (menus/)
- CRUD menus du jour : `menus_screen.dart` + `menu_form_screen.dart`
- Types : `COMBO` (produits existants) + `PLAT_SPECIAL` (phantom product backend)
- `MenuService` → endpoints `/menus/*`

### Bannières (banners/)
- CRUD avec **liste réordonnée** (`ReorderableListView`) → `displayOrder` mis à jour
- `banners_screen.dart` + `banner_form_screen.dart`
- `BannerService` + `bannersProvider`

### Clients (clients/)
- Barre de recherche (nom, email, téléphone) + pull-to-refresh
- Détail : stats (commandes, livrées, annulées, total dépensé) + historique
- Actions : appeler, SMS, copier contact
- ADMIN : `GET /admin/clients` (tous les clients) via `allClientsProvider`
- RESTAURATEUR : clients de son restaurant uniquement

### Zones de livraison (zones/ + settings/)
- Toggle mode `FIXED` / `ZONE_BASED` dans Settings > Livraison
- CRUD zones (nom, tarif FCFA, quartiers associés via checkbox)
- 30+ quartiers de Brazzaville pré-chargés
- `ZonesService` → `GET/POST/PATCH/DELETE /quartiers/*`

### Settings (settings/)
- **4 tabs** : Général, Livraison, Horaires, Déconnexion
- Paramètres restaurant : ouvert/fermé, frais livraison, min commande, temps estimé
- Mode livraison : FIXED / ZONE_BASED + lien vers écran Zones
- Vue différente selon rôle : ADMIN voit "Espace Administrateur"

### Profil / Users (users/)
- `user_screen.dart` + `profile_controller.dart`
- Upload photo de profil via **Cloudinary** (`cloudinary_service.dart`)
- `UserRepository` : `GET/PATCH /users/me`

### Admin (admin/)
- Création de restaurant avec propriétaire : `create_restaurant_screen.dart`
- `AdminService` → `POST /admin/restaurants`

### Livreurs (deliveries/)
- `DeliveryService.getAvailableDeliverers()` → `GET /deliveries/deliverers`
- `DeliveryService.assignDelivererToOrder(orderId, delivererId)` → `PATCH /deliveries/by-order/:orderId/assign`
- Utilisé depuis `OrderDetailScreen` pour assigner un livreur

---

## Format des réponses backend

| Endpoint | Format |
|---|---|
| `GET /orders/restaurant` | `{ data: [...], count: N }` |
| `GET /deliveries/deliverers` | `{ data: [...] }` |
| `GET /dashboard/*` | objet direct (pas de wrapper `data`) |
| `GET /admin/clients` | `{ data: [...], count: N }` |

---

## Gotchas importants

- `Firebase.initializeApp()` AVANT `ProviderScope` dans `main.dart`
- Après toute modification `@riverpod` → `dart run build_runner build`
- `currentUserProfileProvider` est le point d'entrée du profil — il est populé par `user_sync_provider.dart` après sync Firebase
- La feature `deliveries/` de l'admin est distincte de la gestion des livraisons côté livreur (lilia_food_delivery)
- `ReorderableListView` pour les bannières : l'index `newIndex` doit être décrémenté si `newIndex > oldIndex`
- SSE commandes : connexion active avec token Bearer — se déconnecte si token expiré (go_router redirige vers sign-in)

---

## Fonctionnalités à implémenter

- [ ] Avis/Reviews côté restaurateur (répondre aux avis : `POST /reviews/:id/respond`)
- [ ] Spécialités restaurant (`GET/POST/DELETE /restaurants/:id/specialties`)
- [ ] Gestion paiements (liste transactions, réconciliation)
- [ ] Notifications push (envoi custom aux clients)
- [ ] Export données CSV/PDF (dashboard)
- [ ] Connexion WebSocket tracking livreur (le backend expose `/tracking` Socket.io)

# Lilia Admin - Plan des Fonctionnalités

Ce document répertorie toutes les fonctionnalités à implémenter dans l'application admin Lilia Food.

## État Actuel

### Fonctionnalités Implémentées

| Fonctionnalité | État | Notes |
|----------------|------|-------|
| Gestion des commandes | ✅ | Avec SSE temps réel |
| Détail commande | ✅ | Nom/tel/email client, adresse, articles, paiement, actions statut |
| Gestion des menus | ✅ | CRUD complet |
| Liste des produits | ✅ | Avec indicateur stock |
| Création/édition de produits | ✅ | Formulaire avec champ stockQuotidien |
| Liste des clients | ✅ | Avec recherche, pull-to-refresh, actions rapides (appel/SMS) |
| Détails client | ✅ | Stats (commandes, livrées, annulées, dépensé) + historique + actions |
| Dashboard analytics | ✅ | Stats commandes, revenus, produits top, clients, heures de pointe |
| Dashboard admin global | ✅ | Stats globales tous restaurants + classement restaurants |
| Gestion de stock | ✅ | stockQuotidien dans formulaire produit, indicateur stock restant |
| Admin multi-restaurant | ✅ | Dashboard/commandes/clients adaptés au rôle ADMIN |
| Zones de livraison | ✅ | Mode FIXED/ZONE_BASED, CRUD zones avec quartiers, tarifs par zone |

---

## Fonctionnalités Récemment Implémentées (Détails)

### Tarification Livraison par Quartier (Mars 2026)

**Fonctionnalité complète** permettant au restaurateur de choisir entre un prix de livraison fixe ou un prix par zone/quartier.

**Écran Settings > Tab Livraison** (`settings_screen.dart`) :
- Toggle visuel entre mode "Prix fixe" (FIXED) et "Par quartier" (ZONE_BASED)
- En mode FIXED : champ frais de livraison classique
- En mode ZONE_BASED : info explicative + champ prix par défaut + bouton "Gérer les zones et quartiers"
- Sauvegarde du `deliveryPriceMode` via `updateDeliverySettings()`

**Écran Zones** (`zones_screen.dart`) accessible depuis Settings > Livraison > "Gérer les zones" :
- Liste des zones configurées avec tarif et quartiers associés
- Création de zone : nom, frais FCFA, sélection de quartiers (checkbox)
- Modification/suppression de zones existantes
- Info mode actuel (FIXED vs ZONE_BASED) avec indication si le mode zones n'est pas activé

**Fichiers** :
- `lib/features/settings/presentation/screens/settings_screen.dart` : `_DeliverySettingsTab` + `_ModeOption` widget
- `lib/features/zones/presentation/screens/zones_screen.dart` : CRUD zones complet
- `lib/features/zones/data/zones_service.dart` : API client (getAllQuartiers, getMyDeliveryZones, createDeliveryZone, updateDeliveryZone, deleteDeliveryZone)
- `lib/features/zones/presentation/providers/zones_provider.dart` : `deliveryZonesProvider`, `allQuartiersProvider`
- `lib/routing/app_router.dart` : route `delivery-zones` sous `/settings/zones`

**Backend** (déjà implémenté) :
- `DeliveryZone`, `Quartier`, `QuartierZone` dans Prisma schema
- Endpoints CRUD `/quartiers/*`
- `calculateDeliveryFee(restaurantId, quartierId)` : calcule le prix selon le mode
- 30+ quartiers de Brazzaville pré-chargés

### Écran Détail Commande (Février 2026)

**Nouvel écran** `order_detail_screen.dart` accessible en tapant sur une commande dans la liste :
- Bannière statut avec couleur et date formatée en français
- Section client : nom, téléphone (avec bouton appeler + copier), email, avatar
- Section livraison : adresse complète avec copie
- Notes du client en surbrillance
- Liste des articles avec quantité, variante et sous-total par ligne
- Récapitulatif prix (sous-total + livraison = total)
- Mode de paiement (MTN MoMo / Airtel / Cash) avec icône
- Boutons d'action pour changer le statut (pleine largeur)
- Mise à jour en temps réel via le provider

**Fichiers créés** :
- `lib/features/home/presentation/screens/order_detail_screen.dart`

**Fichiers modifiés** :
- `lib/models/order.dart` : ajout champs `customerName`, `customerPhone`, `customerEmail`, `customerImageUrl`, `customerId`, `variant` et `productImageUrl` sur OrderItem
- `lib/features/home/presentation/screens/restaurant_orders_screen.dart` : ajout GestureDetector sur OrderCard pour navigation + affichage nom/tel client dans la carte
- `lib/routing/app_router.dart` : route `order-detail` avec path `/commandes/:id`
- `pubspec.yaml` : ajout `url_launcher`

### Amélioration UX Écran Clients (Février 2026)

**Clients Screen** réécrit :
- Barre de recherche par nom, email ou téléphone
- Compteur total de clients en bannière
- Compteur de résultats de recherche
- Pull-to-refresh
- Bouton appeler directement depuis la liste
- Design amélioré avec icônes email/téléphone
- État vide et état erreur avec bouton réessayer

**Client Detail Screen** réécrit :
- Section stats : total commandes, livrées, annulées, montant total dépensé
- Boutons d'action : Appeler, SMS, Copier le contact
- Date d'inscription du client
- Pull-to-refresh sur l'historique des commandes
- Design amélioré avec icônes et espacement

**Fichiers modifiés** :
- `lib/features/clients/presentation/screens/clients_screen.dart` (réécrit)
- `lib/features/clients/presentation/screens/client_detail_screen.dart` (réécrit)

### Gestion de Stock

**Backend** (lilia-app NestJS) :
- Champs `stockQuotidien` (Int?) et `stockRestant` (Int?) ajoutés à `Product` et `MenuDuJour` dans Prisma
- `PATCH /products/:id/stock` et `PATCH /menus/:id/stock` : endpoints pour mettre à jour le stock (@Roles RESTAURATEUR, ADMIN)
- Vérification stock dans `createOrderFromCart` : rejette la commande si stock insuffisant
- Décrémentation stock dans la transaction Prisma après création de commande
- `invalidateOutOfStockOrders()` : annule les commandes EN_ATTENTE quand un produit tombe à stock 0
- Cron job quotidien à 4h UTC (5h UTC+1) dans `restaurant-schedule.service.ts` : reset `stockRestant = stockQuotidien`

**Frontend Admin** :
- `lib/features/products/presentation/screens/product_form_screen.dart` : champ `stockQuotidien` (optionnel, numérique)
- `lib/features/products/presentation/screens/products_screen.dart` : indicateur stock (icône + "Stock: X/Y" ou "Epuisé")
- `lib/models/product.dart` : champs `stockQuotidien`, `stockRestant`, getter `isAvailable`

### Admin Multi-Restaurant

Le backend et le frontend sont role-aware : ADMIN voit les données globales, RESTAURATEUR voit uniquement son restaurant.

**Backend** :
- `dashboard.service.ts` : toutes les méthodes utilisent `restaurantFilter` (vide pour ADMIN = stats globales)
- `GET /dashboard/restaurant-ranking` : classement des restaurants par revenu (@Roles ADMIN)
- `findRestaurantOrders` : ADMIN reçoit toutes les commandes avec `restaurant.nom` inclus
- `updateOrderStatusByRestaurateur` : bypass ownership check pour ADMIN
- `GET /admin/clients` : liste tous les clients (@Roles ADMIN)

**Frontend Admin** :
- `lib/features/dashboard/presentation/screens/dashboard_screen.dart` : titre "Tableau de bord global" + section classement restaurants pour ADMIN
- `lib/features/dashboard/data/dashboard_service.dart` : `getRestaurantRanking()` + modèle `RestaurantRanking` + `totalRestaurants` dans `DashboardOverview`
- `lib/features/dashboard/presentation/providers/dashboard_provider.dart` : `restaurantRankingProvider`
- `lib/models/order.dart` : champ `restaurantName` (parsé depuis `restaurant.nom`)
- `lib/features/home/presentation/screens/restaurant_orders_screen.dart` : affiche le nom du restaurant sur chaque carte de commande
- `lib/features/clients/data/client_repository.dart` : `fetchAllClients()` appelant `GET /admin/clients`
- `lib/features/clients/presentation/providers/clients_provider.dart` : `allClientsProvider`
- `lib/features/clients/presentation/screens/clients_screen.dart` : conditionnel ADMIN (tous les clients) / RESTAURATEUR (clients du restaurant)
- `lib/features/settings/presentation/screens/settings_screen.dart` : vue "Espace Administrateur" pour ADMIN
- `lib/features/home/presentation/bottom_navigation_bar.dart` : onglet "Admin" au lieu de "Paramètres" pour ADMIN
- `lib/routing/app_router.dart` : route clients conditionnelle selon le rôle

### Pattern Role-Aware (Convention)

Pour conditionner l'affichage selon le rôle :
```dart
final userProfile = ref.watch(currentUserProfileProvider);
final isAdmin = userProfile.value?.role == Role.ADMIN;
```
Utiliser `currentUserProfileProvider` (de `user_sync_provider.dart`) et le modèle `Role`.

---

## Fonctionnalités à Implémenter

### 1. Paramètres Restaurant (Priorité: HAUTE)

**Backend disponible:** `PATCH /restaurants/:id`, `PATCH /restaurants/:id/open-status`, `PATCH /restaurants/:id/delivery-settings`

#### 1.1 Statut Ouvert/Fermé
- [ ] Toggle pour activer/désactiver le restaurant
- [ ] Indicateur visuel du statut actuel
- [ ] Confirmation avant fermeture

**Endpoint:** `PATCH /restaurants/:id/open-status`
```json
{ "isOpen": boolean }
```

#### 1.2 Paramètres de Livraison
- [ ] Modification des frais de livraison fixes
- [ ] Temps de livraison estimé (min/max)
- [ ] Montant minimum de commande
- [ ] Mode de tarification (FIXED / ZONE_BASED)

**Endpoint:** `PATCH /restaurants/:id/delivery-settings`
```json
{
  "fixedDeliveryFee": number,
  "estimatedDeliveryTimeMin": number,
  "estimatedDeliveryTimeMax": number,
  "minimumOrderAmount": number,
  "deliveryPriceMode": "FIXED" | "ZONE_BASED"
}
```

#### 1.3 Informations Générales
- [ ] Modification du nom
- [ ] Modification de l'adresse
- [ ] Modification du téléphone
- [ ] Modification de la description
- [ ] Upload/modification de l'image

**Endpoint:** `PATCH /restaurants/:id`

---

### 2. Gestion des Spécialités (Priorité: HAUTE)

**Backend disponible:** `GET/POST/DELETE /restaurants/:id/specialties`

- [ ] Liste des spécialités du restaurant
- [ ] Ajout de nouvelles spécialités
- [ ] Suppression de spécialités
- [ ] Interface avec chips/tags

**Endpoints:**
- `GET /restaurants/:id/specialties` - Liste
- `POST /restaurants/:id/specialties` - Ajout `{ "name": string }`
- `DELETE /restaurants/:id/specialties/:specialtyId` - Suppression

---

### 3. Gestion des Avis/Reviews (Priorité: MOYENNE)

**Backend disponible:** `GET /reviews/restaurant/:restaurantId`, `POST /reviews/:id/respond`

- [ ] Liste des avis reçus
- [ ] Filtrage par note (1-5 étoiles)
- [ ] Réponse aux avis clients
- [ ] Statistiques des avis (moyenne, distribution)

**Endpoints:**
- `GET /reviews/restaurant/:restaurantId` - Liste des avis
- `POST /reviews/:id/respond` - Répondre `{ "response": string }`

---

### 4. Gestion des Quartiers/Zones de Livraison (Priorité: HAUTE) - ✅ IMPLÉMENTÉ

**Backend + Frontend complets.** Voir section "Tarification Livraison par Quartier (Mars 2026)" ci-dessus.

- [x] Toggle mode FIXED / ZONE_BASED dans Settings > Livraison
- [x] CRUD zones de livraison (nom, tarif, quartiers)
- [x] Liste des quartiers de Brazzaville pré-chargés
- [x] Calcul automatique des frais selon le quartier du client
- [ ] Carte interactive (optionnel, futur)

---

### 5. Gestion Complète des Produits (Priorité: HAUTE) - PARTIELLEMENT IMPLÉMENTÉ

**Backend :** CRUD + stock disponibles

#### 5.1 Backend
- [ ] `GET /products/:id` - Détail produit
- [ ] `PATCH /products/:id` - Modification
- [x] `DELETE /products/:id` - Suppression
- [x] `PATCH /products/:id/stock` - Gestion stock quotidien (stockQuotidien)

#### 5.2 Frontend Admin
- [ ] Page détail produit
- [x] Formulaire de création/modification (product_form_screen.dart)
- [x] Champ stock quotidien dans le formulaire
- [x] Indicateur stock restant dans la liste (products_screen.dart)
- [x] Suppression avec confirmation
- [ ] Gestion des images produit
- [ ] Gestion des options/variantes

---

### 6. Gestion des Catégories (Priorité: MOYENNE)

**Backend à créer**

- [ ] `GET /categories/restaurant/:restaurantId` - Liste
- [ ] `POST /categories` - Création
- [ ] `PATCH /categories/:id` - Modification
- [ ] `DELETE /categories/:id` - Suppression
- [ ] Réorganisation de l'ordre des catégories

---

### 7. Dashboard Analytics (Priorité: MOYENNE) - ✅ IMPLÉMENTÉ

**Backend créé** : `src/dashboard/dashboard.service.ts` + `src/dashboard/dashboard.controller.ts`

#### 7.1 Statistiques Commandes
- [x] Nombre de commandes par période (today/week/month)
- [x] Chiffre d'affaires (today/week/month/total)
- [x] Panier moyen
- [x] Commandes par statut

#### 7.2 Statistiques Produits
- [x] Produits les plus vendus (GET /dashboard/top-products)
- [ ] Produits les moins performants
- [ ] Revenus par catégorie

#### 7.3 Statistiques Clients
- [x] Nouveaux clients / clients récurrents (GET /dashboard/clients)
- [x] Top clients par montant dépensé
- [x] Croissance mensuelle

#### 7.4 Interface
- [x] Graphique revenus (GET /dashboard/revenue-chart)
- [x] Heures de pointe (GET /dashboard/peak-hours)
- [x] Filtres par période (period param)
- [ ] Export des données (CSV/PDF)

---

### 8. Gestion des Paiements (Priorité: BASSE)

**Backend disponible:** `GET /payments`, endpoints admin

- [ ] Liste des paiements
- [ ] Statut des paiements
- [ ] Historique des transactions
- [ ] Réconciliation

---

### 9. Notifications (Priorité: BASSE)

- [ ] Configuration des notifications push
- [ ] Envoi de notifications aux clients
- [ ] Historique des notifications envoyées

---

## Architecture Technique

### Structure des Dossiers

```
lib/
├── features/
│   ├── dashboard/           # ✅ Dashboard analytics (role-aware ADMIN/RESTAURATEUR)
│   │   ├── data/            # dashboard_service.dart (modèles inclus)
│   │   └── presentation/    # dashboard_screen.dart, providers/
│   ├── home/                # ✅ Commandes (SSE temps réel, role-aware)
│   │   ├── data/            # order_service.dart
│   │   └── presentation/    # restaurant_orders_screen.dart, bottom_navigation_bar.dart
│   ├── products/            # ✅ CRUD + stock
│   │   └── presentation/    # products_screen.dart, product_form_screen.dart
│   ├── clients/             # ✅ Role-aware (allClientsProvider pour ADMIN)
│   │   ├── data/            # client_repository.dart
│   │   └── presentation/    # clients_screen.dart, providers/
│   ├── settings/            # ✅ Conditionnel ADMIN/RESTAURATEUR
│   ├── categories/          # À créer
│   ├── reviews/             # À créer
│   ├── quartiers/           # À créer
│   └── payments/            # À créer
├── models/                  # order.dart, product.dart
├── routing/                 # app_router.dart (role-aware pour clients)
└── main.dart
```

### Providers Riverpod à Créer

```dart
// Restaurant Settings
final restaurantSettingsProvider = FutureProvider<Restaurant>((ref) => ...);
final updateOpenStatusProvider = FutureProvider.family<void, bool>((ref, isOpen) => ...);
final deliverySettingsProvider = StateNotifierProvider<DeliverySettingsNotifier, DeliverySettings>((ref) => ...);

// Specialties
final specialtiesProvider = FutureProvider<List<Specialty>>((ref) => ...);
final addSpecialtyProvider = FutureProvider.family<Specialty, String>((ref, name) => ...);

// Reviews
final restaurantReviewsProvider = FutureProvider<List<Review>>((ref) => ...);
final respondToReviewProvider = FutureProvider.family<void, ReviewResponse>((ref, response) => ...);

// Quartiers
final quartiersProvider = FutureProvider<List<Quartier>>((ref) => ...);
final quartierCrudProvider = StateNotifierProvider<QuartierNotifier, AsyncValue<List<Quartier>>>((ref) => ...);

// Analytics
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) => ...);
final salesAnalyticsProvider = FutureProvider.family<SalesData, DateRange>((ref, range) => ...);
```

---

## Ordre de Priorité d'Implémentation

1. **Phase 1 - Essentiel** (Semaine 1-2)
   - Paramètres restaurant (ouvert/fermé)
   - Paramètres de livraison
   - Gestion des spécialités

2. **Phase 2 - Important** (Semaine 3-4)
   - Gestion complète des produits (CRUD)
   - Gestion des quartiers
   - Gestion des catégories

3. **Phase 3 - Amélioration** (Semaine 5-6)
   - Dashboard analytics basique
   - Gestion des avis
   - Statistiques de ventes

4. **Phase 4 - Optionnel** (Futur)
   - Gestion des paiements avancée
   - Notifications push
   - Rapports exportables

---

## Notes Backend

### Endpoints Disponibles (Backend: C:\Users\fatak\lilia-app)

```typescript
// Dashboard (role-aware: ADMIN = global, RESTAURATEUR = son restaurant)
GET /dashboard/overview
GET /dashboard/orders?period=
GET /dashboard/top-products?limit=&period=
GET /dashboard/revenue-chart?days=
GET /dashboard/clients
GET /dashboard/peak-hours?period=
GET /dashboard/restaurant-ranking?period=  // ADMIN uniquement

// Stock
PATCH /products/:id/stock  { stockQuotidien: number }  // RESTAURATEUR, ADMIN
PATCH /menus/:id/stock     { stockQuotidien: number }  // RESTAURATEUR, ADMIN

// Commandes (role-aware)
GET /orders/restaurants     // ADMIN = toutes, RESTAURATEUR = les siennes
PATCH /orders/:id/status    // RESTAURATEUR, ADMIN

// Admin
GET /admin/clients          // ADMIN uniquement - tous les clients
```

### Endpoints Manquants à Créer

```typescript
// Products - compléter CRUD
@Get(':id')
@Patch(':id')

// Categories - Nouveau module
@Get('restaurant/:restaurantId')
@Post()
@Patch(':id')
@Delete(':id')
```

---

## Checklist de Développement

### Avant chaque fonctionnalité
- [ ] Vérifier que l'endpoint backend existe
- [ ] Créer le modèle Dart si nécessaire
- [ ] Créer le provider Riverpod
- [ ] Implémenter l'UI
- [ ] Tester l'intégration
- [ ] Gérer les états d'erreur

### Standards de Code
- Utiliser Riverpod pour la gestion d'état
- Suivre le pattern Repository pour les appels API
- Implémenter les états loading/error/data
- Ajouter des messages de feedback utilisateur (SnackBar)
- Supporter le pull-to-refresh où applicable

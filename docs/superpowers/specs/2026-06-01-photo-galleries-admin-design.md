# Design — Admin photo galleries (Flutter + Web)

**Date** : 2026-06-01
**Chantier** : E2 (2e sous-chantier de Photo Galleries — suite de E1 backend, précède E3 client display)
**Auteur** : Henok Mipoka + Claude
**Status** : Approved → ready for implementation plan

## Contexte

E1 (backend) a livré 3 modules NestJS (`/vendor-photos`, `/product-images`, `/menu-images`) avec 5 endpoints chacun : `GET` public, `POST`, `PATCH /:id`, `DELETE /:id`, `POST /reorder`. Max 5 photos par entité, ownership IDOR (RESTAURATEUR owner ou ADMIN), invariant un seul cover par entité, cleanup Cloudinary à la suppression. Branche `hmipoka/photo-galleries-backend` mergée (PR à créer).

Côté admin, aucune UI n'existe pour gérer ces galeries. Les `imageUrl` actuels (une seule image par entité) restent éditables comme avant via les forms existants, mais les nouvelles galeries ne sont pas accessibles. E2 ajoute cette UI dans deux surfaces administratives :

- **`lilia-food-admin/`** : app Flutter + Riverpod (utilisée par RESTAURATEUR + ADMIN)
- **`lilia-food-web/apps/admin/`** : dashboard Next.js (utilisé principalement par ADMIN, accessible aux RESTAURATEUR via desktop)

E3 (display client mobile + web) consomme les mêmes endpoints en lecture publique et reste indépendant.

## Objectif

- Permettre à un RESTAURATEUR ou ADMIN de gérer une galerie de jusqu'à 5 photos par Restaurant, Product, MenuDuJour depuis l'admin Flutter et l'admin web
- Couvrir les 5 opérations : lister, ajouter (upload Cloudinary direct + POST), définir cover, éditer alt, supprimer, réordonner (drag-and-drop)
- Capturer le `publicId` Cloudinary à l'upload pour activer le cleanup auto au DELETE backend

## Non-objectifs

- Display côté client mobile / web — c'est Chantier E3
- Migration des `imageUrl` existants vers les galeries — purement additif (le form existant continue d'éditer `imageUrl`, la galerie est en parallèle)
- Édition d'image (crop, rotate, filtres) — l'utilisateur uploade déjà retouché
- Multi-upload simultané (sélection multiple) — un fichier à la fois
- Lightbox / viewer custom plein écran — on s'appuie sur le zoom natif du navigateur ou de la PhotoView Flutter existante au cas par cas
- Modération bloquante par photo — pas de workflow d'approbation
- Signed Cloudinary upload via backend — on reste sur unsigned preset (`ml_default`) côté Flutter et côté web

## Décisions validées par le user

1. **Découpage** : 1 chantier E2 unique couvrant Flutter admin + Web admin (pas de séparation par stack). E3 (client mobile + web) sera un chantier suivant indépendant.
2. **Couverture entités** : les 3 d'un coup (Restaurant + Product + MenuDuJour) — le widget gallery est paramétré par `entityType` et `parentId`, donc le coût marginal de couvrir les 3 est faible.
3. **Upload web admin** : Cloudinary direct via unsigned preset (mirror du pattern Flutter actuel) — pas de nouveau endpoint backend, pas de bande passante backend.
4. **`publicId` capturé** au moment de l'upload et passé au POST. Sans cela, les assets Cloudinary s'accumulent indéfiniment.
5. **Drag-to-reorder** activé dans cette PR. Flutter : `ReorderableListView` (pattern déjà utilisé pour banners). Web : `@dnd-kit/core` + `@dnd-kit/sortable`.
6. **Entry points** :
   - Flutter : écran dédié `PhotosScreen`, accessible via bouton "Photos" depuis chaque form (restaurant, product, menu)
   - Web : section embarquée dans les pages détail existantes (`/restaurants/[id]`, `/produits/[id]`, page menu à créer ou compléter)

## Architecture

### Modèle commun front

Les 3 tables backend ont un shape identique. Côté front on définit **un seul `Photo`** + un type union `EntityType = 'vendor' | 'product' | 'menu'` :

```typescript
// packages/types/src/index.ts
export type EntityType = 'vendor' | 'product' | 'menu';

export interface Photo {
  id: string;
  url: string;
  publicId: string | null;
  alt: string | null;
  displayOrder: number;
  isCover: boolean;
  createdAt: string;
  // L'identifiant parent dépend de entityType — utilisé seulement à l'écriture.
}
```

```dart
// lilia-food-admin/lib/features/photos/data/photo_models.dart
enum EntityType { vendor, product, menu }

class Photo {
  final String id;
  final String url;
  final String? publicId;
  final String? alt;
  final int displayOrder;
  final bool isCover;
  final DateTime createdAt;
  // ...
}
```

### Routing endpoint par entityType

Une factory dispatch les calls HTTP en fonction d'`entityType` :

| EntityType | URL base | Champ parent dans body |
|---|---|---|
| `vendor` | `/vendor-photos` | `restaurantId` |
| `product` | `/product-images` | `productId` |
| `menu` | `/menu-images` | `menuDuJourId` |

GET utilise le param query du champ parent (`?restaurantId=...` etc.).

### Cloudinary upload partagé

**Flutter** : `lib/features/users/data/cloudinary_service.dart` (existant) est étendu pour retourner un `CloudinaryUploadResult { url, publicId }` au lieu de juste `String?`. Le package `cloudinary_public` expose `publicId` dans son response — il faut juste l'extraire.

**Web** : nouveau utility `apps/admin/lib/cloudinary-upload.ts`. Fait un `fetch('https://api.cloudinary.com/v1_1/<cloud>/image/upload')` avec `FormData` contenant `file` + `upload_preset`. Retourne `{ secureUrl, publicId }`. Env vars (publiques, sans secret) :
- `NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME=dun9ev7pw`
- `NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET=ml_default`

## Implémentation Flutter (`lilia-food-admin`)

### Structure

```
lib/features/photos/
├── data/
│   ├── photo_models.dart                # Photo + EntityType + CloudinaryUploadResult
│   ├── vendor_photos_service.dart       # GET/POST/PATCH/DELETE /vendor-photos
│   ├── product_images_service.dart      # idem /product-images
│   ├── menu_images_service.dart         # idem /menu-images
│   └── photos_facade.dart               # factory dispatch par EntityType
├── application/
│   ├── photos_controller.dart           # @riverpod AsyncNotifier paramétré
│   └── photos_controller.g.dart         # généré
└── presentation/
    └── screens/photos_screen.dart       # écran dédié

lib/common_widgets/
└── photo_gallery_editor.dart            # widget réutilisable (grille + actions)

lib/features/users/data/cloudinary_service.dart   # modifié : retourne CloudinaryUploadResult
```

### Provider Riverpod

`photosControllerProvider(EntityType type, String parentId)` → `AsyncNotifier<List<Photo>>` avec méthodes :
- `add(XFile file, {bool isCover = false, String? alt})` — upload Cloudinary → POST
- `setCover(String photoId)` — PATCH isCover=true, optimistic
- `editAlt(String photoId, String alt)` — PATCH alt
- `delete(String photoId)` — DELETE, optimistic remove
- `reorder(List<String> newIds)` — POST /reorder, optimistic

Toutes les mutations font optimistic update avec rollback sur erreur (toast).

### Entry points

- **Restaurant** : bouton "Gérer les photos" dans la home du RESTAURATEUR (sa fiche). Pour ADMIN : bouton dans `admin_vendors_screen.dart` à côté de chaque vendor.
- **Product** : bouton "Photos" dans `product_form_screen.dart`, visible uniquement en mode édition (pas à la création — il faut d'abord un `productId`).
- **Menu** : bouton "Photos" dans `menu_form_screen.dart`, idem visible en édition.

Navigation : push une route `/photos?entityType=...&parentId=...`. Le `PhotosScreen` lit ces params et instancie le widget `PhotoGalleryEditor`.

### Réordonnage

`ReorderableListView` (pattern banners). À la fin du drag, on capture la nouvelle liste d'IDs et on appelle `controller.reorder(newIds)`.

## Implémentation Web (`lilia-food-web/apps/admin`)

### Shared packages

**`packages/types/src/index.ts`** :
```typescript
export type EntityType = 'vendor' | 'product' | 'menu';

export interface Photo {
  id: string;
  url: string;
  publicId: string | null;
  alt: string | null;
  displayOrder: number;
  isCover: boolean;
  createdAt: string;
}
```

**`packages/api-client/src/hooks/photos.ts`** (nouveau fichier) :

| Hook | HTTP | Notes |
|---|---|---|
| `usePhotos(entity, parentId, token?)` | `GET` | React Query, public — token optionnel |
| `useUploadPhoto(entity, parentId, token)` | `POST` | reçoit `{ url, publicId, alt?, isCover? }` |
| `useUpdatePhoto(entity, photoId, token)` | `PATCH /:id` | accepte `{ alt?, displayOrder?, isCover? }` |
| `useDeletePhoto(entity, photoId, token)` | `DELETE /:id` | |
| `useReorderPhotos(entity, parentId, token)` | `POST /reorder` | body `{ <parentField>, ids }` |

Toutes les mutations utilisent `useMutation` avec `onMutate` pour optimistic update + `onError` pour rollback (cf. pattern `useToggleFavorite` déjà présent dans `packages/api-client/src/hooks/favorites.ts`).

### App admin

```
apps/admin/
├── lib/
│   └── cloudinary-upload.ts             # POST direct vers Cloudinary, retourne {secureUrl, publicId}
├── components/
│   └── photo-gallery-editor.tsx         # composant unique paramétré entity + parentId + token
└── app/(protected)/
    ├── restaurants/[id]/page.tsx        # ajouter section <PhotoGalleryEditor entity="vendor" .../>
    ├── produits/[id]/page.tsx           # ajouter section <PhotoGalleryEditor entity="product" .../>
    └── menus/[id]/page.tsx              # créer la page si absente, + section
```

### Drag-and-drop

Ajouter `@dnd-kit/core` + `@dnd-kit/sortable` à `apps/admin/package.json`. Le `PhotoGalleryEditor` enveloppe sa grille dans `<DndContext>` + `<SortableContext>` ; chaque photo card est un `useSortable` hook. À la fin du drag, capturer le nouvel ordre et appeler `useReorderPhotos.mutate({ ids })`.

## Opérations & UX

### Les 5 opérations

| Action | Backend | UX |
|---|---|---|
| Lister | `GET /<endpoint>?<parentField>=X` | Grille responsive (mobile 2 cols, desktop 5 cols). Skeleton loader pendant fetch. Cover badge étoile en overlay. |
| Ajouter | upload Cloudinary → POST | Bouton "+" désactivé si déjà 5 photos avec tooltip "Maximum 5 atteint". Spinner pendant upload. Toast succès/erreur. Premier upload d'une entité (liste actuellement vide) → le front passe `isCover: true` automatiquement, sinon le user a un toggle au moment de l'upload pour choisir s'il veut la marquer cover. Le backend n'auto-marque pas la première photo. |
| Définir cover | `PATCH /:id { isCover: true }` | Tap sur l'étoile vide → bascule en étoile pleine. Optimistic, rollback si erreur. Backend assure unicité (transaction `demoteOtherCovers`). |
| Éditer alt | `PATCH /:id { alt }` | Champ texte (max 200) en inline edit ou modal. Save explicite (pas d'auto-save). |
| Supprimer | `DELETE /:id` | Confirm dialog : "Supprimer cette photo ?". Optimistic remove + rollback si erreur. Cleanup Cloudinary non-bloquant côté backend. |
| Réordonner | drag → `POST /reorder { <parentField>, ids }` | Visuel réordonné pendant drag. Persiste au drop. Rollback en cas d'erreur. |

### États

- **Vide** : "Aucune photo pour l'instant" + CTA "Ajouter la première"
- **Max atteint** : bouton désactivé + message tooltip
- **Loading initial** : skeleton grid
- **Network error** : bouton "Réessayer" sur la liste, toast d'erreur sur les mutations
- **403 (IDOR)** : toast "Vous n'avez pas accès à cette galerie"

### Authorization

Le backend enforce déjà IDOR. Le front fait confiance : on affiche le bouton "Photos" partout dans le menu admin, et le backend renverra 403 si pas autorisé (le toast d'erreur affiche le message du backend).

## Tests

### Flutter

- Tests unitaires Riverpod sur `photosController` :
  - upload optimistic ajoute la photo localement puis confirme via API
  - setCover bascule isCover sur la cible et démet les autres covers localement
  - delete fait optimistic remove
  - reorder réordonne localement avant API
  - rollback sur erreur réseau pour chacune des mutations
- Mocks `http` via `mocktail` ou `nock`-like Dart equivalent.
- Pas de widget tests (convention repo).

### Web

- Tests React Testing Library sur `PhotoGalleryEditor` :
  - rendering du loading / empty / list states
  - bouton "+" désactivé à 5 photos
  - optimistic update sur setCover / delete avec rollback simulé
  - drag-and-drop déclenche `useReorderPhotos`
- Mocks fetch via `msw` (si présent dans le projet, sinon `vi.fn()` direct).

## Dépendances

### Flutter (`lilia-food-admin`)

- `cloudinary_public` (déjà présent) : version ≥ 0.21 confirme le retour de `publicId`. À vérifier dans pubspec.lock pendant le plan.
- `image_picker` (déjà présent) : pas de changement.
- Aucun nouveau package requis.

### Web (`lilia-food-web/apps/admin`)

- **Nouveaux** : `@dnd-kit/core`, `@dnd-kit/sortable`, `@dnd-kit/utilities`
- Existants utilisés : React Query (déjà dans `packages/api-client`), Sonner ou autre toast (à vérifier — sinon réutiliser le pattern existant)

### Env vars

À ajouter dans `apps/admin/.env.example` (créer si absent) :
```
NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME=dun9ev7pw
NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET=ml_default
```

Pour la prod Vercel, les mêmes vars sont à déclarer dans le dashboard Vercel du projet admin.

## Risques & dette technique

- **Drag-and-drop sur mobile web** : `@dnd-kit` supporte touch via `TouchSensor`, mais l'UX sur smartphone reste meilleure dans l'app Flutter. Acceptable car le web admin est utilisé principalement sur desktop.
- **Unsigned upload preset** : un attaquant pourrait théoriquement upload n'importe quoi sur notre compte Cloudinary tant qu'il connaît le cloud name + preset. Acceptable au lancement (le compte est gratuit / free tier), à durcir plus tard avec signed upload via backend si besoin (E2.5 ou plus tard).
- **Pas de UI de migration** `imageUrl` → galerie. Les entités existantes gardent leur `imageUrl` indépendant. Documenté hors scope, à traiter post-E3 selon retours utilisateurs.
- **Branches Flutter et Web différentes** : on travaille sur 2 repos donc 2 PRs distinctes. Coordonner le merge pour éviter qu'un seul côté soit déployé sans l'autre.

## Suite

Une fois E2 mergé et déployé :
- **E3** : display galerie sur le client mobile (`lilia-app`) et le client web (`lilia-food-web/apps/web`) — carrousels sur fiches resto / produit / menu, avec fallback sur `imageUrl` si galerie vide
- **E2.5 (optionnel)** : signed upload Cloudinary via backend si l'unsigned preset devient un problème

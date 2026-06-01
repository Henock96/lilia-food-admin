# Admin Photo Galleries (E2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Surfaces admin Flutter (lilia-food-admin) + Next.js (lilia-food-web/apps/admin) qui consomment les 15 endpoints E1 pour gérer les galeries multi-photos Restaurant/Product/MenuDuJour.

**Architecture:** Un widget paramétré `PhotoGalleryEditor` par stack qui sait dispatcher vers le bon endpoint selon `entityType: 'vendor' | 'product' | 'menu'`. Upload Cloudinary direct (unsigned preset). Drag-to-reorder. Optimistic updates avec rollback.

**Tech Stack:** Flutter + Riverpod + cloudinary_public + http (lilia-food-admin) ; Next.js + React Query + @dnd-kit + shared packages TS (lilia-food-web).

**Spec source:** `docs/superpowers/specs/2026-06-01-photo-galleries-admin-design.md`

---

## Pré-requis

- Backend E1 mergé et déployé sur `https://lilia-backend.onrender.com` (les 15 endpoints `/vendor-photos`, `/product-images`, `/menu-images` doivent répondre).
- Repo `lilia-food-admin` : la branche `hmipoka/photo-galleries-admin` existe déjà (vérifiable via `git branch --show-current`). Aucune nouvelle branche à couper ici.
- Repo `lilia-food-web` : la branche `hmipoka/photo-galleries-admin` est à créer en Phase F1.
- Variables d'environnement Cloudinary connues : `cloud_name=dun9ev7pw`, `upload_preset=ml_default` (déjà utilisés par `lib/features/users/data/cloudinary_service.dart`).
- Outils locaux : Flutter ≥ 3.41, Dart ≥ 3.10, pnpm 9.15+ (pour le repo web — `pnpm --version`), Node ≥ 18.

### Conventions transverses

- **Working directories** :
  - Flutter : `/Users/henokmipoks/Desktop/code/lilia-food-admin/`
  - Web : `/Users/henokmipoks/Desktop/code/lilia-food-web/`
  - Les phases A-E sont en Flutter, F-H en Web. Chaque commande indique son `cd` explicitement.
- **Package manager** : Flutter = `dart`/`flutter`. Web = `pnpm@9.15.0` (déclaré dans `package.json#packageManager`, malgré la présence parallèle d'un `bun.lock` historique non utilisé). On commande `pnpm add` / `pnpm --filter <name> run <script>`.
- **Commits** : un commit par phase. Messages en français (convention projet). Format `feat(scope): description` ou `refactor(scope): description`.
- **Aucun TODO/TBD** : si un détail manque, l'implémenteur consulte le spec ou demande à l'utilisateur ; pas de placeholder dans le code livré.

---

## Phase A — Flutter : modèles + service Cloudinary étendu

**Objectif :** poser les fondations Dart : un fichier modèles pour `Photo`, `EntityType` et `CloudinaryUploadResult`, et adapter `CloudinaryService` pour exposer le `publicId` (sans casser l'usage existant dans `profile_controller.dart`).

### Tâches

#### A1. Créer `lib/features/photos/data/photo_models.dart`

- [ ] Vérifier que le dossier `lib/features/photos/data/` n'existe pas encore :
  ```bash
  ls /Users/henokmipoks/Desktop/code/lilia-food-admin/lib/features/photos 2>/dev/null || echo "à créer"
  ```
- [ ] Créer le fichier `lib/features/photos/data/photo_models.dart` avec ce contenu exact :

  ```dart
  /// Modèles partagés pour la feature galeries photos (Restaurant / Product /
  /// MenuDuJour). Les 3 entités backend partagent un shape identique côté
  /// API, donc on les modélise via une classe unique `Photo` paramétrée par
  /// [EntityType].
  enum EntityType { vendor, product, menu }

  extension EntityTypeX on EntityType {
    /// Préfixe URL de l'endpoint REST associé.
    String get endpoint {
      switch (this) {
        case EntityType.vendor:
          return '/vendor-photos';
        case EntityType.product:
          return '/product-images';
        case EntityType.menu:
          return '/menu-images';
      }
    }

    /// Nom du champ "parent" attendu en query (GET) et en body (POST /reorder).
    String get parentField {
      switch (this) {
        case EntityType.vendor:
          return 'restaurantId';
        case EntityType.product:
          return 'productId';
        case EntityType.menu:
          return 'menuDuJourId';
      }
    }

    /// Libellé humain pour les écrans / toasts.
    String get label {
      switch (this) {
        case EntityType.vendor:
          return 'restaurant';
        case EntityType.product:
          return 'produit';
        case EntityType.menu:
          return 'menu du jour';
      }
    }

    static EntityType fromString(String value) {
      switch (value) {
        case 'vendor':
          return EntityType.vendor;
        case 'product':
          return EntityType.product;
        case 'menu':
          return EntityType.menu;
        default:
          throw ArgumentError('EntityType inconnu: $value');
      }
    }

    String get asString {
      switch (this) {
        case EntityType.vendor:
          return 'vendor';
        case EntityType.product:
          return 'product';
        case EntityType.menu:
          return 'menu';
      }
    }
  }

  /// Réponse d'un upload Cloudinary direct. On capture `publicId` pour
  /// permettre au backend de faire le cleanup à la suppression.
  class CloudinaryUploadResult {
    final String secureUrl;
    final String publicId;

    const CloudinaryUploadResult({
      required this.secureUrl,
      required this.publicId,
    });
  }

  /// Représente une photo de galerie côté Flutter, indépendamment de
  /// l'entité parente (Restaurant / Product / MenuDuJour).
  class Photo {
    final String id;
    final String url;
    final String? publicId;
    final String? alt;
    final int displayOrder;
    final bool isCover;
    final DateTime createdAt;

    const Photo({
      required this.id,
      required this.url,
      required this.publicId,
      required this.alt,
      required this.displayOrder,
      required this.isCover,
      required this.createdAt,
    });

    factory Photo.fromJson(Map<String, dynamic> json) {
      return Photo(
        id: json['id'] as String,
        url: json['url'] as String,
        publicId: json['publicId'] as String?,
        alt: json['alt'] as String?,
        displayOrder: json['displayOrder'] as int? ?? 0,
        isCover: json['isCover'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
    }

    Photo copyWith({
      String? id,
      String? url,
      String? publicId,
      String? alt,
      int? displayOrder,
      bool? isCover,
      DateTime? createdAt,
    }) {
      return Photo(
        id: id ?? this.id,
        url: url ?? this.url,
        publicId: publicId ?? this.publicId,
        alt: alt ?? this.alt,
        displayOrder: displayOrder ?? this.displayOrder,
        isCover: isCover ?? this.isCover,
        createdAt: createdAt ?? this.createdAt,
      );
    }
  }
  ```

#### A2. Étendre `lib/features/users/data/cloudinary_service.dart`

- [ ] Lire le fichier pour mémoriser son contenu actuel (déjà connu : retourne `String?`, signature `Future<String?> uploadImage(XFile image)`).
- [ ] Remplacer son contenu par :

  ```dart
  import 'package:cloudinary_public/cloudinary_public.dart';
  import 'package:flutter/foundation.dart';
  import 'package:image_picker/image_picker.dart';

  import '../../photos/data/photo_models.dart';

  class CloudinaryService {
    final _cloudinary = CloudinaryPublic('dun9ev7pw', 'ml_default', cache: false);

    /// Conserve l'API historique pour `profile_controller.dart` : ne retourne
    /// que l'URL secure.
    Future<String?> uploadImage(XFile image) async {
      final result = await uploadImageWithPublicId(image);
      return result?.secureUrl;
    }

    /// Nouvelle API utilisée par la feature photos : retourne aussi le
    /// `publicId` Cloudinary, nécessaire pour activer le cleanup côté backend.
    Future<CloudinaryUploadResult?> uploadImageWithPublicId(XFile image) async {
      try {
        final response = await _cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            image.path,
            resourceType: CloudinaryResourceType.Image,
          ),
        );
        return CloudinaryUploadResult(
          secureUrl: response.secureUrl,
          publicId: response.publicId,
        );
      } on CloudinaryException catch (e) {
        debugPrint('CloudinaryException: ${e.message}');
        return null;
      }
    }
  }

  //CLOUDINARY_URL=cloudinary://779627169413964:zhYvHdrvy5xh64DG6DbCiw9JplE@dun9ev7pw
  ```

- [ ] Vérifier qu'aucun autre fichier ne casse :
  ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-admin && flutter analyze lib/features/users
  ```

#### A3. Vérification de phase

- [ ] Lancer une analyse globale pour s'assurer que rien d'autre n'est cassé :
  ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-admin && flutter analyze
  ```
- [ ] Aucune erreur attendue (warnings préexistants tolérés).

#### A4. Commit de la phase A

- [ ] Vérifier l'état git :
  ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-admin && git status
  ```
- [ ] Ajouter les fichiers :
  ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-admin && git add lib/features/photos/data/photo_models.dart lib/features/users/data/cloudinary_service.dart
  ```
- [ ] Committer :
  ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-admin && git commit -m "$(cat <<'EOF'
  feat(photos): modèles Photo/EntityType + Cloudinary publicId

  Pose les fondations pour la feature galeries photos admin (E2) :
  - Nouvelle classe Photo + enum EntityType (vendor/product/menu) avec
    extensions pour endpoint, parentField et label.
  - CloudinaryUploadResult { secureUrl, publicId } pour capturer le
    publicId nécessaire au cleanup backend.
  - CloudinaryService expose désormais uploadImageWithPublicId() sans
    casser uploadImage() utilisé par le profil.
  EOF
  )"
  ```

---

## Phase B — Flutter : 3 services HTTP + facade

**Objectif :** un service HTTP par entité (vendor / product / menu), tous calqués sur le pattern de `banner_service.dart`. Une facade `PhotosFacade` dispatch les appels selon `EntityType`. Cinq méthodes par service : `list`, `create`, `update`, `delete`, `reorder`.

### Tâches

#### B1. Créer `lib/features/photos/data/vendor_photos_service.dart`

- [ ] Contenu :

  ```dart
  import 'dart:convert';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:http/http.dart' as http;

  import 'photo_models.dart';

  class VendorPhotosService {
    final String _baseUrl = "https://lilia-backend.onrender.com";
    final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

    Future<String?> _getAuthToken() async {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      return await user.getIdToken();
    }

    Future<List<Photo>> list(String restaurantId) async {
      final token = await _getAuthToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/vendor-photos?restaurantId=$restaurantId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final responseData =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final data = responseData['data'] as List<dynamic>? ?? [];
        return data
            .map((j) => Photo.fromJson(j as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to load vendor photos: ${response.body}');
    }

    Future<Photo> create({
      required String restaurantId,
      required String url,
      required String publicId,
      String? alt,
      bool isCover = false,
    }) async {
      final token = await _getAuthToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/vendor-photos'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'restaurantId': restaurantId,
          'url': url,
          'publicId': publicId,
          if (alt != null) 'alt': alt,
          'isCover': isCover,
        }),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final photoJson = responseData['data'] as Map<String, dynamic>?;
        if (photoJson == null) {
          throw Exception('Vendor photo data null in response');
        }
        return Photo.fromJson(photoJson);
      }
      throw Exception('Failed to create vendor photo: ${response.body}');
    }

    Future<Photo> update(
      String photoId, {
      String? alt,
      bool? isCover,
      int? displayOrder,
    }) async {
      final token = await _getAuthToken();
      final body = <String, dynamic>{};
      if (alt != null) body['alt'] = alt;
      if (isCover != null) body['isCover'] = isCover;
      if (displayOrder != null) body['displayOrder'] = displayOrder;

      final response = await http.patch(
        Uri.parse('$_baseUrl/vendor-photos/$photoId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );
      if (response.statusCode == 200) {
        final responseData =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final photoJson = responseData['data'] as Map<String, dynamic>?;
        if (photoJson == null) {
          throw Exception('Vendor photo data null in response');
        }
        return Photo.fromJson(photoJson);
      }
      throw Exception('Failed to update vendor photo: ${response.body}');
    }

    Future<void> delete(String photoId) async {
      final token = await _getAuthToken();
      final response = await http.delete(
        Uri.parse('$_baseUrl/vendor-photos/$photoId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete vendor photo: ${response.body}');
      }
    }

    Future<void> reorder(String restaurantId, List<String> ids) async {
      final token = await _getAuthToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/vendor-photos/reorder'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'restaurantId': restaurantId, 'ids': ids}),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to reorder vendor photos: ${response.body}');
      }
    }
  }
  ```

#### B2. Créer `lib/features/photos/data/product_images_service.dart`

- [ ] Même structure que B1, avec :
  - `class ProductImagesService`
  - Endpoint `/product-images`
  - Champ parent `productId`
  - Messages d'erreur : remplacer "vendor photo" par "product image"

  ```dart
  import 'dart:convert';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:http/http.dart' as http;

  import 'photo_models.dart';

  class ProductImagesService {
    final String _baseUrl = "https://lilia-backend.onrender.com";
    final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

    Future<String?> _getAuthToken() async {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      return await user.getIdToken();
    }

    Future<List<Photo>> list(String productId) async {
      final token = await _getAuthToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/product-images?productId=$productId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final responseData =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final data = responseData['data'] as List<dynamic>? ?? [];
        return data
            .map((j) => Photo.fromJson(j as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to load product images: ${response.body}');
    }

    Future<Photo> create({
      required String productId,
      required String url,
      required String publicId,
      String? alt,
      bool isCover = false,
    }) async {
      final token = await _getAuthToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/product-images'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'productId': productId,
          'url': url,
          'publicId': publicId,
          if (alt != null) 'alt': alt,
          'isCover': isCover,
        }),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final photoJson = responseData['data'] as Map<String, dynamic>?;
        if (photoJson == null) {
          throw Exception('Product image data null in response');
        }
        return Photo.fromJson(photoJson);
      }
      throw Exception('Failed to create product image: ${response.body}');
    }

    Future<Photo> update(
      String photoId, {
      String? alt,
      bool? isCover,
      int? displayOrder,
    }) async {
      final token = await _getAuthToken();
      final body = <String, dynamic>{};
      if (alt != null) body['alt'] = alt;
      if (isCover != null) body['isCover'] = isCover;
      if (displayOrder != null) body['displayOrder'] = displayOrder;

      final response = await http.patch(
        Uri.parse('$_baseUrl/product-images/$photoId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );
      if (response.statusCode == 200) {
        final responseData =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final photoJson = responseData['data'] as Map<String, dynamic>?;
        if (photoJson == null) {
          throw Exception('Product image data null in response');
        }
        return Photo.fromJson(photoJson);
      }
      throw Exception('Failed to update product image: ${response.body}');
    }

    Future<void> delete(String photoId) async {
      final token = await _getAuthToken();
      final response = await http.delete(
        Uri.parse('$_baseUrl/product-images/$photoId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete product image: ${response.body}');
      }
    }

    Future<void> reorder(String productId, List<String> ids) async {
      final token = await _getAuthToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/product-images/reorder'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'productId': productId, 'ids': ids}),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to reorder product images: ${response.body}');
      }
    }
  }
  ```

#### B3. Créer `lib/features/photos/data/menu_images_service.dart`

- [ ] Même structure que B1/B2 avec :
  - `class MenuImagesService`
  - Endpoint `/menu-images`
  - Champ parent `menuDuJourId`

  ```dart
  import 'dart:convert';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:http/http.dart' as http;

  import 'photo_models.dart';

  class MenuImagesService {
    final String _baseUrl = "https://lilia-backend.onrender.com";
    final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

    Future<String?> _getAuthToken() async {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      return await user.getIdToken();
    }

    Future<List<Photo>> list(String menuDuJourId) async {
      final token = await _getAuthToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/menu-images?menuDuJourId=$menuDuJourId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final responseData =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final data = responseData['data'] as List<dynamic>? ?? [];
        return data
            .map((j) => Photo.fromJson(j as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to load menu images: ${response.body}');
    }

    Future<Photo> create({
      required String menuDuJourId,
      required String url,
      required String publicId,
      String? alt,
      bool isCover = false,
    }) async {
      final token = await _getAuthToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/menu-images'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'menuDuJourId': menuDuJourId,
          'url': url,
          'publicId': publicId,
          if (alt != null) 'alt': alt,
          'isCover': isCover,
        }),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final photoJson = responseData['data'] as Map<String, dynamic>?;
        if (photoJson == null) {
          throw Exception('Menu image data null in response');
        }
        return Photo.fromJson(photoJson);
      }
      throw Exception('Failed to create menu image: ${response.body}');
    }

    Future<Photo> update(
      String photoId, {
      String? alt,
      bool? isCover,
      int? displayOrder,
    }) async {
      final token = await _getAuthToken();
      final body = <String, dynamic>{};
      if (alt != null) body['alt'] = alt;
      if (isCover != null) body['isCover'] = isCover;
      if (displayOrder != null) body['displayOrder'] = displayOrder;

      final response = await http.patch(
        Uri.parse('$_baseUrl/menu-images/$photoId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );
      if (response.statusCode == 200) {
        final responseData =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final photoJson = responseData['data'] as Map<String, dynamic>?;
        if (photoJson == null) {
          throw Exception('Menu image data null in response');
        }
        return Photo.fromJson(photoJson);
      }
      throw Exception('Failed to update menu image: ${response.body}');
    }

    Future<void> delete(String photoId) async {
      final token = await _getAuthToken();
      final response = await http.delete(
        Uri.parse('$_baseUrl/menu-images/$photoId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete menu image: ${response.body}');
      }
    }

    Future<void> reorder(String menuDuJourId, List<String> ids) async {
      final token = await _getAuthToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/menu-images/reorder'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'menuDuJourId': menuDuJourId, 'ids': ids}),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to reorder menu images: ${response.body}');
      }
    }
  }
  ```

#### B4. Créer la facade `lib/features/photos/data/photos_facade.dart`

- [ ] La facade reçoit les 3 services et dispatch selon `EntityType`.

  ```dart
  import 'menu_images_service.dart';
  import 'photo_models.dart';
  import 'product_images_service.dart';
  import 'vendor_photos_service.dart';

  /// Routeur uniforme : expose les 5 opérations CRUD+reorder pour les 3
  /// entités photo en redirigeant vers le bon service HTTP selon
  /// [EntityType]. C'est ce que consomme `PhotosController`.
  class PhotosFacade {
    final VendorPhotosService _vendor;
    final ProductImagesService _product;
    final MenuImagesService _menu;

    PhotosFacade({
      VendorPhotosService? vendor,
      ProductImagesService? product,
      MenuImagesService? menu,
    })  : _vendor = vendor ?? VendorPhotosService(),
          _product = product ?? ProductImagesService(),
          _menu = menu ?? MenuImagesService();

    Future<List<Photo>> list(EntityType type, String parentId) {
      switch (type) {
        case EntityType.vendor:
          return _vendor.list(parentId);
        case EntityType.product:
          return _product.list(parentId);
        case EntityType.menu:
          return _menu.list(parentId);
      }
    }

    Future<Photo> create(
      EntityType type,
      String parentId, {
      required String url,
      required String publicId,
      String? alt,
      bool isCover = false,
    }) {
      switch (type) {
        case EntityType.vendor:
          return _vendor.create(
            restaurantId: parentId,
            url: url,
            publicId: publicId,
            alt: alt,
            isCover: isCover,
          );
        case EntityType.product:
          return _product.create(
            productId: parentId,
            url: url,
            publicId: publicId,
            alt: alt,
            isCover: isCover,
          );
        case EntityType.menu:
          return _menu.create(
            menuDuJourId: parentId,
            url: url,
            publicId: publicId,
            alt: alt,
            isCover: isCover,
          );
      }
    }

    Future<Photo> update(
      EntityType type,
      String photoId, {
      String? alt,
      bool? isCover,
      int? displayOrder,
    }) {
      switch (type) {
        case EntityType.vendor:
          return _vendor.update(
            photoId,
            alt: alt,
            isCover: isCover,
            displayOrder: displayOrder,
          );
        case EntityType.product:
          return _product.update(
            photoId,
            alt: alt,
            isCover: isCover,
            displayOrder: displayOrder,
          );
        case EntityType.menu:
          return _menu.update(
            photoId,
            alt: alt,
            isCover: isCover,
            displayOrder: displayOrder,
          );
      }
    }

    Future<void> delete(EntityType type, String photoId) {
      switch (type) {
        case EntityType.vendor:
          return _vendor.delete(photoId);
        case EntityType.product:
          return _product.delete(photoId);
        case EntityType.menu:
          return _menu.delete(photoId);
      }
    }

    Future<void> reorder(
      EntityType type,
      String parentId,
      List<String> ids,
    ) {
      switch (type) {
        case EntityType.vendor:
          return _vendor.reorder(parentId, ids);
        case EntityType.product:
          return _product.reorder(parentId, ids);
        case EntityType.menu:
          return _menu.reorder(parentId, ids);
      }
    }
  }
  ```

#### B5. Vérification + commit

- [ ] Analyse :
  ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-admin && flutter analyze lib/features/photos
  ```
- [ ] Aucune erreur attendue.
- [ ] Stage + commit :
  ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-admin && git add lib/features/photos/data/
  ```
  ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-admin && git commit -m "$(cat <<'EOF'
  feat(photos): services HTTP vendor/product/menu + PhotosFacade

  Trois services HTTP (VendorPhotosService, ProductImagesService,
  MenuImagesService) calqués sur banner_service.dart : Bearer token
  Firebase, parsing du wrapper { data: [...] }, baseUrl onrender.

  PhotosFacade route vers le bon service selon EntityType ; c'est l'API
  que consommera le controller Riverpod en phase C.

  Couvre les 5 endpoints E1 × 3 entités : list, create, update, delete,
  reorder.
  EOF
  )"
  ```

---

## Phase C — Flutter : controller Riverpod + tests

**Objectif :** un controller `PhotosController` paramétré (famille `EntityType`/`parentId`) avec 5 mutations toutes optimistic + rollback. Tests unitaires sur les optimistic updates et rollbacks.

### Tâches

#### C1. Créer `lib/features/photos/application/photos_controller.dart`

- [ ] Contenu :

  ```dart
  import 'package:image_picker/image_picker.dart';
  import 'package:riverpod_annotation/riverpod_annotation.dart';

  import '../../users/data/cloudinary_service.dart';
  import '../data/photo_models.dart';
  import '../data/photos_facade.dart';

  part 'photos_controller.g.dart';

  /// Provider de la façade — overridable dans les tests.
  @riverpod
  PhotosFacade photosFacade(Ref ref) => PhotosFacade();

  /// Provider du service Cloudinary — overridable dans les tests.
  @riverpod
  CloudinaryService cloudinaryServiceForPhotos(Ref ref) => CloudinaryService();

  /// AsyncNotifier paramétré par (EntityType, parentId). Gère la liste des
  /// photos d'une entité + les 5 mutations optimistic.
  @riverpod
  class PhotosController extends _$PhotosController {
    @override
    Future<List<Photo>> build(EntityType type, String parentId) async {
      final facade = ref.watch(photosFacadeProvider);
      final list = await facade.list(type, parentId);
      // Garde la liste triée par displayOrder pour l'UI.
      list.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      return list;
    }

    /// Recharge la liste depuis l'API.
    Future<void> refresh() async {
      state = const AsyncLoading();
      state = await AsyncValue.guard(() async {
        final facade = ref.read(photosFacadeProvider);
        final list = await facade.list(type, parentId);
        list.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        return list;
      });
    }

    /// Upload Cloudinary puis POST. Le premier upload d'une entité (liste
    /// actuellement vide) marque automatiquement la photo comme cover.
    Future<void> add(XFile file, {bool? isCover, String? alt}) async {
      final current = state.valueOrNull ?? const [];
      if (current.length >= 5) {
        throw Exception('Maximum 5 photos par ${type.label}');
      }

      final cloudinary = ref.read(cloudinaryServiceForPhotosProvider);
      final upload = await cloudinary.uploadImageWithPublicId(file);
      if (upload == null) {
        throw Exception('Échec de l\'upload Cloudinary');
      }

      final shouldBeCover = isCover ?? current.isEmpty;

      final facade = ref.read(photosFacadeProvider);
      final created = await facade.create(
        type,
        parentId,
        url: upload.secureUrl,
        publicId: upload.publicId,
        alt: alt,
        isCover: shouldBeCover,
      );

      // Mise à jour : si la nouvelle photo est cover, on démet les autres
      // covers localement (le backend a déjà fait le travail côté DB).
      final updated = [
        for (final p in current)
          if (shouldBeCover) p.copyWith(isCover: false) else p,
        created,
      ];
      updated.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      state = AsyncData(updated);
    }

    /// Bascule isCover=true sur la cible et démet les autres covers en local
    /// avant l'appel API. Rollback complet sur erreur.
    Future<void> setCover(String photoId) async {
      final current = state.valueOrNull ?? const [];
      if (current.isEmpty) return;

      final previous = current;
      final optimistic = current
          .map((p) => p.copyWith(isCover: p.id == photoId))
          .toList();
      state = AsyncData(optimistic);

      try {
        final facade = ref.read(photosFacadeProvider);
        await facade.update(type, photoId, isCover: true);
      } catch (e) {
        state = AsyncData(previous);
        rethrow;
      }
    }

    /// Édite le `alt` d'une photo. Optimistic + rollback.
    Future<void> editAlt(String photoId, String alt) async {
      final current = state.valueOrNull ?? const [];
      final previous = current;
      final optimistic = current
          .map((p) => p.id == photoId ? p.copyWith(alt: alt) : p)
          .toList();
      state = AsyncData(optimistic);

      try {
        final facade = ref.read(photosFacadeProvider);
        await facade.update(type, photoId, alt: alt);
      } catch (e) {
        state = AsyncData(previous);
        rethrow;
      }
    }

    /// Supprime localement avant l'appel DELETE. Rollback si erreur réseau.
    Future<void> delete(String photoId) async {
      final current = state.valueOrNull ?? const [];
      final previous = current;
      final optimistic = current.where((p) => p.id != photoId).toList();
      state = AsyncData(optimistic);

      try {
        final facade = ref.read(photosFacadeProvider);
        await facade.delete(type, photoId);
      } catch (e) {
        state = AsyncData(previous);
        rethrow;
      }
    }

    /// Réordonne en local (avec réécriture des displayOrder) puis POST
    /// /reorder avec la liste d'IDs. Rollback si erreur.
    Future<void> reorder(List<String> newIds) async {
      final current = state.valueOrNull ?? const [];
      if (current.isEmpty) return;

      final previous = current;
      final byId = {for (final p in current) p.id: p};
      final reordered = <Photo>[];
      for (var i = 0; i < newIds.length; i++) {
        final photo = byId[newIds[i]];
        if (photo == null) continue;
        reordered.add(photo.copyWith(displayOrder: i));
      }
      state = AsyncData(reordered);

      try {
        final facade = ref.read(photosFacadeProvider);
        await facade.reorder(type, parentId, newIds);
      } catch (e) {
        state = AsyncData(previous);
        rethrow;
      }
    }
  }
  ```

#### C2. Générer le code Riverpod

- [ ] Lancer build_runner pour générer `photos_controller.g.dart` :
  ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-admin && dart run build_runner build --delete-conflicting-outputs
  ```
- [ ] Vérifier que `lib/features/photos/application/photos_controller.g.dart` existe.

#### C3. Créer les tests unitaires `lib/features/photos/application/photos_controller_test.dart`

- [ ] Le but : vérifier les 4 comportements clés (optimistic add, setCover demote local, delete rollback, reorder).

  ```dart
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:lilia_admin/features/photos/application/photos_controller.dart';
  import 'package:lilia_admin/features/photos/data/photo_models.dart';
  import 'package:lilia_admin/features/photos/data/photos_facade.dart';

  class _FakeFacade implements PhotosFacade {
    _FakeFacade(this.initial);

    final List<Photo> initial;
    bool throwOnUpdate = false;
    bool throwOnDelete = false;
    bool throwOnReorder = false;
    List<String>? lastReorderIds;

    @override
    Future<List<Photo>> list(EntityType type, String parentId) async =>
        List.of(initial);

    @override
    Future<Photo> create(
      EntityType type,
      String parentId, {
      required String url,
      required String publicId,
      String? alt,
      bool isCover = false,
    }) async {
      return Photo(
        id: 'new-${initial.length + 1}',
        url: url,
        publicId: publicId,
        alt: alt,
        displayOrder: initial.length,
        isCover: isCover,
        createdAt: DateTime.now(),
      );
    }

    @override
    Future<Photo> update(
      EntityType type,
      String photoId, {
      String? alt,
      bool? isCover,
      int? displayOrder,
    }) async {
      if (throwOnUpdate) throw Exception('boom');
      final existing = initial.firstWhere((p) => p.id == photoId);
      return existing.copyWith(alt: alt, isCover: isCover);
    }

    @override
    Future<void> delete(EntityType type, String photoId) async {
      if (throwOnDelete) throw Exception('boom');
    }

    @override
    Future<void> reorder(
      EntityType type,
      String parentId,
      List<String> ids,
    ) async {
      lastReorderIds = ids;
      if (throwOnReorder) throw Exception('boom');
    }
  }

  Photo _photo(String id, {int order = 0, bool cover = false}) => Photo(
        id: id,
        url: 'https://x/$id.jpg',
        publicId: 'lilia/$id',
        alt: null,
        displayOrder: order,
        isCover: cover,
        createdAt: DateTime(2026, 1, 1),
      );

  void main() {
    group('PhotosController', () {
      test('setCover demote local + persiste', () async {
        final initial = [
          _photo('a', order: 0, cover: true),
          _photo('b', order: 1),
        ];
        final fake = _FakeFacade(initial);
        final container = ProviderContainer(
          overrides: [photosFacadeProvider.overrideWith((ref) => fake)],
        );
        addTearDown(container.dispose);

        final notifier = container.read(
          photosControllerProvider(EntityType.vendor, 'r1').notifier,
        );
        await container.read(
          photosControllerProvider(EntityType.vendor, 'r1').future,
        );

        await notifier.setCover('b');

        final state = container
            .read(photosControllerProvider(EntityType.vendor, 'r1'))
            .value!;
        expect(state.firstWhere((p) => p.id == 'a').isCover, isFalse);
        expect(state.firstWhere((p) => p.id == 'b').isCover, isTrue);
      });

      test('setCover rollback si API throw', () async {
        final initial = [
          _photo('a', order: 0, cover: true),
          _photo('b', order: 1),
        ];
        final fake = _FakeFacade(initial)..throwOnUpdate = true;
        final container = ProviderContainer(
          overrides: [photosFacadeProvider.overrideWith((ref) => fake)],
        );
        addTearDown(container.dispose);

        final notifier = container.read(
          photosControllerProvider(EntityType.vendor, 'r1').notifier,
        );
        await container.read(
          photosControllerProvider(EntityType.vendor, 'r1').future,
        );

        expect(() => notifier.setCover('b'), throwsException);
        await Future<void>.delayed(Duration.zero);

        final state = container
            .read(photosControllerProvider(EntityType.vendor, 'r1'))
            .value!;
        expect(state.firstWhere((p) => p.id == 'a').isCover, isTrue);
        expect(state.firstWhere((p) => p.id == 'b').isCover, isFalse);
      });

      test('delete optimistic remove puis rollback si throw', () async {
        final initial = [
          _photo('a', order: 0),
          _photo('b', order: 1),
        ];
        final fake = _FakeFacade(initial)..throwOnDelete = true;
        final container = ProviderContainer(
          overrides: [photosFacadeProvider.overrideWith((ref) => fake)],
        );
        addTearDown(container.dispose);

        final notifier = container.read(
          photosControllerProvider(EntityType.vendor, 'r1').notifier,
        );
        await container.read(
          photosControllerProvider(EntityType.vendor, 'r1').future,
        );

        expect(() => notifier.delete('a'), throwsException);
        await Future<void>.delayed(Duration.zero);

        final state = container
            .read(photosControllerProvider(EntityType.vendor, 'r1'))
            .value!;
        expect(state.map((p) => p.id).toList(), ['a', 'b']);
      });

      test('reorder réordonne localement et envoie les ids', () async {
        final initial = [
          _photo('a', order: 0),
          _photo('b', order: 1),
          _photo('c', order: 2),
        ];
        final fake = _FakeFacade(initial);
        final container = ProviderContainer(
          overrides: [photosFacadeProvider.overrideWith((ref) => fake)],
        );
        addTearDown(container.dispose);

        final notifier = container.read(
          photosControllerProvider(EntityType.vendor, 'r1').notifier,
        );
        await container.read(
          photosControllerProvider(EntityType.vendor, 'r1').future,
        );

        await notifier.reorder(['c', 'a', 'b']);

        expect(fake.lastReorderIds, ['c', 'a', 'b']);
        final state = container
            .read(photosControllerProvider(EntityType.vendor, 'r1'))
            .value!;
        expect(state.map((p) => p.id).toList(), ['c', 'a', 'b']);
        expect(state[0].displayOrder, 0);
        expect(state[2].displayOrder, 2);
      });
    });
  }
  ```

#### C4. Vérification

- [ ] Lancer les tests :
  ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-admin && flutter test test/ lib/features/photos/application/photos_controller_test.dart
  ```
  Note : le fichier de test étant placé sous `lib/`, on l'invoque directement. Si la convention du repo est d'avoir les tests sous `test/`, déplacer le fichier vers `test/features/photos/photos_controller_test.dart` et ajuster l'import en conséquence avant de committer.
- [ ] `flutter analyze` doit toujours passer.

#### C5. Commit phase C

- [ ] Stage :
  ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-admin && git add lib/features/photos/application/
  ```
- [ ] Commit :
  ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-admin && git commit -m "$(cat <<'EOF'
  feat(photos): PhotosController Riverpod + tests optimistic

  AsyncNotifier paramétré (EntityType, parentId) avec les 5 mutations :
  add (upload Cloudinary + POST, auto-cover si premier), setCover (demote
  local + PATCH), editAlt, delete (optimistic remove), reorder (réécrit
  displayOrder local + POST /reorder). Toutes les mutations sont
  optimistic avec rollback sur erreur.

  Tests : setCover demote, rollback update, rollback delete, reorder.
  EOF
  )"
  ```

---

## Phase D — Flutter : widget PhotoGalleryEditor + PhotosScreen

**Objectif :** un widget réutilisable `PhotoGalleryEditor` qui rend la grille, gère drag-to-reorder, et expose les actions per-tile (set cover, edit alt, delete). Un écran `PhotosScreen` qui le wrap et lit les args.

### Tâches

#### D1. Créer le widget `lib/common_widgets/photo_gallery_editor.dart`

- [ ] Le dossier `lib/common_widgets/` n'existe pas encore. Le créer en posant le fichier directement.
- [ ] Contenu :

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:image_picker/image_picker.dart';

  import '../features/photos/application/photos_controller.dart';
  import '../features/photos/data/photo_models.dart';

  /// Widget réutilisable qui rend la galerie photos d'une entité.
  /// Paramétré par [entityType] + [parentId]. Connecté à
  /// `photosControllerProvider(entityType, parentId)`.
  class PhotoGalleryEditor extends ConsumerWidget {
    const PhotoGalleryEditor({
      super.key,
      required this.entityType,
      required this.parentId,
    });

    final EntityType entityType;
    final String parentId;

    static const int _maxPhotos = 5;

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final provider = photosControllerProvider(entityType, parentId);
      final asyncPhotos = ref.watch(provider);

      return asyncPhotos.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, _) => _ErrorState(
          message: 'Erreur de chargement : $err',
          onRetry: () => ref.read(provider.notifier).refresh(),
        ),
        data: (photos) {
          if (photos.isEmpty) {
            return _EmptyState(
              onAdd: () => _pickAndUpload(context, ref),
              entityType: entityType,
            );
          }
          return _GalleryGrid(
            photos: photos,
            canAddMore: photos.length < _maxPhotos,
            onAdd: () => _pickAndUpload(context, ref),
            onReorder: (ids) =>
                ref.read(provider.notifier).reorder(ids),
            onSetCover: (id) async {
              try {
                await ref.read(provider.notifier).setCover(id);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur cover : $e')),
                  );
                }
              }
            },
            onEditAlt: (photo) => _showEditAltDialog(context, ref, photo),
            onDelete: (photo) => _confirmDelete(context, ref, photo),
          );
        },
      );
    }

    Future<void> _pickAndUpload(BuildContext context, WidgetRef ref) async {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;

      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Upload en cours…'),
          duration: Duration(seconds: 60),
        ),
      );

      try {
        await ref
            .read(photosControllerProvider(entityType, parentId).notifier)
            .add(file);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(const SnackBar(content: Text('Photo ajoutée')));
      } catch (e) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(SnackBar(content: Text('Erreur upload : $e')));
      }
    }

    Future<void> _showEditAltDialog(
      BuildContext context,
      WidgetRef ref,
      Photo photo,
    ) async {
      final controller = TextEditingController(text: photo.alt ?? '');
      final result = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Description (alt)'),
          content: TextField(
            controller: controller,
            maxLength: 200,
            decoration: const InputDecoration(
              hintText: 'Décrivez la photo',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      );
      if (result == null) return;
      try {
        await ref
            .read(photosControllerProvider(entityType, parentId).notifier)
            .editAlt(photo.id, result);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur édition alt : $e')),
          );
        }
      }
    }

    Future<void> _confirmDelete(
      BuildContext context,
      WidgetRef ref,
      Photo photo,
    ) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Supprimer cette photo ?'),
          content: const Text('Cette action est définitive.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      try {
        await ref
            .read(photosControllerProvider(entityType, parentId).notifier)
            .delete(photo.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur suppression : $e')),
          );
        }
      }
    }
  }

  class _EmptyState extends StatelessWidget {
    const _EmptyState({required this.onAdd, required this.entityType});

    final VoidCallback onAdd;
    final EntityType entityType;

    @override
    Widget build(BuildContext context) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Aucune photo pour l\'instant',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                'Ajoutez la première photo de ce ${entityType.label}.',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Ajouter la première'),
              ),
            ],
          ),
        ),
      );
    }
  }

  class _ErrorState extends StatelessWidget {
    const _ErrorState({required this.message, required this.onRetry});

    final String message;
    final VoidCallback onRetry;

    @override
    Widget build(BuildContext context) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      );
    }
  }

  class _GalleryGrid extends StatelessWidget {
    const _GalleryGrid({
      required this.photos,
      required this.canAddMore,
      required this.onAdd,
      required this.onReorder,
      required this.onSetCover,
      required this.onEditAlt,
      required this.onDelete,
    });

    final List<Photo> photos;
    final bool canAddMore;
    final VoidCallback onAdd;
    final ValueChanged<List<String>> onReorder;
    final ValueChanged<String> onSetCover;
    final ValueChanged<Photo> onEditAlt;
    final ValueChanged<Photo> onDelete;

    @override
    Widget build(BuildContext context) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${photos.length} / 5 photos',
                    style: Theme.of(context).textTheme.titleSmall),
                Tooltip(
                  message: canAddMore
                      ? 'Ajouter une photo'
                      : 'Maximum 5 atteint',
                  child: FilledButton.icon(
                    onPressed: canAddMore ? onAdd : null,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('Ajouter'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: photos.length,
              onReorderItem: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex--;
                final ids = photos.map((p) => p.id).toList();
                final moved = ids.removeAt(oldIndex);
                ids.insert(newIndex, moved);
                onReorder(ids);
              },
              itemBuilder: (context, index) {
                final photo = photos[index];
                return _PhotoTile(
                  key: ValueKey(photo.id),
                  photo: photo,
                  onSetCover: () => onSetCover(photo.id),
                  onEditAlt: () => onEditAlt(photo),
                  onDelete: () => onDelete(photo),
                );
              },
            ),
          ),
        ],
      );
    }
  }

  class _PhotoTile extends StatelessWidget {
    const _PhotoTile({
      super.key,
      required this.photo,
      required this.onSetCover,
      required this.onEditAlt,
      required this.onDelete,
    });

    final Photo photo;
    final VoidCallback onSetCover;
    final VoidCallback onEditAlt;
    final VoidCallback onDelete;

    @override
    Widget build(BuildContext context) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Stack(
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: Image.network(
                    photo.url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, size: 32),
                    ),
                  ),
                ),
                if (photo.isCover)
                  const Positioned(
                    top: 6,
                    left: 6,
                    child: Icon(Icons.star, color: Colors.amber, size: 24),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      photo.alt?.isNotEmpty == true ? photo.alt! : '(sans alt)',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ordre ${photo.displayOrder}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          tooltip: photo.isCover ? 'Cover actuel' : 'Définir cover',
                          icon: Icon(
                            photo.isCover ? Icons.star : Icons.star_outline,
                            color: photo.isCover ? Colors.amber : null,
                          ),
                          onPressed: photo.isCover ? null : onSetCover,
                        ),
                        IconButton(
                          tooltip: 'Éditer description',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: onEditAlt,
                        ),
                        IconButton(
                          tooltip: 'Supprimer',
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: onDelete,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.drag_handle, color: Colors.grey),
            ),
          ],
        ),
      );
    }
  }
  ```

  Note : la consigne de spec mentionne une grille responsive (2 cols mobile / 5 desktop). Pour simplifier et rester cohérent avec le pattern banners utilisé partout dans l'admin (qui est `ReorderableListView` vertical), on reste sur une liste verticale avec tiles larges. Les écrans admin Flutter sont conçus pour mobile prioritairement ; la grille responsive est implémentée côté web (Phase G) où le desktop est central.

#### D2. Créer l'écran `lib/features/photos/presentation/screens/photos_screen.dart`

- [ ] Contenu :

  ```dart
  import 'package:flutter/material.dart';

  import '../../../../common_widgets/photo_gallery_editor.dart';
  import '../../data/photo_models.dart';

  /// Écran dédié à la gestion des photos d'une entité.
  /// Reçoit `entityType` (string brute issue de la query) + `parentId`.
  class PhotosScreen extends StatelessWidget {
    const PhotosScreen({
      super.key,
      required this.entityTypeString,
      required this.parentId,
    });

    final String entityTypeString;
    final String parentId;

    @override
    Widget build(BuildContext context) {
      final EntityType entityType;
      try {
        entityType = EntityTypeX.fromString(entityTypeString);
      } catch (_) {
        return Scaffold(
          appBar: AppBar(title: const Text('Photos')),
          body: const Center(
            child: Text('Type d\'entité inconnu.'),
          ),
        );
      }

      return Scaffold(
        appBar: AppBar(
          title: Text('Photos · ${entityType.label}'),
          centerTitle: true,
        ),
        body: PhotoGalleryEditor(
          entityType: entityType,
          parentId: parentId,
        ),
      );
    }
  }
  ```

#### D3. Vérification

- [ ] Analyser :
  ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-admin && flutter analyze lib/common_widgets lib/features/photos
  ```
- [ ] Aucune erreur attendue.

#### D4. Commit phase D

- [ ] Stage :
  ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-admin && git add lib/common_widgets/ lib/features/photos/presentation/
  ```
- [ ] Commit :
  ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-admin && git commit -m "$(cat <<'EOF'
  feat(photos): widget PhotoGalleryEditor + PhotosScreen

  Widget réutilisable connecté à photosControllerProvider :
  ReorderableListView avec tiles photo (image, badge cover, alt, actions
  set cover / edit alt / delete). Bouton "Ajouter" désactivé à 5 photos
  avec tooltip. Snackbars pour feedback upload/erreurs.

  PhotosScreen wrap le widget et lit entityType + parentId depuis les
  paramètres de route. Branchement à go_router en Phase E.
  EOF
  )"
  ```

---

## Phase E — Flutter : entry points

**Objectif :** ajouter le bouton "Photos" depuis chaque form (product, menu) et depuis l'écran restaurant accessible au RESTAURATEUR (settings) + un point d'entrée ADMIN pour les autres restaurants. Déclarer la route `/photos` dans `app_router.dart`.

### Tâches

#### E1. Explorer le code pour trouver les bons fichiers

L'implémenteur doit lancer ces commandes AVANT de coder, pour vérifier l'état réel du repo :

- [ ] ```bash
  grep -rln "RESTAURATEUR" /Users/henokmipoks/Desktop/code/lilia-food-admin/lib/features/home /Users/henokmipoks/Desktop/code/lilia-food-admin/lib/features/restaurant 2>/dev/null
  ```
- [ ] ```bash
  find /Users/henokmipoks/Desktop/code/lilia-food-admin/lib -name "*router*" -o -name "*routes*"
  ```
- [ ] ```bash
  ls /Users/henokmipoks/Desktop/code/lilia-food-admin/lib/features/admin/presentation/screens
  ```

Constats attendus (à confirmer par les commandes) :
- Il n'existe **pas** de fichier `admin_vendors_screen.dart` aujourd'hui. Le spec mentionne ce fichier mais on ne va pas l'inventer juste pour ce chantier (hors scope E2). L'entrée ADMIN se fait via la même route `/photos?entityType=vendor&parentId=:id` qu'il faudra atteindre depuis l'écran de création/listing restaurant existant (`create_restaurant_screen.dart`) OU via un appel direct (l'ADMIN peut taper l'URL ou utiliser le repo web pour ce cas). **À confirmer si l'utilisateur veut absolument un bouton dans l'admin Flutter ; sinon l'ADMIN passera principalement par l'admin web.**
- Le RESTAURATEUR n'a pas non plus de "home restaurant" dédiée — sa fiche se gère via `settings_screen.dart` (tab Général). On ajoute le bouton "Gérer les photos du restaurant" dans le `_GeneralInfoTab` du settings.
- Le routeur est `lib/routing/app_router.dart` (go_router avec `@riverpod GoRouter router(Ref ref)`).

#### E2. Ajouter la route `/photos` dans `lib/routing/app_router.dart`

- [ ] Ajouter l'import en haut du fichier (sous les autres imports `lilia_admin/features/...`) :
  ```dart
  import 'package:lilia_admin/features/photos/presentation/screens/photos_screen.dart';
  ```
- [ ] Ajouter une `GoRoute` plein écran (hors bottom nav) au même niveau que `/deliverers/:id`. Insérer après la route `/deliveries/:orderId/tracking` et avant le `StatefulShellRoute.indexedStack`. Le contenu à insérer :
  ```dart
        GoRoute(
          path: '/photos',
          name: 'photos',
          pageBuilder: (context, state) {
            final entityType = state.uri.queryParameters['entityType'];
            final parentId = state.uri.queryParameters['parentId'];
            if (entityType == null || parentId == null || parentId.isEmpty) {
              return MaterialPage(
                child: _MissingRouteDataScreen(
                  title: 'Photos indisponibles',
                  message: 'Paramètres manquants pour afficher la galerie.',
                  backRouteName: 'dashboard',
                ),
              );
            }
            return MaterialPage(
              child: PhotosScreen(
                entityTypeString: entityType,
                parentId: parentId,
              ),
            );
          },
        ),
  ```
- [ ] Vérifier :
  ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-admin && flutter analyze lib/routing
  ```

#### E3. Ajouter le bouton "Photos" dans `product_form_screen.dart`

- [ ] Le bouton doit être visible **uniquement en mode édition** (i.e. quand `widget.product != null` ou variable équivalente).
- [ ] Ouvrir le fichier et :
  ```bash
  grep -n "widget.product\|isEditing\|_isEditing\|AppBar(" /Users/henokmipoks/Desktop/code/lilia-food-admin/lib/features/products/presentation/screens/product_form_screen.dart | head -20
  ```
  pour repérer le flag d'édition + la zone AppBar.
- [ ] Ajouter l'import :
  ```dart
  import 'package:go_router/go_router.dart';
  ```
- [ ] Dans le `appBar: AppBar(...)`, ajouter une `actions:` (créer le champ s'il n'existe pas) avec :
  ```dart
        actions: [
          if (widget.product != null)
            IconButton(
              tooltip: 'Gérer les photos',
              icon: const Icon(Icons.photo_library_outlined),
              onPressed: () => context.goNamed(
                'photos',
                queryParameters: {
                  'entityType': 'product',
                  'parentId': widget.product!.id,
                },
              ),
            ),
        ],
  ```
  Adapter `widget.product` / `widget.product!.id` au nom réel du flag (cf. grep). Si le form est `ConsumerStatefulWidget` et que la prop est nommée `product`, ces refs marchent telles quelles.

#### E4. Ajouter le bouton "Photos" dans `menu_form_screen.dart`

- [ ] Cf. fichier déjà connu : `widget.menu` est le flag d'édition (`isEditing => widget.menu != null` à la ligne 31).
- [ ] Ajouter l'import :
  ```dart
  import 'package:go_router/go_router.dart';
  ```
- [ ] Dans `appBar: AppBar(...)`, ajouter `actions:` :
  ```dart
        actions: [
          if (isEditing)
            IconButton(
              tooltip: 'Gérer les photos',
              icon: const Icon(Icons.photo_library_outlined),
              onPressed: () => context.goNamed(
                'photos',
                queryParameters: {
                  'entityType': 'menu',
                  'parentId': widget.menu!.id,
                },
              ),
            ),
        ],
  ```

#### E5. Ajouter le bouton "Photos" dans `settings_screen.dart` (tab Général, pour le RESTAURATEUR)

- [ ] Le tab `_GeneralInfoTab` reçoit `restaurant` en paramètre. Le bouton doit pointer vers `/photos?entityType=vendor&parentId=${restaurant.id}`.
- [ ] Localiser une zone de boutons d'action dans `_GeneralInfoTabState.build` (typiquement avant ou après le bouton "Enregistrer") :
  ```bash
  grep -n "Enregistrer\|FilledButton\|ElevatedButton" /Users/henokmipoks/Desktop/code/lilia-food-admin/lib/features/settings/presentation/screens/settings_screen.dart | head -20
  ```
- [ ] Si `go_router` n'est pas déjà importé en haut du fichier, ajouter :
  ```dart
  import 'package:go_router/go_router.dart';
  ```
- [ ] Insérer juste après le titre/section image (où l'image actuelle est éditée) un `OutlinedButton.icon` :
  ```dart
        OutlinedButton.icon(
          onPressed: () => context.goNamed(
            'photos',
            queryParameters: {
              'entityType': 'vendor',
              'parentId': widget.restaurant.id,
            },
          ),
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Gérer la galerie photos du restaurant'),
        ),
        const SizedBox(height: 16),
  ```
- [ ] Placement précis : juste sous le champ `imageUrl` actuel (cherche `imageUrl` dans la fonction `_buildGeneralTab` / `_GeneralInfoTabState`). L'objectif est que l'utilisateur voie clairement que la galerie complète l'image principale.

#### E6. Point d'entrée ADMIN (optionnel/partiel)

L'admin Flutter n'a pas d'écran "liste de tous les restaurants" aujourd'hui. Pour ce chantier, on accepte que l'ADMIN passe par l'admin web (Phase H) pour gérer les photos restaurant d'un vendor donné. Aucune modification supplémentaire requise pour l'ADMIN dans Flutter.

Si l'utilisateur veut un point d'entrée ADMIN Flutter en plus, c'est à confirmer hors chantier E2 (créer un `admin_vendors_screen.dart` est un sous-projet à part).

#### E7. Vérification

- [ ] ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-admin && flutter analyze
  ```
- [ ] Smoke test manuel :
  - Lancer l'app : `flutter run`
  - Login RESTAURATEUR → onglet Settings → tab Général → bouton "Gérer la galerie photos du restaurant" → arrive sur l'écran photos.
  - Aller dans Produits → éditer un produit → icône appareil photo dans l'AppBar → arrive sur l'écran photos avec entityType=product.
  - Idem Menus.
- [ ] Documenter les éventuels écarts visuels dans le commit.

#### E8. Commit phase E

- [ ] Stage :
  ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-admin && git add lib/routing/app_router.dart lib/features/products/presentation/screens/product_form_screen.dart lib/features/menus/presentation/screens/menu_form_screen.dart lib/features/settings/presentation/screens/settings_screen.dart
  ```
- [ ] Commit :
  ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-admin && git commit -m "$(cat <<'EOF'
  feat(photos): entry points produit / menu / restaurant

  Ajoute la route plein écran /photos?entityType=...&parentId=... dans
  app_router.dart, et un bouton/icone "Photos" :
  - product_form_screen : action AppBar visible en mode édition
  - menu_form_screen : action AppBar visible en mode édition
  - settings_screen (tab Général) : bouton outlined sous l'image
    principale, accessible au RESTAURATEUR pour sa propre fiche
  EOF
  )"
  ```

---

## Phase F — Web : branche + shared packages

**Objectif :** couper la branche `hmipoka/photo-galleries-admin` sur `lilia-food-web`, étendre `@lilia/types` avec `Photo`/`EntityType` et créer le hook React Query factory `photos.ts`.

### Tâches

#### F1. Vérifier l'état du repo web et couper la branche

- [ ] Vérifier la branche par défaut du remote :
  ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-web && git remote show origin | grep "HEAD branch"
  ```
  (résultat attendu : `master` — confirmé lors de la planification ; si le résultat diffère, utiliser la branche signalée pour les commandes ci-dessous.)
- [ ] Fetcher + couper la branche depuis master :
  ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-web && git fetch origin && git checkout -b hmipoka/photo-galleries-admin origin/master
  ```
- [ ] Vérifier la propreté du working tree :
  ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-web && git status
  ```

#### F2. Étendre `packages/types/src/index.ts`

- [ ] Ouvrir le fichier ; il commence par `// --- Enums ---`.
- [ ] À la fin du fichier (après les types existants), ajouter une nouvelle section :

  ```typescript

  // --- Photo Galleries (E1/E2) ---
  // Trois entités backend (vendor-photos, product-images, menu-images)
  // partagent un shape identique côté API → un seul type Photo + un
  // discriminant EntityType.

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

  // Aliases pour clarifier les call sites quand l'entité est connue.
  export type VendorPhoto = Photo & { restaurantId: string };
  export type ProductImage = Photo & { productId: string };
  export type MenuImage = Photo & { menuDuJourId: string };
  ```

- [ ] Vérifier que rien ne casse :
  ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-web && pnpm --filter @lilia/types run type-check 2>/dev/null || pnpm --filter admin run type-check
  ```
  (Si la première commande échoue parce que `@lilia/types` n'a pas de script `type-check`, c'est OK — le typage sera validé en Phase H avec le build admin.)

#### F3. Créer `packages/api-client/src/hooks/photos.ts`

- [ ] Le pattern à suivre est `favorites.ts` (chargé dans le plan). Le fichier complet :

  ```typescript
  'use client';

  import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
  import type { EntityType, Photo } from '@lilia/types';
  import { apiClient } from '../client';

  const endpoints: Record<EntityType, string> = {
    vendor: '/vendor-photos',
    product: '/product-images',
    menu: '/menu-images',
  };

  const parentFields: Record<EntityType, string> = {
    vendor: 'restaurantId',
    product: 'productId',
    menu: 'menuDuJourId',
  };

  export const photoKeys = {
    all: ['photos'] as const,
    list: (entity: EntityType, parentId: string) =>
      ['photos', entity, parentId] as const,
  };

  /**
   * Liste publique des photos d'une entité. Le backend ne requiert pas de
   * token mais on le passe quand il est dispo pour rester cohérent.
   */
  export function usePhotos(
    entity: EntityType,
    parentId: string,
    token: string | null,
  ) {
    return useQuery({
      queryKey: photoKeys.list(entity, parentId),
      queryFn: () =>
        apiClient<Photo[]>(
          `${endpoints[entity]}?${parentFields[entity]}=${parentId}`,
          { token },
        ),
      enabled: !!parentId,
      staleTime: 30 * 1000,
    });
  }

  type UploadPayload = {
    url: string;
    publicId: string;
    alt?: string;
    isCover?: boolean;
  };

  /**
   * POST création. Le caller fait l'upload Cloudinary séparément (cf.
   * apps/admin/lib/cloudinary-upload.ts) puis passe url + publicId ici.
   */
  export function useUploadPhoto(
    entity: EntityType,
    parentId: string,
    token: string | null,
  ) {
    const queryClient = useQueryClient();
    return useMutation({
      mutationFn: (payload: UploadPayload) =>
        apiClient<Photo>(endpoints[entity], {
          method: 'POST',
          token,
          body: {
            [parentFields[entity]]: parentId,
            url: payload.url,
            publicId: payload.publicId,
            ...(payload.alt !== undefined ? { alt: payload.alt } : {}),
            isCover: payload.isCover ?? false,
          },
        }),
      onSuccess: () => {
        void queryClient.invalidateQueries({
          queryKey: photoKeys.list(entity, parentId),
        });
      },
    });
  }

  type UpdatePayload = {
    photoId: string;
    alt?: string;
    isCover?: boolean;
    displayOrder?: number;
  };

  /**
   * PATCH /:id. Optimistic : si isCover passe à true, on démet les autres
   * covers en local avant l'appel API ; rollback en cas d'erreur.
   */
  export function useUpdatePhoto(
    entity: EntityType,
    parentId: string,
    token: string | null,
  ) {
    const queryClient = useQueryClient();
    const key = photoKeys.list(entity, parentId);
    return useMutation({
      mutationFn: ({ photoId, ...patch }: UpdatePayload) =>
        apiClient<Photo>(`${endpoints[entity]}/${photoId}`, {
          method: 'PATCH',
          token,
          body: patch,
        }),
      onMutate: async ({ photoId, alt, isCover }) => {
        await queryClient.cancelQueries({ queryKey: key });
        const previous = queryClient.getQueryData<Photo[]>(key);
        queryClient.setQueryData<Photo[]>(key, (old = []) =>
          old.map((p) => {
            if (p.id === photoId) {
              return {
                ...p,
                ...(alt !== undefined ? { alt } : {}),
                ...(isCover !== undefined ? { isCover } : {}),
              };
            }
            if (isCover === true) {
              return { ...p, isCover: false };
            }
            return p;
          }),
        );
        return { previous };
      },
      onError: (_err, _vars, ctx) => {
        if (ctx?.previous) queryClient.setQueryData(key, ctx.previous);
      },
      onSettled: () => {
        void queryClient.invalidateQueries({ queryKey: key });
      },
    });
  }

  /**
   * DELETE /:id. Optimistic remove + rollback en cas d'erreur.
   */
  export function useDeletePhoto(
    entity: EntityType,
    parentId: string,
    token: string | null,
  ) {
    const queryClient = useQueryClient();
    const key = photoKeys.list(entity, parentId);
    return useMutation({
      mutationFn: (photoId: string) =>
        apiClient<void>(`${endpoints[entity]}/${photoId}`, {
          method: 'DELETE',
          token,
        }),
      onMutate: async (photoId) => {
        await queryClient.cancelQueries({ queryKey: key });
        const previous = queryClient.getQueryData<Photo[]>(key);
        queryClient.setQueryData<Photo[]>(key, (old = []) =>
          old.filter((p) => p.id !== photoId),
        );
        return { previous };
      },
      onError: (_err, _vars, ctx) => {
        if (ctx?.previous) queryClient.setQueryData(key, ctx.previous);
      },
      onSettled: () => {
        void queryClient.invalidateQueries({ queryKey: key });
      },
    });
  }

  /**
   * POST /reorder. Reçoit la liste d'IDs ordonnée. Optimistic : réécrit
   * `displayOrder` localement.
   */
  export function useReorderPhotos(
    entity: EntityType,
    parentId: string,
    token: string | null,
  ) {
    const queryClient = useQueryClient();
    const key = photoKeys.list(entity, parentId);
    return useMutation({
      mutationFn: (ids: string[]) =>
        apiClient<void>(`${endpoints[entity]}/reorder`, {
          method: 'POST',
          token,
          body: { [parentFields[entity]]: parentId, ids },
        }),
      onMutate: async (ids) => {
        await queryClient.cancelQueries({ queryKey: key });
        const previous = queryClient.getQueryData<Photo[]>(key);
        const byId = new Map((previous ?? []).map((p) => [p.id, p]));
        const next: Photo[] = ids
          .map((id, idx) => {
            const existing = byId.get(id);
            if (!existing) return null;
            return { ...existing, displayOrder: idx };
          })
          .filter((p): p is Photo => p !== null);
        queryClient.setQueryData<Photo[]>(key, next);
        return { previous };
      },
      onError: (_err, _vars, ctx) => {
        if (ctx?.previous) queryClient.setQueryData(key, ctx.previous);
      },
      onSettled: () => {
        void queryClient.invalidateQueries({ queryKey: key });
      },
    });
  }
  ```

  Note importante : la signature exacte de `apiClient` (`{ method, token, body }` vs autre) doit être confirmée en lisant `packages/api-client/src/client.ts` avant d'écrire le fichier. Le pattern ci-dessus suit `favorites.ts` qui utilise `{ method: 'DELETE', token }` et `{ method: 'POST', token }` ; pour le body, vérifier comment d'autres hooks le passent (e.g. `useCreate*` dans `orders.ts` ou `products.ts`). Adapter le shape `body:` si nécessaire (par exemple `body: JSON.stringify(...)` ou option `json:` ou autre).

  Si `apiClient` n'accepte pas `body` directement, suivre le pattern utilisé dans le hook le plus proche (`hooks/orders.ts` ou `hooks/products.ts`).

#### F4. Ré-exporter le hook depuis `packages/api-client/src/index.ts`

- [ ] Ajouter la ligne à la suite des autres exports :
  ```typescript
  export * from './hooks/photos';
  ```

#### F5. Vérification + commit

- [ ] Type check du package admin (qui consomme `@lilia/types` et `@lilia/api-client`) :
  ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-web && pnpm --filter admin run type-check
  ```
- [ ] Si erreur sur la signature `apiClient`, lire `packages/api-client/src/client.ts` et corriger `photos.ts`.
- [ ] Stage :
  ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-web && git add packages/types/src/index.ts packages/api-client/src/hooks/photos.ts packages/api-client/src/index.ts
  ```
- [ ] Commit :
  ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-web && git commit -m "$(cat <<'EOF'
  feat(photos): types Photo/EntityType + hooks React Query

  packages/types : ajout Photo, EntityType ('vendor'|'product'|'menu') et
  alias VendorPhoto/ProductImage/MenuImage.

  packages/api-client/hooks/photos : 5 hooks (usePhotos, useUploadPhoto,
  useUpdatePhoto, useDeletePhoto, useReorderPhotos) qui dispatchent vers
  /vendor-photos, /product-images ou /menu-images selon EntityType.
  Optimistic update + rollback sur update/delete/reorder, calqué sur le
  pattern useToggleFavorite.
  EOF
  )"
  ```

---

## Phase G — Web : composants admin

**Objectif :** créer l'utility Cloudinary, installer @dnd-kit, et créer le composant React `PhotoGalleryEditor` complet (grille responsive, drag-and-drop, file input upload).

### Tâches

#### G1. Vérifier le filter name + dépendances déjà présentes

- [ ] ```bash
  cat /Users/henokmipoks/Desktop/code/lilia-food-web/apps/admin/package.json | grep '"name"'
  ```
  Résultat attendu : `"name": "admin"` (et non `@lilia/admin`). Donc le filter est `admin`, pas `@lilia/admin`.
- [ ] Vérifier que `sonner` est déjà dans les deps (toast lib) :
  ```bash
  grep -E '"sonner"|"react-dropzone"' /Users/henokmipoks/Desktop/code/lilia-food-web/apps/admin/package.json
  ```
  `sonner` est attendu présent (confirmé).

#### G2. Installer @dnd-kit

- [ ] ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-web && pnpm add @dnd-kit/core @dnd-kit/sortable @dnd-kit/utilities --filter admin
  ```
- [ ] Vérifier que `apps/admin/package.json` contient bien les 3 nouvelles deps.

#### G3. Créer `apps/admin/.env.example`

- [ ] Vérifier s'il existe :
  ```bash
  ls /Users/henokmipoks/Desktop/code/lilia-food-web/apps/admin/.env.example 2>/dev/null
  ```
- [ ] S'il n'existe pas, le créer avec :
  ```
  # API
  NEXT_PUBLIC_API_URL=https://lilia-backend.onrender.com

  # Cloudinary (unsigned upload — pas de secret)
  NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME=dun9ev7pw
  NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET=ml_default
  ```
- [ ] S'il existe déjà, n'ajouter QUE les deux dernières lignes Cloudinary (préserver le reste). À vérifier avec `grep`.

#### G4. Créer `apps/admin/lib/cloudinary-upload.ts`

- [ ] Le dossier `apps/admin/lib/` existe déjà (vu dans l'inspection initiale).
- [ ] Contenu :

  ```typescript
  /**
   * Upload direct vers Cloudinary via unsigned preset. Pas de secret côté
   * client — `upload_preset` et `cloud_name` sont publics. Capture le
   * `public_id` retourné par Cloudinary pour permettre le cleanup backend
   * au DELETE.
   */
  export type CloudinaryUploadResult = {
    secureUrl: string;
    publicId: string;
  };

  export async function uploadToCloudinary(file: File): Promise<CloudinaryUploadResult> {
    const cloudName = process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME;
    const uploadPreset = process.env.NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET;

    if (!cloudName || !uploadPreset) {
      throw new Error(
        'Cloudinary env vars manquantes : NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME / NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET',
      );
    }

    const formData = new FormData();
    formData.append('file', file);
    formData.append('upload_preset', uploadPreset);

    const res = await fetch(
      `https://api.cloudinary.com/v1_1/${cloudName}/image/upload`,
      {
        method: 'POST',
        body: formData,
      },
    );

    if (!res.ok) {
      const text = await res.text();
      throw new Error(`Cloudinary upload failed (${res.status}): ${text}`);
    }

    const data = (await res.json()) as { secure_url: string; public_id: string };
    return {
      secureUrl: data.secure_url,
      publicId: data.public_id,
    };
  }
  ```

#### G5. Créer `apps/admin/components/photo-gallery-editor.tsx`

- [ ] Le composant : Client component, grille responsive `grid-cols-2 md:grid-cols-3 lg:grid-cols-5`, dnd-kit pour le drag, file input via `<input type=file>` (pas de drag-drop fichier pour rester simple), badge cover étoile, actions per-tile.
- [ ] Contenu :

  ```tsx
  'use client';

  import { useRef, useState } from 'react';
  import {
    DndContext,
    closestCenter,
    KeyboardSensor,
    PointerSensor,
    TouchSensor,
    useSensor,
    useSensors,
    type DragEndEvent,
  } from '@dnd-kit/core';
  import {
    SortableContext,
    arrayMove,
    rectSortingStrategy,
    sortableKeyboardCoordinates,
    useSortable,
  } from '@dnd-kit/sortable';
  import { CSS } from '@dnd-kit/utilities';
  import {
    usePhotos,
    useUploadPhoto,
    useUpdatePhoto,
    useDeletePhoto,
    useReorderPhotos,
  } from '@lilia/api-client';
  import type { EntityType, Photo } from '@lilia/types';
  import { toast } from 'sonner';
  import { Loader2, Star, Trash2, Pencil, Plus } from 'lucide-react';
  import { uploadToCloudinary } from '@/lib/cloudinary-upload';

  const MAX_PHOTOS = 5;

  type Props = {
    entity: EntityType;
    parentId: string;
    token: string | null;
  };

  export function PhotoGalleryEditor({ entity, parentId, token }: Props) {
    const photosQuery = usePhotos(entity, parentId, token);
    const upload = useUploadPhoto(entity, parentId, token);
    const update = useUpdatePhoto(entity, parentId, token);
    const remove = useDeletePhoto(entity, parentId, token);
    const reorder = useReorderPhotos(entity, parentId, token);

    const fileInputRef = useRef<HTMLInputElement>(null);
    const [isUploading, setIsUploading] = useState(false);

    const sensors = useSensors(
      useSensor(PointerSensor, { activationConstraint: { distance: 5 } }),
      useSensor(TouchSensor, { activationConstraint: { delay: 150, tolerance: 5 } }),
      useSensor(KeyboardSensor, { coordinateGetter: sortableKeyboardCoordinates }),
    );

    const photos = (photosQuery.data ?? []).slice().sort(
      (a, b) => a.displayOrder - b.displayOrder,
    );
    const atMax = photos.length >= MAX_PHOTOS;

    async function handleFile(file: File | null) {
      if (!file) return;
      if (atMax) {
        toast.error(`Maximum ${MAX_PHOTOS} photos atteint`);
        return;
      }
      setIsUploading(true);
      try {
        const { secureUrl, publicId } = await uploadToCloudinary(file);
        await upload.mutateAsync({
          url: secureUrl,
          publicId,
          isCover: photos.length === 0, // premier upload = cover
        });
        toast.success('Photo ajoutée');
      } catch (err) {
        const msg = err instanceof Error ? err.message : 'Erreur upload';
        toast.error(msg);
      } finally {
        setIsUploading(false);
        if (fileInputRef.current) fileInputRef.current.value = '';
      }
    }

    function handleDragEnd(event: DragEndEvent) {
      const { active, over } = event;
      if (!over || active.id === over.id) return;
      const oldIndex = photos.findIndex((p) => p.id === active.id);
      const newIndex = photos.findIndex((p) => p.id === over.id);
      if (oldIndex < 0 || newIndex < 0) return;
      const next = arrayMove(photos, oldIndex, newIndex);
      reorder.mutate(next.map((p) => p.id), {
        onError: (err) => {
          const msg = err instanceof Error ? err.message : 'Erreur reorder';
          toast.error(msg);
        },
      });
    }

    async function handleSetCover(photo: Photo) {
      if (photo.isCover) return;
      try {
        await update.mutateAsync({ photoId: photo.id, isCover: true });
        toast.success('Cover mis à jour');
      } catch (err) {
        const msg = err instanceof Error ? err.message : 'Erreur cover';
        toast.error(msg);
      }
    }

    async function handleEditAlt(photo: Photo) {
      const alt = window.prompt('Description de la photo (alt) :', photo.alt ?? '');
      if (alt === null) return;
      try {
        await update.mutateAsync({ photoId: photo.id, alt: alt.trim() });
        toast.success('Description mise à jour');
      } catch (err) {
        const msg = err instanceof Error ? err.message : 'Erreur alt';
        toast.error(msg);
      }
    }

    async function handleDelete(photo: Photo) {
      if (!window.confirm('Supprimer cette photo ? Cette action est définitive.')) return;
      try {
        await remove.mutateAsync(photo.id);
        toast.success('Photo supprimée');
      } catch (err) {
        const msg = err instanceof Error ? err.message : 'Erreur suppression';
        toast.error(msg);
      }
    }

    if (photosQuery.isLoading) {
      return (
        <div className="grid grid-cols-2 gap-3 md:grid-cols-3 lg:grid-cols-5">
          {Array.from({ length: 4 }).map((_, i) => (
            <div
              key={i}
              className="aspect-square animate-pulse rounded-md bg-neutral-100"
            />
          ))}
        </div>
      );
    }

    if (photosQuery.isError) {
      return (
        <div className="flex flex-col items-center gap-3 rounded-md border border-dashed p-6 text-sm">
          <p>Erreur de chargement de la galerie.</p>
          <button
            type="button"
            onClick={() => photosQuery.refetch()}
            className="rounded-md border px-3 py-1 text-sm"
          >
            Réessayer
          </button>
        </div>
      );
    }

    return (
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <p className="text-sm text-neutral-600">
            {photos.length} / {MAX_PHOTOS} photos
          </p>
          <button
            type="button"
            onClick={() => fileInputRef.current?.click()}
            disabled={atMax || isUploading}
            className="inline-flex items-center gap-2 rounded-md bg-neutral-900 px-3 py-1.5 text-sm font-medium text-white disabled:cursor-not-allowed disabled:opacity-50"
            title={atMax ? 'Maximum 5 atteint' : 'Ajouter une photo'}
          >
            {isUploading ? <Loader2 className="size-4 animate-spin" /> : <Plus className="size-4" />}
            Ajouter
          </button>
          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            className="hidden"
            onChange={(e) => handleFile(e.target.files?.[0] ?? null)}
          />
        </div>

        {photos.length === 0 ? (
          <div className="rounded-md border border-dashed p-8 text-center text-sm text-neutral-500">
            Aucune photo pour l'instant.
          </div>
        ) : (
          <DndContext
            sensors={sensors}
            collisionDetection={closestCenter}
            onDragEnd={handleDragEnd}
          >
            <SortableContext items={photos.map((p) => p.id)} strategy={rectSortingStrategy}>
              <div className="grid grid-cols-2 gap-3 md:grid-cols-3 lg:grid-cols-5">
                {photos.map((photo) => (
                  <SortablePhotoTile
                    key={photo.id}
                    photo={photo}
                    onSetCover={() => handleSetCover(photo)}
                    onEditAlt={() => handleEditAlt(photo)}
                    onDelete={() => handleDelete(photo)}
                  />
                ))}
              </div>
            </SortableContext>
          </DndContext>
        )}
      </div>
    );
  }

  type TileProps = {
    photo: Photo;
    onSetCover: () => void;
    onEditAlt: () => void;
    onDelete: () => void;
  };

  function SortablePhotoTile({ photo, onSetCover, onEditAlt, onDelete }: TileProps) {
    const { attributes, listeners, setNodeRef, transform, transition, isDragging } =
      useSortable({ id: photo.id });

    const style = {
      transform: CSS.Transform.toString(transform),
      transition,
      opacity: isDragging ? 0.5 : 1,
    };

    return (
      <div
        ref={setNodeRef}
        style={style}
        className="group relative overflow-hidden rounded-md border bg-white"
      >
        <div
          {...attributes}
          {...listeners}
          className="aspect-square w-full cursor-grab bg-neutral-100"
        >
          { /* eslint-disable-next-line @next/next/no-img-element */ }
          <img
            src={photo.url}
            alt={photo.alt ?? ''}
            className="size-full object-cover"
            draggable={false}
          />
        </div>
        {photo.isCover && (
          <div className="absolute left-2 top-2 rounded-full bg-amber-500/90 p-1 text-white shadow">
            <Star className="size-4 fill-white" />
          </div>
        )}
        <div className="flex items-center justify-between gap-1 border-t bg-white p-1.5">
          <button
            type="button"
            onClick={onSetCover}
            disabled={photo.isCover}
            title={photo.isCover ? 'Cover actuel' : 'Définir comme cover'}
            className="rounded p-1 hover:bg-neutral-100 disabled:cursor-default disabled:opacity-50"
          >
            <Star
              className={`size-4 ${photo.isCover ? 'fill-amber-400 text-amber-500' : 'text-neutral-500'}`}
            />
          </button>
          <button
            type="button"
            onClick={onEditAlt}
            title="Éditer la description"
            className="rounded p-1 text-neutral-500 hover:bg-neutral-100"
          >
            <Pencil className="size-4" />
          </button>
          <button
            type="button"
            onClick={onDelete}
            title="Supprimer"
            className="rounded p-1 text-red-500 hover:bg-red-50"
          >
            <Trash2 className="size-4" />
          </button>
        </div>
      </div>
    );
  }
  ```

  Notes d'implémentation :
  - `@/lib/cloudinary-upload` suppose un alias `@` configuré dans `tsconfig.json` (vérifier avec `cat apps/admin/tsconfig.json | grep paths -A 5` ; si l'alias n'existe pas, remplacer par `../lib/cloudinary-upload`).
  - L'édition `alt` est volontairement simple (window.prompt). Une modal stylée peut être ajoutée plus tard si besoin — la spec autorise « inline edit ou modal ».
  - Les icônes viennent de `lucide-react` déjà dans les deps.

#### G6. Vérification + commit

- [ ] Type check :
  ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-web && pnpm --filter admin run type-check
  ```
- [ ] Build complet (optionnel mais conseillé pour valider l'arbre) :
  ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-web && pnpm --filter admin run build
  ```
  Note : le build peut échouer tant que le composant n'est pas instancié dans une page. C'est OK — la vérification finale est en Phase H.
- [ ] Stage :
  ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-web && git add apps/admin/lib/cloudinary-upload.ts apps/admin/components/photo-gallery-editor.tsx apps/admin/.env.example apps/admin/package.json
  ```
  Ne PAS oublier d'ajouter `pnpm-lock.yaml` :
  ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-web && git add pnpm-lock.yaml
  ```
- [ ] Commit :
  ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-web && git commit -m "$(cat <<'EOF'
  feat(photos): composant admin web PhotoGalleryEditor

  - apps/admin/lib/cloudinary-upload.ts : utility unsigned upload qui
    retourne { secureUrl, publicId }
  - apps/admin/.env.example : déclare NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME
    + NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET
  - apps/admin/components/photo-gallery-editor.tsx : composant client,
    grille responsive (2/3/5 cols), drag-and-drop via @dnd-kit, badge
    cover, actions set cover / edit alt / delete par tile, file input
    pour upload (premier upload auto-cover)
  - Ajout deps @dnd-kit/core + @dnd-kit/sortable + @dnd-kit/utilities
  EOF
  )"
  ```

---

## Phase H — Web : wiring pages détail

**Objectif :** brancher `<PhotoGalleryEditor>` dans les pages détail restaurant, produit et menu. Créer la page menu si elle n'existe pas. Récupérer le token Firebase de la même manière que les autres pages admin protégées.

### Tâches

#### H1. Exploration préalable

L'implémenteur lance :

- [ ] ```bash
  ls /Users/henokmipoks/Desktop/code/lilia-food-web/apps/admin/app/\(protected\)/restaurants/
  ```
- [ ] ```bash
  ls /Users/henokmipoks/Desktop/code/lilia-food-web/apps/admin/app/\(protected\)/produits/
  ```
- [ ] ```bash
  ls /Users/henokmipoks/Desktop/code/lilia-food-web/apps/admin/app/\(protected\)/menus/ 2>/dev/null
  ```

Constats attendus (à confirmer) :
- `restaurants/` ne contient que `page.tsx` (la liste). Pas de page `[id]/`. **Il faut donc créer `restaurants/[id]/page.tsx`.**
- `produits/` ne contient que `page.tsx`. **Il faut donc créer `produits/[id]/page.tsx`.**
- `menus/` n'existe pas. **Il faut créer le dossier + `menus/[id]/page.tsx`.**

Décision : pour rester minimal et focus sur E2 (photos), on crée des pages détail minimales qui affichent juste l'ID + la galerie photo (pas le form complet de l'entité — c'est un sous-projet à part). Si une page détail existe déjà avec un form, on ajoute juste une section `<PhotoGalleryEditor>` à la fin.

Avant de créer chaque page, vérifier UNE FOIS le pattern d'auth/token utilisé dans une page protégée existante :

- [ ] ```bash
  grep -rln "useAuth\|firebase/auth\|getIdToken" /Users/henokmipoks/Desktop/code/lilia-food-web/apps/admin/app/\(protected\)/ /Users/henokmipoks/Desktop/code/lilia-food-web/apps/admin/store/ /Users/henokmipoks/Desktop/code/lilia-food-web/apps/admin/components/ | head -10
  ```
  Le résultat indique le hook ou store utilisé pour récupérer le token Firebase. Le reuser tel quel dans les nouvelles pages.

#### H2. Créer `apps/admin/app/(protected)/restaurants/[id]/page.tsx`

- [ ] Créer le dossier puis le fichier :
  ```bash
  mkdir -p /Users/henokmipoks/Desktop/code/lilia-food-web/apps/admin/app/\(protected\)/restaurants/\[id\]
  ```
- [ ] Contenu (adapter `useAuth` / `useToken` au pattern réel découvert en H1) :

  ```tsx
  'use client';

  import { use } from 'react';
  import { PhotoGalleryEditor } from '@/components/photo-gallery-editor';
  // ADAPTER : remplacer cet import par le hook/store réel du repo
  import { useAuthToken } from '@/store/auth'; // ou autre selon H1

  export default function RestaurantDetailPage({
    params,
  }: {
    params: Promise<{ id: string }>;
  }) {
    const { id } = use(params);
    const token = useAuthToken();

    return (
      <div className="space-y-6 p-6">
        <header>
          <h1 className="text-2xl font-semibold">Restaurant {id}</h1>
          <p className="text-sm text-neutral-500">
            Gestion de la galerie photos.
          </p>
        </header>

        <section>
          <h2 className="mb-3 text-lg font-medium">Photos</h2>
          <PhotoGalleryEditor entity="vendor" parentId={id} token={token} />
        </section>
      </div>
    );
  }
  ```

  Si le pattern d'auth est différent (par exemple un Provider qui passe le token via context), suivre exactement ce qui est fait dans `apps/admin/app/(protected)/clients/page.tsx` ou similar.

#### H3. Créer `apps/admin/app/(protected)/produits/[id]/page.tsx`

- [ ] ```bash
  mkdir -p /Users/henokmipoks/Desktop/code/lilia-food-web/apps/admin/app/\(protected\)/produits/\[id\]
  ```
- [ ] Contenu identique à H2 avec `entity="product"` et titre adapté :

  ```tsx
  'use client';

  import { use } from 'react';
  import { PhotoGalleryEditor } from '@/components/photo-gallery-editor';
  import { useAuthToken } from '@/store/auth';

  export default function ProduitDetailPage({
    params,
  }: {
    params: Promise<{ id: string }>;
  }) {
    const { id } = use(params);
    const token = useAuthToken();

    return (
      <div className="space-y-6 p-6">
        <header>
          <h1 className="text-2xl font-semibold">Produit {id}</h1>
          <p className="text-sm text-neutral-500">Galerie photos du produit.</p>
        </header>

        <section>
          <h2 className="mb-3 text-lg font-medium">Photos</h2>
          <PhotoGalleryEditor entity="product" parentId={id} token={token} />
        </section>
      </div>
    );
  }
  ```

#### H4. Créer `apps/admin/app/(protected)/menus/[id]/page.tsx`

- [ ] ```bash
  mkdir -p /Users/henokmipoks/Desktop/code/lilia-food-web/apps/admin/app/\(protected\)/menus/\[id\]
  ```
- [ ] Pour la page liste `menus/page.tsx` (qui n'existe pas non plus), créer juste un placeholder minimal pour que la navigation soit cohérente :
  ```bash
  ls /Users/henokmipoks/Desktop/code/lilia-food-web/apps/admin/app/\(protected\)/menus/page.tsx 2>/dev/null && echo "déjà là" || echo "à créer"
  ```
  Si à créer, faire un placeholder qui dit "Liste des menus à venir — accéder directement à /menus/<id> pour gérer les photos". Sinon, ignorer.
- [ ] Page détail menu :

  ```tsx
  'use client';

  import { use } from 'react';
  import { PhotoGalleryEditor } from '@/components/photo-gallery-editor';
  import { useAuthToken } from '@/store/auth';

  export default function MenuDuJourDetailPage({
    params,
  }: {
    params: Promise<{ id: string }>;
  }) {
    const { id } = use(params);
    const token = useAuthToken();

    return (
      <div className="space-y-6 p-6">
        <header>
          <h1 className="text-2xl font-semibold">Menu du jour {id}</h1>
          <p className="text-sm text-neutral-500">Galerie photos du menu.</p>
        </header>

        <section>
          <h2 className="mb-3 text-lg font-medium">Photos</h2>
          <PhotoGalleryEditor entity="menu" parentId={id} token={token} />
        </section>
      </div>
    );
  }
  ```

#### H5. Vérification finale

- [ ] Build complet de l'admin :
  ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-web && pnpm --filter admin run build
  ```
  Doit passer sans erreur. Si erreur sur un import (`useAuthToken` introuvable), corriger en se basant sur la vraie API d'auth (H1).
- [ ] Smoke test local (recommandé) :
  ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-web && pnpm --filter admin run dev
  ```
  - Ouvrir http://localhost:3001
  - Login admin
  - Visiter `/restaurants/<un-id-réel>` → la galerie photo s'affiche
  - Ajouter une photo, drag-reorder, supprimer
  - Idem pour `/produits/<id>` et `/menus/<id>`

#### H6. Commit phase H

- [ ] Stage :
  ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-web && git add apps/admin/app/\(protected\)/restaurants/\[id\]/ apps/admin/app/\(protected\)/produits/\[id\]/ apps/admin/app/\(protected\)/menus/
  ```
- [ ] Commit :
  ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-web && git commit -m "$(cat <<'EOF'
  feat(photos): pages détail admin vendor/product/menu

  Crée les routes /restaurants/[id], /produits/[id], /menus/[id] côté
  admin web. Chaque page rend une section <PhotoGalleryEditor> branchée
  sur l'entityType correspondant et le token Firebase de l'admin.

  Ces routes étaient inexistantes ; les pages sont minimales (titre +
  galerie) — l'édition complète de l'entité reste hors scope E2.
  EOF
  )"
  ```

---

## Phase I — Vérification globale + push

### Tâches

#### I1. Vérification Flutter

- [ ] ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-admin && flutter analyze
  ```
- [ ] ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-admin && flutter test
  ```
  Les tests photos (Phase C) doivent passer. Les autres tests doivent rester verts.
- [ ] Smoke test manuel (cf. E7) — vérifier les 3 surfaces (settings restaurateur, product form, menu form).

#### I2. Vérification Web

- [ ] ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-web && pnpm --filter admin run type-check
  ```
- [ ] ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-web && pnpm --filter admin run build
  ```
- [ ] Smoke test manuel (cf. H5).

#### I3. Push les deux branches

- [ ] Push Flutter :
  ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-admin && git push -u origin hmipoka/photo-galleries-admin
  ```
- [ ] Push Web :
  ```bash
  cd /Users/henokmipoks/Desktop/code/lilia-food-web && git push -u origin hmipoka/photo-galleries-admin
  ```
- [ ] Vérifier que les deux remotes sont à jour via `gh pr status` ou via le dashboard GitHub.

#### I4. PR (à la demande de l'utilisateur uniquement)

- [ ] Ne PAS créer les PRs automatiquement. Attendre la consigne explicite de l'utilisateur, qui validera d'abord les smoke tests en local. À ce moment, créer 2 PRs avec :
  - **lilia-food-admin** : titre `feat(admin): galeries photos Restaurant/Product/Menu (E2)`
  - **lilia-food-web** : titre `feat(admin): galeries photos Restaurant/Product/Menu (E2)`
  - Body : référence le spec `docs/superpowers/specs/2026-06-01-photo-galleries-admin-design.md` + liste les écrans/routes ajoutés.

---

## Annexe — Récap des fichiers livrés

### Flutter (`lilia-food-admin/`)

**Nouveaux :**
- `lib/features/photos/data/photo_models.dart`
- `lib/features/photos/data/vendor_photos_service.dart`
- `lib/features/photos/data/product_images_service.dart`
- `lib/features/photos/data/menu_images_service.dart`
- `lib/features/photos/data/photos_facade.dart`
- `lib/features/photos/application/photos_controller.dart`
- `lib/features/photos/application/photos_controller.g.dart` (généré)
- `lib/features/photos/application/photos_controller_test.dart`
- `lib/features/photos/presentation/screens/photos_screen.dart`
- `lib/common_widgets/photo_gallery_editor.dart`

**Modifiés :**
- `lib/features/users/data/cloudinary_service.dart`
- `lib/routing/app_router.dart`
- `lib/features/products/presentation/screens/product_form_screen.dart`
- `lib/features/menus/presentation/screens/menu_form_screen.dart`
- `lib/features/settings/presentation/screens/settings_screen.dart`

### Web (`lilia-food-web/`)

**Nouveaux :**
- `packages/api-client/src/hooks/photos.ts`
- `apps/admin/lib/cloudinary-upload.ts`
- `apps/admin/components/photo-gallery-editor.tsx`
- `apps/admin/.env.example` (si absent)
- `apps/admin/app/(protected)/restaurants/[id]/page.tsx`
- `apps/admin/app/(protected)/produits/[id]/page.tsx`
- `apps/admin/app/(protected)/menus/[id]/page.tsx`

**Modifiés :**
- `packages/types/src/index.ts`
- `packages/api-client/src/index.ts`
- `apps/admin/package.json` + lockfile

---

## Annexe — Mapping spec → tâches

| Item spec | Phase / tâches |
|---|---|
| Modèle `Photo` + `EntityType` Flutter | A1 |
| `CloudinaryUploadResult { url, publicId }` Flutter | A1, A2 |
| 3 services HTTP Flutter + facade | B1, B2, B3, B4 |
| Controller Riverpod paramétré + optimistic | C1 |
| Tests Riverpod | C3 |
| Widget gallery réutilisable Flutter | D1 |
| `PhotosScreen` Flutter | D2 |
| Route `/photos` go_router | E2 |
| Entry RESTAURATEUR (settings tab Général) | E5 |
| Entry produit / menu form (action AppBar) | E3, E4 |
| Entry ADMIN Flutter | E6 (documenté hors scope — passe par web) |
| Drag-to-reorder Flutter (`ReorderableListView`) | D1 (`_GalleryGrid`) |
| Branche `lilia-food-web` | F1 |
| Types `Photo` + `EntityType` TS | F2 |
| 5 hooks React Query optimistic | F3 |
| Re-export hook depuis index | F4 |
| Utility Cloudinary web | G4 |
| Env vars Cloudinary admin web | G3 |
| Dépendances @dnd-kit | G2 |
| Composant `PhotoGalleryEditor` web (grille responsive + drag) | G5 |
| Page détail restaurant | H2 |
| Page détail produit | H3 |
| Page détail menu (nouvelle) | H4 |
| Tests RTL composant web | non couverts ici — voir « écarts » ci-dessous |

---

## Annexe — Écarts assumés vs spec

1. **`admin_vendors_screen.dart`** : le spec mentionne ce fichier pour l'entry point ADMIN Flutter. Il n'existe pas aujourd'hui ; le créer hors scope E2. L'ADMIN gère les photos d'autres restaurants via l'admin web (Phase H).
2. **Home RESTAURATEUR** : il n'y a pas d'écran "home restaurant" dédié — la fiche se gère via Settings tab Général. C'est là qu'on ajoute le bouton "Gérer la galerie photos du restaurant".
3. **Tests React Testing Library** côté web : la spec les recommande. Ils ne sont pas inclus dans ce plan parce que le repo `lilia-food-web` ne semble pas avoir d'infra RTL pré-configurée pour `apps/admin` (à vérifier). À ajouter dans un sous-chantier dédié si besoin.
4. **Grille responsive Flutter (2/5 cols)** : remplacée par un `ReorderableListView` vertical riche pour rester cohérent avec le pattern banners de l'admin Flutter (utilisé exclusivement en mobile). La grille responsive 2/3/5 cols est implémentée côté web où le desktop est central.
5. **Package manager web** : `pnpm@9.15.0` confirmé via `package.json#packageManager`. Un `bun.lock` historique existe en parallèle mais n'est plus la source de vérité — toutes les commandes du plan utilisent `pnpm`.
6. **Édition `alt` côté web** : `window.prompt` au lieu d'une modal stylée — acceptable d'après la spec (« inline edit ou modal »). Modal à styliser dans un suivi UX si besoin.

import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/utils/api_response.dart';

import '../../../models/product.dart';

class ProductService {
  final ApiClient _api;

  ProductService(this._api);

  /// Taille de page maximale acceptée par l'API (`MAX_PAGE_SIZE` backend).
  static const int _maxPageSize = 100;

  /// Garde-fou : la boucle de pagination est pilotée par une valeur venue du
  /// serveur, elle doit rester finie même si `totalPages` est aberrant.
  static const int _maxPages = 50;

  /// Catalogue complet du vendeur — `GET /products/manage`.
  ///
  /// Cette méthode lisait `GET /products`, la route **publique**. Trois
  /// conséquences, toutes silencieuses :
  ///
  /// 1. aucune pagination transmise, donc **20 produits au maximum** : un
  ///    vendeur avec un vrai catalogue en perdait la moitié sans rien voir ;
  /// 2. les produits marqués indisponibles ou hors de leur fenêtre horaire
  ///    disparaissaient de l'écran depuis lequel on les corrige ;
  /// 3. un vendeur suspendu ou encore en `DRAFT` ne voyait **rien** — au moment
  ///    précis où il doit remplir ou corriger sa boutique.
  ///
  /// La route de gestion applique la même règle de propriété que les écritures
  /// (`restaurantId` n'est lu que pour un ADMIN).
  Future<List<Product>> getProducts(String restaurantId) async {
    final products = <Product>[];

    for (var page = 1; page <= _maxPages; page++) {
      final res = await _api.getJson('/products/manage', query: {
        'restaurantId': restaurantId,
        'page': '$page',
        'limit': '$_maxPageSize',
      });

      // Tolère liste brute / simple wrap / double wrap (interceptor backend).
      products.addAll(ApiResponse.listOf(res.data)
          .map((json) => Product.fromJson(json as Map<String, dynamic>)));

      if (page >= _totalPagesOf(res.data)) break;
    }

    return products;
  }

  /// Nombre de pages annoncé par le serveur, 1 si la réponse ne le porte pas
  /// (un client à jour contre un backend ancien ne doit pas boucler).
  static int _totalPagesOf(dynamic decoded) {
    if (decoded is! Map<String, dynamic>) return 1;
    final inner = decoded['data'];
    final meta = decoded['meta'] ??
        (inner is Map<String, dynamic> ? inner['meta'] : null);
    if (meta is Map<String, dynamic> && meta['totalPages'] is int) {
      return meta['totalPages'] as int;
    }
    return 1;
  }

  Future<Product> getProduct(String productId) async {
    final res = await _api.getJson('/products/$productId');
    final productData =
        (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
    if (productData == null) {
      throw Exception('Product data is null');
    }
    return Product.fromJson(productData);
  }

  Future<Product> createProduct(Map<String, dynamic> productData) async {
    final res = await _api.postJson('/products', body: productData);
    final productJson =
        (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
    if (productJson == null) {
      throw Exception('Product data is null in response');
    }
    return Product.fromJson(productJson);
  }

  Future<Product> updateProduct(
      String productId, Map<String, dynamic> productData) async {
    final res = await _api.patchJson('/products/$productId', body: productData);
    final productJson =
        (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
    if (productJson == null) {
      throw Exception('Product data is null in response');
    }
    return Product.fromJson(productJson);
  }

  /// Réapprovisionne un produit — `PATCH /products/:id/stock`.
  ///
  /// C'est la **seule** route qui remette `stockRestant` à niveau
  /// inconditionnellement. `updateProduct` ci-dessus décrit la fiche produit :
  /// il ne réaligne le stock restant que si la capacité déclarée change,
  /// sinon corriger une description l'après-midi ressusciterait les unités
  /// déjà vendues dans la journée.
  ///
  /// `null` = stock illimité, et c'est une valeur significative : c'est le seul
  /// chemin pour y revenir depuis un stock fini.
  Future<Product> restock(String productId, int? stockQuotidien) async {
    final res = await _api.patchJson(
      '/products/$productId/stock',
      body: {'stockQuotidien': stockQuotidien},
    );
    final productJson =
        (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
    if (productJson == null) {
      throw Exception('Product data is null in response');
    }
    return Product.fromJson(productJson);
  }

  /// Retire ou remet un produit à la vente — `PATCH /products/:id/availability`.
  ///
  /// La route existe côté serveur depuis le fix M2 d'août 2026 et **aucun
  /// client Flutter ne l'appelait** : le seul levier du vendeur était de
  /// mettre son stock à 0, ce qui affiche « épuisé » — une information
  /// différente, et fausse.
  ///
  /// ⚠️ N'a de sens que sur `GET /products/manage` : sur le catalogue public,
  /// le produit disparaît en même temps que le bouton qui le réactive.
  Future<Product> setAvailability(String productId, bool isAvailable) async {
    final res = await _api.patchJson(
      '/products/$productId/availability',
      body: {'isAvailable': isAvailable},
    );
    final productJson =
        (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
    if (productJson == null) {
      throw Exception('Product data is null in response');
    }
    return Product.fromJson(productJson);
  }

  Future<void> deleteProduct(String productId) async {
    await _api.deleteJson('/products/$productId');
  }
}

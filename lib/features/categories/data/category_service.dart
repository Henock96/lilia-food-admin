import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/utils/api_response.dart';

import '../../../models/product.dart';

/// Sections de menu d'un vendeur (`/categories`).
///
/// ⚠️ Ce service postait auparavant sur `/categories?restaurantId=X` — un
/// paramètre que le backend **ne lisait pas**. L'écran, son wording et son
/// provider étaient donc bâtis sur une hypothèse fausse : la catégorie était en
/// réalité globale à toute la plateforme. Le modèle est désormais réellement
/// « une section appartient à un vendeur », et le ciblage passe par le **corps**
/// de la requête, réservé à l'ADMIN.
class CategoryService {
  final ApiClient _api;

  CategoryService(this._api);

  /// GET /categories — mes sections (ADMIN : celles du vendeur ciblé).
  ///
  /// Rend **toutes** les sections, y compris vides et désactivées : c'est la vue
  /// du propriétaire, celle où l'on remplit. Une section vide qui disparaît de
  /// cette liste ne peut plus jamais être remplie.
  Future<List<Category>> getCategories({String? restaurantId}) async {
    final res = await _api.getJson(
      '/categories',
      query: {if (restaurantId != null) 'restaurantId': restaurantId},
    );
    return ApiResponse.listOf(res.data)
        .map((json) => Category.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// POST /categories — `restaurantId` uniquement si l'appelant est ADMIN.
  Future<Category> createCategory(
    Map<String, dynamic> body, {
    String? restaurantId,
  }) async {
    final res = await _api.postJson('/categories', body: {
      ...body,
      if (restaurantId != null) 'restaurantId': restaurantId,
    });
    return Category.fromJson(ApiResponse.mapOf(res.data));
  }

  /// PATCH /categories/:id — nom, description, ordre, activation.
  Future<Category> updateCategory(
    String categoryId,
    Map<String, dynamic> body,
  ) async {
    final res = await _api.patchJson('/categories/$categoryId', body: body);
    return Category.fromJson(ApiResponse.mapOf(res.data));
  }

  /// PATCH /categories/reorder — liste ordonnée **complète**.
  Future<void> reorderCategories(
    List<String> categoryIds, {
    String? restaurantId,
  }) async {
    await _api.patchJson('/categories/reorder', body: {
      'categoryIds': categoryIds,
      if (restaurantId != null) 'restaurantId': restaurantId,
    });
  }

  /// DELETE /categories/:id — les produits sont **détachés**, jamais supprimés.
  Future<void> deleteCategory(String categoryId) async {
    await _api.deleteJson('/categories/$categoryId');
  }
}

import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/utils/api_response.dart';

import '../../../models/product.dart';

class CategoryService {
  final ApiClient _api;

  CategoryService(this._api);

  Future<List<Category>> getCategories(String restaurantId) async {
    final res = await _api
        .getJson('/categories', query: {'restaurantId': restaurantId});
    // Backend renvoie { data:[...], count } → double-wrappé par l'interceptor.
    // ApiResponse.listOf tolère liste brute / simple wrap / double wrap.
    final categoriesData = ApiResponse.listOf(res.data);
    return categoriesData
        .map((json) => Category.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Category> getCategory(String categoryId) async {
    final res = await _api.getJson('/categories/$categoryId');
    final categoryData =
        (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
    if (categoryData == null) {
      throw Exception('Category data is null');
    }
    return Category.fromJson(categoryData);
  }

  Future<Category> createCategory(
      String restaurantId, Map<String, dynamic> categoryData) async {
    final res = await _api.postJson(
      '/categories?restaurantId=$restaurantId',
      body: categoryData,
    );
    final categoryJson =
        (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
    if (categoryJson == null) {
      throw Exception('Category data is null in response');
    }
    return Category.fromJson(categoryJson);
  }

  Future<Category> updateCategory(
      String categoryId, Map<String, dynamic> categoryData) async {
    final res = await _api.patchJson('/categories/$categoryId', body: categoryData);
    final categoryJson =
        (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
    if (categoryJson == null) {
      throw Exception('Category data is null in response');
    }
    return Category.fromJson(categoryJson);
  }

  Future<void> deleteCategory(String categoryId) async {
    await _api.deleteJson('/categories/$categoryId');
  }
}

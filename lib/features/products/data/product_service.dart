import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/utils/api_response.dart';

import '../../../models/product.dart';

class ProductService {
  final ApiClient _api;

  ProductService(this._api);

  Future<List<Product>> getProducts(String restaurantId) async {
    final res =
        await _api.getJson('/products', query: {'restaurantId': restaurantId});
    // Tolère liste brute / simple wrap / double wrap (interceptor backend).
    final productsData = ApiResponse.listOf(res.data);
    return productsData
        .map((json) => Product.fromJson(json as Map<String, dynamic>))
        .toList();
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

  Future<void> deleteProduct(String productId) async {
    await _api.deleteJson('/products/$productId');
  }
}

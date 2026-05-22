import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../models/product.dart';
import '../../../restaurant/presentation/providers/restaurant_provider.dart';
import '../../data/product_service.dart';

part 'products_provider.g.dart';

@riverpod
ProductService productService(Ref ref) {
  return ProductService();
}

@riverpod
class Products extends _$Products {
  @override
  Future<List<Product>> build() async {
    final restaurantId = ref.watch(currentRestaurantIdProvider);
    if (restaurantId.isEmpty) return const [];
    final service = ref.watch(productServiceProvider);
    return service.getProducts(restaurantId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final restaurantId = ref.read(currentRestaurantIdProvider);
      if (restaurantId.isEmpty) return const <Product>[];
      final service = ref.read(productServiceProvider);
      return service.getProducts(restaurantId);
    });
  }

  Future<void> createProduct(Map<String, dynamic> productData) async {
    final service = ref.read(productServiceProvider);
    await service.createProduct(productData);
    await refresh();
  }

  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> productData,
  ) async {
    final service = ref.read(productServiceProvider);
    await service.updateProduct(productId, productData);
    await refresh();
  }

  Future<void> deleteProduct(String productId) async {
    final service = ref.read(productServiceProvider);
    await service.deleteProduct(productId);
    await refresh();
  }
}

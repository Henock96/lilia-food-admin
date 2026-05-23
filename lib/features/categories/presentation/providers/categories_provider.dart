import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../models/product.dart';
import '../../../restaurant/presentation/providers/restaurant_provider.dart';
import '../../data/category_service.dart';

part 'categories_provider.g.dart';

@riverpod
CategoryService categoryService(Ref ref) {
  return CategoryService();
}

@riverpod
class Categories extends _$Categories {
  @override
  Future<List<Category>> build() async {
    final restaurantId = ref.watch(currentRestaurantIdProvider);
    if (restaurantId.isEmpty) return const [];
    final service = ref.watch(categoryServiceProvider);
    return service.getCategories(restaurantId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final restaurantId = ref.read(currentRestaurantIdProvider);
      if (restaurantId.isEmpty) return const <Category>[];
      final service = ref.read(categoryServiceProvider);
      return service.getCategories(restaurantId);
    });
  }

  Future<void> createCategory(Map<String, dynamic> categoryData) async {
    final restaurantId = ref.read(currentRestaurantIdProvider);
    if (restaurantId.isEmpty) {
      throw Exception('Restaurant non chargé. Veuillez réessayer.');
    }
    final service = ref.read(categoryServiceProvider);
    await service.createCategory(restaurantId, categoryData);
    await refresh();
  }

  Future<void> updateCategory(
    String categoryId,
    Map<String, dynamic> categoryData,
  ) async {
    final service = ref.read(categoryServiceProvider);
    await service.updateCategory(categoryId, categoryData);
    await refresh();
  }

  Future<void> deleteCategory(String categoryId) async {
    final service = ref.read(categoryServiceProvider);
    await service.deleteCategory(categoryId);
    await refresh();
  }
}

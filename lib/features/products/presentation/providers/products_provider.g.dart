// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'products_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(productService)
final productServiceProvider = ProductServiceProvider._();

final class ProductServiceProvider
    extends $FunctionalProvider<ProductService, ProductService, ProductService>
    with $Provider<ProductService> {
  ProductServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'productServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$productServiceHash();

  @$internal
  @override
  $ProviderElement<ProductService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ProductService create(Ref ref) {
    return productService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProductService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProductService>(value),
    );
  }
}

String _$productServiceHash() => r'0473fdd2a61f1b9401fe8cd8815ed49e7139952a';

@ProviderFor(Products)
final productsProvider = ProductsProvider._();

final class ProductsProvider
    extends $AsyncNotifierProvider<Products, List<Product>> {
  ProductsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'productsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$productsHash();

  @$internal
  @override
  Products create() => Products();
}

String _$productsHash() => r'6fea59a1badbf59a8059c9c40dd97d552803558a';

abstract class _$Products extends $AsyncNotifier<List<Product>> {
  FutureOr<List<Product>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Product>>, List<Product>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Product>>, List<Product>>,
              AsyncValue<List<Product>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

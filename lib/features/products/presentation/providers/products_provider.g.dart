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

String _$productServiceHash() => r'585339dce0c6b80a447b8653aa1234e2a81e2317';

/// Catalogue du vendeur courant (`catalogScopeProvider`).
///
/// La **lecture** est filtrée par `restaurantId` en query — c'est un filtre, il
/// ne donne aucun droit. L'**écriture**, elle, ne transmet ce champ que pour un
/// ADMIN : c'est la seule règle que le backend accepte, et la confondre avec le
/// filtre de lecture est ce qui a mis la création de produit hors service pour
/// tous les restaurateurs.

@ProviderFor(Products)
final productsProvider = ProductsProvider._();

/// Catalogue du vendeur courant (`catalogScopeProvider`).
///
/// La **lecture** est filtrée par `restaurantId` en query — c'est un filtre, il
/// ne donne aucun droit. L'**écriture**, elle, ne transmet ce champ que pour un
/// ADMIN : c'est la seule règle que le backend accepte, et la confondre avec le
/// filtre de lecture est ce qui a mis la création de produit hors service pour
/// tous les restaurateurs.
final class ProductsProvider
    extends $AsyncNotifierProvider<Products, List<Product>> {
  /// Catalogue du vendeur courant (`catalogScopeProvider`).
  ///
  /// La **lecture** est filtrée par `restaurantId` en query — c'est un filtre, il
  /// ne donne aucun droit. L'**écriture**, elle, ne transmet ce champ que pour un
  /// ADMIN : c'est la seule règle que le backend accepte, et la confondre avec le
  /// filtre de lecture est ce qui a mis la création de produit hors service pour
  /// tous les restaurateurs.
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

String _$productsHash() => r'678b397e5d6c4927a85e13b961d92cd33b03a27f';

/// Catalogue du vendeur courant (`catalogScopeProvider`).
///
/// La **lecture** est filtrée par `restaurantId` en query — c'est un filtre, il
/// ne donne aucun droit. L'**écriture**, elle, ne transmet ce champ que pour un
/// ADMIN : c'est la seule règle que le backend accepte, et la confondre avec le
/// filtre de lecture est ce qui a mis la création de produit hors service pour
/// tous les restaurateurs.

abstract class _$Products extends $AsyncNotifier<List<Product>> {
  FutureOr<List<Product>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Product>>, List<Product>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Product>>, List<Product>>,
              AsyncValue<List<Product>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

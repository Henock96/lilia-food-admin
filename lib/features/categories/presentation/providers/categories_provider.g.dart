// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categories_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(categoryService)
final categoryServiceProvider = CategoryServiceProvider._();

final class CategoryServiceProvider
    extends
        $FunctionalProvider<CategoryService, CategoryService, CategoryService>
    with $Provider<CategoryService> {
  CategoryServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryServiceHash();

  @$internal
  @override
  $ProviderElement<CategoryService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CategoryService create(Ref ref) {
    return categoryService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CategoryService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CategoryService>(value),
    );
  }
}

String _$categoryServiceHash() => r'67d5d8c71ccfea387031346dd1763cc0e359be1b';

/// Sections de menu du vendeur courant.
///
/// Le périmètre vient de `catalogScopeProvider` : son propre vendeur pour un
/// RESTAURATEUR, celui sélectionné pour un ADMIN. Changer de vendeur recharge
/// automatiquement la liste — `ref.watch` s'en charge, sans invalidation
/// manuelle à répartir sur chaque écran.

@ProviderFor(Categories)
final categoriesProvider = CategoriesProvider._();

/// Sections de menu du vendeur courant.
///
/// Le périmètre vient de `catalogScopeProvider` : son propre vendeur pour un
/// RESTAURATEUR, celui sélectionné pour un ADMIN. Changer de vendeur recharge
/// automatiquement la liste — `ref.watch` s'en charge, sans invalidation
/// manuelle à répartir sur chaque écran.
final class CategoriesProvider
    extends $AsyncNotifierProvider<Categories, List<Category>> {
  /// Sections de menu du vendeur courant.
  ///
  /// Le périmètre vient de `catalogScopeProvider` : son propre vendeur pour un
  /// RESTAURATEUR, celui sélectionné pour un ADMIN. Changer de vendeur recharge
  /// automatiquement la liste — `ref.watch` s'en charge, sans invalidation
  /// manuelle à répartir sur chaque écran.
  CategoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoriesHash();

  @$internal
  @override
  Categories create() => Categories();
}

String _$categoriesHash() => r'5671f664bd5bd31dc308c9ac5de38949fd21c139';

/// Sections de menu du vendeur courant.
///
/// Le périmètre vient de `catalogScopeProvider` : son propre vendeur pour un
/// RESTAURATEUR, celui sélectionné pour un ADMIN. Changer de vendeur recharge
/// automatiquement la liste — `ref.watch` s'en charge, sans invalidation
/// manuelle à répartir sur chaque écran.

abstract class _$Categories extends $AsyncNotifier<List<Category>> {
  FutureOr<List<Category>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Category>>, List<Category>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Category>>, List<Category>>,
              AsyncValue<List<Category>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

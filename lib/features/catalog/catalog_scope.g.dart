// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_scope.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Sur QUEL vendeur portent les écrans de catalogue (produits, sections, menus).
///
/// Une seule règle, partagée par les trois écrans, plutôt qu'un
/// `currentRestaurantIdProvider` lu directement partout :
///
///  - **RESTAURATEUR** → son vendeur, et lui seul. Aucun sélecteur affiché : il
///    n'y a rien à choisir, et un champ qu'on ne peut pas changer est un piège.
///  - **ADMIN** → le vendeur qu'il a sélectionné. Il n'en possède aucun, donc
///    sans sélection il n'y a pas de cible : les écrans le disent au lieu
///    d'afficher une liste vide inexplicable.
///
/// C'est ce provider qui alimente le `restaurantId` envoyé au backend — lequel
/// ne l'accepte QUE d'un ADMIN. Envoyer son propre identifiant en tant que
/// RESTAURATEUR renvoyait 403 : la création de produit était cassée pour tous
/// les vendeurs depuis l'ouverture de ce champ aux administrateurs.

@ProviderFor(CatalogScope)
final catalogScopeProvider = CatalogScopeProvider._();

/// Sur QUEL vendeur portent les écrans de catalogue (produits, sections, menus).
///
/// Une seule règle, partagée par les trois écrans, plutôt qu'un
/// `currentRestaurantIdProvider` lu directement partout :
///
///  - **RESTAURATEUR** → son vendeur, et lui seul. Aucun sélecteur affiché : il
///    n'y a rien à choisir, et un champ qu'on ne peut pas changer est un piège.
///  - **ADMIN** → le vendeur qu'il a sélectionné. Il n'en possède aucun, donc
///    sans sélection il n'y a pas de cible : les écrans le disent au lieu
///    d'afficher une liste vide inexplicable.
///
/// C'est ce provider qui alimente le `restaurantId` envoyé au backend — lequel
/// ne l'accepte QUE d'un ADMIN. Envoyer son propre identifiant en tant que
/// RESTAURATEUR renvoyait 403 : la création de produit était cassée pour tous
/// les vendeurs depuis l'ouverture de ce champ aux administrateurs.
final class CatalogScopeProvider
    extends $NotifierProvider<CatalogScope, String?> {
  /// Sur QUEL vendeur portent les écrans de catalogue (produits, sections, menus).
  ///
  /// Une seule règle, partagée par les trois écrans, plutôt qu'un
  /// `currentRestaurantIdProvider` lu directement partout :
  ///
  ///  - **RESTAURATEUR** → son vendeur, et lui seul. Aucun sélecteur affiché : il
  ///    n'y a rien à choisir, et un champ qu'on ne peut pas changer est un piège.
  ///  - **ADMIN** → le vendeur qu'il a sélectionné. Il n'en possède aucun, donc
  ///    sans sélection il n'y a pas de cible : les écrans le disent au lieu
  ///    d'afficher une liste vide inexplicable.
  ///
  /// C'est ce provider qui alimente le `restaurantId` envoyé au backend — lequel
  /// ne l'accepte QUE d'un ADMIN. Envoyer son propre identifiant en tant que
  /// RESTAURATEUR renvoyait 403 : la création de produit était cassée pour tous
  /// les vendeurs depuis l'ouverture de ce champ aux administrateurs.
  CatalogScopeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'catalogScopeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$catalogScopeHash();

  @$internal
  @override
  CatalogScope create() => CatalogScope();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$catalogScopeHash() => r'ef65201a0082c4cd8ef491e3d81c47c6698a1def';

/// Sur QUEL vendeur portent les écrans de catalogue (produits, sections, menus).
///
/// Une seule règle, partagée par les trois écrans, plutôt qu'un
/// `currentRestaurantIdProvider` lu directement partout :
///
///  - **RESTAURATEUR** → son vendeur, et lui seul. Aucun sélecteur affiché : il
///    n'y a rien à choisir, et un champ qu'on ne peut pas changer est un piège.
///  - **ADMIN** → le vendeur qu'il a sélectionné. Il n'en possède aucun, donc
///    sans sélection il n'y a pas de cible : les écrans le disent au lieu
///    d'afficher une liste vide inexplicable.
///
/// C'est ce provider qui alimente le `restaurantId` envoyé au backend — lequel
/// ne l'accepte QUE d'un ADMIN. Envoyer son propre identifiant en tant que
/// RESTAURATEUR renvoyait 403 : la création de produit était cassée pour tous
/// les vendeurs depuis l'ouverture de ce champ aux administrateurs.

abstract class _$CatalogScope extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// L'appelant est-il un ADMIN agissant au nom d'un tiers ?

@ProviderFor(isCatalogAdmin)
final isCatalogAdminProvider = IsCatalogAdminProvider._();

/// L'appelant est-il un ADMIN agissant au nom d'un tiers ?

final class IsCatalogAdminProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// L'appelant est-il un ADMIN agissant au nom d'un tiers ?
  IsCatalogAdminProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isCatalogAdminProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isCatalogAdminHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isCatalogAdmin(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isCatalogAdminHash() => r'0ee51ab0142d87303a7e44ae1707cc0fa14163ad';

/// `restaurantId` à joindre au corps d'une écriture catalogue.
///
/// `null` pour un RESTAURATEUR : le backend déduit alors le vendeur du compte
/// authentifié, et c'est la **seule** règle correcte — un identifiant transmis
/// par un vendeur n'est jamais digne de confiance, donc le backend le refuse
/// plutôt que de le remplacer en silence.

@ProviderFor(catalogTargetRestaurantId)
final catalogTargetRestaurantIdProvider = CatalogTargetRestaurantIdProvider._();

/// `restaurantId` à joindre au corps d'une écriture catalogue.
///
/// `null` pour un RESTAURATEUR : le backend déduit alors le vendeur du compte
/// authentifié, et c'est la **seule** règle correcte — un identifiant transmis
/// par un vendeur n'est jamais digne de confiance, donc le backend le refuse
/// plutôt que de le remplacer en silence.

final class CatalogTargetRestaurantIdProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// `restaurantId` à joindre au corps d'une écriture catalogue.
  ///
  /// `null` pour un RESTAURATEUR : le backend déduit alors le vendeur du compte
  /// authentifié, et c'est la **seule** règle correcte — un identifiant transmis
  /// par un vendeur n'est jamais digne de confiance, donc le backend le refuse
  /// plutôt que de le remplacer en silence.
  CatalogTargetRestaurantIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'catalogTargetRestaurantIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$catalogTargetRestaurantIdHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return catalogTargetRestaurantId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$catalogTargetRestaurantIdHash() =>
    r'ef02771d7c8ff354f02d5ade837605ba4e7080c7';

/// Vendeurs sélectionnables par un ADMIN — **tous**, y compris `DRAFT` et non
/// approuvés.
///
/// `GET /admin/vendors` et non `GET /restaurants` : la route publique ne rend
/// que les commerces déjà publiés, c'est-à-dire l'exact complément de ceux dont
/// l'admin doit remplir le catalogue pour pouvoir les activer.

@ProviderFor(catalogSelectableVendors)
final catalogSelectableVendorsProvider = CatalogSelectableVendorsProvider._();

/// Vendeurs sélectionnables par un ADMIN — **tous**, y compris `DRAFT` et non
/// approuvés.
///
/// `GET /admin/vendors` et non `GET /restaurants` : la route publique ne rend
/// que les commerces déjà publiés, c'est-à-dire l'exact complément de ceux dont
/// l'admin doit remplir le catalogue pour pouvoir les activer.

final class CatalogSelectableVendorsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AdminVendorItem>>,
          List<AdminVendorItem>,
          FutureOr<List<AdminVendorItem>>
        >
    with
        $FutureModifier<List<AdminVendorItem>>,
        $FutureProvider<List<AdminVendorItem>> {
  /// Vendeurs sélectionnables par un ADMIN — **tous**, y compris `DRAFT` et non
  /// approuvés.
  ///
  /// `GET /admin/vendors` et non `GET /restaurants` : la route publique ne rend
  /// que les commerces déjà publiés, c'est-à-dire l'exact complément de ceux dont
  /// l'admin doit remplir le catalogue pour pouvoir les activer.
  CatalogSelectableVendorsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'catalogSelectableVendorsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$catalogSelectableVendorsHash();

  @$internal
  @override
  $FutureProviderElement<List<AdminVendorItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AdminVendorItem>> create(Ref ref) {
    return catalogSelectableVendors(ref);
  }
}

String _$catalogSelectableVendorsHash() =>
    r'c7eda426d1930e56fd4cf184f4a3fc70ef600926';

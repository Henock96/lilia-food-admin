// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_vendors_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// LIL-128 : liste complète des vendeurs pour l'admin. Filtres optionnels.
/// Le notifier expose les actions approve/suspend qui invalident la liste.

@ProviderFor(AdminVendorsList)
final adminVendorsListProvider = AdminVendorsListProvider._();

/// LIL-128 : liste complète des vendeurs pour l'admin. Filtres optionnels.
/// Le notifier expose les actions approve/suspend qui invalident la liste.
final class AdminVendorsListProvider
    extends $AsyncNotifierProvider<AdminVendorsList, List<AdminVendorItem>> {
  /// LIL-128 : liste complète des vendeurs pour l'admin. Filtres optionnels.
  /// Le notifier expose les actions approve/suspend qui invalident la liste.
  AdminVendorsListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminVendorsListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminVendorsListHash();

  @$internal
  @override
  AdminVendorsList create() => AdminVendorsList();
}

String _$adminVendorsListHash() => r'c7edbac67732ac1f5d1275494eeff8d565faa0cc';

/// LIL-128 : liste complète des vendeurs pour l'admin. Filtres optionnels.
/// Le notifier expose les actions approve/suspend qui invalident la liste.

abstract class _$AdminVendorsList
    extends $AsyncNotifier<List<AdminVendorItem>> {
  FutureOr<List<AdminVendorItem>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<AdminVendorItem>>, List<AdminVendorItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<AdminVendorItem>>,
                List<AdminVendorItem>
              >,
              AsyncValue<List<AdminVendorItem>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// LIL-128 : vendeurs en attente d'approbation. Utilisé par le badge "À valider"
/// du dashboard admin et le tab dédié sur /admin/vendeurs.

@ProviderFor(adminPendingVendors)
final adminPendingVendorsProvider = AdminPendingVendorsProvider._();

/// LIL-128 : vendeurs en attente d'approbation. Utilisé par le badge "À valider"
/// du dashboard admin et le tab dédié sur /admin/vendeurs.

final class AdminPendingVendorsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AdminVendorItem>>,
          List<AdminVendorItem>,
          FutureOr<List<AdminVendorItem>>
        >
    with
        $FutureModifier<List<AdminVendorItem>>,
        $FutureProvider<List<AdminVendorItem>> {
  /// LIL-128 : vendeurs en attente d'approbation. Utilisé par le badge "À valider"
  /// du dashboard admin et le tab dédié sur /admin/vendeurs.
  AdminPendingVendorsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminPendingVendorsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminPendingVendorsHash();

  @$internal
  @override
  $FutureProviderElement<List<AdminVendorItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AdminVendorItem>> create(Ref ref) {
    return adminPendingVendors(ref);
  }
}

String _$adminPendingVendorsHash() =>
    r'0713711c1a7ed2edd08b14b126e3e3bd0573cae5';

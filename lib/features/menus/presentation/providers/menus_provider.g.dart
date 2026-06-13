// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menus_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(menuService)
final menuServiceProvider = MenuServiceProvider._();

final class MenuServiceProvider
    extends $FunctionalProvider<MenuService, MenuService, MenuService>
    with $Provider<MenuService> {
  MenuServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'menuServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$menuServiceHash();

  @$internal
  @override
  $ProviderElement<MenuService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MenuService create(Ref ref) {
    return menuService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MenuService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MenuService>(value),
    );
  }
}

String _$menuServiceHash() => r'171945dbf23db445a91697c137fbfa9bf21252e0';

@ProviderFor(Menus)
final menusProvider = MenusProvider._();

final class MenusProvider
    extends $AsyncNotifierProvider<Menus, List<MenuDuJour>> {
  MenusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'menusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$menusHash();

  @$internal
  @override
  Menus create() => Menus();
}

String _$menusHash() => r'd361e8ec2f2170e8c20bd5e689516a492f6213aa';

abstract class _$Menus extends $AsyncNotifier<List<MenuDuJour>> {
  FutureOr<List<MenuDuJour>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<MenuDuJour>>, List<MenuDuJour>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<MenuDuJour>>, List<MenuDuJour>>,
              AsyncValue<List<MenuDuJour>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

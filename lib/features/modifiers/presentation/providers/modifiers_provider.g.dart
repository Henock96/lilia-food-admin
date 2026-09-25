// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'modifiers_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(modifierService)
final modifierServiceProvider = ModifierServiceProvider._();

final class ModifierServiceProvider
    extends
        $FunctionalProvider<ModifierService, ModifierService, ModifierService>
    with $Provider<ModifierService> {
  ModifierServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'modifierServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$modifierServiceHash();

  @$internal
  @override
  $ProviderElement<ModifierService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ModifierService create(Ref ref) {
    return modifierService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ModifierService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ModifierService>(value),
    );
  }
}

String _$modifierServiceHash() => r'08459975e273fcd5c721b2fa0adbc5b756d60e32';

/// F3-09 — bibliothèque d'options du vendeur courant (`catalogScopeProvider`).
///
/// Même périmètre que les sections et les produits : son propre vendeur pour
/// un RESTAURATEUR, celui choisi pour un ADMIN.

@ProviderFor(Modifiers)
final modifiersProvider = ModifiersProvider._();

/// F3-09 — bibliothèque d'options du vendeur courant (`catalogScopeProvider`).
///
/// Même périmètre que les sections et les produits : son propre vendeur pour
/// un RESTAURATEUR, celui choisi pour un ADMIN.
final class ModifiersProvider
    extends $AsyncNotifierProvider<Modifiers, ModifierLibrary> {
  /// F3-09 — bibliothèque d'options du vendeur courant (`catalogScopeProvider`).
  ///
  /// Même périmètre que les sections et les produits : son propre vendeur pour
  /// un RESTAURATEUR, celui choisi pour un ADMIN.
  ModifiersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'modifiersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$modifiersHash();

  @$internal
  @override
  Modifiers create() => Modifiers();
}

String _$modifiersHash() => r'3119e034e519971f98fdf799160ae2339a5f355e';

/// F3-09 — bibliothèque d'options du vendeur courant (`catalogScopeProvider`).
///
/// Même périmètre que les sections et les produits : son propre vendeur pour
/// un RESTAURATEUR, celui choisi pour un ADMIN.

abstract class _$Modifiers extends $AsyncNotifier<ModifierLibrary> {
  FutureOr<ModifierLibrary> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ModifierLibrary>, ModifierLibrary>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ModifierLibrary>, ModifierLibrary>,
              AsyncValue<ModifierLibrary>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

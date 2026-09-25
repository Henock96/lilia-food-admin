// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'claims_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(claimsRepository)
final claimsRepositoryProvider = ClaimsRepositoryProvider._();

final class ClaimsRepositoryProvider
    extends
        $FunctionalProvider<
          ClaimsRepository,
          ClaimsRepository,
          ClaimsRepository
        >
    with $Provider<ClaimsRepository> {
  ClaimsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'claimsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$claimsRepositoryHash();

  @$internal
  @override
  $ProviderElement<ClaimsRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ClaimsRepository create(Ref ref) {
    return claimsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClaimsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClaimsRepository>(value),
    );
  }
}

String _$claimsRepositoryHash() => r'26dd5ab6ee55a81c8af81b39146babb30be7fcee';

@ProviderFor(claimsList)
final claimsListProvider = ClaimsListFamily._();

final class ClaimsListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ClaimRow>>,
          List<ClaimRow>,
          FutureOr<List<ClaimRow>>
        >
    with $FutureModifier<List<ClaimRow>>, $FutureProvider<List<ClaimRow>> {
  ClaimsListProvider._({
    required ClaimsListFamily super.from,
    required bool super.argument,
  }) : super(
         retry: null,
         name: r'claimsListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$claimsListHash();

  @override
  String toString() {
    return r'claimsListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ClaimRow>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ClaimRow>> create(Ref ref) {
    final argument = this.argument as bool;
    return claimsList(ref, openOnly: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ClaimsListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$claimsListHash() => r'8c11677ac0a9bae45b0e00cb7ef89bdcd3729be1';

final class ClaimsListFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ClaimRow>>, bool> {
  ClaimsListFamily._()
    : super(
        retry: null,
        name: r'claimsListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ClaimsListProvider call({required bool openOnly}) =>
      ClaimsListProvider._(argument: openOnly, from: this);

  @override
  String toString() => r'claimsListProvider';
}

/// Fil relu toutes les 30 s tant que l'écran l'observe (pas de WebSocket).

@ProviderFor(claimThread)
final claimThreadProvider = ClaimThreadFamily._();

/// Fil relu toutes les 30 s tant que l'écran l'observe (pas de WebSocket).

final class ClaimThreadProvider
    extends
        $FunctionalProvider<
          AsyncValue<ClaimThread>,
          ClaimThread,
          FutureOr<ClaimThread>
        >
    with $FutureModifier<ClaimThread>, $FutureProvider<ClaimThread> {
  /// Fil relu toutes les 30 s tant que l'écran l'observe (pas de WebSocket).
  ClaimThreadProvider._({
    required ClaimThreadFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'claimThreadProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$claimThreadHash();

  @override
  String toString() {
    return r'claimThreadProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ClaimThread> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ClaimThread> create(Ref ref) {
    final argument = this.argument as String;
    return claimThread(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ClaimThreadProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$claimThreadHash() => r'61caf85719e994056ce5890d82dbacb490a9f358';

/// Fil relu toutes les 30 s tant que l'écran l'observe (pas de WebSocket).

final class ClaimThreadFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ClaimThread>, String> {
  ClaimThreadFamily._()
    : super(
        retry: null,
        name: r'claimThreadProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fil relu toutes les 30 s tant que l'écran l'observe (pas de WebSocket).

  ClaimThreadProvider call(String id) =>
      ClaimThreadProvider._(argument: id, from: this);

  @override
  String toString() => r'claimThreadProvider';
}

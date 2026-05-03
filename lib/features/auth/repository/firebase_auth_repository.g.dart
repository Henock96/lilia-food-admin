// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firebase_auth_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

final class AuthRepositoryProvider
    extends
        $FunctionalProvider<
          FirebaseAuthenticationRepository,
          FirebaseAuthenticationRepository,
          FirebaseAuthenticationRepository
        >
    with $Provider<FirebaseAuthenticationRepository> {
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<FirebaseAuthenticationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FirebaseAuthenticationRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseAuthenticationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseAuthenticationRepository>(
        value,
      ),
    );
  }
}

String _$authRepositoryHash() => r'222fa4d2b5f40f5c9e90c205ccb564533e9e3263';

@ProviderFor(firebaseAuth)
final firebaseAuthProvider = FirebaseAuthProvider._();

final class FirebaseAuthProvider
    extends $FunctionalProvider<FirebaseAuth, FirebaseAuth, FirebaseAuth>
    with $Provider<FirebaseAuth> {
  FirebaseAuthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseAuthProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseAuthHash();

  @$internal
  @override
  $ProviderElement<FirebaseAuth> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FirebaseAuth create(Ref ref) {
    return firebaseAuth(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseAuth value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseAuth>(value),
    );
  }
}

String _$firebaseAuthHash() => r'cb440927c3ab863427fd4b052a8ccba4c024c863';

@ProviderFor(authStateChange)
final authStateChangeProvider = AuthStateChangeProvider._();

final class AuthStateChangeProvider
    extends
        $FunctionalProvider<AsyncValue<AppUser?>, AppUser?, Stream<AppUser?>>
    with $FutureModifier<AppUser?>, $StreamProvider<AppUser?> {
  AuthStateChangeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateChangeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateChangeHash();

  @$internal
  @override
  $StreamProviderElement<AppUser?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<AppUser?> create(Ref ref) {
    return authStateChange(ref);
  }
}

String _$authStateChangeHash() => r'13565a8e927e644060491f8e10cca3bbaedd897e';

@ProviderFor(firebaseIdToken)
final firebaseIdTokenProvider = FirebaseIdTokenProvider._();

final class FirebaseIdTokenProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, Stream<String?>>
    with $FutureModifier<String?>, $StreamProvider<String?> {
  FirebaseIdTokenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseIdTokenProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseIdTokenHash();

  @$internal
  @override
  $StreamProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String?> create(Ref ref) {
    return firebaseIdToken(ref);
  }
}

String _$firebaseIdTokenHash() => r'fac680c4cd078ff8bb538e947b64a1ac9509f1dd';

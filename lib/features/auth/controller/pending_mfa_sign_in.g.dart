// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_mfa_sign_in.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// F3-08 — connexion interrompue par le second facteur (TOTP). Tant qu'il
/// est non nul, l'écran de connexion demande le code de l'application
/// d'authentification.

@ProviderFor(PendingMfaSignIn)
final pendingMfaSignInProvider = PendingMfaSignInProvider._();

/// F3-08 — connexion interrompue par le second facteur (TOTP). Tant qu'il
/// est non nul, l'écran de connexion demande le code de l'application
/// d'authentification.
final class PendingMfaSignInProvider
    extends $NotifierProvider<PendingMfaSignIn, MultiFactorResolver?> {
  /// F3-08 — connexion interrompue par le second facteur (TOTP). Tant qu'il
  /// est non nul, l'écran de connexion demande le code de l'application
  /// d'authentification.
  PendingMfaSignInProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingMfaSignInProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingMfaSignInHash();

  @$internal
  @override
  PendingMfaSignIn create() => PendingMfaSignIn();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MultiFactorResolver? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MultiFactorResolver?>(value),
    );
  }
}

String _$pendingMfaSignInHash() => r'2810480ea5d95fd9d2d630701e51f3eb00581b55';

/// F3-08 — connexion interrompue par le second facteur (TOTP). Tant qu'il
/// est non nul, l'écran de connexion demande le code de l'application
/// d'authentification.

abstract class _$PendingMfaSignIn extends $Notifier<MultiFactorResolver?> {
  MultiFactorResolver? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MultiFactorResolver?, MultiFactorResolver?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MultiFactorResolver?, MultiFactorResolver?>,
              MultiFactorResolver?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

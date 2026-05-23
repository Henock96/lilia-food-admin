// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_sync_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider qui stocke le profil utilisateur complet (incluant le restaurant)

@ProviderFor(CurrentUserProfile)
final currentUserProfileProvider = CurrentUserProfileProvider._();

/// Provider qui stocke le profil utilisateur complet (incluant le restaurant)
final class CurrentUserProfileProvider
    extends $NotifierProvider<CurrentUserProfile, AppUser?> {
  /// Provider qui stocke le profil utilisateur complet (incluant le restaurant)
  CurrentUserProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserProfileProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserProfileHash();

  @$internal
  @override
  CurrentUserProfile create() => CurrentUserProfile();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppUser? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppUser?>(value),
    );
  }
}

String _$currentUserProfileHash() =>
    r'34e997bc960bb3ba98a8c55ba6115480e706d402';

/// Provider qui stocke le profil utilisateur complet (incluant le restaurant)

abstract class _$CurrentUserProfile extends $Notifier<AppUser?> {
  AppUser? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AppUser?, AppUser?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppUser?, AppUser?>,
              AppUser?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(UserDataSynchronizer)
final userDataSynchronizerProvider = UserDataSynchronizerProvider._();

final class UserDataSynchronizerProvider
    extends $AsyncNotifierProvider<UserDataSynchronizer, void> {
  UserDataSynchronizerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userDataSynchronizerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userDataSynchronizerHash();

  @$internal
  @override
  UserDataSynchronizer create() => UserDataSynchronizer();
}

String _$userDataSynchronizerHash() =>
    r'7a4609aad98cab47b2a9f481a5aa538465fdc2ae';

abstract class _$UserDataSynchronizer extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

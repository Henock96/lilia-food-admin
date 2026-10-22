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
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AppUser?, AppUser?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppUser?, AppUser?>,
              AppUser?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(ProfileSyncStatus)
final profileSyncStatusProvider = ProfileSyncStatusProvider._();

final class ProfileSyncStatusProvider
    extends $NotifierProvider<ProfileSyncStatus, ProfileSyncState> {
  ProfileSyncStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileSyncStatusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileSyncStatusHash();

  @$internal
  @override
  ProfileSyncStatus create() => ProfileSyncStatus();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileSyncState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileSyncState>(value),
    );
  }
}

String _$profileSyncStatusHash() => r'a1a02dc04026e82a5f86289707c73636e575c136';

abstract class _$ProfileSyncStatus extends $Notifier<ProfileSyncState> {
  ProfileSyncState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ProfileSyncState, ProfileSyncState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProfileSyncState, ProfileSyncState>,
              ProfileSyncState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// `POST /users/sync` puis `GET /restaurants/mine`. Surchargeable en test.
///
/// 404 sur `/restaurants/mine` = pas de boutique (ADMIN) : profil sans
/// restaurant. Toute autre erreur fait échouer la synchronisation — un
/// vendeur ne travaille pas sans sa boutique, et l'ancien `catch` qui avalait
/// tout le laissait devant une app vide sans le lui dire.

@ProviderFor(profileLoader)
final profileLoaderProvider = ProfileLoaderProvider._();

/// `POST /users/sync` puis `GET /restaurants/mine`. Surchargeable en test.
///
/// 404 sur `/restaurants/mine` = pas de boutique (ADMIN) : profil sans
/// restaurant. Toute autre erreur fait échouer la synchronisation — un
/// vendeur ne travaille pas sans sa boutique, et l'ancien `catch` qui avalait
/// tout le laissait devant une app vide sans le lui dire.

final class ProfileLoaderProvider
    extends
        $FunctionalProvider<
          Future<AppUser?> Function(),
          Future<AppUser?> Function(),
          Future<AppUser?> Function()
        >
    with $Provider<Future<AppUser?> Function()> {
  /// `POST /users/sync` puis `GET /restaurants/mine`. Surchargeable en test.
  ///
  /// 404 sur `/restaurants/mine` = pas de boutique (ADMIN) : profil sans
  /// restaurant. Toute autre erreur fait échouer la synchronisation — un
  /// vendeur ne travaille pas sans sa boutique, et l'ancien `catch` qui avalait
  /// tout le laissait devant une app vide sans le lui dire.
  ProfileLoaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileLoaderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileLoaderHash();

  @$internal
  @override
  $ProviderElement<Future<AppUser?> Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Future<AppUser?> Function() create(Ref ref) {
    return profileLoader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Future<AppUser?> Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Future<AppUser?> Function()>(value),
    );
  }
}

String _$profileLoaderHash() => r'265a8b0b7117b9e23123843549e18009032c159f';

/// Effets d'un profil chargé : contexte Sentry, enregistrement du jeton FCM.
/// Surchargeable en test (FCM touche le plugin natif).

@ProviderFor(onProfileSynced)
final onProfileSyncedProvider = OnProfileSyncedProvider._();

/// Effets d'un profil chargé : contexte Sentry, enregistrement du jeton FCM.
/// Surchargeable en test (FCM touche le plugin natif).

final class OnProfileSyncedProvider
    extends
        $FunctionalProvider<
          Future<void> Function(AppUser user),
          Future<void> Function(AppUser user),
          Future<void> Function(AppUser user)
        >
    with $Provider<Future<void> Function(AppUser user)> {
  /// Effets d'un profil chargé : contexte Sentry, enregistrement du jeton FCM.
  /// Surchargeable en test (FCM touche le plugin natif).
  OnProfileSyncedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onProfileSyncedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onProfileSyncedHash();

  @$internal
  @override
  $ProviderElement<Future<void> Function(AppUser user)> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Future<void> Function(AppUser user) create(Ref ref) {
    return onProfileSynced(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Future<void> Function(AppUser user) value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Future<void> Function(AppUser user)>(
        value,
      ),
    );
  }
}

String _$onProfileSyncedHash() => r'76374016a68511a8b5b27ab05342a0f75a1aea97';

/// Effets d'une déconnexion côté profil. Surchargeable en test.

@ProviderFor(onProfileCleared)
final onProfileClearedProvider = OnProfileClearedProvider._();

/// Effets d'une déconnexion côté profil. Surchargeable en test.

final class OnProfileClearedProvider
    extends
        $FunctionalProvider<
          Future<void> Function(),
          Future<void> Function(),
          Future<void> Function()
        >
    with $Provider<Future<void> Function()> {
  /// Effets d'une déconnexion côté profil. Surchargeable en test.
  OnProfileClearedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onProfileClearedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onProfileClearedHash();

  @$internal
  @override
  $ProviderElement<Future<void> Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Future<void> Function() create(Ref ref) {
    return onProfileCleared(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Future<void> Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Future<void> Function()>(value),
    );
  }
}

String _$onProfileClearedHash() => r'8ac6e9be41fab9229ceb6fa36cf67ce6cfe0c6fe';

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
    r'c00c531f456f719820221b98ec9a0a792823f40d';

abstract class _$UserDataSynchronizer extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

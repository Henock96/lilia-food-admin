// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_guard.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Message laissé pour l'écran de connexion après une déconnexion forcée.

@ProviderFor(SessionEndNotice)
final sessionEndNoticeProvider = SessionEndNoticeProvider._();

/// Message laissé pour l'écran de connexion après une déconnexion forcée.
final class SessionEndNoticeProvider
    extends $NotifierProvider<SessionEndNotice, String?> {
  /// Message laissé pour l'écran de connexion après une déconnexion forcée.
  SessionEndNoticeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionEndNoticeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionEndNoticeHash();

  @$internal
  @override
  SessionEndNotice create() => SessionEndNotice();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$sessionEndNoticeHash() => r'3a21669263f475b7fd76b7bd5d0aa57e47b02836';

/// Message laissé pour l'écran de connexion après une déconnexion forcée.

abstract class _$SessionEndNotice extends $Notifier<String?> {
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

/// Une session Firebase est-elle ouverte ? Surchargeable en test.

@ProviderFor(hasFirebaseSession)
final hasFirebaseSessionProvider = HasFirebaseSessionProvider._();

/// Une session Firebase est-elle ouverte ? Surchargeable en test.

final class HasFirebaseSessionProvider
    extends
        $FunctionalProvider<bool Function(), bool Function(), bool Function()>
    with $Provider<bool Function()> {
  /// Une session Firebase est-elle ouverte ? Surchargeable en test.
  HasFirebaseSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hasFirebaseSessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hasFirebaseSessionHash();

  @$internal
  @override
  $ProviderElement<bool Function()> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool Function() create(Ref ref) {
    return hasFirebaseSession(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool Function()>(value),
    );
  }
}

String _$hasFirebaseSessionHash() =>
    r'49d6b39bb6530947deb59c57c4b9697aaae76101';

/// Déconnexion complète (jeton FCM, Firebase, données). Surchargeable en test.

@ProviderFor(sessionSignOut)
final sessionSignOutProvider = SessionSignOutProvider._();

/// Déconnexion complète (jeton FCM, Firebase, données). Surchargeable en test.

final class SessionSignOutProvider
    extends
        $FunctionalProvider<
          Future<bool> Function(),
          Future<bool> Function(),
          Future<bool> Function()
        >
    with $Provider<Future<bool> Function()> {
  /// Déconnexion complète (jeton FCM, Firebase, données). Surchargeable en test.
  SessionSignOutProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionSignOutProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionSignOutHash();

  @$internal
  @override
  $ProviderElement<Future<bool> Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Future<bool> Function() create(Ref ref) {
    return sessionSignOut(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Future<bool> Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Future<bool> Function()>(value),
    );
  }
}

String _$sessionSignOutHash() => r'5ea1df98d879e9f169ce5cb47cc2dd02d5d7e11e';

@ProviderFor(SessionGuard)
final sessionGuardProvider = SessionGuardProvider._();

final class SessionGuardProvider extends $NotifierProvider<SessionGuard, void> {
  SessionGuardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionGuardProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionGuardHash();

  @$internal
  @override
  SessionGuard create() => SessionGuard();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$sessionGuardHash() => r'c35d105c1641b083be9154b18e364e8af9d055cb';

abstract class _$SessionGuard extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

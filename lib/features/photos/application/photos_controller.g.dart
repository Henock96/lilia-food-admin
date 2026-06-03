// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photos_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider de la façade — overridable dans les tests.

@ProviderFor(photosFacade)
final photosFacadeProvider = PhotosFacadeProvider._();

/// Provider de la façade — overridable dans les tests.

final class PhotosFacadeProvider
    extends $FunctionalProvider<PhotosFacade, PhotosFacade, PhotosFacade>
    with $Provider<PhotosFacade> {
  /// Provider de la façade — overridable dans les tests.
  PhotosFacadeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'photosFacadeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$photosFacadeHash();

  @$internal
  @override
  $ProviderElement<PhotosFacade> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PhotosFacade create(Ref ref) {
    return photosFacade(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PhotosFacade value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PhotosFacade>(value),
    );
  }
}

String _$photosFacadeHash() => r'2f6bc2749395e3ac8641fb2278e30d6efbc9d589';

/// Provider du service Cloudinary — overridable dans les tests.

@ProviderFor(cloudinaryServiceForPhotos)
final cloudinaryServiceForPhotosProvider =
    CloudinaryServiceForPhotosProvider._();

/// Provider du service Cloudinary — overridable dans les tests.

final class CloudinaryServiceForPhotosProvider
    extends
        $FunctionalProvider<
          CloudinaryService,
          CloudinaryService,
          CloudinaryService
        >
    with $Provider<CloudinaryService> {
  /// Provider du service Cloudinary — overridable dans les tests.
  CloudinaryServiceForPhotosProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cloudinaryServiceForPhotosProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cloudinaryServiceForPhotosHash();

  @$internal
  @override
  $ProviderElement<CloudinaryService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CloudinaryService create(Ref ref) {
    return cloudinaryServiceForPhotos(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CloudinaryService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CloudinaryService>(value),
    );
  }
}

String _$cloudinaryServiceForPhotosHash() =>
    r'ed1504a4a79badfa83c2795749a34b21a4fd52f5';

/// AsyncNotifier paramétré par (EntityType, parentId). Gère la liste des
/// photos d'une entité + les 5 mutations optimistic.

@ProviderFor(PhotosController)
final photosControllerProvider = PhotosControllerFamily._();

/// AsyncNotifier paramétré par (EntityType, parentId). Gère la liste des
/// photos d'une entité + les 5 mutations optimistic.
final class PhotosControllerProvider
    extends $AsyncNotifierProvider<PhotosController, List<Photo>> {
  /// AsyncNotifier paramétré par (EntityType, parentId). Gère la liste des
  /// photos d'une entité + les 5 mutations optimistic.
  PhotosControllerProvider._({
    required PhotosControllerFamily super.from,
    required (EntityType, String) super.argument,
  }) : super(
         retry: null,
         name: r'photosControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$photosControllerHash();

  @override
  String toString() {
    return r'photosControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  PhotosController create() => PhotosController();

  @override
  bool operator ==(Object other) {
    return other is PhotosControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$photosControllerHash() => r'1d7a10001404820a1f245a2f973db8a0ddf2472c';

/// AsyncNotifier paramétré par (EntityType, parentId). Gère la liste des
/// photos d'une entité + les 5 mutations optimistic.

final class PhotosControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          PhotosController,
          AsyncValue<List<Photo>>,
          List<Photo>,
          FutureOr<List<Photo>>,
          (EntityType, String)
        > {
  PhotosControllerFamily._()
    : super(
        retry: null,
        name: r'photosControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// AsyncNotifier paramétré par (EntityType, parentId). Gère la liste des
  /// photos d'une entité + les 5 mutations optimistic.

  PhotosControllerProvider call(EntityType type, String parentId) =>
      PhotosControllerProvider._(argument: (type, parentId), from: this);

  @override
  String toString() => r'photosControllerProvider';
}

/// AsyncNotifier paramétré par (EntityType, parentId). Gère la liste des
/// photos d'une entité + les 5 mutations optimistic.

abstract class _$PhotosController extends $AsyncNotifier<List<Photo>> {
  late final _$args = ref.$arg as (EntityType, String);
  EntityType get type => _$args.$1;
  String get parentId => _$args.$2;

  FutureOr<List<Photo>> build(EntityType type, String parentId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Photo>>, List<Photo>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Photo>>, List<Photo>>,
              AsyncValue<List<Photo>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}

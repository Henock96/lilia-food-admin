import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../users/data/cloudinary_service.dart';
import '../data/photo_models.dart';
import '../data/photos_facade.dart';

part 'photos_controller.g.dart';

/// Provider de la façade — overridable dans les tests.
@riverpod
PhotosFacade photosFacade(Ref ref) => PhotosFacade();

/// Provider du service Cloudinary — overridable dans les tests.
@riverpod
CloudinaryService cloudinaryServiceForPhotos(Ref ref) => CloudinaryService();

/// AsyncNotifier paramétré par (EntityType, parentId). Gère la liste des
/// photos d'une entité + les 5 mutations optimistic.
@riverpod
class PhotosController extends _$PhotosController {
  @override
  Future<List<Photo>> build(EntityType type, String parentId) async {
    final facade = ref.watch(photosFacadeProvider);
    final list = await facade.list(type, parentId);
    // Garde la liste triée par displayOrder pour l'UI.
    list.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return list;
  }

  /// Recharge la liste depuis l'API.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final facade = ref.read(photosFacadeProvider);
      final list = await facade.list(type, parentId);
      list.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      return list;
    });
  }

  /// Upload Cloudinary puis POST. Le premier upload d'une entité (liste
  /// actuellement vide) marque automatiquement la photo comme cover.
  Future<void> add(XFile file, {bool? isCover, String? alt}) async {
    final current = state.value ?? const <Photo>[];
    if (current.length >= 5) {
      throw Exception('Maximum 5 photos par ${type.label}');
    }

    final cloudinary = ref.read(cloudinaryServiceForPhotosProvider);
    final upload = await cloudinary.uploadImageWithPublicId(file);
    if (upload == null) {
      throw Exception('Échec de l\'upload Cloudinary');
    }

    final shouldBeCover = isCover ?? current.isEmpty;

    final facade = ref.read(photosFacadeProvider);
    final created = await facade.create(
      type,
      parentId,
      url: upload.secureUrl,
      publicId: upload.publicId,
      alt: alt,
      isCover: shouldBeCover,
    );

    // Mise à jour : si la nouvelle photo est cover, on démet les autres
    // covers localement (le backend a déjà fait le travail côté DB).
    final updated = [
      for (final p in current)
        if (shouldBeCover) p.copyWith(isCover: false) else p,
      created,
    ];
    updated.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    state = AsyncData(updated);
  }

  /// Bascule isCover=true sur la cible et démet les autres covers en local
  /// avant l'appel API. Rollback complet sur erreur.
  Future<void> setCover(String photoId) async {
    final current = state.value ?? const <Photo>[];
    if (current.isEmpty) return;

    final previous = current;
    final optimistic = current
        .map((p) => p.copyWith(isCover: p.id == photoId))
        .toList();
    state = AsyncData(optimistic);

    try {
      final facade = ref.read(photosFacadeProvider);
      await facade.update(type, photoId, isCover: true);
    } catch (e) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  /// Édite le `alt` d'une photo. Optimistic + rollback.
  Future<void> editAlt(String photoId, String alt) async {
    final current = state.value ?? const <Photo>[];
    final previous = current;
    final optimistic = current
        .map((p) => p.id == photoId ? p.copyWith(alt: alt) : p)
        .toList();
    state = AsyncData(optimistic);

    try {
      final facade = ref.read(photosFacadeProvider);
      await facade.update(type, photoId, alt: alt);
    } catch (e) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  /// Supprime localement avant l'appel DELETE. Rollback si erreur réseau.
  Future<void> delete(String photoId) async {
    final current = state.value ?? const <Photo>[];
    final previous = current;
    final optimistic = current.where((p) => p.id != photoId).toList();
    state = AsyncData(optimistic);

    try {
      final facade = ref.read(photosFacadeProvider);
      await facade.delete(type, photoId);
    } catch (e) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  /// Réordonne en local (avec réécriture des displayOrder) puis POST
  /// /reorder avec la liste d'IDs. Rollback si erreur.
  Future<void> reorder(List<String> newIds) async {
    final current = state.value ?? const <Photo>[];
    if (current.isEmpty) return;

    final previous = current;
    final byId = {for (final p in current) p.id: p};
    final reordered = <Photo>[];
    for (var i = 0; i < newIds.length; i++) {
      final photo = byId[newIds[i]];
      if (photo == null) continue;
      reordered.add(photo.copyWith(displayOrder: i));
    }
    state = AsyncData(reordered);

    try {
      final facade = ref.read(photosFacadeProvider);
      await facade.reorder(type, parentId, newIds);
    } catch (e) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

import 'menu_images_service.dart';
import 'photo_models.dart';
import 'product_images_service.dart';
import 'vendor_photos_service.dart';

/// Routeur uniforme : expose les 5 opérations CRUD+reorder pour les 3
/// entités photo en redirigeant vers le bon service HTTP selon
/// [EntityType]. C'est ce que consomme `PhotosController`.
class PhotosFacade {
  final VendorPhotosService _vendor;
  final ProductImagesService _product;
  final MenuImagesService _menu;

  PhotosFacade({
    VendorPhotosService? vendor,
    ProductImagesService? product,
    MenuImagesService? menu,
  })  : _vendor = vendor ?? VendorPhotosService(),
        _product = product ?? ProductImagesService(),
        _menu = menu ?? MenuImagesService();

  Future<List<Photo>> list(EntityType type, String parentId) {
    switch (type) {
      case EntityType.vendor:
        return _vendor.list(parentId);
      case EntityType.product:
        return _product.list(parentId);
      case EntityType.menu:
        return _menu.list(parentId);
    }
  }

  Future<Photo> create(
    EntityType type,
    String parentId, {
    required String url,
    required String publicId,
    String? alt,
    bool isCover = false,
  }) {
    switch (type) {
      case EntityType.vendor:
        return _vendor.create(
          restaurantId: parentId,
          url: url,
          publicId: publicId,
          alt: alt,
          isCover: isCover,
        );
      case EntityType.product:
        return _product.create(
          productId: parentId,
          url: url,
          publicId: publicId,
          alt: alt,
          isCover: isCover,
        );
      case EntityType.menu:
        return _menu.create(
          menuDuJourId: parentId,
          url: url,
          publicId: publicId,
          alt: alt,
          isCover: isCover,
        );
    }
  }

  Future<Photo> update(
    EntityType type,
    String photoId, {
    String? alt,
    bool? isCover,
    int? displayOrder,
  }) {
    switch (type) {
      case EntityType.vendor:
        return _vendor.update(
          photoId,
          alt: alt,
          isCover: isCover,
          displayOrder: displayOrder,
        );
      case EntityType.product:
        return _product.update(
          photoId,
          alt: alt,
          isCover: isCover,
          displayOrder: displayOrder,
        );
      case EntityType.menu:
        return _menu.update(
          photoId,
          alt: alt,
          isCover: isCover,
          displayOrder: displayOrder,
        );
    }
  }

  Future<void> delete(EntityType type, String photoId) {
    switch (type) {
      case EntityType.vendor:
        return _vendor.delete(photoId);
      case EntityType.product:
        return _product.delete(photoId);
      case EntityType.menu:
        return _menu.delete(photoId);
    }
  }

  Future<void> reorder(
    EntityType type,
    String parentId,
    List<String> ids,
  ) {
    switch (type) {
      case EntityType.vendor:
        return _vendor.reorder(parentId, ids);
      case EntityType.product:
        return _product.reorder(parentId, ids);
      case EntityType.menu:
        return _menu.reorder(parentId, ids);
    }
  }
}

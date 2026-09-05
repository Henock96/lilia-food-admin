import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'package:lilia_admin/core/network/api_client.dart';

import '../../photos/data/photo_models.dart';

/// Dossiers Cloudinary acceptés par le backend (`CloudinaryFolder`).
///
/// Le périmètre réellement autorisé dépend du rôle de l'appelant : un CLIENT
/// n'écrit que dans `users`, un RESTAURATEUR n'atteint pas `banners`. Le
/// contrôle est fait côté serveur — cette énumération sert à ne pas envoyer une
/// valeur qui sera de toute façon refusée.
enum UploadFolder { restaurants, products, menus, users, banners }

/// Upload d'images via le backend (`POST /upload/image`).
///
/// **Historique.** Ce service uploadait en direct vers Cloudinary avec un preset
/// *unsigned* (`ml_default`) et un `cloud_name` codé en dur dans le bundle :
/// n'importe qui pouvait déposer des fichiers arbitraires sur le compte
/// Cloudinary de Lilia — abus de quota et hébergement de contenu illicite sous
/// le domaine du projet. Aucune des protections du backend ne s'appliquait à ce
/// chemin : ni taille maximale, ni type MIME, ni rôle, ni dossier imposé.
///
/// `apps/admin` (web) avait été migré lors de l'audit d'août 2026 ; cette app
/// ne l'avait pas été, alors que sa documentation l'affirmait. C'est corrigé
/// ici : tout passe désormais par le backend authentifié, qui applique 5 Mo
/// max, un `FileTypeValidator` (jpeg/png/webp), un contrôle de rôle et un
/// throttle.
class CloudinaryService {
  final ApiClient _api;

  CloudinaryService(this._api);

  /// Limite alignée sur `MaxFileSizeValidator` côté backend. La vraie barrière
  /// est côté serveur ; ce contrôle évite un aller-retour réseau inutile sur
  /// une image manifestement trop lourde.
  static const int maxBytes = 5 * 1024 * 1024;
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  /// Conserve l'API historique pour `profile_controller.dart` : ne retourne
  /// que l'URL sécurisée.
  Future<String?> uploadImage(
    XFile image, {
    UploadFolder folder = UploadFolder.users,
  }) async {
    final result = await uploadImageWithPublicId(image, folder: folder);
    return result?.secureUrl;
  }

  /// Retourne aussi le `publicId`, nécessaire pour que le backend puisse
  /// supprimer l'ancienne image lors d'un remplacement.
  Future<CloudinaryUploadResult?> uploadImageWithPublicId(
    XFile image, {
    UploadFolder folder = UploadFolder.products,
  }) async {
    try {
      final bytes = await image.readAsBytes();
      if (bytes.lengthInBytes > maxBytes) {
        throw const UploadException(
          'Image trop lourde : 5 Mo maximum. Choisissez une image plus légère.',
        );
      }

      final name = image.name.toLowerCase();
      final hasAllowedExtension =
          allowedExtensions.any((ext) => name.endsWith('.$ext'));
      if (!hasAllowedExtension) {
        throw const UploadException(
          'Format non accepté. Utilisez une image JPEG, PNG ou WebP.',
        );
      }

      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: image.name),
      });

      final res = await _api.postForm(
        '/upload/image',
        form,
        query: {'folder': folder.name},
      );

      // `POST /upload/image` renvoie un objet plat `{ url, publicId, ... }`,
      // enveloppé par l'intercepteur global en `{ data: {...} }`.
      final data = res.data;
      final map = data is Map<String, dynamic> && data['data'] is Map
          ? data['data'] as Map<String, dynamic>
          : data as Map<String, dynamic>;

      return CloudinaryUploadResult(
        secureUrl: map['url'] as String,
        publicId: map['publicId'] as String? ?? '',
      );
    } on UploadException {
      rethrow;
    } catch (e) {
      debugPrint('Upload image échoué : $e');
      return null;
    }
  }
}

/// Erreur d'upload porteuse d'un message affichable à l'utilisateur.
class UploadException implements Exception {
  final String message;
  const UploadException(this.message);

  @override
  String toString() => message;
}

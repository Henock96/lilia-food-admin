import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../photos/data/photo_models.dart';

class CloudinaryService {
  final _cloudinary = CloudinaryPublic('dun9ev7pw', 'ml_default', cache: false);

  /// Conserve l'API historique pour `profile_controller.dart` : ne retourne
  /// que l'URL secure.
  Future<String?> uploadImage(XFile image) async {
    final result = await uploadImageWithPublicId(image);
    return result?.secureUrl;
  }

  /// Nouvelle API utilisée par la feature photos : retourne aussi le
  /// `publicId` Cloudinary, nécessaire pour activer le cleanup côté backend.
  Future<CloudinaryUploadResult?> uploadImageWithPublicId(XFile image) async {
    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          image.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return CloudinaryUploadResult(
        secureUrl: response.secureUrl,
        publicId: response.publicId,
      );
    } on CloudinaryException catch (e) {
      debugPrint('CloudinaryException: ${e.message}');
      return null;
    }
  }
}

import 'package:flutter/material.dart';

import '../../../../common_widgets/photo_gallery_editor.dart';
import '../../data/photo_models.dart';

/// Écran dédié à la gestion des photos d'une entité.
/// Reçoit `entityType` (string brute issue de la query) + `parentId`.
class PhotosScreen extends StatelessWidget {
  const PhotosScreen({
    super.key,
    required this.entityTypeString,
    required this.parentId,
  });

  final String entityTypeString;
  final String parentId;

  @override
  Widget build(BuildContext context) {
    final EntityType entityType;
    try {
      entityType = EntityTypeX.fromString(entityTypeString);
    } catch (_) {
      return Scaffold(
        appBar: AppBar(title: const Text('Photos')),
        body: const Center(
          child: Text('Type d\'entité inconnu.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Photos · ${entityType.label}'),
        centerTitle: true,
      ),
      body: PhotoGalleryEditor(
        entityType: entityType,
        parentId: parentId,
      ),
    );
  }
}

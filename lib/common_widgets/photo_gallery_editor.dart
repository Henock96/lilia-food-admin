import 'package:flutter/material.dart';
import 'package:lilia_admin/common_widgets/app_cached_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../features/photos/application/photos_controller.dart';
import '../features/photos/data/photo_models.dart';

/// Widget réutilisable qui rend la galerie photos d'une entité.
/// Paramétré par [entityType] + [parentId]. Connecté à
/// `photosControllerProvider(entityType, parentId)`.
class PhotoGalleryEditor extends ConsumerWidget {
  const PhotoGalleryEditor({
    super.key,
    required this.entityType,
    required this.parentId,
  });

  final EntityType entityType;
  final String parentId;

  static const int _maxPhotos = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = photosControllerProvider(entityType, parentId);
    final asyncPhotos = ref.watch(provider);

    return asyncPhotos.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) => _ErrorState(
        message: 'Erreur de chargement : $err',
        onRetry: () => ref.read(provider.notifier).refresh(),
      ),
      data: (photos) {
        if (photos.isEmpty) {
          return _EmptyState(
            onAdd: () => _pickAndUpload(context, ref),
            entityType: entityType,
          );
        }
        return _GalleryGrid(
          photos: photos,
          canAddMore: photos.length < _maxPhotos,
          onAdd: () => _pickAndUpload(context, ref),
          onReorder: (ids) =>
              ref.read(provider.notifier).reorder(ids),
          onSetCover: (id) async {
            try {
              await ref.read(provider.notifier).setCover(id);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur cover : $e')),
                );
              }
            }
          },
          onEditAlt: (photo) => _showEditAltDialog(context, ref, photo),
          onDelete: (photo) => _confirmDelete(context, ref, photo),
        );
      },
    );
  }

  Future<void> _pickAndUpload(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Upload en cours…'),
        duration: Duration(seconds: 60),
      ),
    );

    try {
      await ref
          .read(photosControllerProvider(entityType, parentId).notifier)
          .add(file);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(const SnackBar(content: Text('Photo ajoutée')));
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text('Erreur upload : $e')));
    }
  }

  Future<void> _showEditAltDialog(
    BuildContext context,
    WidgetRef ref,
    Photo photo,
  ) async {
    final controller = TextEditingController(text: photo.alt ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Description (alt)'),
        content: TextField(
          controller: controller,
          maxLength: 200,
          decoration: const InputDecoration(
            hintText: 'Décrivez la photo',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (result == null) return;
    try {
      await ref
          .read(photosControllerProvider(entityType, parentId).notifier)
          .editAlt(photo.id, result);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur édition alt : $e')),
        );
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Photo photo,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette photo ?'),
        content: const Text('Cette action est définitive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(photosControllerProvider(entityType, parentId).notifier)
          .delete(photo.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur suppression : $e')),
        );
      }
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd, required this.entityType});

  final VoidCallback onAdd;
  final EntityType entityType;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Aucune photo pour l\'instant',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez la première photo de ce ${entityType.label}.',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Ajouter la première'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}

class _GalleryGrid extends StatelessWidget {
  const _GalleryGrid({
    required this.photos,
    required this.canAddMore,
    required this.onAdd,
    required this.onReorder,
    required this.onSetCover,
    required this.onEditAlt,
    required this.onDelete,
  });

  final List<Photo> photos;
  final bool canAddMore;
  final VoidCallback onAdd;
  final ValueChanged<List<String>> onReorder;
  final ValueChanged<String> onSetCover;
  final ValueChanged<Photo> onEditAlt;
  final ValueChanged<Photo> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${photos.length} / 5 photos',
                  style: Theme.of(context).textTheme.titleSmall),
              Tooltip(
                message: canAddMore
                    ? 'Ajouter une photo'
                    : 'Maximum 5 atteint',
                child: FilledButton.icon(
                  onPressed: canAddMore ? onAdd : null,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Ajouter'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: photos.length,
            onReorderItem: (oldIndex, newIndex) {
              final ids = photos.map((p) => p.id).toList();
              final moved = ids.removeAt(oldIndex);
              ids.insert(newIndex, moved);
              onReorder(ids);
            },
            itemBuilder: (context, index) {
              final photo = photos[index];
              return _PhotoTile(
                key: ValueKey(photo.id),
                photo: photo,
                onSetCover: () => onSetCover(photo.id),
                onEditAlt: () => onEditAlt(photo),
                onDelete: () => onDelete(photo),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    super.key,
    required this.photo,
    required this.onSetCover,
    required this.onEditAlt,
    required this.onDelete,
  });

  final Photo photo;
  final VoidCallback onSetCover;
  final VoidCallback onEditAlt;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Stack(
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: AppCachedImage(
                  imageUrl: photo.url,
                  fit: BoxFit.cover,
                  errorIcon: Icons.broken_image,
                ),
              ),
              if (photo.isCover)
                const Positioned(
                  top: 6,
                  left: 6,
                  child: Icon(Icons.star, color: Colors.amber, size: 24),
                ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    photo.alt?.isNotEmpty == true ? photo.alt! : '(sans alt)',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ordre ${photo.displayOrder}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: photo.isCover ? 'Cover actuel' : 'Définir cover',
                        icon: Icon(
                          photo.isCover ? Icons.star : Icons.star_outline,
                          color: photo.isCover ? Colors.amber : null,
                        ),
                        onPressed: photo.isCover ? null : onSetCover,
                      ),
                      IconButton(
                        tooltip: 'Éditer description',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: onEditAlt,
                      ),
                      IconButton(
                        tooltip: 'Supprimer',
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.drag_handle, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

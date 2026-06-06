import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../photos/application/photos_controller.dart';
import 'product_image_buffer.dart';

/// Champ de formulaire (création produit) : sélection multiple d'images,
/// upload Cloudinary immédiat, grille de previews avec couverture / suppression.
/// Le rattachement aux ProductImage se fait après création du produit.
class ProductImageBufferField extends ConsumerStatefulWidget {
  const ProductImageBufferField({super.key, required this.buffer});

  final ProductImageBuffer buffer;

  @override
  ConsumerState<ProductImageBufferField> createState() =>
      _ProductImageBufferFieldState();
}

class _ProductImageBufferFieldState
    extends ConsumerState<ProductImageBufferField> {
  bool _isUploading = false;

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (files.isEmpty) return;

    setState(() => _isUploading = true);
    final cloudinary = ref.read(cloudinaryServiceForPhotosProvider);
    var failures = 0;
    for (final file in files) {
      if (widget.buffer.isFull) break;
      final result = await cloudinary.uploadImageWithPublicId(file);
      if (result == null) {
        failures++;
        continue;
      }
      widget.buffer.add(url: result.secureUrl, publicId: result.publicId);
    }
    if (mounted) {
      setState(() => _isUploading = false);
      if (failures > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$failures image(s) n\'ont pas pu être uploadées')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.buffer,
      builder: (context, _) {
        final drafts = widget.buffer.drafts;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Photos ${drafts.length}/${ProductImageBuffer.maxImages}',
                    style: Theme.of(context).textTheme.titleSmall),
                FilledButton.icon(
                  onPressed: (_isUploading || widget.buffer.isFull)
                      ? null
                      : _pickAndUpload,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (drafts.isEmpty)
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Center(
                  child: Text('Aucune photo. Ajoutez-en jusqu\'à 5.',
                      style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: drafts.length,
                itemBuilder: (context, index) {
                  final d = drafts[index];
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(d.url, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 2, left: 2,
                        child: IconButton(
                          tooltip: d.isCover ? 'Couverture' : 'Définir couverture',
                          iconSize: 20,
                          onPressed: () => widget.buffer.setCover(index),
                          icon: Icon(
                            d.isCover ? Icons.star : Icons.star_outline,
                            color: d.isCover ? Colors.amber : Colors.white,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 2, right: 2,
                        child: IconButton(
                          tooltip: 'Supprimer',
                          iconSize: 20,
                          onPressed: () => widget.buffer.removeAt(index),
                          icon: const Icon(Icons.cancel, color: Colors.redAccent),
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

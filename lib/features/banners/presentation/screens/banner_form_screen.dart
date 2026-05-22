import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../models/banner.dart';
import '../../../users/data/cloudinary_service.dart';
import '../providers/banners_provider.dart';

class BannerFormScreen extends ConsumerStatefulWidget {
  final AppBanner? banner;

  const BannerFormScreen({super.key, this.banner});

  @override
  ConsumerState<BannerFormScreen> createState() => _BannerFormScreenState();
}

class _BannerFormScreenState extends ConsumerState<BannerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageUrlController;
  late TextEditingController _linkUrlController;
  bool _isActive = true;
  bool _isLoading = false;
  bool _isUploading = false;

  bool get isEditing => widget.banner != null;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.banner?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.banner?.description ?? '');
    _imageUrlController =
        TextEditingController(text: widget.banner?.imageUrl ?? '');
    _linkUrlController =
        TextEditingController(text: widget.banner?.linkUrl ?? '');
    _isActive = widget.banner?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _linkUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final cloudinary = CloudinaryService();
      final url = await cloudinary.uploadImage(image);

      if (url != null && mounted) {
        setState(() {
          _imageUrlController.text = url;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploadée avec succès')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de l'upload")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _saveBanner() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = {
        if (_titleController.text.trim().isNotEmpty)
          'title': _titleController.text.trim(),
        'imageUrl': _imageUrlController.text.trim(),
        if (_descriptionController.text.trim().isNotEmpty)
          'description': _descriptionController.text.trim(),
        if (_linkUrlController.text.trim().isNotEmpty)
          'linkUrl': _linkUrlController.text.trim(),
        'isActive': _isActive,
      };

      if (isEditing) {
        await ref
            .read(bannersProvider.notifier)
            .updateBanner(widget.banner!.id, data);
      } else {
        await ref.read(bannersProvider.notifier).createBanner(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Bannière mise à jour'
                  : 'Bannière créée avec succès',
            ),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier la bannière' : 'Nouvelle bannière'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Aperçu image
              GestureDetector(
                onTap: _isUploading ? null : _pickAndUploadImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _isUploading
                      ? const Center(child: CircularProgressIndicator())
                      : _imageUrlController.text.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _imageUrlController.text,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (_, _, _) =>
                                    _buildImagePlaceholder(),
                              ),
                            )
                          : _buildImagePlaceholder(),
                ),
              ),

              const SizedBox(height: 20),

              // Titre
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre (optionnel)',
                  border: OutlineInputBorder(),
                  hintText: 'Titre de la bannière',
                ),
              ),

              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  hintText: 'Description optionnelle',
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              // URL image (en lecture, rempli par Cloudinary)
              TextFormField(
                controller: _imageUrlController,
                decoration: InputDecoration(
                  labelText: 'URL de l\'image *',
                  border: const OutlineInputBorder(),
                  hintText: 'Uploadez une image ci-dessus',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.upload),
                    onPressed: _isUploading ? null : _pickAndUploadImage,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "L'image est obligatoire";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // URL lien (optionnel)
              TextFormField(
                controller: _linkUrlController,
                decoration: const InputDecoration(
                  labelText: 'Lien (optionnel)',
                  border: OutlineInputBorder(),
                  hintText: 'URL de redirection au clic',
                ),
              ),

              const SizedBox(height: 16),

              // Toggle actif
              SwitchListTile(
                title: const Text('Bannière active'),
                subtitle: Text(
                  _isActive
                      ? 'Visible sur l\'application'
                      : 'Masquée de l\'application',
                ),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 24),

              // Bouton sauvegarder
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveBanner,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isEditing ? 'Mettre à jour' : 'Créer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey),
        SizedBox(height: 8),
        Text(
          'Appuyez pour ajouter une image',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lilia_admin/common_widgets/app_cached_image.dart';
import 'package:lilia_admin/core/network/api_client.dart';
import 'package:image_picker/image_picker.dart';
import '../../../users/data/cloudinary_service.dart';
import '../../data/admin_service.dart';

class CreateRestaurantScreen extends ConsumerStatefulWidget {
  const CreateRestaurantScreen({super.key});

  @override
  ConsumerState<CreateRestaurantScreen> createState() =>
      _CreateRestaurantScreenState();
}

class _CreateRestaurantScreenState extends ConsumerState<CreateRestaurantScreen> {
  int _currentStep = 0;
  final _formKeyStep0 = GlobalKey<FormState>();
  final _formKeyStep1 = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isUploading = false;

  // Step 1 - Owner info
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  // Step 2 - Restaurant info
  final _restaurantNomController = TextEditingController();
  final _restaurantAdresseController = TextEditingController();
  final _restaurantPhoneController = TextEditingController();
  final _restaurantImageUrlController = TextEditingController();

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _restaurantNomController.dispose();
    _restaurantAdresseController.dispose();
    _restaurantPhoneController.dispose();
    _restaurantImageUrlController.dispose();
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
          _restaurantImageUrlController.text = url;
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

  Future<void> _submit() async {
    setState(() => _isLoading = true);

    try {
      final adminService = AdminService(ref.read(apiClientProvider));
      await adminService.createRestaurantWithOwner(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        nom: _nomController.text.trim(),
        phone: _phoneController.text.trim(),
        restaurantNom: _restaurantNomController.text.trim(),
        restaurantAdresse: _restaurantAdresseController.text.trim(),
        restaurantPhone: _restaurantPhoneController.text.trim(),
        restaurantImageUrl: _restaurantImageUrlController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restaurant et restaurateur créés avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      if (!_formKeyStep0.currentState!.validate()) return;
    } else if (_currentStep == 1) {
      if (!_formKeyStep1.currentState!.validate()) return;
    }

    if (_currentStep < 2) {
      setState(() => _currentStep += 1);
    } else {
      _submit();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un restaurant'),
        centerTitle: true,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _isLoading ? null : _onStepContinue,
        onStepCancel: _isLoading ? null : _onStepCancel,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : details.onStepContinue,
                  child: _isLoading && _currentStep == 2
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_currentStep == 2 ? 'Créer' : 'Suivant'),
                ),
                const SizedBox(width: 12),
                if (_currentStep > 0)
                  TextButton(
                    onPressed: _isLoading ? null : details.onStepCancel,
                    child: const Text('Précédent'),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Restaurateur'),
            subtitle: const Text('Informations du propriétaire'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: Form(
              key: _formKeyStep0,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nomController,
                    decoration: const InputDecoration(
                      labelText: 'Nom *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Le nom est requis' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'L\'email est requis';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                        return 'Email invalide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Mot de passe *',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Le mot de passe est requis';
                      }
                      if (v.trim().length < 6) {
                        return 'Minimum 6 caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Téléphone (optionnel)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Restaurant'),
            subtitle: const Text('Informations du restaurant'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: Form(
              key: _formKeyStep1,
              child: Column(
                children: [
                  TextFormField(
                    controller: _restaurantNomController,
                    decoration: const InputDecoration(
                      labelText: 'Nom du restaurant *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Le nom est requis'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _restaurantAdresseController,
                    decoration: const InputDecoration(
                      labelText: 'Adresse *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'L\'adresse est requise'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _restaurantPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Téléphone restaurant *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Le téléphone est requis'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  // Image upload
                  GestureDetector(
                    onTap: _isUploading ? null : _pickAndUploadImage,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: _isUploading
                          ? const Center(child: CircularProgressIndicator())
                          : _restaurantImageUrlController.text.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: AppCachedImage(
                                    imageUrl: _restaurantImageUrlController.text,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorWidget: _buildImagePlaceholder(),
                                  ),
                                )
                              : _buildImagePlaceholder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Récapitulatif'),
            subtitle: const Text('Vérifiez les informations'),
            isActive: _currentStep >= 2,
            content: _buildSummary(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Restaurateur',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _summaryRow('Nom', _nomController.text),
        _summaryRow('Email', _emailController.text),
        _summaryRow('Mot de passe', '••••••'),
        if (_phoneController.text.isNotEmpty)
          _summaryRow('Téléphone', _phoneController.text),
        const Divider(height: 24),
        const Text(
          'Restaurant',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _summaryRow('Nom', _restaurantNomController.text),
        _summaryRow('Adresse', _restaurantAdresseController.text),
        _summaryRow('Téléphone', _restaurantPhoneController.text),
        if (_restaurantImageUrlController.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AppCachedImage(
              imageUrl: _restaurantImageUrlController.text,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
              errorWidget: const SizedBox.shrink(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label :',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey),
        SizedBox(height: 8),
        Text(
          'Ajouter une image (optionnel)',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}

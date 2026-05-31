import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../models/product.dart';
import '../../../../models/product_type.dart';
import '../../../../models/stock_mode.dart';
import '../../../../models/vendor_type.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../categories/presentation/widgets/create_category_dialog.dart';
import '../../../restaurant/presentation/providers/restaurant_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../users/data/cloudinary_service.dart';
import '../providers/products_provider.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _imageUrlController;
  late TextEditingController _stockController;
  late TextEditingController _ingredientsController;
  late TextEditingController _shelfLifeController;
  String? _selectedCategoryId;
  List<ProductVariant> _variants = [];
  bool _isLoading = false;
  bool _isUploading = false;

  // LIL-126 : champs marketplace + pré-commande
  ProductType? _productType;
  StockMode _stockMode = StockMode.DAILY;
  bool _madeToOrder = false;

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.product?.description ?? '');
    _priceController = TextEditingController(
        text: widget.product?.prixOriginal.toStringAsFixed(0) ?? '');
    _imageUrlController =
        TextEditingController(text: widget.product?.imageUrl ?? '');
    _stockController = TextEditingController(
        text: widget.product?.stockQuotidien?.toString() ?? '');
    _ingredientsController =
        TextEditingController(text: widget.product?.ingredients ?? '');
    _shelfLifeController = TextEditingController(
        text: widget.product?.shelfLifeDays?.toString() ?? '');
    _selectedCategoryId = widget.product?.categoryId;
    _variants = widget.product?.variants.toList() ?? [];
    _productType = widget.product?.productType;
    _stockMode = widget.product?.stockMode ?? StockMode.DAILY;
    _madeToOrder = widget.product?.madeToOrder ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _stockController.dispose();
    _ingredientsController.dispose();
    _shelfLifeController.dispose();
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

  /// LIL-129 : champ catégorie qui s'adapte au cas où la liste est vide
  /// (cas typique des nouveaux vendeurs non-RESTAURANT qui n'ont pas
  /// encore créé leurs catégories). Affiche un état vide bloquant avec
  /// bouton "Créer ma 1re catégorie" plutôt qu'un dropdown vide qui
  /// empêcherait l'enregistrement.
  Widget _buildCategoryField(List<Category> categories) {
    if (categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.amber[800]),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Aucune catégorie',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Vous devez créer au moins une catégorie pour pouvoir '
              'enregistrer un produit (ex. "Pâtisseries", "Boissons").',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _openCreateCategoryDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Créer ma 1re catégorie'),
            ),
          ],
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _selectedCategoryId,
            decoration: const InputDecoration(
              labelText: 'Catégorie *',
              border: OutlineInputBorder(),
            ),
            items: categories
                .map((cat) => DropdownMenuItem(
                      value: cat.id,
                      child: Text(cat.name),
                    ))
                .toList(),
            onChanged: (value) =>
                setState(() => _selectedCategoryId = value),
            validator: (value) =>
                value == null ? 'Sélectionnez une catégorie' : null,
          ),
        ),
        const SizedBox(width: 8),
        // Raccourci "+" pour créer une catégorie sans quitter le form.
        IconButton.filledTonal(
          tooltip: 'Nouvelle catégorie',
          onPressed: _openCreateCategoryDialog,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }

  Future<void> _openCreateCategoryDialog() async {
    final created = await showCreateCategoryDialog(context, ref);
    if (created != null && mounted) {
      // Auto-sélectionne la catégorie tout juste créée.
      setState(() => _selectedCategoryId = created.id);
    }
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

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une catégorie')),
      );
      return;
    }
    if (_productType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un type de produit')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final restaurantId = ref.read(currentRestaurantIdProvider);
      final stockText = _stockController.text.trim();
      final ingredientsText = _ingredientsController.text.trim();
      final shelfLifeText = _shelfLifeController.text.trim();
      final productData = {
        'nom': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'prixOriginal': double.parse(_priceController.text.trim()),
        'imageUrl': _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
        'categoryId': _selectedCategoryId,
        'restaurantId': restaurantId,
        'variants': _variants.map((v) => v.toJson()).toList(),
        if (stockText.isNotEmpty) 'stockQuotidien': int.parse(stockText),
        'productType': _productType!.name,
        'stockMode': _stockMode.name,
        'madeToOrder': _madeToOrder,
        if (ingredientsText.isNotEmpty) 'ingredients': ingredientsText,
        if (shelfLifeText.isNotEmpty)
          'shelfLifeDays': int.parse(shelfLifeText),
      };

      if (isEditing) {
        await ref
            .read(productsProvider.notifier)
            .updateProduct(widget.product!.id, productData);
      } else {
        await ref.read(productsProvider.notifier).createProduct(productData);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Produit modifié' : 'Produit créé'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addVariant() {
    showDialog(
      context: context,
      builder: (context) => _VariantDialog(
        onSave: (variant) {
          setState(() => _variants.add(variant));
        },
      ),
    );
  }

  void _editVariant(int index) {
    showDialog(
      context: context,
      builder: (context) => _VariantDialog(
        variant: _variants[index],
        onSave: (variant) {
          setState(() => _variants[index] = variant);
        },
      ),
    );
  }

  void _removeVariant(int index) {
    setState(() => _variants.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final restaurantAsync = ref.watch(restaurantSettingsProvider);
    final vendorType = restaurantAsync.value?.vendorType ?? VendorType.RESTAURANT;
    // Matrice alignée sur ProductValidatorService backend. ALCOHOL est exclu
    // par le filtre `!= ALCOHOL` pour respecter le pivot lancement.
    final allowedTypes = (kAllowedProductTypes[vendorType] ?? const [])
        .where((t) => t != ProductType.ALCOHOL)
        .toList();
    // Initialise _productType au 1er type autorisé si pas encore défini
    // (création d'un produit ; édition garde la valeur existante).
    if (_productType == null && allowedTypes.isNotEmpty) {
      _productType = allowedTypes.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier le produit' : 'Nouveau produit'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom du produit *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom est requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Prix (FCFA) *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le prix est requis';
                }
                if (double.tryParse(value.trim()) == null) {
                  return 'Entrez un prix valide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stockController,
              decoration: const InputDecoration(
                labelText: 'Stock quotidien (optionnel)',
                border: OutlineInputBorder(),
                helperText: 'Laisser vide pour un stock illimite',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  if (int.tryParse(value.trim()) == null) {
                    return 'Entrez un nombre valide';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 12),
            TextFormField(
              controller: _imageUrlController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'URL de l\'image',
                border: const OutlineInputBorder(),
                hintText: 'Uploadez une image ci-dessus',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.upload),
                  onPressed: _isUploading ? null : _pickAndUploadImage,
                ),
              ),
            ),
            const SizedBox(height: 16),
            categoriesAsync.when(
              data: (categories) => _buildCategoryField(categories),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Erreur: $e'),
            ),
            const SizedBox(height: 16),
            // LIL-126 : ProductType (filtré par vendorType via la matrice
            // partagée avec le backend).
            DropdownButtonFormField<ProductType>(
              initialValue: _productType,
              decoration: const InputDecoration(
                labelText: 'Type de produit *',
                border: OutlineInputBorder(),
              ),
              items: allowedTypes
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.label),
                      ))
                  .toList(),
              onChanged: allowedTypes.isEmpty
                  ? null
                  : (value) => setState(() => _productType = value),
              validator: (value) =>
                  value == null ? 'Sélectionnez un type' : null,
            ),
            const SizedBox(height: 16),
            // LIL-126 : StockMode (DAILY reset chaque nuit, PERMANENT non reset).
            DropdownButtonFormField<StockMode>(
              initialValue: _stockMode,
              decoration: const InputDecoration(
                labelText: 'Gestion du stock',
                border: OutlineInputBorder(),
                helperText:
                    'Journalier : reset chaque nuit. Permanent : décrémentation pure.',
              ),
              items: StockMode.values
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.label),
                      ))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _stockMode = value ?? StockMode.DAILY),
            ),
            const SizedBox(height: 16),
            // LIL-126 : Switch madeToOrder. Si activé, le produit déclenche
            // la pré-commande côté client (créneau requis au checkout).
            SwitchListTile(
              value: _madeToOrder,
              onChanged: (value) => setState(() => _madeToOrder = value),
              title: const Text('Produit fait sur commande'),
              subtitle: const Text(
                'Le client devra choisir un créneau de retrait. '
                'Notification automatique J-1 au matin.',
              ),
              contentPadding: EdgeInsets.zero,
              activeThumbColor: Colors.orange,
            ),
            // LIL-130 : champs ingrédients + DLC pour produits faits maison /
            // pâtisseries. Visibles seulement quand le contexte s'y prête —
            // évite de polluer le form pour des FOOD/BEVERAGE classiques.
            if (_productType == ProductType.PASTRY || _madeToOrder) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _ingredientsController,
                decoration: const InputDecoration(
                  labelText: 'Ingrédients (allergènes)',
                  helperText:
                      'Texte libre, ex: "Farine, beurre, œufs, sucre, noisettes".',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.list_alt_outlined),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _shelfLifeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Durée de conservation (jours)',
                  helperText: 'Ex: 3 pour un gâteau, vide si non applicable.',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.schedule_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  if (int.tryParse(value.trim()) == null) {
                    return 'Entrez un nombre de jours valide';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Variantes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _addVariant,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_variants.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Aucune variante. Ajoutez des variantes pour proposer différentes tailles ou options.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _variants.length,
                itemBuilder: (context, index) {
                  final variant = _variants[index];
                  return Card(
                    child: ListTile(
                      title: Text(variant.label!),
                      subtitle: Text('${variant.prix.toStringAsFixed(0)} FCFA'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _editVariant(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                size: 20, color: Colors.red),
                            onPressed: () => _removeVariant(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Enregistrer' : 'Créer le produit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VariantDialog extends StatefulWidget {
  final ProductVariant? variant;
  final Function(ProductVariant) onSave;

  const _VariantDialog({this.variant, required this.onSave});

  @override
  State<_VariantDialog> createState() => _VariantDialogState();
}

class _VariantDialogState extends State<_VariantDialog> {
  late TextEditingController _labelController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.variant?.label ?? '');
    _priceController = TextEditingController(
        text: widget.variant?.prix.toStringAsFixed(0) ?? '');
  }

  @override
  void dispose() {
    _labelController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          Text(widget.variant != null ? 'Modifier la variante' : 'Nouvelle variante'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: 'Nom (ex: 30cl, 1.5L, Grand)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _priceController,
            decoration: const InputDecoration(
              labelText: 'Prix (FCFA)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            final label = _labelController.text.trim();
            final price = double.tryParse(_priceController.text.trim());

            if (label.isEmpty || price == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Remplissez tous les champs')),
              );
              return;
            }

            widget.onSave(ProductVariant(
              id: widget.variant?.id,
              label: label,
              prix: price,
            ));
            Navigator.pop(context);
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

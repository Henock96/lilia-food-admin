import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lilia_admin/core/utils/currency.dart';
import '../../../../common_widgets/photo_gallery_editor.dart';
import '../../../../models/product.dart';
import '../../../../models/product_type.dart';
import '../../../../models/stock_policy.dart';
import '../../../../models/stock_unit.dart';
import '../../../../models/vendor_type.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../categories/presentation/widgets/create_category_dialog.dart';
import '../../../photos/application/photos_controller.dart';
import '../../../photos/data/photo_models.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/products_provider.dart';
import '../widgets/product_image_buffer.dart';
import '../widgets/product_image_buffer_field.dart';

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
  late TextEditingController _stockController;
  late TextEditingController _ingredientsController;
  late TextEditingController _shelfLifeController;
  String? _selectedCategoryId;
  List<ProductVariant> _variants = [];
  bool _isLoading = false;
  final ProductImageBuffer _imageBuffer = ProductImageBuffer();

  // LIL-126 : champs marketplace + pré-commande
  ProductType? _productType;
  // F3-10 — politique explicite (remplace « journalier / permanent » et le
  // « champ vide = illimité »), et unité de ce que l'on compte.
  StockPolicy _stockPolicy = StockPolicy.UNLIMITED;
  StockUnit _stockUnit = StockUnit.PIECE;
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
    _stockController = TextEditingController(
        text: widget.product?.stockQuotidien?.toString() ?? '');
    _stockPolicy = widget.product?.stockPolicy ?? StockPolicy.UNLIMITED;
    _stockUnit = widget.product?.stockUnit ?? StockUnit.PIECE;
    _ingredientsController =
        TextEditingController(text: widget.product?.ingredients ?? '');
    _shelfLifeController = TextEditingController(
        text: widget.product?.shelfLifeDays?.toString() ?? '');
    _selectedCategoryId = widget.product?.categoryId;
    _variants = widget.product?.variants.toList() ?? [];
    _productType = widget.product?.productType;
    _madeToOrder = widget.product?.madeToOrder ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _ingredientsController.dispose();
    _shelfLifeController.dispose();
    _imageBuffer.dispose();
    super.dispose();
  }

  /// Champ section de menu — **facultatif**.
  ///
  /// L'état vide n'est plus bloquant (et devient rare : chaque vendeur naît
  /// avec des sections par défaut selon son `vendorType`). Rendre la section
  /// obligatoire faisait dépendre la mise en vente d'un produit d'une décision
  /// d'organisation : un vendeur sans section ne pouvait rien vendre.
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
              'Vous pouvez enregistrer ce produit sans section — il apparaîtra '
              'dans « Autres » chez le client. Créez-en une pour organiser '
              'votre carte (ex. « Pâtisseries », « Boissons »).',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _openCreateCategoryDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Créer ma 1re section'),
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
              labelText: 'Section de menu (facultatif)',
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
            // Aucun `validator` : une section est un confort d'organisation,
            // pas une condition de vente. Un produit sans section reste
            // parfaitement vendable et remonte dans « Autres » chez le client.
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

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_productType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un type de produit')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final stockText = _stockController.text.trim();
      final ingredientsText = _ingredientsController.text.trim();
      final shelfLifeText = _shelfLifeController.text.trim();
      final productData = <String, dynamic>{
        'nom': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'prixOriginal': double.parse(_priceController.text.trim()),
        'categoryId': _selectedCategoryId,
        // ⚠️ `restaurantId` n'est PLUS envoyé ici. Le champ est réservé à
        // l'ADMIN côté backend : le transmettre en tant que RESTAURATEUR
        // déclenchait « Seul un administrateur peut écrire dans le catalogue
        // d'un autre vendeur » — un 403 sur SA PROPRE boutique, qui rendait la
        // création de produit impossible depuis cette application.
        // C'est `ProductsNotifier.createProduct` qui l'ajoute, et seulement
        // pour un administrateur agissant au nom d'un tiers.
        'variants': _variants.map((v) => v.toJson()).toList(),
        ..._stockPayload(stockText),
        'productType': _productType!.name,
        'madeToOrder': _madeToOrder,
        if (ingredientsText.isNotEmpty) 'ingredients': ingredientsText,
        if (shelfLifeText.isNotEmpty)
          'shelfLifeDays': int.parse(shelfLifeText),
      };

      if (isEditing) {
        // En édition, la galerie embarquée gère les images en live (et la
        // couverture pilote imageUrl côté backend). On n'envoie pas imageUrl.
        await ref
            .read(productsProvider.notifier)
            .updateProduct(widget.product!.id, productData);
      } else {
        // Création : la couverture du buffer alimente imageUrl, puis on
        // rattache chaque image bufferisée au produit fraîchement créé.
        productData['imageUrl'] = _imageBuffer.coverUrl;
        final created = await ref
            .read(productsProvider.notifier)
            .createProduct(productData);
        final failures = await _attachBufferedImages(created.id);
        if (mounted && failures > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Produit créé, mais $failures photo(s) n\'ont pas pu être ajoutées — réessayez depuis l\'édition.'),
            ),
          );
        }
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

  /// F3-10 — champs de stock envoyés.
  ///
  /// - « Toujours disponible » : `stockQuotidien: null`, explicitement ;
  /// - « Quantité du jour » : le quota (renvoyer le même ne réaligne rien côté
  ///   serveur : corriger une description ne ressuscite pas les ventes) ;
  /// - « Stock réel » : la quantité n'est envoyée qu'à la création ou au
  ///   changement de politique. Ensuite, le stock bouge par les gestes
  ///   « Réapprovisionner » et « Inventaire » de la liste — jamais par une
  ///   réécriture de fiche, qui perdrait les ventes faites entre-temps.
  ///
  /// `stockMode` part en double pour un serveur antérieur à F3-10.
  Map<String, dynamic> _stockPayload(String stockText) {
    final policyChanged =
        !isEditing || widget.product!.stockPolicy != _stockPolicy;
    return {
      'stockPolicy': _stockPolicy.name,
      'stockMode': _stockPolicy.legacyMode.name,
      'stockUnit': _stockUnit.name,
      if (_stockPolicy == StockPolicy.UNLIMITED)
        'stockQuotidien': null
      else if (policyChanged || _stockPolicy == StockPolicy.DAILY_QUOTA)
        'stockQuotidien': int.parse(stockText),
    };
  }

  /// Le champ quantité est-il saisissable ? Pas pour un stock réel déjà en
  /// place : il se gère par gestes, depuis la liste.
  bool get _quantityEditable =>
      _stockPolicy != StockPolicy.UNLIMITED &&
      !(isEditing &&
          _stockPolicy == StockPolicy.INVENTORY &&
          widget.product!.stockPolicy == StockPolicy.INVENTORY);

  /// POST chaque image du buffer vers /product-images dans l'ordre. Renvoie le
  /// nombre d'échecs (les images sont secondaires : pas de rollback produit).
  Future<int> _attachBufferedImages(String productId) async {
    final facade = ref.read(photosFacadeProvider);
    final drafts = _imageBuffer.drafts;
    var failures = 0;
    for (final d in drafts) {
      try {
        await facade.create(
          EntityType.product,
          productId,
          url: d.url,
          publicId: d.publicId,
          isCover: d.isCover,
        );
      } catch (_) {
        failures++;
      }
    }
    return failures;
  }

  void _addVariant() {
    showDialog(
      context: context,
      builder: (context) => _VariantDialog(
        stockUnit: _stockUnit,
        multiUnitEnabled:
            ref.read(multiUnitVariantsEnabledProvider).value ?? false,
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
        stockUnit: _stockUnit,
        multiUnitEnabled:
            ref.read(multiUnitVariantsEnabledProvider).value ?? false,
        onSave: (variant) {
          setState(() => _variants[index] = variant);
        },
      ),
    );
  }

  void _removeVariant(int index) {
    setState(() => _variants.removeAt(index));
  }

  /// F3-10 — « Comment ce produit est-il disponible ? »
  Widget _buildStockSection() {
    final product = widget.product;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Disponibilité',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SegmentedButton<StockPolicy>(
          segments: [
            for (final policy in StockPolicy.values)
              ButtonSegment(value: policy, label: Text(policy.label)),
          ],
          selected: {_stockPolicy},
          showSelectedIcon: false,
          onSelectionChanged: (selection) =>
              setState(() => _stockPolicy = selection.first),
        ),
        const SizedBox(height: 6),
        Text(
          _stockPolicy.help,
          style: TextStyle(color: Colors.grey[700], fontSize: 13),
        ),
        if (_stockPolicy != StockPolicy.UNLIMITED) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<StockUnit>(
            initialValue: _stockUnit,
            decoration: const InputDecoration(
              labelText: 'On compte en',
              border: OutlineInputBorder(),
              helperText:
                  'La plus petite unité vendue : une bouteille, pas un carton.',
            ),
            items: StockUnit.values
                .map((u) => DropdownMenuItem(value: u, child: Text(u.title)))
                .toList(),
            onChanged: (value) =>
                setState(() => _stockUnit = value ?? StockUnit.PIECE),
          ),
          const SizedBox(height: 12),
          if (_quantityEditable)
            TextFormField(
              controller: _stockController,
              decoration: InputDecoration(
                labelText: '${_stockPolicy.quantityLabel} *',
                suffixText: _stockUnit.plural,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                final n = int.tryParse(value?.trim() ?? '');
                if (n == null || n < 0) return 'Entrez un nombre entier';
                return null;
              },
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'En stock : ${_stockUnit.format(product?.stockRestant ?? 0)}.\n'
                'Utilisez « Réapprovisionner » ou « Faire l’inventaire » depuis '
                'la liste des produits.',
                style: const TextStyle(fontSize: 13),
              ),
            ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    // Préchargé pour le dialogue des formats.
    ref.watch(multiUnitVariantsEnabledProvider);
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
                labelText: 'Prix (XAF) *',
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
            _buildStockSection(),
            const SizedBox(height: 16),
            // Galerie photos : buffer en création, galerie live en édition.
            if (isEditing)
              SizedBox(
                height: 360,
                child: PhotoGalleryEditor(
                  entityType: EntityType.product,
                  parentId: widget.product!.id,
                ),
              )
            else
              ProductImageBufferField(buffer: _imageBuffer),
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
                  'Formats',
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
                  'Aucun format. Ajoutez-en pour proposer plusieurs tailles ou conditionnements (bouteille, carton de 6…).',
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
                      title: Text(variant.label ?? 'Standard'),
                      subtitle: Text(
                        variant.stockConsumption > 1
                            ? '${formatXaf(variant.prix)} · '
                                '${_stockUnit.format(variant.stockConsumption)}'
                            : formatXaf(variant.prix),
                      ),
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
  final StockUnit stockUnit;
  final bool multiUnitEnabled;
  final Function(ProductVariant) onSave;

  const _VariantDialog({
    this.variant,
    required this.stockUnit,
    required this.multiUnitEnabled,
    required this.onSave,
  });

  @override
  State<_VariantDialog> createState() => _VariantDialogState();
}

class _VariantDialogState extends State<_VariantDialog> {
  late TextEditingController _labelController;
  late TextEditingController _priceController;
  late TextEditingController _consumptionController;

  /// F3-10 — la consommation d'un format enregistré ne se modifie pas (le
  /// serveur refuse : `STOCK_CONSUMPTION_IMMUTABLE`). « Carton de 12 » n'est
  /// pas une édition de « Carton de 6 » : c'est un autre format.
  bool get _consumptionEditable =>
      !(widget.variant?.isPersisted ?? false) && widget.multiUnitEnabled;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.variant?.label ?? '');
    _priceController = TextEditingController(
        text: widget.variant?.prix.toStringAsFixed(0) ?? '');
    _consumptionController = TextEditingController(
        text: (widget.variant?.stockConsumption ?? 1).toString());
  }

  @override
  void dispose() {
    _labelController.dispose();
    _priceController.dispose();
    _consumptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final persisted = widget.variant?.isPersisted ?? false;
    return AlertDialog(
      title: Text(widget.variant != null ? 'Modifier le format' : 'Nouveau format'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: 'Nom (ex: Bouteille, Carton de 6, 30cl, Grand)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _priceController,
            decoration: const InputDecoration(
              labelText: 'Prix (XAF)',
              border: OutlineInputBorder(),
              helperText: 'Libre : un carton peut coûter moins que 6 bouteilles.',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _consumptionController,
            enabled: _consumptionEditable,
            decoration: InputDecoration(
              labelText: 'Nombre de ${widget.stockUnit.plural} par format',
              border: const OutlineInputBorder(),
              helperText: persisted
                  ? 'Non modifiable : créez un autre format et retirez celui-ci.'
                  : widget.multiUnitEnabled
                      ? 'Ex. 6 pour un carton de 6. Chaque vente retire ce nombre du stock.'
                      : 'Les formats de plusieurs unités ne sont pas encore ouverts.',
              helperMaxLines: 2,
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
            final consumption = int.tryParse(_consumptionController.text.trim());

            if (label.isEmpty ||
                price == null ||
                consumption == null ||
                consumption < 1) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Remplissez tous les champs')),
              );
              return;
            }

            widget.onSave(ProductVariant(
              id: widget.variant?.id,
              label: label,
              prix: price,
              stockConsumption: consumption,
            ));
            Navigator.pop(context);
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

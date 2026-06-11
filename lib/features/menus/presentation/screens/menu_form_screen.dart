import 'package:flutter/material.dart';
import 'package:lilia_admin/common_widgets/app_cached_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lilia_admin/core/utils/currency.dart';
import '../../../../models/menu.dart';
import '../../../products/presentation/providers/products_provider.dart';
import '../providers/menus_provider.dart';

class MenuFormScreen extends ConsumerStatefulWidget {
  final MenuDuJour? menu;

  const MenuFormScreen({super.key, this.menu});

  @override
  ConsumerState<MenuFormScreen> createState() => _MenuFormScreenState();
}

class _MenuFormScreenState extends ConsumerState<MenuFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _imageUrlController;
  late TextEditingController _ingredientsController;
  late DateTime _dateDebut;
  late DateTime _dateFin;
  bool _isActive = true;
  late String _menuType; // 'COMBO' ou 'PLAT_SPECIAL'
  List<String> _selectedProductIds = [];
  bool _isLoading = false;

  bool get isEditing => widget.menu != null;
  bool get isPlatSpecial => _menuType == 'PLAT_SPECIAL';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.menu?.nom ?? '');
    _descriptionController =
        TextEditingController(text: widget.menu?.description ?? '');
    _priceController = TextEditingController(
        text: widget.menu?.prix.toStringAsFixed(0) ?? '');
    _imageUrlController =
        TextEditingController(text: widget.menu?.imageUrl ?? '');
    _ingredientsController =
        TextEditingController(text: widget.menu?.ingredients ?? '');
    _dateDebut = widget.menu?.dateDebut ?? DateTime.now();
    _dateFin =
        widget.menu?.dateFin ?? DateTime.now().add(const Duration(hours: 12));
    _isActive = widget.menu?.isActive ?? true;
    _menuType = widget.menu?.type ?? 'COMBO';
    _selectedProductIds =
        widget.menu?.products.map((p) => p.productId).toList() ?? [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _ingredientsController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(bool isStart) async {
    final initialDate = isStart ? _dateDebut : _dateFin;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (time != null) {
        final dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        setState(() {
          if (isStart) {
            _dateDebut = dateTime;
            if (_dateFin.isBefore(_dateDebut)) {
              _dateFin = _dateDebut.add(const Duration(hours: 12));
            }
          } else {
            _dateFin = dateTime;
          }
        });
      }
    }
  }

  Future<void> _saveMenu() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dateFin.isBefore(_dateDebut)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('La date de fin doit être après la date de début')),
      );
      return;
    }

    if (!isPlatSpecial && _selectedProductIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Sélectionnez au moins un produit pour un menu combo')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final menuData = <String, dynamic>{
        'nom': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'prix': double.parse(_priceController.text.trim()),
        'imageUrl': _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
        'dateDebut': _dateDebut.toIso8601String(),
        'dateFin': _dateFin.toIso8601String(),
        'isActive': _isActive,
        'type': _menuType,
      };

      if (isPlatSpecial) {
        menuData['ingredients'] = _ingredientsController.text.trim().isEmpty
            ? null
            : _ingredientsController.text.trim();
      } else {
        menuData['products'] = _selectedProductIds
            .asMap()
            .entries
            .map((e) => {'productId': e.value, 'ordre': e.key})
            .toList();
      }

      if (isEditing) {
        await ref
            .read(menusProvider.notifier)
            .updateMenu(widget.menu!.id, menuData);
      } else {
        await ref.read(menusProvider.notifier).createMenu(menuData);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Menu modifié' : 'Menu créé'),
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

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier le menu' : 'Nouveau menu'),
        actions: [
          if (isEditing)
            IconButton(
              tooltip: 'Gérer les photos',
              icon: const Icon(Icons.photo_library_outlined),
              onPressed: () => context.pushNamed(
                'photos',
                queryParameters: {
                  'entityType': 'menu',
                  'parentId': widget.menu!.id,
                },
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Selecteur de type de menu
            if (!isEditing) ...[
              const Text(
                'Type de menu',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: 'COMBO',
                    label: Text('Menu Combo'),
                    icon: Icon(Icons.restaurant_menu),
                  ),
                  ButtonSegment<String>(
                    value: 'PLAT_SPECIAL',
                    label: Text('Plat Special'),
                    icon: Icon(Icons.local_dining),
                  ),
                ],
                selected: {_menuType},
                onSelectionChanged: (selection) {
                  setState(() => _menuType = selection.first);
                },
              ),
              const SizedBox(height: 8),
              Text(
                isPlatSpecial
                    ? 'Un plat unique temporaire avec sa composition'
                    : 'Un menu compose de plusieurs produits existants',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
            ] else ...[
              // En edition, afficher le type comme info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isPlatSpecial ? Colors.orange[50] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPlatSpecial ? Icons.local_dining : Icons.restaurant_menu,
                      size: 18,
                      color: isPlatSpecial ? Colors.orange : Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isPlatSpecial ? 'Plat Special' : 'Menu Combo',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isPlatSpecial ? Colors.orange[800] : Colors.blue[800],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: isPlatSpecial ? 'Nom du plat *' : 'Nom du menu *',
                border: const OutlineInputBorder(),
                hintText: isPlatSpecial
                    ? 'Ex: Riz compose poulet-legumes'
                    : 'Ex: Menu du Jour - Mercredi',
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
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'URL de l\'image',
                border: OutlineInputBorder(),
                hintText: 'https://...',
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Période de validité',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDateTime(true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Début',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(dateFormat.format(_dateDebut)),
                          const Icon(Icons.calendar_today, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDateTime(false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fin',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(dateFormat.format(_dateFin)),
                          const Icon(Icons.calendar_today, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Menu actif'),
              subtitle: Text(
                _isActive
                    ? 'Le menu sera visible pendant la période de validité'
                    : 'Le menu ne sera pas visible',
              ),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            const SizedBox(height: 24),

            // Section conditionnelle : Ingredients OU Produits
            if (isPlatSpecial) ...[
              const Text(
                'Composition / Ingredients',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Decrivez la composition du plat (texte libre)',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ingredientsController,
                decoration: const InputDecoration(
                  labelText: 'Ingredients / Composition',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Riz, poulet grille, legumes sautes, sauce tomate',
                ),
                maxLines: 4,
              ),
            ] else ...[
              const Text(
                'Produits du menu',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              productsAsync.when(
                data: (products) {
                  if (products.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Aucun produit disponible. Créez d\'abord des produits.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      ...products.map((product) => CheckboxListTile(
                            title: Text(product.name),
                            subtitle: Text(formatXaf(product.prixOriginal)),
                            value: _selectedProductIds.contains(product.id),
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedProductIds.add(product.id);
                                } else {
                                  _selectedProductIds.remove(product.id);
                                }
                              });
                            },
                            secondary: product.imageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: AppCachedImage(
                                      imageUrl: product.imageUrl!,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorIcon: Icons.fastfood,
                                    ),
                                  )
                                : Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.fastfood),
                                  ),
                          )),
                      if (_selectedProductIds.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${_selectedProductIds.length} produit(s) sélectionné(s)',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Erreur: $e'),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveMenu,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Enregistrer' : 'Créer le menu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

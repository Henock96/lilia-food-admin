import 'package:flutter/material.dart';
import 'package:lilia_admin/common_widgets/app_cached_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lilia_admin/core/utils/currency.dart';
import '../../../../models/product.dart';
import '../../../catalog/catalog_scope.dart';
import '../providers/products_provider.dart';
import 'product_form_screen.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    // Un ADMIN ne possède aucun vendeur : sans sélection, il n'y a pas de
    // catalogue à afficher ni de cible où créer. On le dit, plutôt que
    // d'afficher une liste vide qui ressemble à une panne.
    final needsVendor =
        ref.watch(isCatalogAdminProvider) &&
        ref.watch(catalogScopeProvider) == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            onPressed: () => context.goNamed('categories'),
            tooltip: 'Gérer les sections de menu',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(productsProvider.notifier).refresh(),
            tooltip: 'Actualiser',
          ),
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProductFormScreen(),
                ),
              );
            },
            tooltip: 'Ajouter un produit',
          ),
        ],
      ),
      body: Column(
        children: [
          const CatalogScopeBar(),
          Expanded(
            child: needsVendor
                ? const CatalogScopeEmpty(quoi: 'produits')
                : _buildProducts(context, ref, productsAsync),
          ),
        ],
      ),
      floatingActionButton: needsVendor
          ? null
          : FloatingActionButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProductFormScreen(),
                ),
              ),
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildProducts(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Product>> productsAsync,
  ) {
    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Aucun produit',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Appuyez sur + pour ajouter un produit',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // La liste arrive triée par le serveur (`displayOrder` puis date de
        // création) : c'est **l'ordre que voient les clients**. On la regroupe
        // par section pour que le classement porte sur ce que l'acheteur voit
        // réellement côte à côte — les deux clients rendent la carte groupée.
        final sections = _groupBySection(products);

        return RefreshIndicator(
          onRefresh: () => ref.read(productsProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final section in sections) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          section.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (section.products.length > 1)
                        Text(
                          'Maintenez pour classer',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: section.products.length > 1,
                  // `onReorderItem` et non `onReorder` : il ajuste lui-même
                  // l'index après retrait de l'élément déplacé. L'API dépréciée
                  // laissait ce décalage à l'appelant, source classique d'un
                  // décalage d'un cran vers le bas.
                  onReorderItem: (oldIndex, newIndex) =>
                      _reorder(ref, section, oldIndex, newIndex),
                  children: [
                    for (final product in section.products)
                      _ProductCard(key: ValueKey(product.id), product: product),
                  ],
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(productsProvider.notifier).refresh(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  /// Regroupe le catalogue par section, **en préservant l'ordre serveur**.
  ///
  /// `LinkedHashMap` par construction en Dart : les sections sortent dans
  /// l'ordre où leur premier produit apparaît, c'est-à-dire dans l'ordre du
  /// vendeur. Les produits sans section rejoignent « Autres » — même libellé
  /// que les deux applications clientes.
  List<_Section> _groupBySection(List<Product> products) {
    final grouped = <String, _Section>{};
    for (final product in products) {
      final id = product.categoryId ?? _uncategorizedKey;
      final name = product.category?.name ?? 'Autres';
      grouped.putIfAbsent(id, () => _Section(id: id, name: name, products: []));
      grouped[id]!.products.add(product);
    }
    return grouped.values.toList();
  }

  /// Envoie la liste ordonnée **complète de la section**.
  ///
  /// Un couple `(id, position)` suffirait pour un seul appelant ; à deux,
  /// chacun partant d'un ordre différent, le résultat ne serait celui d'aucun
  /// des deux.
  Future<void> _reorder(
    WidgetRef ref,
    _Section section,
    int oldIndex,
    int newIndex,
  ) async {
    // `onReorderItem` livre déjà l'index **après** retrait : aucun ajustement
    // à faire ici (contrairement à `onReorder`, déprécié).
    final next = [...section.products];
    next.insert(newIndex, next.removeAt(oldIndex));

    try {
      await ref
          .read(productsProvider.notifier)
          .reorder(next.map((p) => p.id).toList());
    } catch (_) {
      // `refresh()` du provider remet l'ordre serveur : on ne laisse pas
      // l'interface afficher un classement que la base n'a pas accepté.
      await ref.read(productsProvider.notifier).refresh();
    }
  }
}

/// Clé de la section fourre-tout — jamais un identifiant réel de catégorie.
const String _uncategorizedKey = '__sans_section__';

class _Section {
  final String id;
  final String name;
  final List<Product> products;

  _Section({required this.id, required this.name, required this.products});
}

class _ProductCard extends ConsumerWidget {
  final Product product;

  const _ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: product.imageUrl != null
              ? AppCachedImage(
                  imageUrl: product.imageUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[200],
                  child: const Icon(Icons.fastfood),
                ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.category != null)
              Text(
                product.category!.name,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            Text(
              formatXaf(product.prixOriginal),
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (product.variants.isNotEmpty)
              Text(
                '${product.variants.length} variante(s)',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            // « Retiré de la vente » et « épuisé » sont deux états distincts :
            // le premier est une décision du vendeur, le second une
            // conséquence du stock. Le backend les a séparés en août 2026
            // (fix M2) ; cet écran les confondait encore, faute de lire le
            // `isAvailable` du serveur (fix S-3). Sur cette liste — qui montre
            // volontairement les produits retirés — un produit retiré mais
            // encore en stock s'affichait « Stock: 4/10 », en bleu, sur
            // l'écran même qui porte le bouton pour le remettre en vente.
            if (!product.isAvailable)
              const Row(
                children: [
                  Icon(Icons.visibility_off, size: 14, color: Colors.orange),
                  SizedBox(width: 4),
                  Text(
                    'Retiré de la vente',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            if (product.stockQuotidien != null)
              Row(
                children: [
                  Icon(
                    product.isInStock ? Icons.inventory : Icons.block,
                    size: 14,
                    color: product.isInStock ? Colors.blue : Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    product.isInStock
                        ? 'Stock: ${product.stockRestant}/${product.stockQuotidien}'
                        : 'Épuisé',
                    style: TextStyle(
                      color: product.isInStock ? Colors.blue : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ProductFormScreen(product: product),
                ),
              );
            } else if (value == 'availability') {
              try {
                await ref
                    .read(productsProvider.notifier)
                    .setAvailability(product.id, !product.isAvailable);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        product.isAvailable
                            ? 'Produit retiré de la vente'
                            : 'Produit remis en vente',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                }
              }
            } else if (value == 'restock') {
              await _promptRestock(context, ref, product);
            } else if (value == 'delete') {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Supprimer le produit'),
                  content: Text(
                    'Voulez-vous vraiment supprimer "${product.name}" ?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Supprimer'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                try {
                  await ref
                      .read(productsProvider.notifier)
                      .deleteProduct(product.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Produit supprimé')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                  }
                }
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'availability',
              child: Row(
                children: [
                  Icon(
                    product.isAvailable
                        ? Icons.visibility_off
                        : Icons.visibility,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    product.isAvailable
                        ? 'Retirer de la vente'
                        : 'Remettre en vente',
                  ),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'restock',
              child: Row(
                children: [
                  Icon(Icons.refresh, size: 20),
                  SizedBox(width: 8),
                  Text('Réapprovisionner'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProductFormScreen(product: product),
            ),
          );
        },
      ),
    );
  }

  /// Réassort explicite — `PATCH /products/:id/stock`.
  ///
  /// Le formulaire produit décrit la **capacité déclarée** ; ce geste-ci
  /// remet le **stock restant** à niveau. Ce sont deux intentions, et les
  /// confondre était la moitié du bug S-1 : `stockQuotidien` était absent du
  /// DTO de mise à jour côté serveur, donc supprimé en silence par le
  /// `ValidationPipe`. L'écran affichait « Produit mis à jour » et rien
  /// n'était écrit — définitivement pour un `stockMode = PERMANENT`, que le
  /// cron de 5 h ne touche jamais.
  Future<void> _promptRestock(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    final controller = TextEditingController(
      text: product.stockQuotidien?.toString() ?? '',
    );

    final value = await showDialog<String?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Réapprovisionner « ${product.name} »'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stock restant : ${product.stockRestant ?? "illimité"}\n'
              'Capacité déclarée : ${product.stockQuotidien ?? "illimitée"}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nouvelle quantité disponible',
                helperText: 'Laisser vide = stock illimité',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Réapprovisionner'),
          ),
        ],
      ),
    );

    if (value == null) return;

    // Vide = illimité. C'est le seul chemin pour revenir d'un stock fini à un
    // stock illimité : le formulaire, lui, traite un champ vide comme « ne pas
    // toucher ».
    int? quantity;
    if (value.isNotEmpty) {
      quantity = int.tryParse(value);
      if (quantity == null || quantity < 0) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Indiquez un nombre entier d’unités, ou rien'),
            ),
          );
        }
        return;
      }
    }

    try {
      await ref.read(productsProvider.notifier).restock(product.id, quantity);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              quantity == null
                  ? 'Produit repassé en stock illimité'
                  : 'Stock remis à $quantity',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }
}

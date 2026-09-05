import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/product.dart';
import '../../../catalog/catalog_scope.dart';
import '../providers/categories_provider.dart';
import '../widgets/create_category_dialog.dart';

/// Sections de menu du vendeur — création, renommage, ordre, activation.
///
/// L'écran affiche **toutes** les sections, y compris vides : c'est la vue où
/// l'on remplit sa carte. Le client, lui, ne voit que les sections actives et
/// non vides — deux questions différentes, deux requêtes différentes.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final needsVendor = ref.watch(isCatalogAdminProvider) &&
        ref.watch(catalogScopeProvider) == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sections de menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(categoriesProvider.notifier).refresh(),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          const CatalogScopeBar(),
          Expanded(
            child: needsVendor
                ? const CatalogScopeEmpty(quoi: 'sections de menu')
                : categoriesAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => _ErrorState(
                      error: error,
                      onRetry: () =>
                          ref.read(categoriesProvider.notifier).refresh(),
                    ),
                    data: (categories) => categories.isEmpty
                        ? const _EmptyState()
                        : _CategoryList(categories: categories),
                  ),
          ),
        ],
      ),
      floatingActionButton: needsVendor
          ? null
          : FloatingActionButton(
              onPressed: () => showCreateCategoryDialog(context, ref),
              tooltip: 'Nouvelle section',
              child: const Icon(Icons.add),
            ),
    );
  }
}

/// Liste réordonnable — le vendeur pose l'ordre de sa carte, et le client le
/// respecte. Sans cela, les sections sortaient par ordre alphabétique côté
/// mobile : « Accompagnements » avant « Les Grillades ».
class _CategoryList extends ConsumerWidget {
  final List<Category> categories;
  const _CategoryList({required this.categories});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.read(categoriesProvider.notifier).refresh(),
      child: ReorderableListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
        itemCount: categories.length,
        onReorderItem: (oldIndex, newIndex) {
          // `onReorderItem` (Flutter ≥ 3.41) ajuste déjà `newIndex` pour le
          // retrait de l'élément déplacé — contrairement à `onReorder`, où il
          // fallait décrémenter à la main. C'est le piège des bannières, réglé
          // en amont par le framework.
          final ids = categories.map((c) => c.id).toList();
          final moved = ids.removeAt(oldIndex);
          ids.insert(newIndex, moved);
          ref.read(categoriesProvider.notifier).reorder(ids);
        },
        itemBuilder: (context, index) => _CategoryCard(
          key: ValueKey(categories[index].id),
          category: categories[index],
          position: index,
        ),
      ),
    );
  }
}

class _CategoryCard extends ConsumerWidget {
  final Category category;
  final int position;

  const _CategoryCard({
    super.key,
    required this.category,
    required this.position,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = category.productCount;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: ReorderableDragStartListener(
          index: position,
          child: const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Icon(Icons.drag_indicator, color: Colors.grey),
          ),
        ),
        title: Text(
          category.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            // Une section désactivée reste dans la liste du vendeur, mais elle
            // doit se distinguer d'un coup d'œil de ce que voit le client.
            color: category.isActive ? null : theme.disabledColor,
          ),
        ),
        subtitle: Text([
          if (count != null) '$count produit${count > 1 ? "s" : ""}',
          if (!category.isActive) 'Masquée aux clients',
        ].join(' · ')),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _onAction(context, ref, value),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Renommer')),
            PopupMenuItem(
              value: 'toggle',
              child: Text(category.isActive ? 'Masquer aux clients' : 'Afficher aux clients'),
            ),
            const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
          ],
        ),
      ),
    );
  }

  Future<void> _onAction(
      BuildContext context, WidgetRef ref, String action) async {
    final notifier = ref.read(categoriesProvider.notifier);
    switch (action) {
      case 'edit':
        final nom = await _promptName(context, initial: category.name);
        if (nom != null && context.mounted) {
          await _guard(context, () => notifier.updateCategory(category.id, {'nom': nom}),
              'Section renommée');
        }
      case 'toggle':
        final count = category.productCount ?? 0;
        if (category.isActive && count > 0) {
          final ok = await _confirm(
            context,
            titre: 'Masquer « ${category.name} » ?',
            message:
                'Cette section contient $count produit${count > 1 ? "s" : ""}. '
                'Ils resteront en vente et apparaîtront dans « Autres » chez le client.',
            action: 'Masquer',
          );
          if (ok != true) return;
        }
        if (!context.mounted) return;
        await _guard(context, () => notifier.setActive(category.id, !category.isActive),
            category.isActive ? 'Section masquée' : 'Section affichée');
      case 'delete':
        final count = category.productCount ?? 0;
        final ok = await _confirm(
          context,
          titre: 'Supprimer « ${category.name} » ?',
          message: count > 0
              // Le message précédent annonçait que les produits « seraient
              // affectés », alors que le backend refusait purement la
              // suppression. Les deux étaient faux ; voici ce qui se passe.
              ? '$count produit${count > 1 ? "s" : ""} ${count > 1 ? "seront" : "sera"} '
                  'sans section et ${count > 1 ? "resteront" : "restera"} en vente. '
                  'Aucun produit n\'est supprimé.'
              : 'Cette section est vide.',
          action: 'Supprimer',
          destructif: true,
        );
        if (ok == true && context.mounted) {
          await _guard(context, () => notifier.deleteCategory(category.id),
              'Section supprimée');
        }
    }
  }

  Future<void> _guard(
      BuildContext context, Future<void> Function() run, String succes) async {
    // Le messenger est capturé AVANT l'await : après, le widget peut avoir été
    // démonté et `context` ne vaut plus rien.
    final messenger = ScaffoldMessenger.of(context);
    try {
      await run();
      messenger.showSnackBar(SnackBar(content: Text(succes)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  Future<String?> _promptName(BuildContext context, {required String initial}) {
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renommer la section'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 60,
          decoration: const InputDecoration(
            labelText: 'Nom de la section',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final v = ctrl.text.trim();
              if (v.isNotEmpty) Navigator.pop(ctx, v);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirm(
    BuildContext context, {
    required String titre,
    required String message,
    required String action,
    bool destructif = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titre),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: destructif
                ? TextButton.styleFrom(foregroundColor: Colors.red)
                : null,
            child: Text(action),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucune section', style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Appuyez sur + pour organiser votre carte.',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
}

class _ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('Erreur : $error', textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      );
}

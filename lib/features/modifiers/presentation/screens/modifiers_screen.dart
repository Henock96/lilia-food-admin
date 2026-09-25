import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/modifier_group.dart';
import '../../../../models/product.dart';
import '../../../catalog/catalog_scope.dart';
import '../../../products/presentation/providers/products_provider.dart';
import '../providers/modifiers_provider.dart';
import '../widgets/modifier_group_form.dart';

/// F3-09 — options & suppléments de la boutique.
///
/// ```
/// Accompagnement                 Obligatoire · 1 choix
///   [Alloco +500] [Frites] [Riz · épuisé]            [Modifier]
/// Suppléments                    Facultatif · jusqu'à 2
///   [Œuf +300 ×3] [Fromage +500]
/// ```
///
/// Toucher une option la met en rupture (ou la remet en vente) : « plus
/// d'alloco ce soir » est un geste, pas un formulaire. Le serveur reste
/// l'autorité — cet écran affiche ses refus tels quels.
class ModifiersScreen extends ConsumerWidget {
  const ModifiersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryAsync = ref.watch(modifiersProvider);
    final isAdmin = ref.watch(isCatalogAdminProvider);
    final needsVendor = isAdmin && ref.watch(catalogScopeProvider) == null;
    final library = libraryAsync.value;
    // Un vendeur n'écrit que si l'éditeur est ouvert (vérifié par le serveur).
    // Tant que la bibliothèque n'est pas chargée, on ne sait pas : aucun
    // bouton d'écriture ne s'affiche, même le temps d'une frame.
    final readOnly = !isAdmin && (library == null || !library.managementEnabled);
    final showClosedBanner =
        !isAdmin && library != null && !library.managementEnabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Options & suppléments'),
        actions: [
          if (!needsVendor && !readOnly && (library?.groups.isNotEmpty ?? false))
            IconButton(
              icon: const Icon(Icons.link),
              tooltip: 'Options d\'un produit',
              onPressed: () => _openAttachSheet(context, library!.groups),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: () => ref.read(modifiersProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          const CatalogScopeBar(),
          if (library != null && !library.modifiersEnabled)
            const _Banner(
              'Les options ne sont pas encore proposées aux clients. '
              'Rien n\'est visible ni exigé tant que la plateforme ne les a pas activées.',
            ),
          if (showClosedBanner)
            const _Banner(
              'L\'éditeur d\'options ouvrira dès que les applications clientes '
              'seront à jour.',
            ),
          Expanded(
            child: needsVendor
                ? const CatalogScopeEmpty(quoi: 'options')
                : libraryAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$error', textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: () =>
                                  ref.read(modifiersProvider.notifier).refresh(),
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    data: (lib) => lib.groups.isEmpty
                        ? const _EmptyState()
                        : _GroupList(groups: lib.groups, readOnly: readOnly),
                  ),
          ),
        ],
      ),
      floatingActionButton: needsVendor || readOnly
          ? null
          : FloatingActionButton.extended(
              onPressed: () => showModifierGroupForm(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Nouveau groupe'),
            ),
    );
  }

  void _openAttachSheet(BuildContext context, List<ModifierGroup> groups) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AttachSheet(groups: groups),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(color: cs.onTertiaryContainer)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'Aucun groupe d\'options.\n\nExemple : « Accompagnement » (obligatoire) '
          'avec Alloco, Frites, Riz — puis attachez-le à vos plats.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _GroupList extends ConsumerWidget {
  const _GroupList({required this.groups, required this.readOnly});

  final List<ModifierGroup> groups;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.read(modifiersProvider.notifier).refresh(),
      child: ReorderableListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
        buildDefaultDragHandles: false,
        itemCount: groups.length,
        onReorderItem: (oldIndex, newIndex) {
          if (readOnly) return;
          final ids = groups.map((g) => g.id).toList();
          final moved = ids.removeAt(oldIndex);
          ids.insert(newIndex, moved);
          _run(context, () => ref.read(modifiersProvider.notifier).reorder(ids));
        },
        itemBuilder: (context, index) => _GroupCard(
          key: ValueKey(groups[index].id),
          group: groups[index],
          index: index,
          readOnly: readOnly,
        ),
      ),
    );
  }
}

class _GroupCard extends ConsumerWidget {
  const _GroupCard({
    super.key,
    required this.group,
    required this.index,
    required this.readOnly,
  });

  final ModifierGroup group;
  final int index;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (!readOnly)
                  ReorderableDragStartListener(
                    index: index,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.drag_indicator),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.name, style: theme.textTheme.titleMedium),
                      Text(
                        group.products.isEmpty
                            ? '${group.ruleLabel} · attaché à aucun produit'
                            : '${group.ruleLabel} · ${group.products.map((p) => p.name).join(', ')}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (!readOnly) ...[
                  IconButton(
                    tooltip: 'Modifier',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () =>
                        showModifierGroupForm(context, ref, group: group),
                  ),
                  IconButton(
                    tooltip: 'Supprimer',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(context, ref),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final option in group.options)
                    FilterChip(
                      key: ValueKey('option-${option.id}'),
                      label: Text(_chipLabel(option)),
                      selected: option.isAvailable,
                      showCheckmark: false,
                      tooltip: option.isAvailable
                          ? 'Toucher pour marquer en rupture'
                          : 'Toucher pour remettre en vente',
                      onSelected: readOnly || option.id == null
                          ? null
                          : (available) => _run(
                              context,
                              () => ref
                                  .read(modifiersProvider.notifier)
                                  .setOptionAvailability(option.id!, available),
                              success: available
                                  ? '${option.name} remis en vente'
                                  : '${option.name} en rupture',
                            ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _chipLabel(ModifierOption o) {
    final price = o.priceDeltaXaf > 0 ? ' +${o.priceDeltaXaf}' : '';
    final qty = o.maxQuantity > 1 ? ' ×${o.maxQuantity}' : '';
    return o.isAvailable ? '${o.name}$price$qty' : '${o.name} · épuisé';
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer « ${group.name} » ?'),
        content: Text(
          'Le groupe sera retiré de ${group.products.length} produit(s). '
          'Les paniers qui portent une de ses options perdront la ligne entière '
          '— jamais le plat sans son option. Les commandes passées gardent leur copie.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await _run(
      context,
      () => ref.read(modifiersProvider.notifier).deleteGroup(group.id),
      success: 'Groupe supprimé',
    );
  }
}

/// Associe des groupes à un produit, dans l'ordre de sélection.
class _AttachSheet extends ConsumerStatefulWidget {
  const _AttachSheet({required this.groups});
  final List<ModifierGroup> groups;

  @override
  ConsumerState<_AttachSheet> createState() => _AttachSheetState();
}

class _AttachSheetState extends ConsumerState<_AttachSheet> {
  Product? _product;
  List<String> _selected = [];
  bool _saving = false;

  void _choose(Product? p) {
    setState(() {
      _product = p;
      _selected = p == null
          ? []
          : widget.groups
                .where((g) => g.products.any((ref) => ref.id == p.id))
                .map((g) => g.id)
                .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider).value ?? const <Product>[];
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Options d\'un produit',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Product>(
            initialValue: _product,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Produit'),
            items: [
              for (final p in products)
                DropdownMenuItem(value: p, child: Text(p.name)),
            ],
            onChanged: _choose,
          ),
          if (_product != null) ...[
            const SizedBox(height: 8),
            for (final g in widget.groups)
              CheckboxListTile(
                dense: true,
                value: _selected.contains(g.id),
                title: Text(g.name),
                subtitle: Text(g.ruleLabel),
                secondary: _selected.contains(g.id)
                    ? Text('#${_selected.indexOf(g.id) + 1}')
                    : null,
                onChanged: (on) => setState(() {
                  on == true ? _selected.add(g.id) : _selected.remove(g.id);
                }),
              ),
            const Text(
              'L\'ordre d\'affichage suit l\'ordre de sélection. Toutes les '
              'variantes du produit partagent ces options.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving
                  ? null
                  : () async {
                      setState(() => _saving = true);
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);
                      try {
                        await ref
                            .read(modifiersProvider.notifier)
                            .setProductGroups(_product!.id, _selected);
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Options du produit mises à jour'),
                          ),
                        );
                        navigator.pop();
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Erreur : $e')),
                        );
                        if (mounted) setState(() => _saving = false);
                      }
                    },
              child: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Exécute un geste et en affiche l'issue ; le refus du serveur est montré tel
/// quel (il est rédigé pour être lu).
Future<void> _run(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await action();
    if (success != null) {
      messenger.showSnackBar(SnackBar(content: Text(success)));
    }
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Erreur : $e')));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/product.dart';
import '../providers/categories_provider.dart';

/// LIL-129 : dialog minimal pour créer une catégorie à la volée depuis
/// n'importe quel écran (form produit en particulier). Retourne la
/// Category créée pour permettre l'auto-sélection côté caller.
Future<Category?> showCreateCategoryDialog(
  BuildContext context,
  WidgetRef ref, {
  String? initialName,
}) {
  return showDialog<Category?>(
    context: context,
    builder: (ctx) => _CreateCategoryDialog(initialName: initialName),
  );
}

class _CreateCategoryDialog extends ConsumerStatefulWidget {
  final String? initialName;
  const _CreateCategoryDialog({this.initialName});

  @override
  ConsumerState<_CreateCategoryDialog> createState() =>
      _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends ConsumerState<_CreateCategoryDialog> {
  late final TextEditingController _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom est requis')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final created = await ref
          .read(categoriesProvider.notifier)
          .createCategory({'nom': name});
      if (!mounted) return;
      Navigator.pop(context, created);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouvelle catégorie'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
        decoration: const InputDecoration(
          labelText: 'Nom de la catégorie',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Créer'),
        ),
      ],
    );
  }
}

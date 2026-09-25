import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/modifier_group.dart';
import '../providers/modifiers_provider.dart';

/// F3-09 — création / modification d'un groupe d'options et de ses options.
///
/// Les règles qui comptent (cardinalités cohérentes, plafonds, supplément
/// jamais négatif) sont vérifiées par le serveur ; le formulaire se contente
/// d'empêcher les saisies évidemment fausses et de prévenir des conséquences
/// d'une suppression d'option sur les paniers.
Future<void> showModifierGroupForm(
  BuildContext context,
  WidgetRef ref, {
  ModifierGroup? group,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => ModifierGroupFormDialog(group: group),
  );
}

class ModifierGroupFormDialog extends ConsumerStatefulWidget {
  const ModifierGroupFormDialog({super.key, this.group});

  final ModifierGroup? group;

  @override
  ConsumerState<ModifierGroupFormDialog> createState() =>
      _ModifierGroupFormDialogState();
}

class _OptionDraft {
  _OptionDraft(this.base)
    : name = TextEditingController(text: base.name),
      price = TextEditingController(
        text: base.priceDeltaXaf == 0 ? '' : '${base.priceDeltaXaf}',
      ),
      maxQuantity = base.maxQuantity;

  final ModifierOption base;
  final TextEditingController name;
  final TextEditingController price;
  int maxQuantity;

  ModifierOption toOption() => base.copyWith(
    name: name.text.trim(),
    priceDeltaXaf: int.tryParse(price.text.trim()) ?? 0,
    maxQuantity: maxQuantity,
  );

  void dispose() {
    name.dispose();
    price.dispose();
  }
}

class _ModifierGroupFormDialogState
    extends ConsumerState<ModifierGroupFormDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.group?.name ?? '',
  );
  late bool _required = widget.group?.isRequired ?? true;
  late int _maxSelect = widget.group?.maxSelect ?? 1;
  late final List<_OptionDraft> _options = [
    for (final o
        in widget.group?.options ??
            const [ModifierOption(name: '')])
      _OptionDraft(o),
  ];
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    for (final o in _options) {
      o.dispose();
    }
    super.dispose();
  }

  /// Options existantes retirées du formulaire — elles quitteront la carte.
  List<String> get _removed {
    final kept = _options.map((o) => o.base.id).whereType<String>().toSet();
    return [
      for (final o in widget.group?.options ?? const <ModifierOption>[])
        if (o.id != null && !kept.contains(o.id)) o.name,
    ];
  }

  Future<void> _save() async {
    final options = _options
        .map((o) => o.toOption())
        .where((o) => o.name.isNotEmpty)
        .toList();
    final messenger = ScaffoldMessenger.of(context);
    if (_name.text.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Le nom du groupe est requis')),
      );
      return;
    }
    if (options.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Ajoutez au moins une option')),
      );
      return;
    }
    final minSelect = _required ? 1 : 0;
    final maxSelect = _maxSelect < minSelect ? minSelect : _maxSelect;
    setState(() => _saving = true);
    final notifier = ref.read(modifiersProvider.notifier);
    final navigator = Navigator.of(context);
    try {
      if (widget.group == null) {
        await notifier.createGroup(
          name: _name.text,
          minSelect: minSelect,
          maxSelect: maxSelect,
          options: options,
        );
        messenger.showSnackBar(const SnackBar(content: Text('Groupe créé')));
      } else {
        final purged = await notifier.updateGroup(
          widget.group!.id,
          name: _name.text,
          minSelect: minSelect,
          maxSelect: maxSelect,
          options: options,
        );
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              purged > 0
                  ? 'Groupe mis à jour — $purged ligne(s) de panier retirée(s)'
                  : 'Groupe mis à jour',
            ),
          ),
        );
      }
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erreur : $e')));
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final removed = _removed;
    return AlertDialog(
      title: Text(
        widget.group == null ? 'Nouveau groupe d\'options' : 'Modifier le groupe',
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _name,
                maxLength: 80,
                autofocus: widget.group == null,
                decoration: const InputDecoration(
                  labelText: 'Nom (vu par le client)',
                  hintText: 'Accompagnement, Sauce, Suppléments…',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Choix obligatoire'),
                value: _required,
                onChanged: (v) => setState(() => _required = v),
              ),
              Row(
                children: [
                  const Expanded(child: Text('Choix maximum')),
                  IconButton(
                    tooltip: 'Moins',
                    icon: const Icon(Icons.remove),
                    onPressed: _maxSelect > 1
                        ? () => setState(() => _maxSelect--)
                        : null,
                  ),
                  Text('$_maxSelect'),
                  IconButton(
                    tooltip: 'Plus',
                    icon: const Icon(Icons.add),
                    onPressed: _maxSelect < 20
                        ? () => setState(() => _maxSelect++)
                        : null,
                  ),
                ],
              ),
              Text(
                _maxSelect == 1
                    ? 'Le client choisit une seule option.'
                    : 'Jusqu\'à $_maxSelect options différentes.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Divider(height: 24),
              Text('Options', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              for (var i = 0; i < _options.length; i++)
                _OptionRow(
                  key: ObjectKey(_options[i]),
                  draft: _options[i],
                  canMoveUp: i > 0,
                  canMoveDown: i < _options.length - 1,
                  onMove: (dir) => setState(() {
                    final moved = _options.removeAt(i);
                    _options.insert(i + dir, moved);
                  }),
                  onRemove: () => setState(() => _options.removeAt(i).dispose()),
                  onChanged: () => setState(() {}),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(
                    () => _options.add(_OptionDraft(const ModifierOption(name: ''))),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter une option'),
                ),
              ),
              if (removed.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${removed.join(', ')} ${removed.length > 1 ? 'seront retirées' : 'sera retirée'} '
                    'de la carte. Les paniers qui les contiennent perdront la ligne '
                    'entière — jamais le plat sans son option.',
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
        ),
      ],
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    super.key,
    required this.draft,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMove,
    required this.onRemove,
    required this.onChanged,
  });

  final _OptionDraft draft;
  final bool canMoveUp;
  final bool canMoveDown;
  final void Function(int dir) onMove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: canMoveUp ? () => onMove(-1) : null,
                child: const Icon(Icons.keyboard_arrow_up, size: 18),
              ),
              InkWell(
                onTap: canMoveDown ? () => onMove(1) : null,
                child: const Icon(Icons.keyboard_arrow_down, size: 18),
              ),
            ],
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 3,
            child: TextField(
              controller: draft.name,
              maxLength: 80,
              decoration: const InputDecoration(
                hintText: 'Alloco',
                counterText: '',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: draft.price,
              keyboardType: TextInputType.number,
              // Un supplément n'est jamais négatif (R-09.6) : chiffres seuls.
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                hintText: '0',
                prefixText: '+',
                suffixText: 'F',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 4),
          DropdownButton<int>(
            value: draft.maxQuantity,
            underline: const SizedBox.shrink(),
            items: [
              for (var q = 1; q <= 10; q++)
                DropdownMenuItem(value: q, child: Text('×$q')),
            ],
            onChanged: (q) {
              if (q == null) return;
              draft.maxQuantity = q;
              onChanged();
            },
          ),
          IconButton(
            tooltip: 'Retirer l\'option',
            icon: const Icon(Icons.close),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

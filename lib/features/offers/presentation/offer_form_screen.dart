import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lilia_admin/core/network/api_exception.dart';
import 'package:lilia_admin/core/utils/currency.dart';
import 'package:lilia_admin/features/offers/data/offers_repository.dart';
import 'package:lilia_admin/features/offers/presentation/offers_providers.dart';

/// Publier une offre boutique (F3-11).
///
/// Deux formes : « −10 % sur toute la boutique » et « −500 dès 5 000 ». Le
/// budget est obligatoire : c'est ce qui protège le vendeur de sa propre
/// offre. Les bornes (≤ 50 %, ≤ 30 jours, seuil ≥ 2 × remise) sont rappelées
/// ici et vérifiées par le serveur, dont le message s'affiche tel quel.
class OfferFormScreen extends ConsumerStatefulWidget {
  const OfferFormScreen({super.key, this.now});

  /// Horloge injectable (tests).
  final DateTime Function()? now;

  @override
  ConsumerState<OfferFormScreen> createState() => _OfferFormScreenState();
}

class _OfferFormScreenState extends ConsumerState<OfferFormScreen> {
  static const _durations = [7, 14, 30];
  /// Panier de référence de l'aperçu « coût estimé ».
  static const _sampleBasketXaf = 5000;

  OfferKind _kind = OfferKind.percent;
  int _days = 14;
  final _value = TextEditingController(text: '10');
  final _threshold = TextEditingController();
  final _cap = TextEditingController();
  final _budget = TextEditingController(text: '20000');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _value.dispose();
    _threshold.dispose();
    _cap.dispose();
    _budget.dispose();
    super.dispose();
  }

  int? _int(TextEditingController c) =>
      int.tryParse(c.text.replaceAll(RegExp(r'\s'), ''));

  NewOffer? get _draft {
    final value = _int(_value);
    final budget = _int(_budget);
    if (value == null || budget == null) return null;
    final now = (widget.now ?? DateTime.now)();
    return NewOffer(
      kind: _kind,
      value: value,
      minSubTotalXaf: _int(_threshold) ?? 0,
      maxDiscountXaf: _kind == OfferKind.percent ? _int(_cap) : null,
      budgetXaf: budget,
      endsAt: now.add(Duration(days: _days)),
    );
  }

  Future<void> _submit() async {
    final draft = _draft;
    if (draft == null) {
      setState(() => _error = 'Renseignez la remise et le budget.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(offersRepositoryProvider).create(draft);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    final isPercent = _kind == OfferKind.percent;
    final sampleBasket = isPercent
        ? _sampleBasketXaf
        : (_int(_threshold) ?? _sampleBasketXaf);
    final sample = draft?.discountOn(sampleBasket) ?? 0;
    final coverable =
        (draft != null && sample > 0) ? draft.budgetXaf ~/ sample : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle offre')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<OfferKind>(
            segments: const [
              ButtonSegment(
                value: OfferKind.percent,
                label: Text('− % boutique'),
              ),
              ButtonSegment(
                value: OfferKind.fixedThreshold,
                label: Text('− montant dès…'),
              ),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() {
              _kind = s.first;
              _value.text = _kind == OfferKind.percent ? '10' : '500';
              _threshold.text = _kind == OfferKind.percent ? '' : '5000';
            }),
          ),
          const SizedBox(height: 16),
          _field(
            key: 'offer-value',
            controller: _value,
            label: isPercent ? 'Remise (%)' : 'Remise (XAF)',
            help: isPercent ? 'Entre 1 et 50 %.' : null,
          ),
          _field(
            key: 'offer-threshold',
            controller: _threshold,
            label: isPercent
                ? 'Montant minimal du panier (XAF, facultatif)'
                : 'Dès un panier de (XAF)',
            help: isPercent ? null : 'Au moins deux fois la remise.',
          ),
          if (isPercent)
            _field(
              key: 'offer-cap',
              controller: _cap,
              label: 'Remise maximale par commande (XAF, facultatif)',
            ),
          const SizedBox(height: 8),
          const Text('Durée', style: TextStyle(fontWeight: FontWeight.w600)),
          Wrap(
            spacing: 8,
            children: [
              for (final d in _durations)
                ChoiceChip(
                  label: Text('$d jours'),
                  selected: _days == d,
                  onSelected: (_) => setState(() => _days = d),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _field(
            key: 'offer-budget',
            controller: _budget,
            label: 'Budget total (XAF)',
            help: 'Le maximum que vous acceptez d’offrir. L’offre s’arrête '
                'd’elle-même une fois le budget atteint.',
          ),
          if (draft != null && sample > 0)
            Container(
              key: const Key('offer-preview'),
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Sur un panier de ${formatXaf(sampleBasket)}, votre client '
                'économise ${formatXaf(sample)}, retenus sur votre versement. '
                '${coverable != null ? 'Votre budget couvre environ $coverable commande${coverable > 1 ? 's' : ''} de ce montant.' : ''}',
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                key: const Key('offer-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 20),
          FilledButton(
            key: const Key('offer-submit'),
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Publier l’offre'),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required String key,
    required TextEditingController controller,
    required String label,
    String? help,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          key: Key(key),
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: label,
            helperText: help,
            helperMaxLines: 3,
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
      );
}

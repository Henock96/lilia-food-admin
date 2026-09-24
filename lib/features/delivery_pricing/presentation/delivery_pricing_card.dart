import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lilia_admin/core/network/api_exception.dart';
import 'package:lilia_admin/features/delivery_pricing/data/delivery_pricing_service.dart';
import 'package:lilia_admin/models/restaurant.dart';

String _xaf(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return '$buf FCFA';
}

String _km(double km) =>
    km == km.roundToDouble() ? km.toStringAsFixed(0) : km.toStringAsFixed(1);

/// Écran « Livraison » du vendeur, partie prix (F3-02).
///
/// En mode plateforme, la grille Lilia est affichée **en lecture** et le
/// vendeur choisit seulement la part qu'il offre à ses clients. En mode
/// vendeur, le réglage se prépare déjà : il s'appliquera à la bascule.
class DeliveryPricingCard extends ConsumerStatefulWidget {
  final Restaurant restaurant;

  /// Appelé après un enregistrement réussi (rechargement du restaurant).
  final VoidCallback? onSaved;

  const DeliveryPricingCard({
    super.key,
    required this.restaurant,
    this.onSaved,
  });

  @override
  ConsumerState<DeliveryPricingCard> createState() =>
      _DeliveryPricingCardState();
}

class _DeliveryPricingCardState extends ConsumerState<DeliveryPricingCard> {
  late String _mode = widget.restaurant.deliverySubsidyMode;
  late final _amount = TextEditingController(
    text: widget.restaurant.deliverySubsidyXaf?.toString() ?? '',
  );
  late final _threshold = TextEditingController(
    text: widget.restaurant.freeDeliveryThresholdXaf?.toString() ?? '',
  );
  bool _saving = false;
  DeliverySubsidySimulation? _simulation;
  bool _simulating = false;

  @override
  void dispose() {
    _amount.dispose();
    _threshold.dispose();
    super.dispose();
  }

  /// `null` = réglage incomplet (montant ou seuil manquant).
  DeliverySubsidySetting? get _setting {
    if (_mode == 'NONE') return const DeliverySubsidySetting(mode: 'NONE');
    final raw = (_mode == 'FIXED' ? _amount : _threshold).text.trim();
    final n = int.tryParse(raw);
    if (n == null || n < 1) return null;
    return _mode == 'FIXED'
        ? DeliverySubsidySetting(mode: 'FIXED', amountXaf: n)
        : DeliverySubsidySetting(mode: 'FREE_ABOVE', thresholdXaf: n);
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _save() async {
    final setting = _setting;
    if (setting == null) {
      _snack(
        _mode == 'FIXED'
            ? 'Indiquez un montant entier en FCFA.'
            : 'Indiquez un seuil entier en FCFA.',
        error: true,
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(deliveryPricingServiceProvider)
          .updateSubsidy(widget.restaurant.id, setting);
      if (!mounted) return;
      _snack('Part offerte enregistrée');
      widget.onSaved?.call();
    } on ApiException catch (e) {
      if (mounted) _snack(e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _simulate() async {
    final setting = _setting;
    if (setting == null || setting.mode == 'NONE') return;
    setState(() => _simulating = true);
    try {
      final result = await ref
          .read(deliveryPricingServiceProvider)
          .simulateSubsidy(widget.restaurant.id, setting);
      if (mounted) setState(() => _simulation = result);
    } on ApiException catch (e) {
      if (mounted) _snack(e.message, error: true);
    } finally {
      if (mounted) setState(() => _simulating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final current = ref.watch(currentDeliveryTariffProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        current.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Row(
            children: [
              Expanded(
                child: Text(
                  e is ApiException
                      ? e.message
                      : 'Impossible de charger la grille de livraison.',
                  style: TextStyle(color: cs.error, fontSize: 13),
                ),
              ),
              TextButton(
                onPressed: () => ref.invalidate(currentDeliveryTariffProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
          data: (tariff) => tariff.isPlatform
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Le prix de chaque livraison est fixé par Lilia selon la '
                      'distance${tariff.version != null ? ' (grille v${tariff.version})' : ''}.',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (var i = 0; i < tariff.bands.length; i++)
                          Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text(
                              '${i == 0 ? '0' : _km(tariff.bands[i - 1].maxKm)}–'
                              '${_km(tariff.bands[i].maxKm)} km : '
                              '${_xaf(tariff.bands[i].feeXaf)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ],
                )
              : Text(
                  'Vos prix de livraison s’appliquent encore. La part offerte '
                  'se prépare dès maintenant et s’appliquera au passage à la '
                  'grille Lilia.',
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Offrir une partie de la livraison à vos clients',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'NONE', label: Text('Aucune')),
            ButtonSegment(value: 'FIXED', label: Text('Montant fixe')),
            ButtonSegment(value: 'FREE_ABOVE', label: Text('Dès un panier')),
          ],
          selected: {_mode},
          onSelectionChanged: (s) => setState(() {
            _mode = s.first;
            _simulation = null;
          }),
        ),
        if (_mode != 'NONE') ...[
          const SizedBox(height: 12),
          TextField(
            controller: _mode == 'FIXED' ? _amount : _threshold,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() => _simulation = null),
            decoration: InputDecoration(
              labelText: _mode == 'FIXED'
                  ? 'Montant offert par commande'
                  : 'Livraison offerte à partir d’un panier de',
              helperText: _mode == 'FIXED'
                  ? 'Plafonné au prix de la course.'
                  : null,
              suffixText: 'FCFA',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _simulating ? null : _simulate,
              icon: const Icon(Icons.calculate_outlined, size: 18),
              label: const Text('Combien cela m’aurait coûté ?'),
            ),
          ),
          if (_simulation != null)
            Text(
              _simulation!.orders == 0
                  ? 'Pas encore de commande payée à rejouer : le coût ne peut '
                        'pas être estimé.'
                  : 'Sur vos ${_simulation!.orders} dernières commandes, ce '
                        'réglage vous aurait coûté ${_xaf(_simulation!.costXaf)} '
                        '(${_simulation!.subsidizedOrders} commande(s) '
                        'concernée(s)), retenus sur vos reversements.',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _saving ? null : _save,
            child: Text(
              _saving ? 'Enregistrement…' : 'Enregistrer la part offerte',
            ),
          ),
        ),
      ],
    );
  }
}

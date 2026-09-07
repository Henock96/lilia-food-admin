import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lilia_admin/features/admin/presentation/providers/admin_operations_provider.dart';
import 'package:lilia_admin/models/platform_settings.dart';

class PlatformSettingsScreen extends ConsumerWidget {
  const PlatformSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(platformSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres plateforme'),
        centerTitle: true,
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Impossible de charger la configuration',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(platformSettingsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (settings) => _PlatformSettingsForm(settings: settings),
      ),
    );
  }
}

class _PlatformSettingsForm extends ConsumerStatefulWidget {
  const _PlatformSettingsForm({required this.settings});

  final PlatformSettings settings;

  @override
  ConsumerState<_PlatformSettingsForm> createState() =>
      _PlatformSettingsFormState();
}

class _PlatformSettingsFormState extends ConsumerState<_PlatformSettingsForm> {
  late final TextEditingController _serviceFee;
  late final TextEditingController _loyaltyPerOrder;
  late final TextEditingController _loyaltyValue;
  late final TextEditingController _loyaltyMin;
  late final TextEditingController _referrerBonus;
  late final TextEditingController _maintenanceMessage;
  late bool _maintenanceMode;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.settings;
    _serviceFee = TextEditingController(text: s.serviceFeePercent.toString());
    _loyaltyPerOrder =
        TextEditingController(text: s.loyaltyPointsPerOrder.toString());
    _loyaltyValue =
        TextEditingController(text: s.loyaltyPointValueXaf.toString());
    _loyaltyMin =
        TextEditingController(text: s.loyaltyMinRedemption.toString());
    _referrerBonus =
        TextEditingController(text: s.referrerBonusPoints.toString());
    _maintenanceMessage =
        TextEditingController(text: s.maintenanceMessage ?? '');
    _maintenanceMode = s.maintenanceMode;
  }

  @override
  void dispose() {
    _serviceFee.dispose();
    _loyaltyPerOrder.dispose();
    _loyaltyValue.dispose();
    _loyaltyMin.dispose();
    _referrerBonus.dispose();
    _maintenanceMessage.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = widget.settings;
    final dto = <String, dynamic>{
      'serviceFeePercent':
          double.tryParse(_serviceFee.text.trim()) ?? s.serviceFeePercent,
      'loyaltyPointsPerOrder':
          int.tryParse(_loyaltyPerOrder.text.trim()) ?? s.loyaltyPointsPerOrder,
      'loyaltyPointValueXaf':
          int.tryParse(_loyaltyValue.text.trim()) ?? s.loyaltyPointValueXaf,
      'loyaltyMinRedemption':
          int.tryParse(_loyaltyMin.text.trim()) ?? s.loyaltyMinRedemption,
      'referrerBonusPoints':
          int.tryParse(_referrerBonus.text.trim()) ?? s.referrerBonusPoints,

      'maintenanceMode': _maintenanceMode,
      'maintenanceMessage': _maintenanceMessage.text.trim(),
    };

    setState(() => _saving = true);
    try {
      await ref
          .read(adminOperationsRepositoryProvider)
          .updatePlatformSettings(dto);
      if (!mounted) return;
      ref.invalidate(platformSettingsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuration enregistrée'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _section('Frais de service', [
          _numberField(_serviceFee, 'Frais de service', '%'),
        ]),
        _section('Fidélité', [
          _numberField(_loyaltyPerOrder, 'Points / commande livrée', 'pts'),
          _numberField(_loyaltyValue, "Valeur d'un point", 'XAF'),
          // Le seul réglage de cet écran dont la modification a un effet
          // RÉTROACTIF : la valeur est lue au moment de la dépense, jamais
          // figée à l'acquisition.
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              '⚠️ Effet rétroactif : ce montant revalorise tous les points déjà '
              'distribués. Ne pas modifier sans exécuter la procédure de '
              'redénomination (docs/LOYALTY.md).',
              style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
            ),
          ),
          _numberField(_loyaltyMin, "Seuil minimum d'utilisation", 'pts'),
        ]),
        _section('Parrainage', [
          _numberField(_referrerBonus, 'Bonus parrain', 'pts'),
          // Le bonus filleul a été supprimé du programme : seul le parrain est
          // récompensé, et seulement quand la première commande est LIVRÉE.
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Versé au parrain à la première commande LIVRÉE de son filleul. '
              'Le filleul, lui, ne reçoit plus de bonus d\'inscription.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ]),
        _section('Maintenance', [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Mode maintenance',
                style: TextStyle(fontSize: 14)),
            subtitle: const Text('Bloque les nouvelles commandes',
                style: TextStyle(fontSize: 12)),
            value: _maintenanceMode,
            onChanged: (v) => setState(() => _maintenanceMode = v),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _maintenanceMessage,
            decoration: const InputDecoration(
              labelText: 'Message affiché au client',
              hintText: 'La plateforme est en maintenance…',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save),
            label: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _numberField(
      TextEditingController controller, String label, String suffix) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          SizedBox(
            width: 110,
            child: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                suffixText: suffix,
                isDense: true,
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

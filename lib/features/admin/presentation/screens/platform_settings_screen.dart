import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lilia_admin/features/admin/domain/app_update_rules.dart';
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
  late final TextEditingController _minAppVersion;
  late final TextEditingController _latestAppVersion;
  late final TextEditingController _updateUrlAndroid;
  late final TextEditingController _updateUrlIos;
  late final TextEditingController _updateMessage;
  late final TextEditingController _blockConfirmation;

  /// Contrôleur du repli « Blocage du parc », détenu par ce `State`.
  ///
  /// `ExpansionTile.initiallyExpanded` n'est lu qu'une fois, dans son propre
  /// `initState` — un `setState` ultérieur ne le rouvre jamais, et la
  /// `ListView` construisant ses enfants paresseusement, faire sortir le bloc
  /// du viewport puis revenir recrée le `State` de la tuile et relit ce
  /// paramètre figé. En pilotant l'ouverture depuis un `ExpansibleController`
  /// qui survit à ces recréations, un refus de validation peut rouvrir le
  /// repli de façon fiable.
  late final ExpansibleController _blocageController;

  /// Source de vérité de l'ouverture **initiale** (et mise à jour par
  /// `onExpansionChanged` quand l'admin ouvre/ferme à la main) : ne pilote
  /// plus directement l'`ExpansionTile`, c'est `_blocageController` qui le
  /// fait, mais elle reste lue pour construire l'état initial du contrôleur.
  late bool _blocageDeplie;
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
    _minAppVersion = TextEditingController(text: s.minAppVersion ?? '');
    _latestAppVersion = TextEditingController(text: s.latestAppVersion ?? '');
    _updateUrlAndroid =
        TextEditingController(text: s.updateUrlAndroid ?? '');
    _updateUrlIos = TextEditingController(text: s.updateUrlIos ?? '');
    _updateMessage = TextEditingController(text: s.updateMessage ?? '');
    _blockConfirmation = TextEditingController();
    _blocageDeplie = (s.minAppVersion ?? '').isNotEmpty;
    _blocageController = ExpansibleController();
    if (_blocageDeplie) {
      _blocageController.expand();
    }
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
    _minAppVersion.dispose();
    _latestAppVersion.dispose();
    _updateUrlAndroid.dispose();
    _updateUrlIos.dispose();
    _updateMessage.dispose();
    _blockConfirmation.dispose();
    // `ExpansionTile` ne dispose que le contrôleur qu'il crée lui-même quand
    // aucun n'est fourni : le nôtre lui est passé explicitement, donc c'est à
    // nous de le libérer.
    _blocageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = widget.settings;

    final refus = validateAppUpdate(
      minVersion: _minAppVersion.text,
      latestVersion: _latestAppVersion.text,
      urlAndroid: _updateUrlAndroid.text,
      urlIos: _updateUrlIos.text,
    );

    if (requiresBlockConfirmation(
          minVersion: _minAppVersion.text,
          savedMinVersion: s.minAppVersion,
        ) &&
        _blockConfirmation.text.trim().toUpperCase() != 'BLOQUER') {
      refus.add(
        'Vous êtes sur le point de bloquer le parc : tapez BLOQUER dans le '
        'champ de confirmation.',
      );
    }

    if (refus.isNotEmpty) {
      setState(() => _blocageDeplie = true);
      // `setState` seul ne rouvrirait pas le repli si l'admin l'a fermé à la
      // main : `ExpansionTile.initiallyExpanded` n'est lu qu'une fois. C'est
      // le contrôleur, pas `_blocageDeplie`, qui pilote l'ouverture réelle.
      _blocageController.expand();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(refus.join('\n')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
      return;
    }

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
      ...buildAppUpdatePatch(
        minVersion: _minAppVersion.text,
        latestVersion: _latestAppVersion.text,
        urlAndroid: _updateUrlAndroid.text,
        urlIos: _updateUrlIos.text,
        message: _updateMessage.text,
      ),
    };

    setState(() => _saving = true);
    try {
      await ref
          .read(adminOperationsRepositoryProvider)
          .updatePlatformSettings(dto);
      if (!mounted) return;
      ref.invalidate(platformSettingsProvider);
      _blockConfirmation.clear();
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
        _section('Mise à jour de l\'application', [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Réglages de l\'application cliente, pas de celle-ci. '
              'Laisser un champ vide efface la valeur.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
          _textField(
            _latestAppVersion,
            'Dernière version publiée',
            '1.3.0 ou 1.3.0+34',
          ),
          _textField(
            _updateMessage,
            'Message affiché au client',
            'Nouveautés du panier…',
          ),
          _textField(
            _updateUrlAndroid,
            'URL Android',
            'https://play.google.com/…',
          ),
          _textField(_updateUrlIos, 'URL iOS', 'https://apps.apple.com/…'),
          if (_updateUrlIos.text.trim().isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                '⚠️ Sans URL iOS, le client retombe sur un lien placeholder '
                '(id6740000000) : les utilisateurs iPhone atterriraient sur '
                'une fiche App Store inexistante.',
                style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
              ),
            ),
          ExpansionTile(
            controller: _blocageController,
            onExpansionChanged: (v) => setState(() => _blocageDeplie = v),
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: const Text(
              '⚠ Blocage du parc (avancé)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'En dessous de cette version, les clients ne peuvent plus '
                  'commander du tout. Réservé à une faille de sécurité ou une '
                  'rupture de contrat d\'API. Pour pousser une nouveauté, '
                  'utilisez « Dernière version publiée » ci-dessus, qui laisse '
                  'reporter.',
                  style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                ),
              ),
              _textField(
                _minAppVersion,
                'Version minimale',
                'vide = aucun blocage',
              ),
              _textField(
                _blockConfirmation,
                'Tapez BLOQUER pour confirmer',
                'BLOQUER',
              ),
            ],
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

  /// Champ texte pleine largeur. `_numberField` place son libellé à gauche
  /// d'une case étroite, ce qui convient à un pourcentage mais tronquerait une
  /// URL.
  Widget _textField(
      TextEditingController controller, String label, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}

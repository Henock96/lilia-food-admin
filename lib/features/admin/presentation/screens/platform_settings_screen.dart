import 'package:flutter/material.dart';
import 'package:lilia_admin/theme/lilia_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lilia_admin/core/network/api_exception.dart';
import 'package:lilia_admin/features/admin/domain/platform_settings_form.dart';
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
        // Clé = version chargée : après un enregistrement ou un rechargement
        // (409), le formulaire repart des valeurs du serveur au lieu de
        // garder des contrôleurs remplis avec l'ancienne base de comparaison.
        data: (settings) => _PlatformSettingsForm(
          key: ValueKey(
            settings.updatedAtRaw ?? settings.updatedAt.toIso8601String(),
          ),
          settings: settings,
        ),
      ),
    );
  }
}

class _PlatformSettingsForm extends ConsumerStatefulWidget {
  const _PlatformSettingsForm({super.key, required this.settings});

  final PlatformSettings settings;

  @override
  ConsumerState<_PlatformSettingsForm> createState() =>
      _PlatformSettingsFormState();
}

class _PlatformSettingsFormState extends ConsumerState<_PlatformSettingsForm> {
  // D-4 — frais de service des épiceries (vide = taux général).
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
    if (_saving) return;
    final s = widget.settings;

    final result = buildSettingsPatch(
      SettingsFormValues(
        maintenanceMode: _maintenanceMode,
        maintenanceMessage: _maintenanceMessage.text,
        minAppVersion: _minAppVersion.text,
        latestAppVersion: _latestAppVersion.text,
        updateUrlAndroid: _updateUrlAndroid.text,
        updateUrlIos: _updateUrlIos.text,
        updateMessage: _updateMessage.text,
        blockConfirmation: _blockConfirmation.text,
      ),
      s,
    );

    if (!result.ok) {
      setState(() => _blocageDeplie = true);
      // `setState` seul ne rouvrirait pas le repli si l'admin l'a fermé à la
      // main : `ExpansionTile.initiallyExpanded` n'est lu qu'une fois. C'est
      // le contrôleur, pas `_blocageDeplie`, qui pilote l'ouverture réelle.
      _blocageController.expand();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errors.join('\n')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
      return;
    }

    if (!result.changed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune modification à enregistrer.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(adminOperationsRepositoryProvider)
          .updatePlatformSettings(result.patch);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      // Recrée le formulaire (clé = nouvel `updatedAt`) sur les valeurs
      // enregistrées : la prochaine sauvegarde partira de cette base.
      ref.invalidate(platformSettingsProvider);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Configuration enregistrée'),
          backgroundColor: Colors.green,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      // Seul `SETTINGS_STALE` dit « un autre administrateur a modifié la
      // configuration ». Un autre 409 (bascule refusée faute de grille de
      // livraison publiée…) porte un message à afficher tel quel — le
      // maquiller en conflit le rendait incompréhensible (24/09/2026).
      if (isStaleSettingsConflict(e)) {
        await _signalerConflit();
        return;
      }
      _signalerErreur(e.message);
    } catch (e) {
      if (!mounted) return;
      _signalerErreur(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _signalerErreur(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// 409 : un autre administrateur a enregistré depuis l'ouverture de l'écran.
  /// On ne réessaie pas à sa place : on recharge ses valeurs, et l'admin
  /// refait ses changements en connaissance de cause.
  Future<void> _signalerConflit() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Configuration modifiée entre-temps'),
        content: const Text(
          'Un autre administrateur a enregistré la configuration depuis que '
          'vous avez ouvert cet écran. Vos changements n\'ont pas été '
          'enregistrés. Les valeurs actuelles vont être rechargées : '
          'refaites vos changements si nécessaire.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Recharger'),
          ),
        ],
      ),
    );
    if (mounted) ref.invalidate(platformSettingsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // R-09 — réglages qui fixent de l'argent : lecture seule. Ils se
        // demandent depuis l'admin web et s'approuvent à deux administrateurs ;
        // le serveur les refuse dans le PATCH de cet écran.
        _financialNotice(),
        _section('Frais de service', [
          _readOnlyValue(
              'Frais de service', '${_percent(s.serviceFeePercent)} %'),
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text(
              'Payés EN PLUS par le client, ajoutés au panier.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
          // D-4 — seulement si le serveur connaît le réglage.
          if (s.knowsGroceryServiceFee)
            _readOnlyValue(
              'Frais de service épiceries',
              s.groceryServiceFeeBps == null
                  ? 'taux général'
                  : '${groceryServiceFeeText(s)} %',
            ),
        ]),
        _section('Commission vendeur', [
          _readOnlyValue('Commission vendeur',
              '${_percent(s.restaurantCommissionPercent)} %'),
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Retenue SUR le vendeur au reversement — le client ne la paie '
              'pas. Figée sur chaque commande à sa création. Un taux propre à '
              'un vendeur, défini sur sa fiche, prime sur celui-ci.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ]),
        _section('Fidélité', [
          _readOnlyValue(
              'Points / commande livrée', '${s.loyaltyPointsPerOrder} pts'),
          _readOnlyValue("Valeur d'un point", '${s.loyaltyPointValueXaf} XAF'),
          _readOnlyValue(
              "Seuil minimum d'utilisation", '${s.loyaltyMinRedemption} pts'),
        ]),
        _section('Parrainage', [
          _readOnlyValue('Bonus parrain', '${s.referrerBonusPoints} pts'),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Versé au parrain à la première commande LIVRÉE de son filleul.',
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
                'Sans URL iOS, l\'app envoie vers une recherche « Lilia Food » '
                'dans l\'App Store (l\'app n\'y a pas encore de fiche). Seule '
                'une vraie fiche (apps.apple.com/…/id…) est acceptée ici.',
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
                        strokeWidth: 2, color: LiliaColors.charcoal700),
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

  /// « 15 » plutôt que « 15.0 » ; « 7.5 » reste « 7.5 ».
  static String _percent(num v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  Widget _financialNotice() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFFE0F2FE),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.verified_user_outlined, color: Color(0xFF0369A1)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Frais, commission, points et parrainage touchent l’argent : '
                'ils se modifient depuis l’admin web et doivent être approuvés '
                'par un second administrateur.',
                style: TextStyle(fontSize: 13, color: Color(0xFF075985)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _readOnlyValue(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Text(value,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  /// Champ texte pleine largeur (une URL ne tient pas dans une case étroite).
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

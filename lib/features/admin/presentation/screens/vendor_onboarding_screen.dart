import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lilia_admin/core/network/api_client.dart';

import '../../../../models/onboarding_report.dart';
import '../../../../models/restaurant.dart';
import '../../../users/data/cloudinary_service.dart';
import '../../data/vendor_onboarding_service.dart';
import 'vendor_onboarding_steps.dart';

/// Configuration d'un vendeur, étape par étape.
///
/// L'état vit **en base**, pas dans le formulaire : fermer l'écran ne perd
/// rien, et le rouvrir reprend exactement où on s'était arrêté. C'est ce qui
/// permet à l'administrateur et au vendeur de le remplir chacun de leur côté.
///
/// La progression et l'autorisation d'activer viennent de la checklist
/// serveur : rien n'est recalculé ici. Une interface qui déciderait
/// elle-même proposerait tôt ou tard un bouton menant à un 409.
class VendorOnboardingScreen extends ConsumerStatefulWidget {
  final Restaurant vendor;

  const VendorOnboardingScreen({super.key, required this.vendor});

  @override
  ConsumerState<VendorOnboardingScreen> createState() =>
      _VendorOnboardingScreenState();
}

class _VendorOnboardingScreenState
    extends ConsumerState<VendorOnboardingScreen> {
  late VendorOnboardingService _service;
  late Restaurant _vendor;

  OnboardingReport? _report;
  bool _loading = true;
  bool _saving = false;
  int _step = 0;

  /// Définies dans `vendor_onboarding_steps.dart`, avec la règle d'avance.
  static const _steps = vendorOnboardingSteps;

  @override
  void initState() {
    super.initState();
    _vendor = widget.vendor;
    _service = VendorOnboardingService(ref.read(apiClientProvider));
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final report = await _service.getOnboarding(_vendor.id);
      final fresh = await _service.getPreview(_vendor.id);
      if (!mounted) return;
      setState(() {
        _report = report;
        _vendor = fresh;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _toast('Chargement impossible : $e', error: true);
    }
  }

  /// Enveloppe commune des enregistrements de section : verrou anti-double-tap,
  /// rafraîchissement de la checklist, message d'erreur lisible.
  ///
  /// ⚠️ L'avance vers l'étape suivante était **inconditionnelle** : tout
  /// enregistrement réussi faisait `_step++`. Le raccourci tient tant qu'une
  /// étape porte un seul formulaire — ce n'est pas le cas de « Commercial »,
  /// qui en porte deux : les paramètres commerciaux, puis le **compte de
  /// reversement**. Enregistrer les premiers projetait donc sur « Catalogue »,
  /// et le champ de reversement disparaissait après s'être affiché une fois.
  /// Symptôme d'autant plus trompeur que `payout` est une case **bloquante** :
  /// la checklist réclamait un compte que l'assistant venait d'escamoter.
  ///
  /// L'avance suit désormais la même autorité que le reste de l'écran : la
  /// checklist serveur. On ne quitte une étape que si plus aucune de ses cases
  /// **bloquantes** n'est en défaut. Les cases facultatives (description,
  /// couverture, commission) ne retiennent personne.
  Future<void> _save(
    Future<void> Function() action,
    String successMessage,
  ) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await action();
      await _refresh();
      if (!mounted) return;
      _toast(successMessage);
      if (_step < _steps.length - 1 && canLeaveStep(_steps[_step], _report)) {
        setState(() => _step++);
      }
    } catch (e) {
      if (!mounted) return;
      _toast(_readableError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  ReadinessCheck? _check(String key) => _report?.checkFor(key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_vendor.name, overflow: TextOverflow.ellipsis),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_report?.progress ?? 0) / 100,
            backgroundColor: Colors.grey.shade300,
            color: (_report?.isReady ?? false) ? Colors.green : null,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _StatusBanner(report: _report, vendor: _vendor),
                Expanded(
                  child: Stepper(
                    currentStep: _step,
                    onStepTapped: (i) => setState(() => _step = i),
                    controlsBuilder: (_, _) => const SizedBox.shrink(),
                    steps: [
                      for (var i = 0; i < _steps.length; i++)
                        Step(
                          title: Text(_steps[i].title),
                          isActive: _step == i,
                          state: _stepState(_steps[i]),
                          content: _buildStepContent(i),
                        ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _report == null || _report!.isActivated
          ? null
          : _ActivateBar(
              report: _report!,
              busy: _saving,
              onActivate: _activate,
            ),
    );
  }

  StepState _stepState(VendorOnboardingStep def) {
    if (def.checkKeys.isEmpty) return StepState.indexed;
    final checks = def.checkKeys.map(_check).whereType<ReadinessCheck>();
    if (checks.any((c) => c.blocking && !c.isOk)) return StepState.indexed;
    if (checks.any((c) => !c.isOk)) return StepState.editing;
    return StepState.complete;
  }

  Widget _buildStepContent(int index) {
    switch (index) {
      case 0:
        return _IdentityStep(
          vendor: _vendor,
          saving: _saving,
          onSave: _saveIdentity,
        );
      case 1:
        return _VisualsStep(
          vendor: _vendor,
          saving: _saving,
          onPickAndSave: _saveLogo,
        );
      case 2:
        return _LocationStep(
          vendor: _vendor,
          saving: _saving,
          onSave: _saveLocation,
        );
      case 3:
        return _HoursStep(vendor: _vendor, saving: _saving, onSave: _saveHours);
      case 4:
        return _DeliveryStep(
          vendor: _vendor,
          saving: _saving,
          onSave: _saveDelivery,
        );
      case 5:
        return _CommerceStep(
          vendor: _vendor,
          saving: _saving,
          onSave: _saveCommerce,
          onSavePayout: _savePayoutAccount,
          payoutCheck: _check('payout'),
        );
      case 6:
        return _CatalogStep(check: _check('catalog'));
      default:
        return _ReviewStep(report: _report, vendor: _vendor);
    }
  }

  // ─── Enregistrements ───────────────────────────────────────────────────────

  Future<void> _saveIdentity(Map<String, String> values) => _save(
    () => _service.updateIdentity(
      _vendor.id,
      nom: values['nom'],
      description: values['description'],
      phone: values['phone'],
      email: values['email'],
    ),
    'Identité enregistrée',
  );

  Future<void> _saveLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (image == null) return;

    await _save(() async {
      final cloudinary = CloudinaryService(ref.read(apiClientProvider));
      final result = await cloudinary.uploadImageWithPublicId(
        image,
        folder: UploadFolder.restaurants,
      );
      if (result == null) {
        throw const UploadException("L'image n'a pas pu être envoyée.");
      }
      await _service.updateIdentity(
        _vendor.id,
        imageUrl: result.secureUrl,
        imagePublicId: result.publicId,
      );
    }, 'Logo enregistré');
  }

  Future<void> _saveLocation(Map<String, dynamic> values) => _save(
    () => _service.updateLocation(
      _vendor.id,
      adresse: values['adresse'] as String?,
      quartierId: values['quartierId'] as String?,
      latitude: values['latitude'] as double?,
      longitude: values['longitude'] as double?,
      deliveryInstructions: values['deliveryInstructions'] as String?,
    ),
    'Localisation enregistrée',
  );

  Future<void> _saveHours(List<Map<String, dynamic>> hours) => _save(
    () => _service.updateHours(_vendor.id, hours),
    'Horaires enregistrés',
  );

  Future<void> _saveDelivery(Map<String, dynamic> values) => _save(
    () => _service.updateDelivery(
      _vendor.id,
      supportsDelivery: values['supportsDelivery'] as bool?,
      supportsPickup: values['supportsPickup'] as bool?,
      deliveryPriceMode: values['deliveryPriceMode'] as String?,
      fixedDeliveryFee: values['fixedDeliveryFee'] as int?,
      estimatedDeliveryTimeMin: values['estimatedDeliveryTimeMin'] as int?,
      estimatedDeliveryTimeMax: values['estimatedDeliveryTimeMax'] as int?,
    ),
    'Livraison enregistrée',
  );

  Future<void> _saveCommerce(double? commission, int? minOrder) => _save(
    () => _service.updateCommerce(
      _vendor.id,
      commissionPercent: commission,
      clearCommission: commission == null,
      minimumOrderAmount: minOrder,
    ),
    'Paramètres commerciaux enregistrés',
  );

  Future<void> _savePayoutAccount(String phone, String provider) => _save(
    () => _service.updatePayoutAccount(
      _vendor.id,
      payoutPhoneNumber: phone,
      payoutProvider: provider,
    ),
    'Compte de reversement enregistré',
  );

  Future<void> _activate({bool skipRecommendations = false}) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _service.activate(
        _vendor.id,
        skipRecommendations: skipRecommendations,
      );
      await _refresh();
      if (!mounted) return;
      _toast('${_vendor.name} est activé.');
    } catch (e) {
      if (!mounted) return;
      // Un 409 sur les seules recommandations n'est pas un échec : c'est une
      // demande de confirmation. On la pose plutôt que d'afficher une erreur.
      final message = _readableError(e);
      if (!skipRecommendations && message.contains('recommandés')) {
        final confirmed = await _confirmSkipRecommendations();
        if (confirmed == true) {
          setState(() => _saving = false);
          return _activate(skipRecommendations: true);
        }
      } else {
        _toast(message, error: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool?> _confirmSkipRecommendations() => showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Activer malgré tout ?'),
      content: const Text(
        'Des éléments recommandés manquent (description, photo de '
        'couverture). La boutique fonctionnera, mais elle sera moins '
        'attractive pour les clients.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Compléter d’abord'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Activer'),
        ),
      ],
    ),
  );

  String _readableError(Object e) {
    final raw = e.toString();
    return raw.replaceFirst('Exception: ', '');
  }
}

// ─── Bandeau d'état ──────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final OnboardingReport? report;
  final Restaurant vendor;

  const _StatusBanner({required this.report, required this.vendor});

  @override
  Widget build(BuildContext context) {
    if (report == null) return const SizedBox.shrink();

    final activated = report!.isActivated;
    final ready = report!.isReady;
    final (color, icon, text) = activated
        ? (
            Colors.green,
            Icons.check_circle,
            vendor.adminApproved
                ? 'Boutique en ligne — visible par les clients'
                : 'Activée, en attente de validation marketplace',
          )
        : ready
        ? (
            Colors.blue,
            Icons.task_alt,
            'Configuration terminée — prête à activer',
          )
        : (
            Colors.orange,
            Icons.pending_outlined,
            '${report!.blockingIssues.length} élément(s) à compléter — invisible des clients',
          );

    return Container(
      width: double.infinity,
      color: color.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13, color: color)),
          ),
          Text(
            '${report!.progress}%',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Barre d'activation ──────────────────────────────────────────────────────

class _ActivateBar extends StatelessWidget {
  final OnboardingReport report;
  final bool busy;
  final Future<void> Function() onActivate;

  const _ActivateBar({
    required this.report,
    required this.busy,
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FilledButton.icon(
          onPressed: report.isReady && !busy ? () => onActivate() : null,
          icon: busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.rocket_launch),
          label: Text(
            report.isReady
                ? 'Activer la boutique'
                : 'Complétez la configuration pour activer',
          ),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: report.isReady ? Colors.green.shade600 : null,
          ),
        ),
      ),
    );
  }
}

// ─── Étapes ──────────────────────────────────────────────────────────────────

class _IdentityStep extends StatefulWidget {
  final Restaurant vendor;
  final bool saving;
  final Future<void> Function(Map<String, String>) onSave;

  const _IdentityStep({
    required this.vendor,
    required this.saving,
    required this.onSave,
  });

  @override
  State<_IdentityStep> createState() => _IdentityStepState();
}

class _IdentityStepState extends State<_IdentityStep> {
  late final _nom = TextEditingController(text: widget.vendor.name);
  late final _description = TextEditingController(
    text: widget.vendor.description ?? '',
  );
  late final _phone = TextEditingController(
    text: widget.vendor.phoneNumber ?? '',
  );
  late final _email = TextEditingController(
    text: widget.vendor.contactEmail ?? '',
  );

  @override
  void dispose() {
    _nom.dispose();
    _description.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      hint: 'Ce que le client lit en premier sur la fiche.',
      saving: widget.saving,
      onSave: () => widget.onSave({
        'nom': _nom.text.trim(),
        'description': _description.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
      }),
      children: [
        _field(_nom, 'Nom commercial *'),
        _field(
          _description,
          'Description',
          maxLines: 3,
          helper:
              'Recommandé : sans elle, le client ne sait pas ce que vous vendez.',
        ),
        _field(
          _phone,
          'Téléphone du commerce *',
          keyboard: TextInputType.phone,
        ),
        _field(
          _email,
          'E-mail de contact',
          keyboard: TextInputType.emailAddress,
        ),
      ],
    );
  }
}

class _VisualsStep extends StatelessWidget {
  final Restaurant vendor;
  final bool saving;
  final Future<void> Function() onPickAndSave;

  const _VisualsStep({
    required this.vendor,
    required this.saving,
    required this.onPickAndSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Le logo apparaît sur chaque carte du catalogue.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: saving ? null : onPickAndSave,
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400),
              image: vendor.imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(vendor.imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: saving
                ? const Center(child: CircularProgressIndicator())
                : vendor.imageUrl == null
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 36),
                        SizedBox(height: 6),
                        Text('Choisir un logo'),
                      ],
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'JPEG, PNG ou WebP — 5 Mo maximum. L’image est compressée automatiquement.',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        const Text(
          'La photo de couverture et la galerie se gèrent depuis l’écran Photos '
          'du vendeur. Elles sont recommandées mais ne bloquent pas l’activation.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

class _LocationStep extends StatefulWidget {
  final Restaurant vendor;
  final bool saving;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const _LocationStep({
    required this.vendor,
    required this.saving,
    required this.onSave,
  });

  @override
  State<_LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<_LocationStep> {
  late final _adresse = TextEditingController(text: widget.vendor.address);
  late final _lat = TextEditingController(
    text: widget.vendor.latitude?.toString() ?? '',
  );
  late final _lng = TextEditingController(
    text: widget.vendor.longitude?.toString() ?? '',
  );
  late final _instructions = TextEditingController(
    text: widget.vendor.deliveryInstructions ?? '',
  );

  @override
  void dispose() {
    _adresse.dispose();
    _lat.dispose();
    _lng.dispose();
    _instructions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      hint:
          'Sans GPS, le délai affiché au client et le trajet du livreur sont faux.',
      saving: widget.saving,
      onSave: () {
        final lat = double.tryParse(_lat.text.trim());
        final lng = double.tryParse(_lng.text.trim());
        if (lat == null || lng == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coordonnées GPS invalides')),
          );
          return Future.value();
        }
        return widget.onSave({
          'adresse': _adresse.text.trim(),
          'latitude': lat,
          'longitude': lng,
          'deliveryInstructions': _instructions.text.trim(),
        });
      },
      children: [
        _field(_adresse, 'Adresse *'),
        Row(
          children: [
            Expanded(
              child: _field(_lat, 'Latitude *', keyboard: TextInputType.number),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(
                _lng,
                'Longitude *',
                keyboard: TextInputType.number,
              ),
            ),
          ],
        ),
        _field(
          _instructions,
          'Repères pour le livreur',
          helper: 'Ex. : portail bleu, face à la pharmacie',
        ),
        const Text(
          'Le quartier se choisit depuis l’écran Zones du vendeur.',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}

class _HoursStep extends StatefulWidget {
  final Restaurant vendor;
  final bool saving;
  final Future<void> Function(List<Map<String, dynamic>>) onSave;

  const _HoursStep({
    required this.vendor,
    required this.saving,
    required this.onSave,
  });

  @override
  State<_HoursStep> createState() => _HoursStepState();
}

class _HoursStepState extends State<_HoursStep> {
  static const _days = [
    ('LUNDI', 'Lundi'),
    ('MARDI', 'Mardi'),
    ('MERCREDI', 'Mercredi'),
    ('JEUDI', 'Jeudi'),
    ('VENDREDI', 'Vendredi'),
    ('SAMEDI', 'Samedi'),
    ('DIMANCHE', 'Dimanche'),
  ];

  late Map<String, ({String open, String close, bool closed})> _state;

  @override
  void initState() {
    super.initState();
    _state = {
      for (final (key, _) in _days)
        key: () {
          // `dayOfWeek` est un enum `DayOfWeek`, pas une chaîne : comparer
          // directement à `key` renvoyait toujours faux, et tous les jours
          // seraient repartis sur les valeurs par défaut au lieu de refléter
          // les horaires réellement enregistrés.
          final found = widget.vendor.operatingHours
              .where((h) => h.dayOfWeek.name == key)
              .firstOrNull;
          return (
            open: found?.openTime ?? '08:00',
            close: found?.closeTime ?? '20:00',
            // Un jour sans ligne est fermé — défaut sûr, aligné sur le cron qui
            // ferme désormais les vendeurs sans horaires.
            closed: found?.isClosed ?? true,
          );
        }(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      hint:
          'La boutique ouvre et ferme automatiquement selon ces horaires. '
          'Sans aucun jour ouvert, elle reste fermée.',
      saving: widget.saving,
      onSave: () => widget.onSave([
        for (final (key, _) in _days)
          {
            'dayOfWeek': key,
            'openTime': _state[key]!.open,
            'closeTime': _state[key]!.close,
            'isClosed': _state[key]!.closed,
          },
      ]),
      children: [
        TextButton(
          onPressed: () => setState(() {
            final monday = _state['LUNDI']!;
            for (final (key, _) in _days) {
              _state[key] = monday;
            }
          }),
          child: const Text('Appliquer le lundi à toute la semaine'),
        ),
        for (final (key, label) in _days)
          Row(
            children: [
              SizedBox(
                width: 130,
                child: CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: !_state[key]!.closed,
                  onChanged: (v) => setState(() {
                    _state[key] = (
                      open: _state[key]!.open,
                      close: _state[key]!.close,
                      closed: !(v ?? false),
                    );
                  }),
                  title: Text(label, style: const TextStyle(fontSize: 13)),
                ),
              ),
              Expanded(
                child: _TimeButton(
                  value: _state[key]!.open,
                  enabled: !_state[key]!.closed,
                  onPick: (v) => setState(() {
                    _state[key] = (
                      open: v,
                      close: _state[key]!.close,
                      closed: _state[key]!.closed,
                    );
                  }),
                ),
              ),
              const Text(' → '),
              Expanded(
                child: _TimeButton(
                  value: _state[key]!.close,
                  enabled: !_state[key]!.closed,
                  onPick: (v) => setState(() {
                    _state[key] = (
                      open: _state[key]!.open,
                      close: v,
                      closed: _state[key]!.closed,
                    );
                  }),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String value;
  final bool enabled;
  final ValueChanged<String> onPick;

  const _TimeButton({
    required this.value,
    required this.enabled,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: enabled
          ? () async {
              final parts = value.split(':');
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: int.tryParse(parts.first) ?? 8,
                  minute: int.tryParse(parts.last) ?? 0,
                ),
              );
              if (picked != null) {
                onPick(
                  '${picked.hour.toString().padLeft(2, '0')}:'
                  '${picked.minute.toString().padLeft(2, '0')}',
                );
              }
            }
          : null,
      child: Text(value),
    );
  }
}

class _DeliveryStep extends StatefulWidget {
  final Restaurant vendor;
  final bool saving;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const _DeliveryStep({
    required this.vendor,
    required this.saving,
    required this.onSave,
  });

  @override
  State<_DeliveryStep> createState() => _DeliveryStepState();
}

class _DeliveryStepState extends State<_DeliveryStep> {
  late bool _delivery = widget.vendor.supportsDelivery;
  late bool _pickup = widget.vendor.supportsPickup;
  late final _fee = TextEditingController(
    text: widget.vendor.fixedDeliveryFee.toInt().toString(),
  );
  late final _min = TextEditingController(
    text: widget.vendor.estimatedDeliveryTimeMin.toString(),
  );
  late final _max = TextEditingController(
    text: widget.vendor.estimatedDeliveryTimeMax.toString(),
  );

  @override
  void dispose() {
    _fee.dispose();
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      hint: 'Un vendeur doit accepter au moins la livraison ou le retrait.',
      saving: widget.saving,
      onSave: () => widget.onSave({
        'supportsDelivery': _delivery,
        'supportsPickup': _pickup,
        'fixedDeliveryFee': int.tryParse(_fee.text.trim()),
        'estimatedDeliveryTimeMin': int.tryParse(_min.text.trim()),
        'estimatedDeliveryTimeMax': int.tryParse(_max.text.trim()),
      }),
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _delivery,
          onChanged: (v) => setState(() => _delivery = v),
          title: const Text('Livraison à domicile'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _pickup,
          onChanged: (v) => setState(() => _pickup = v),
          title: const Text('Retrait au comptoir'),
        ),
        if (_delivery) ...[
          _field(
            _fee,
            'Frais de livraison (XAF)',
            keyboard: TextInputType.number,
          ),
          Row(
            children: [
              Expanded(
                child: _field(
                  _min,
                  'Délai min (min)',
                  keyboard: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  _max,
                  'Délai max (min)',
                  keyboard: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _CommerceStep extends StatefulWidget {
  final Restaurant vendor;
  final bool saving;
  final Future<void> Function(double?, int?) onSave;
  final Future<void> Function(String phone, String provider) onSavePayout;
  final ReadinessCheck? payoutCheck;

  const _CommerceStep({
    required this.vendor,
    required this.saving,
    required this.onSave,
    required this.onSavePayout,
    required this.payoutCheck,
  });

  @override
  State<_CommerceStep> createState() => _CommerceStepState();
}

class _CommerceStepState extends State<_CommerceStep> {
  late final _commission = TextEditingController(
    text: widget.vendor.commissionPercent?.toString() ?? '',
  );
  late final _minOrder = TextEditingController(
    text: widget.vendor.minimumOrderAmount.toInt().toString(),
  );
  final _payoutPhone = TextEditingController();
  String _payoutProvider = 'MTN_MOMO';

  @override
  void dispose() {
    _commission.dispose();
    _minOrder.dispose();
    _payoutPhone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final payoutOk = widget.payoutCheck?.isOk ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepShell(
          hint:
              'Réservé aux administrateurs — le vendeur ne peut pas modifier sa commission.',
          saving: widget.saving,
          onSave: () => widget.onSave(
            double.tryParse(_commission.text.trim()),
            int.tryParse(_minOrder.text.trim()),
          ),
          children: [
            _field(
              _commission,
              'Commission plateforme (%)',
              keyboard: TextInputType.number,
              helper:
                  'Vide = taux plateforme. Figée sur chaque commande passée.',
            ),
            _field(
              _minOrder,
              'Minimum de commande (XAF)',
              keyboard: TextInputType.number,
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),

        // ── Compte de reversement ────────────────────────────────────────────
        // Case bloquante depuis septembre 2026. Les six vendeurs de production
        // ont vécu sans, onze commandes encaissées et aucun reversement
        // possible : la checklist ne posait pas la question, donc personne ne
        // pouvait y répondre.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (payoutOk ? Colors.green : Colors.orange).withValues(
              alpha: 0.1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                payoutOk ? Icons.check_circle : Icons.account_balance_wallet,
                size: 18,
                color: payoutOk ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.payoutCheck?.detail ??
                      (payoutOk
                          ? 'Compte de reversement enregistré.'
                          : 'Aucun compte de reversement.'),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _StepShell(
          hint:
              'Numéro Mobile Money sur lequel ce vendeur sera payé. Distinct du '
              'téléphone du commerce. Le serveur ne renvoie jamais le numéro en '
              'clair : pour le changer, saisissez-le en entier.',
          saving: widget.saving,
          onSave: () =>
              widget.onSavePayout(_payoutPhone.text.trim(), _payoutProvider),
          children: [
            _field(
              _payoutPhone,
              'Numéro de reversement *',
              keyboard: TextInputType.phone,
              helper: widget.vendor.isPayable
                  ? 'Un compte est déjà enregistré — saisir un numéro le remplace.'
                  : 'Ex. 06 123 45 67',
            ),
            DropdownButtonFormField<String>(
              initialValue: _payoutProvider,
              decoration: const InputDecoration(
                labelText: 'Opérateur *',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'MTN_MOMO', child: Text('MTN MoMo')),
                DropdownMenuItem(
                  value: 'AIRTEL_MONEY',
                  child: Text('Airtel Money'),
                ),
              ],
              onChanged: (v) =>
                  setState(() => _payoutProvider = v ?? 'MTN_MOMO'),
            ),
          ],
        ),
      ],
    );
  }
}

class _CatalogStep extends StatelessWidget {
  final ReadinessCheck? check;
  const _CatalogStep({required this.check});

  @override
  Widget build(BuildContext context) {
    final ok = check?.isOk ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (ok ? Colors.green : Colors.orange).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(check?.detail ?? 'Aucun produit'),
        ),
        const SizedBox(height: 12),
        const Text(
          'Un produit doit avoir un prix supérieur à zéro et au moins une '
          'variante pour être commandable. Gérez le catalogue depuis l’écran '
          'Produits.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  final OnboardingReport? report;
  final Restaurant vendor;

  const _ReviewStep({required this.report, required this.vendor});

  @override
  Widget build(BuildContext context) {
    if (report == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final c in report!.checks)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              c.isOk
                  ? Icons.check_circle
                  : c.blocking
                  ? Icons.radio_button_unchecked
                  : Icons.info_outline,
              size: 18,
              color: c.isOk
                  ? Colors.green
                  : c.blocking
                  ? Colors.grey
                  : Colors.orange,
            ),
            title: Text(
              c.label + (c.blocking || c.isOk ? '' : ' (recommandé)'),
              style: const TextStyle(fontSize: 13),
            ),
            subtitle: c.detail != null
                ? Text(c.detail!, style: const TextStyle(fontSize: 11))
                : null,
          ),
      ],
    );
  }
}

// ─── Primitives ──────────────────────────────────────────────────────────────

class _StepShell extends StatelessWidget {
  final String hint;
  final bool saving;
  final Future<void> Function() onSave;
  final List<Widget> children;

  const _StepShell({
    required this.hint,
    required this.saving,
    required this.onSave,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hint, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 12),
        ...children,
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: saving ? null : () => onSave(),
            child: saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enregistrer'),
          ),
        ),
      ],
    );
  }
}

Widget _field(
  TextEditingController controller,
  String label, {
  TextInputType? keyboard,
  int maxLines = 1,
  String? helper,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        helperMaxLines: 2,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lilia_admin/core/network/api_client.dart';

import '../../../../models/onboarding_report.dart';
import '../../../../models/vendor_type.dart';
import '../../data/vendor_onboarding_service.dart';
import 'vendor_onboarding_screen.dart';

/// Étape 1 de l'onboarding : le compte vendeur et la boutique.
///
/// Deux changements par rapport au formulaire qu'il remplace :
///
/// 1. **Plus de champ mot de passe.** L'administrateur ne choisit plus le
///    secret du vendeur pour le lui transmettre ensuite de vive voix. Le
///    backend envoie une invitation d'activation ; le vendeur définit son mot
///    de passe lui-même.
/// 2. **La boutique naît invisible.** Ces champs ne suffisent pas à publier :
///    le wizard prend le relais pour les horaires, le GPS et le catalogue.
class CreateRestaurantScreen extends ConsumerStatefulWidget {
  const CreateRestaurantScreen({super.key});

  @override
  ConsumerState<CreateRestaurantScreen> createState() =>
      _CreateRestaurantScreenState();
}

class _CreateRestaurantScreenState
    extends ConsumerState<CreateRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  VendorType _vendorType = VendorType.RESTAURANT;

  /// Générée une seule fois par écran : deux envois successifs du même
  /// formulaire portent la même clé et ne créent qu'un vendeur, même si le
  /// premier appel s'est perdu en route.
  final String _idempotencyKey =
      'vendor-${DateTime.now().microsecondsSinceEpoch}';

  final _ownerNom = TextEditingController();
  final _ownerEmail = TextEditingController();
  final _ownerPhone = TextEditingController();
  final _nom = TextEditingController();
  final _adresse = TextEditingController();
  final _phone = TextEditingController();
  final _description = TextEditingController();

  @override
  void dispose() {
    _ownerNom.dispose();
    _ownerEmail.dispose();
    _ownerPhone.dispose();
    _nom.dispose();
    _adresse.dispose();
    _phone.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final service = VendorOnboardingService(ref.read(apiClientProvider));
      final result = await service.createVendor(
        vendorType: _vendorType,
        ownerNom: _ownerNom.text.trim(),
        ownerEmail: _ownerEmail.text.trim(),
        ownerPhone: _ownerPhone.text.trim(),
        nom: _nom.text.trim(),
        adresse: _adresse.text.trim(),
        phone: _phone.text.trim(),
        description: _description.text.trim(),
        idempotencyKey: _idempotencyKey,
      );

      if (!mounted) return;

      // Si l'e-mail n'est pas parti, le backend rend le lien d'activation
      // plutôt que de laisser le vendeur sans accès. On le montre à l'admin.
      final invitation = result.invitation;
      if (invitation != null &&
          !invitation.emailSent &&
          invitation.activationLink != null) {
        await _showFallbackLink(invitation);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${result.vendor.name} créé — invitation envoyée à '
              '${_ownerEmail.text.trim()}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (!mounted) return;
      // Enchaîne sur la configuration : créer sans configurer ne sert à rien,
      // et c'est ce que faisait l'ancien écran en refermant sur une liste.
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => VendorOnboardingScreen(vendor: result.vendor),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showFallbackLink(VendorInvitationResult invitation) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Transmettez ce lien au vendeur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'La boutique est créée, mais l’e-mail d’invitation n’est pas '
              'parti. Ce lien permet au vendeur de définir son mot de passe. '
              'Il est personnel — transmettez-le par un canal sûr.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            SelectableText(
              invitation.activationLink!,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: invitation.activationLink!),
              );
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Lien copié')),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copier'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau vendeur'), centerTitle: true),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Étape 1 sur 8 — la boutique restera invisible des clients '
              'jusqu’à son activation.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            _sectionTitle('Type de vendeur'),
            for (final type in VendorType.values)
              if (type != VendorType.GROCERY)
                RadioListTile<VendorType>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: type,
                  groupValue: _vendorType,
                  onChanged: (v) => setState(() => _vendorType = v!),
                  title: Text('${type.emoji} ${type.label}'),
                  subtitle: Text(
                    type == VendorType.RESTAURANT
                        ? 'Validé d’office'
                        : 'Validation marketplace requise',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),

            const SizedBox(height: 20),
            _sectionTitle('Propriétaire'),
            const Text(
              'Un compte est créé et une invitation part vers cette adresse. '
              'Le vendeur choisira lui-même son mot de passe — vous n’avez '
              'rien à lui transmettre.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            _field(_ownerNom, 'Nom du propriétaire *', required: true),
            _field(
              _ownerEmail,
              'E-mail *',
              required: true,
              keyboard: TextInputType.emailAddress,
              validator: (v) =>
                  RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v?.trim() ?? '')
                      ? null
                      : 'Email invalide',
            ),
            _field(
              _ownerPhone,
              'Téléphone *',
              required: true,
              keyboard: TextInputType.phone,
              helper: 'Un SMS l’avertit que son espace est prêt.',
            ),

            const SizedBox(height: 20),
            _sectionTitle('Boutique'),
            _field(_nom, 'Nom commercial *', required: true),
            _field(_adresse, 'Adresse *', required: true),
            _field(_phone, 'Téléphone du commerce *',
                required: true, keyboard: TextInputType.phone),
            _field(_description, 'Description', maxLines: 3,
                helper: 'Vous pourrez la compléter à l’étape suivante.'),

            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Créer et configurer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: Colors.grey,
          ),
        ),
      );

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    TextInputType? keyboard,
    int maxLines = 1,
    String? helper,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
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
        validator: validator ??
            (required
                ? (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null
                : null),
      ),
    );
  }
}

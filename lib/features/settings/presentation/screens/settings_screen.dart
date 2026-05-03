import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/user_sync_provider.dart';
import '../../../../models/role.dart';
import '../providers/settings_provider.dart';
import '../../../../models/restaurant.dart';

// ============================================================
// Couleurs du theme
// ============================================================
class _AppColors {
  static const primary = Color(0xFF6C63FF);
  static const primaryLight = Color(0xFFEEEDFF);
  static const success = Color(0xFF22C55E);
  static const successLight = Color(0xFFDCFCE7);
  static const danger = Color(0xFFEF4444);
  static const dangerLight = Color(0xFFFEE2E2);
  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFEF3C7);
  static const surface = Color(0xFFF8FAFC);
  static const cardBg = Colors.white;
  static const textPrimary = Color(0xFF1E293B);
  static const textSecondary = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
}

// ============================================================
// Settings Screen principal
// ============================================================
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(currentUserProfileProvider);
    final isAdmin = userProfile?.role == Role.admin;

    if (isAdmin) {
      return Scaffold(
        backgroundColor: _AppColors.surface,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Administration',
            style: TextStyle(
              color: _AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.admin_panel_settings, size: 80, color: _AppColors.primary),
                SizedBox(height: 24),
                Text(
                  'Espace Administrateur',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Les parametres de restaurant sont accessibles depuis le profil de chaque restaurateur. Utilisez le tableau de bord pour voir les statistiques globales.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: _AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final settingsAsync = ref.watch(restaurantSettingsProvider);

    return Scaffold(
      backgroundColor: _AppColors.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Parametres',
          style: TextStyle(
            color: _AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _AppColors.border, width: 1)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: _AppColors.primary,
              unselectedLabelColor: _AppColors.textSecondary,
              indicatorColor: _AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: 'General'),
                Tab(text: 'Horaires'),
                Tab(text: 'Livraison'),
                Tab(text: 'Specialites'),
              ],
            ),
          ),
        ),
      ),
      body: settingsAsync.when(
        data: (restaurant) => TabBarView(
          controller: _tabController,
          children: [
            _GeneralInfoTab(restaurant: restaurant),
            _OperatingHoursTab(restaurant: restaurant),
            _DeliverySettingsTab(restaurant: restaurant),
            _SpecialtiesTab(restaurant: restaurant),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: _AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: _AppColors.dangerLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline, color: _AppColors.danger, size: 48),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Impossible de charger les donnees',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => ref.read(restaurantSettingsProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reessayer'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Widgets reutilisables
// ============================================================
class _SectionCard extends StatelessWidget {
  final String? title;
  final IconData? icon;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({this.title, this.icon, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 18, color: _AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      title!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: 20),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool enabled;
  final TextInputType? keyboardType;
  final String? suffix;
  final int maxLines;
  final IconData? prefixIcon;

  const _StyledTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.enabled = true,
    this.keyboardType,
    this.suffix,
    this.maxLines = 1,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
        color: enabled ? _AppColors.textPrimary : _AppColors.textSecondary,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
        filled: true,
        fillColor: enabled ? Colors.white : _AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _AppColors.primary, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _AppColors.border.withValues(alpha: 0.5)),
        ),
        labelStyle: const TextStyle(color: _AppColors.textSecondary, fontSize: 14),
      ),
    );
  }
}

// ============================================================
// Tab 1 : General
// ============================================================
class _GeneralInfoTab extends ConsumerStatefulWidget {
  final Restaurant restaurant;
  const _GeneralInfoTab({required this.restaurant});

  @override
  ConsumerState<_GeneralInfoTab> createState() => _GeneralInfoTabState();
}

class _GeneralInfoTabState extends ConsumerState<_GeneralInfoTab> {
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _descriptionController;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _nameController = TextEditingController(text: widget.restaurant.name);
    _addressController = TextEditingController(text: widget.restaurant.address);
    _phoneController = TextEditingController(text: widget.restaurant.phoneNumber ?? '');
    _descriptionController = TextEditingController(text: widget.restaurant.description ?? '');
  }

  @override
  void didUpdateWidget(_GeneralInfoTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.restaurant.id != widget.restaurant.id) {
      _initControllers();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(restaurantSettingsProvider.notifier).updateGeneralInfo(
        name: _nameController.text,
        address: _addressController.text,
        phone: _phoneController.text,
        description: _descriptionController.text,
      );
      setState(() => _isEditing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Informations mises a jour'),
              ],
            ),
            backgroundColor: _AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: _AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Statut ouvert/ferme
        _SectionCard(
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: widget.restaurant.isOpen ? _AppColors.successLight : _AppColors.dangerLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  widget.restaurant.isOpen ? Icons.store : Icons.store_outlined,
                  color: widget.restaurant.isOpen ? _AppColors.success : _AppColors.danger,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.restaurant.isOpen ? 'Restaurant ouvert' : 'Restaurant ferme',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: _AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.restaurant.isOpen
                          ? 'Les clients peuvent commander'
                          : 'Les commandes sont desactivees',
                      style: const TextStyle(color: _AppColors.textSecondary, fontSize: 13),
                    ),
                    if (widget.restaurant.manualOverride)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _AppColors.warningLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Mode manuel actif',
                            style: TextStyle(
                              color: _AppColors.warning,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.9,
                child: Switch.adaptive(
                  value: widget.restaurant.isOpen,
                  activeColor: _AppColors.success,
                  onChanged: (value) async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Text(value ? 'Ouvrir le restaurant ?' : 'Fermer le restaurant ?'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              value
                                  ? 'Les clients pourront a nouveau passer des commandes.'
                                  : 'Les clients ne pourront plus passer de commandes.',
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _AppColors.warningLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline, color: _AppColors.warning, size: 18),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Le mode manuel sera active : les horaires automatiques ne modifieront plus le statut.',
                                      style: TextStyle(fontSize: 12, color: _AppColors.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Annuler'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: value ? _AppColors.success : _AppColors.danger,
                            ),
                            child: Text(value ? 'Ouvrir' : 'Fermer'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(restaurantSettingsProvider.notifier).updateOpenStatus(value);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Informations generales
        _SectionCard(
          title: 'Informations generales',
          icon: Icons.info_outline,
          trailing: _isEditing
              ? null
              : IconButton(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: const Icon(Icons.edit_outlined, color: _AppColors.primary, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: _AppColors.primaryLight,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
          child: Column(
            children: [
              _StyledTextField(
                controller: _nameController,
                label: 'Nom du restaurant',
                prefixIcon: Icons.restaurant,
                enabled: _isEditing,
              ),
              const SizedBox(height: 14),
              _StyledTextField(
                controller: _addressController,
                label: 'Adresse',
                prefixIcon: Icons.location_on_outlined,
                enabled: _isEditing,
              ),
              const SizedBox(height: 14),
              _StyledTextField(
                controller: _phoneController,
                label: 'Telephone',
                prefixIcon: Icons.phone_outlined,
                enabled: _isEditing,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              _StyledTextField(
                controller: _descriptionController,
                label: 'Description',
                prefixIcon: Icons.description_outlined,
                enabled: _isEditing,
                maxLines: 3,
              ),
              if (_isEditing) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _initControllers();
                          setState(() => _isEditing = false);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: _AppColors.border),
                        ),
                        child: const Text('Annuler', style: TextStyle(color: _AppColors.textSecondary)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isSaving ? null : _saveChanges,
                        style: FilledButton.styleFrom(
                          backgroundColor: _AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Enregistrer'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// Tab 2 : Horaires d'ouverture
// ============================================================
class _OperatingHoursTab extends ConsumerStatefulWidget {
  final Restaurant restaurant;
  const _OperatingHoursTab({required this.restaurant});

  @override
  ConsumerState<_OperatingHoursTab> createState() => _OperatingHoursTabState();
}

class _OperatingHoursTabState extends ConsumerState<_OperatingHoursTab> {
  late Map<DayOfWeek, _DaySchedule> _schedules;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initSchedules();
  }

  @override
  void didUpdateWidget(_OperatingHoursTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.restaurant.id != widget.restaurant.id) {
      _initSchedules();
    }
  }

  void _initSchedules() {
    _schedules = {};
    for (final day in DayOfWeek.values) {
      final existing = widget.restaurant.operatingHours
          .where((h) => h.dayOfWeek == day)
          .toList();
      if (existing.isNotEmpty) {
        _schedules[day] = _DaySchedule(
          openTime: _parseTimeOfDay(existing.first.openTime),
          closeTime: _parseTimeOfDay(existing.first.closeTime),
          isClosed: existing.first.isClosed,
        );
      } else {
        _schedules[day] = _DaySchedule(
          openTime: const TimeOfDay(hour: 8, minute: 0),
          closeTime: const TimeOfDay(hour: 22, minute: 0),
          isClosed: false,
        );
      }
    }
    _hasChanges = false;
  }

  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickTime(DayOfWeek day, bool isOpenTime) async {
    final schedule = _schedules[day]!;
    final initial = isOpenTime ? schedule.openTime : schedule.closeTime;

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(primary: _AppColors.primary),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isOpenTime) {
          _schedules[day] = schedule.copyWith(openTime: picked);
        } else {
          _schedules[day] = schedule.copyWith(closeTime: picked);
        }
        _hasChanges = true;
      });
    }
  }

  Future<void> _saveAll() async {
    setState(() => _isSaving = true);
    try {
      final hours = _schedules.entries.map((entry) {
        final schedule = entry.value;
        return {
          'dayOfWeek': entry.key.name,
          'openTime': _formatTimeOfDay(schedule.openTime),
          'closeTime': _formatTimeOfDay(schedule.closeTime),
          'isClosed': schedule.isClosed,
        };
      }).toList();

      await ref.read(restaurantSettingsProvider.notifier).setOperatingHours(hours);
      setState(() => _hasChanges = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Horaires enregistres'),
              ],
            ),
            backgroundColor: _AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: _AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasExistingHours = widget.restaurant.operatingHours.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Banner info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_AppColors.primary.withValues(alpha: 0.08), _AppColors.primary.withValues(alpha: 0.03)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _AppColors.primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.schedule, color: _AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Horaires automatiques',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasExistingHours
                          ? 'Le restaurant s\'ouvre et se ferme automatiquement selon ces horaires.'
                          : 'Definissez vos horaires pour activer l\'ouverture/fermeture automatique.',
                      style: const TextStyle(color: _AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        if (widget.restaurant.manualOverride) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _AppColors.warningLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: _AppColors.warning, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Le mode manuel est actif. Enregistrez les horaires pour reactiver le mode automatique.',
                    style: TextStyle(color: _AppColors.textPrimary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Les jours
        ...DayOfWeek.values.map((day) => _buildDayCard(day)),

        const SizedBox(height: 24),

        // Bouton Enregistrer
        FilledButton.icon(
          onPressed: _isSaving ? null : _saveAll,
          icon: _isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save_outlined),
          label: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer les horaires'),
          style: FilledButton.styleFrom(
            backgroundColor: _hasChanges ? _AppColors.primary : _AppColors.primary.withValues(alpha: 0.6),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDayCard(DayOfWeek day) {
    final schedule = _schedules[day]!;
    final isToday = _isCurrentDay(day);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: _AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: isToday ? Border.all(color: _AppColors.primary.withValues(alpha: 0.4), width: 1.5) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Jour
              SizedBox(
                width: 44,
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: schedule.isClosed
                            ? _AppColors.dangerLight
                            : isToday
                                ? _AppColors.primaryLight
                                : _AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          day.shortLabel,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: schedule.isClosed
                                ? _AppColors.danger
                                : isToday
                                    ? _AppColors.primary
                                    : _AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: _AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Horaires ou "Ferme"
              Expanded(
                child: schedule.isClosed
                    ? const Text(
                        'Ferme',
                        style: TextStyle(
                          color: _AppColors.danger,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      )
                    : Row(
                        children: [
                          _TimeChip(
                            time: schedule.openTime,
                            label: 'Ouverture',
                            color: _AppColors.success,
                            onTap: () => _pickTime(day, true),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.arrow_forward, size: 16, color: _AppColors.textSecondary),
                          ),
                          _TimeChip(
                            time: schedule.closeTime,
                            label: 'Fermeture',
                            color: _AppColors.danger,
                            onTap: () => _pickTime(day, false),
                          ),
                        ],
                      ),
              ),

              // Toggle ferme
              Transform.scale(
                scale: 0.8,
                child: Switch.adaptive(
                  value: !schedule.isClosed,
                  activeColor: _AppColors.success,
                  onChanged: (value) {
                    setState(() {
                      _schedules[day] = schedule.copyWith(isClosed: !value);
                      _hasChanges = true;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isCurrentDay(DayOfWeek day) {
    final now = DateTime.now();
    const mapping = {
      1: DayOfWeek.LUNDI,
      2: DayOfWeek.MARDI,
      3: DayOfWeek.MERCREDI,
      4: DayOfWeek.JEUDI,
      5: DayOfWeek.VENDREDI,
      6: DayOfWeek.SAMEDI,
      7: DayOfWeek.DIMANCHE,
    };
    return mapping[now.weekday] == day;
  }
}

class _TimeChip extends StatelessWidget {
  final TimeOfDay time;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _TimeChip({
    required this.time,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Text(
          timeStr,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _DaySchedule {
  final TimeOfDay openTime;
  final TimeOfDay closeTime;
  final bool isClosed;

  _DaySchedule({
    required this.openTime,
    required this.closeTime,
    this.isClosed = false,
  });

  _DaySchedule copyWith({
    TimeOfDay? openTime,
    TimeOfDay? closeTime,
    bool? isClosed,
  }) {
    return _DaySchedule(
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      isClosed: isClosed ?? this.isClosed,
    );
  }
}

// ============================================================
// Tab 3 : Livraison
// ============================================================
class _DeliverySettingsTab extends ConsumerStatefulWidget {
  final Restaurant restaurant;
  const _DeliverySettingsTab({required this.restaurant});

  @override
  ConsumerState<_DeliverySettingsTab> createState() => _DeliverySettingsTabState();
}

class _DeliverySettingsTabState extends ConsumerState<_DeliverySettingsTab> {
  late TextEditingController _deliveryFeeController;
  late TextEditingController _minTimeController;
  late TextEditingController _maxTimeController;
  late TextEditingController _minOrderController;
  late String _deliveryMode;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _deliveryMode = widget.restaurant.deliveryPriceMode;
    _initControllers();
  }

  void _initControllers() {
    _deliveryFeeController = TextEditingController(
      text: widget.restaurant.fixedDeliveryFee.toStringAsFixed(0),
    );
    _minTimeController = TextEditingController(
      text: widget.restaurant.estimatedDeliveryTimeMin.toString(),
    );
    _maxTimeController = TextEditingController(
      text: widget.restaurant.estimatedDeliveryTimeMax.toString(),
    );
    _minOrderController = TextEditingController(
      text: widget.restaurant.minimumOrderAmount.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _deliveryFeeController.dispose();
    _minTimeController.dispose();
    _maxTimeController.dispose();
    _minOrderController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(restaurantSettingsProvider.notifier).updateDeliverySettings(
        fixedDeliveryFee: double.tryParse(_deliveryFeeController.text),
        estimatedDeliveryTimeMin: int.tryParse(_minTimeController.text),
        estimatedDeliveryTimeMax: int.tryParse(_maxTimeController.text),
        minimumOrderAmount: double.tryParse(_minOrderController.text),
        deliveryPriceMode: _deliveryMode,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Parametres de livraison mis a jour'),
              ],
            ),
            backgroundColor: _AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: _AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isZoneBased = _deliveryMode == 'ZONE_BASED';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Section Mode de tarification
        _SectionCard(
          title: 'Mode de tarification',
          icon: Icons.tune_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: _ModeOption(
                      icon: Icons.attach_money,
                      label: 'Prix fixe',
                      description: 'Meme prix pour tous les quartiers',
                      isSelected: !isZoneBased,
                      onTap: () => setState(() => _deliveryMode = 'FIXED'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ModeOption(
                      icon: Icons.map_outlined,
                      label: 'Par quartier',
                      description: 'Prix selon la zone du client',
                      isSelected: isZoneBased,
                      onTap: () => setState(() => _deliveryMode = 'ZONE_BASED'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Section conditionnelle: prix fixe OU zones
        if (!isZoneBased)
          _SectionCard(
            title: 'Frais de livraison',
            icon: Icons.payments_outlined,
            child: _StyledTextField(
              controller: _deliveryFeeController,
              label: 'Frais de livraison',
              suffix: 'FCFA',
              prefixIcon: Icons.monetization_on_outlined,
              keyboardType: TextInputType.number,
            ),
          )
        else
          _SectionCard(
            title: 'Zones de livraison',
            icon: Icons.map_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: _AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Les frais de livraison sont calcules automatiquement selon le quartier du client.',
                          style: TextStyle(fontSize: 13, color: _AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _StyledTextField(
                  controller: _deliveryFeeController,
                  label: 'Prix par defaut (quartier non configure)',
                  suffix: 'FCFA',
                  prefixIcon: Icons.monetization_on_outlined,
                  keyboardType: TextInputType.number,
                  hint: 'Applique si le quartier n\'a pas de zone',
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.goNamed('delivery-zones'),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Gerer les zones et quartiers'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _AppColors.primary,
                      side: const BorderSide(color: _AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        _SectionCard(
          title: 'Temps de livraison estime',
          icon: Icons.timer_outlined,
          child: Row(
            children: [
              Expanded(
                child: _StyledTextField(
                  controller: _minTimeController,
                  label: 'Minimum',
                  suffix: 'min',
                  keyboardType: TextInputType.number,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.arrow_forward, size: 18, color: _AppColors.textSecondary),
              ),
              Expanded(
                child: _StyledTextField(
                  controller: _maxTimeController,
                  label: 'Maximum',
                  suffix: 'min',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Commande minimum',
          icon: Icons.shopping_bag_outlined,
          child: _StyledTextField(
            controller: _minOrderController,
            label: 'Montant minimum de commande',
            suffix: 'FCFA',
            prefixIcon: Icons.monetization_on_outlined,
            keyboardType: TextInputType.number,
            hint: '0 = pas de minimum',
          ),
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: _isSaving ? null : _saveChanges,
          icon: _isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save_outlined),
          label: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer les modifications'),
          style: FilledButton.styleFrom(
            backgroundColor: _AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _ModeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? _AppColors.primary.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _AppColors.primary : _AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? _AppColors.primary.withValues(alpha: 0.12)
                    : Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? _AppColors.primary : _AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? _AppColors.primary : _AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: _AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Tab 4 : Specialites
// ============================================================
class _SpecialtiesTab extends ConsumerStatefulWidget {
  final Restaurant restaurant;
  const _SpecialtiesTab({required this.restaurant});

  @override
  ConsumerState<_SpecialtiesTab> createState() => _SpecialtiesTabState();
}

class _SpecialtiesTabState extends ConsumerState<_SpecialtiesTab> {
  final TextEditingController _newSpecialtyController = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _newSpecialtyController.dispose();
    super.dispose();
  }

  Future<void> _addSpecialty() async {
    final name = _newSpecialtyController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isAdding = true);
    try {
      await ref.read(restaurantSettingsProvider.notifier).addSpecialty(name);
      _newSpecialtyController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Specialite ajoutee'),
              ],
            ),
            backgroundColor: _AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: _AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      setState(() => _isAdding = false);
    }
  }

  Future<void> _removeSpecialty(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer la specialite ?'),
        content: Text('Voulez-vous vraiment supprimer "$name" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: _AppColors.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(restaurantSettingsProvider.notifier).removeSpecialty(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Specialite supprimee'),
                ],
              ),
              backgroundColor: _AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: _AppColors.danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionCard(
          title: 'Ajouter une specialite',
          icon: Icons.add_circle_outline,
          child: Row(
            children: [
              Expanded(
                child: _StyledTextField(
                  controller: _newSpecialtyController,
                  label: 'Nom de la specialite',
                  hint: 'Ex: Pizza, Sushi, Africain...',
                  prefixIcon: Icons.restaurant_menu,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: _isAdding ? null : _addSpecialty,
                  style: FilledButton.styleFrom(
                    backgroundColor: _AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: _isAdding
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.add),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Specialites (${widget.restaurant.specialties.length})',
          icon: Icons.restaurant_menu,
          child: widget.restaurant.specialties.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: _AppColors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.restaurant_menu, color: _AppColors.textSecondary, size: 32),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Aucune specialite ajoutee',
                        style: TextStyle(color: _AppColors.textSecondary, fontSize: 15),
                      ),
                    ],
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.restaurant.specialties.map((specialty) {
                    return Container(
                      decoration: BoxDecoration(
                        color: _AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 14, top: 2, bottom: 2, right: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              specialty.name,
                              style: const TextStyle(
                                color: _AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () => _removeSpecialty(specialty.id, specialty.name),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: _AppColors.primary.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:lilia_admin/features/admin/presentation/providers/deliverer_detail_provider.dart';
import 'package:lilia_admin/models/admin_deliverer.dart';
import 'package:lilia_admin/models/deliverer_detail.dart';
import 'package:lilia_admin/models/deliverer_stats.dart';
import 'package:lilia_admin/models/delivery_mission_summary.dart';
import 'package:lilia_admin/models/delivery_status.dart';
import 'package:lilia_admin/theme/lilia_tokens.dart';
import 'package:lilia_admin/features/admin/data/deliverer_rating_service.dart';

/// Strings UI groupés ici pour rester centralisé (cf. règle « zéro string
/// métier hardcoded »).
class _Strings {
  static const fallbackName = 'Livreur';
  static const fallbackNameLong = 'Livreur sans nom';
  static const sectionStats = 'Statistiques';
  static const sectionCurrentMission = 'Mission en cours';
  static const sectionHistory = 'Historique des missions';
  static const refreshTooltip = 'Actualiser';
  static const callAction = 'Appeler';
  static const copyPhoneAction = 'Copier le téléphone';
  static const retry = 'Réessayer';
  static const errorTitle = 'Erreur de chargement';
  static const phoneCopied = 'Téléphone copié';
  static const noPhone = 'Aucun téléphone disponible';
  static const cantCallNoPhone = 'Aucun numéro à appeler';
  static const trackOnMap = 'Suivre sur la carte';
  static const trackingComingSoon = 'Suivi temps réel bientôt disponible';
  static const filterAll = 'Tout';
  static const emptyMissionsFiltered = 'Aucune mission pour ce filtre';
  static const emptyMissions = 'Aucune mission pour ce livreur';
  static const registeredSince = 'Inscrit depuis le';
  static const statTotalDeliveries = 'Total livraisons';
  static const statSuccessRate = 'Taux de succès';
  static const statRevenue = 'Revenu généré';
  static const statAvgTime = 'Temps moyen';
  static const statLastDelivery = 'Dernière livraison';
  static const statLast30d = '30 derniers jours';
  static const placeholderNoValue = '—';
  static const currencyXAF = 'XAF';
  static const minutesUnit = 'min';
  static const arrowSeparator = '→';
}

/// Labels courts par statut — utilisés dans les chips filtre et la liste.
String _statusLabel(DeliveryStatus s) {
  switch (s) {
    case DeliveryStatus.enAttente:
      return 'En attente';
    case DeliveryStatus.assigner:
      return 'Assigné';
    case DeliveryStatus.enTransit:
      return 'En transit';
    case DeliveryStatus.livrer:
      return 'Livré';
    case DeliveryStatus.echec:
      return 'Échec';
  }
}

IconData _statusIcon(DeliveryStatus s) {
  switch (s) {
    case DeliveryStatus.enAttente:
      return Iconsax.clock;
    case DeliveryStatus.assigner:
      return Iconsax.profile_tick;
    case DeliveryStatus.enTransit:
      return Iconsax.truck_fast;
    case DeliveryStatus.livrer:
      return Iconsax.tick_circle;
    case DeliveryStatus.echec:
      return Iconsax.close_circle;
  }
}

Color _statusColor(BuildContext context, DeliveryStatus s) {
  final scheme = Theme.of(context).colorScheme;
  switch (s) {
    case DeliveryStatus.enAttente:
      return scheme.outline;
    case DeliveryStatus.assigner:
      return scheme.tertiary;
    case DeliveryStatus.enTransit:
      return scheme.primary;
    case DeliveryStatus.livrer:
      // "Livré" → couleur succès. ColorScheme Material n'a pas de slot
      // success — on passe par le token semantic Lilia. Si le thème dark
      // admin est introduit plus tard, exposer un `ThemeExtension<LiliaTheme>`
      // pour résoudre selon `Theme.of(context).brightness`.
      // TODO LIL-90+ : success/danger via ThemeExtension quand dark mode activé.
      return LiliaColors.green400;
    case DeliveryStatus.echec:
      return scheme.error;
  }
}

class DelivererDetailScreen extends ConsumerStatefulWidget {
  final String delivererId;

  const DelivererDetailScreen({super.key, required this.delivererId});

  @override
  ConsumerState<DelivererDetailScreen> createState() =>
      _DelivererDetailScreenState();
}

class _DelivererDetailScreenState extends ConsumerState<DelivererDetailScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _maybeLoadMore();
    }
  }

  void _maybeLoadMore() {
    final missionsAsync =
        ref.read(delivererMissionsControllerProvider(widget.delivererId));
    final state = missionsAsync.value;
    if (state == null) return;
    if (!state.hasMore || state.isLoadingMore) return;
    developer.log(
      'loadMore() page=${state.page} totalPages=${state.totalPages}',
      name: 'DelivererDetailScreen',
    );
    ref
        .read(delivererMissionsControllerProvider(widget.delivererId).notifier)
        .loadMore();
  }

  Future<void> _refreshAll() async {
    developer.log('refreshAll() id=${widget.delivererId}',
        name: 'DelivererDetailScreen');
    ref.invalidate(delivererDetailProvider(widget.delivererId));
    await ref
        .read(delivererMissionsControllerProvider(widget.delivererId).notifier)
        .refresh();
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e, st) {
      developer.log('launchPhone failed: $e',
          name: 'DelivererDetailScreen', error: e, stackTrace: st);
    }
  }

  void _copyPhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_Strings.noPhone)),
      );
      return;
    }
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(_Strings.phoneCopied),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _onTrackTap(String orderId) {
    // TODO LIL-88: route effective branchée sur l'écran tracking.
    developer.log('track tap orderId=$orderId', name: 'DelivererDetailScreen');
    try {
      context.push('/deliveries/$orderId/tracking');
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_Strings.trackingComingSoon)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync =
        ref.watch(delivererDetailProvider(widget.delivererId));

    return Scaffold(
      appBar: AppBar(
        title: Text(detailAsync.maybeWhen(
          data: (d) => d.user.nom ?? _Strings.fallbackName,
          orElse: () => _Strings.fallbackName,
        )),
        actions: [
          IconButton(
            tooltip: _Strings.refreshTooltip,
            icon: const Icon(Iconsax.refresh),
            onPressed: _refreshAll,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              final phone = detailAsync.value?.user.phone;
              switch (value) {
                case 'call':
                  if (phone != null && phone.isNotEmpty) {
                    _launchPhone(phone);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(_Strings.cantCallNoPhone)),
                    );
                  }
                  break;
                case 'copy':
                  _copyPhone(phone);
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'call',
                child: ListTile(
                  leading: Icon(Iconsax.call),
                  title: Text(_Strings.callAction),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'copy',
                child: ListTile(
                  leading: Icon(Iconsax.copy),
                  title: Text(_Strings.copyPhoneAction),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => _ErrorView(
          error: e,
          onRetry: () =>
              ref.invalidate(delivererDetailProvider(widget.delivererId)),
        ),
        data: (detail) => _buildBody(detail),
      ),
    );
  }

  Widget _buildBody(DelivererDetail detail) {
    final missionsAsync =
        ref.watch(delivererMissionsControllerProvider(widget.delivererId));

    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _HeaderCard(deliverer: detail.user)),
          SliverToBoxAdapter(child: _StatsGrid(stats: detail.stats)),
          // Note donnée par les clients après livraison. Elle existait en base
          // sans être affichée nulle part : une notation que personne ne
          // consulte n'a aucun effet sur la qualité de service.
          SliverToBoxAdapter(
            child: _RatingCard(delivererId: detail.user.id),
          ),
          if (detail.currentMission != null)
            SliverToBoxAdapter(
              child: _CurrentMissionCard(
                mission: detail.currentMission!,
                onTrack: () => _onTrackTap(detail.currentMission!.orderId),
              ),
            ),
          SliverToBoxAdapter(
            child: _SectionHeader(title: _Strings.sectionHistory),
          ),
          SliverToBoxAdapter(
            child: _FilterChipsRow(
              selected: missionsAsync.value?.statusFilter,
              onChanged: (status) {
                developer.log('setStatusFilter $status',
                    name: 'DelivererDetailScreen');
                ref
                    .read(delivererMissionsControllerProvider(
                            widget.delivererId)
                        .notifier)
                    .setStatusFilter(status);
              },
            ),
          ),
          ..._buildMissionsSlivers(missionsAsync),
        ],
      ),
    );
  }

  List<Widget> _buildMissionsSlivers(
      AsyncValue<DelivererMissionsState> missionsAsync) {
    return [
      missionsAsync.when(
        loading: () => const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
        error: (e, _) => SliverToBoxAdapter(
          child: _ErrorView(
            error: e,
            onRetry: () => ref
                .read(delivererMissionsControllerProvider(widget.delivererId)
                    .notifier)
                .refresh(),
          ),
        ),
        data: (state) {
          if (state.items.isEmpty) {
            final isFiltered = state.statusFilter != null;
            return SliverToBoxAdapter(
              child: _EmptyView(
                message: isFiltered
                    ? _Strings.emptyMissionsFiltered
                    : _Strings.emptyMissions,
              ),
            );
          }
          return SliverList.builder(
            itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= state.items.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return _MissionTile(mission: state.items[index]);
            },
          );
        },
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
    ];
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _HeaderCard extends StatelessWidget {
  final AdminDeliverer deliverer;

  const _HeaderCard({required this.deliverer});

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final second =
        parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dateFormat = DateFormat.yMMMMd('fr_FR');
    final phone = deliverer.phone;
    final email = deliverer.email;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: scheme.primaryContainer,
                  backgroundImage: deliverer.imageUrl != null
                      ? NetworkImage(deliverer.imageUrl!)
                      : null,
                  child: deliverer.imageUrl == null
                      ? Text(
                          _initials(deliverer.nom),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deliverer.nom ?? _Strings.fallbackNameLong,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Iconsax.calendar,
                              size: 14, color: scheme.outline),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${_Strings.registeredSince} ${dateFormat.format(deliverer.createdAt)}',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: scheme.outline),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (email != null && email.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.email_outlined,
                      size: 16, color: scheme.outline),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      email,
                      style: theme.textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (phone != null && phone.isNotEmpty) ...[
              const SizedBox(height: 8),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  final uri = Uri(scheme: 'tel', path: phone);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Iconsax.call,
                          size: 16, color: scheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        phone,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats grid
// ---------------------------------------------------------------------------

class _StatsGrid extends StatelessWidget {
  final DelivererStats stats;

  const _StatsGrid({required this.stats});

  String _formatInt(int v) => NumberFormat.decimalPattern('fr_FR').format(v);

  String _formatRevenue(int v) =>
      '${NumberFormat.decimalPattern('fr_FR').format(v)} ${_Strings.currencyXAF}';

  String _formatRate(double v) =>
      '${NumberFormat('0.0', 'fr_FR').format(v)} %';

  String _formatAvgMinutes(double? v) {
    if (v == null) return _Strings.placeholderNoValue;
    return '${NumberFormat('0', 'fr_FR').format(v)} ${_Strings.minutesUnit}';
  }

  String _formatLastDelivery(DateTime? date) {
    if (date == null) return _Strings.placeholderNoValue;
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays >= 1) {
      return 'il y a ${diff.inDays} j';
    }
    if (diff.inHours >= 1) {
      return 'il y a ${diff.inHours} h';
    }
    if (diff.inMinutes >= 1) {
      return 'il y a ${diff.inMinutes} min';
    }
    return 'à l’instant';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cards = <_StatCardData>[
      _StatCardData(
        icon: Iconsax.truck,
        label: _Strings.statTotalDeliveries,
        value: _formatInt(stats.totalDeliveries),
      ),
      _StatCardData(
        icon: Iconsax.tick_circle,
        label: _Strings.statSuccessRate,
        value: _formatRate(stats.successRate),
      ),
      _StatCardData(
        icon: Iconsax.wallet,
        label: _Strings.statRevenue,
        value: _formatRevenue(stats.totalRevenueXAF),
      ),
      _StatCardData(
        icon: Iconsax.timer_1,
        label: _Strings.statAvgTime,
        value: _formatAvgMinutes(stats.avgDeliveryMinutes),
      ),
      _StatCardData(
        icon: Iconsax.clock,
        label: _Strings.statLastDelivery,
        value: _formatLastDelivery(stats.lastDeliveryAt),
      ),
      _StatCardData(
        icon: Iconsax.chart,
        label: _Strings.statLast30d,
        value: _formatInt(stats.last30dDeliveries),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
            child: Text(
              _Strings.sectionStats,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.6,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: cards.map((c) => _StatCard(data: c)).toList(),
          ),
        ],
      ),
    );
  }
}

class _StatCardData {
  final IconData icon;
  final String label;
  final String value;

  const _StatCardData({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _StatCard extends StatelessWidget {
  final _StatCardData data;

  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(data.icon, color: scheme.primary, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                data.label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.outline),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                data.value,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Current mission card
// ---------------------------------------------------------------------------

class _CurrentMissionCard extends StatelessWidget {
  final DeliveryMissionSummary mission;
  final VoidCallback onTrack;

  const _CurrentMissionCard({
    required this.mission,
    required this.onTrack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final amountFormat = NumberFormat.decimalPattern('fr_FR');
    final statusColor = _statusColor(context, mission.status);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Card(
        elevation: 0,
        color: scheme.primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_statusIcon(mission.status),
                      color: statusColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _Strings.sectionCurrentMission,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.primary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel(mission.status),
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: statusColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      mission.restaurantName,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(_Strings.arrowSeparator,
                        style: theme.textTheme.bodyMedium),
                  ),
                  Expanded(
                    child: Text(
                      mission.clientName,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Iconsax.wallet, size: 16, color: scheme.outline),
                  const SizedBox(width: 6),
                  Text(
                    '${amountFormat.format(mission.totalXAF)} ${_Strings.currencyXAF}',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onTrack,
                  icon: const Icon(Iconsax.map_1),
                  label: const Text(_Strings.trackOnMap),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header + filter chips + tile + helpers
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _FilterChipsRow extends StatelessWidget {
  final DeliveryStatus? selected;
  final ValueChanged<DeliveryStatus?> onChanged;

  const _FilterChipsRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chips = <Widget>[
      _chip(
        label: _Strings.filterAll,
        isSelected: selected == null,
        onTap: () => onChanged(null),
        theme: theme,
      ),
      ...DeliveryStatus.values.map((s) => _chip(
            label: _statusLabel(s),
            isSelected: selected == s,
            onTap: () => onChanged(s),
            theme: theme,
          )),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          for (final chip in chips)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: chip,
            ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.onPrimaryContainer,
    );
  }
}

class _MissionTile extends StatelessWidget {
  final DeliveryMissionSummary mission;

  const _MissionTile({required this.mission});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountFormat = NumberFormat.decimalPattern('fr_FR');
    final dateFormat = DateFormat.yMMMd('fr_FR').add_Hm();
    final color = _statusColor(context, mission.status);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(_statusIcon(mission.status), color: color, size: 20),
      ),
      title: Text(
        '${mission.restaurantName} ${_Strings.arrowSeparator} ${mission.clientName}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        dateFormat.format(mission.createdAt),
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.outline),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${amountFormat.format(mission.totalXAF)} ${_Strings.currencyXAF}',
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            _statusLabel(mission.status),
            style: theme.textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error / empty views
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(_Strings.errorTitle,
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Iconsax.refresh),
              label: const Text(_Strings.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String message;

  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.truck,
              size: 56, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.outline),
          ),
        ],
      ),
    );
  }
}


/// Note moyenne du livreur, avec la distribution des étoiles.
///
/// Volontairement discret quand il n'y a pas encore de note : un livreur qui
/// débute ne doit pas apparaître comme mal noté.
class _RatingCard extends ConsumerWidget {
  const _RatingCard({required this.delivererId});

  final String delivererId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratingAsync = ref.watch(delivererRatingProvider(delivererId));

    return ratingAsync.maybeWhen(
      // Une note indisponible ne doit pas casser la fiche : on masque.
      orElse: () => const SizedBox.shrink(),
      data: (rating) {
        final cs = Theme.of(context).colorScheme;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.star_rounded,
                  color: rating.hasRatings ? Colors.amber : cs.outline,
                  size: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rating.hasRatings
                            ? '${rating.averageRating!.toStringAsFixed(1)} / 5'
                            : 'Pas encore noté',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rating.hasRatings
                            ? '${rating.totalReviews} avis client'
                              '${rating.totalReviews > 1 ? 's' : ''}'
                            : 'La note apparaîtra après la première livraison notée',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (rating.hasRatings)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [5, 4, 3, 2, 1]
                        .map(
                          (star) => Text(
                            '$star★ ${rating.distribution[star] ?? 0}',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

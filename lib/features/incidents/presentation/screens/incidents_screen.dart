import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:lilia_admin/features/incidents/presentation/providers/incidents_provider.dart';
import 'package:lilia_admin/models/incident.dart';

const _pageSize = 20;

/// Écran admin : liste paginée des incidents avec filtres rapides (status +
/// sévérité) et chip "Type" qui ouvre un menu déroulant pour les 11 types.
class IncidentsScreen extends ConsumerStatefulWidget {
  const IncidentsScreen({super.key});

  @override
  ConsumerState<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends ConsumerState<IncidentsScreen> {
  IncidentStatus? _status = IncidentStatus.open;
  IncidentSeverity? _severity;
  IncidentType? _type;
  int _page = 1;

  int get _offset => (_page - 1) * _pageSize;

  void _resetPage() => setState(() => _page = 1);

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(incidentsListProvider(
      status: _status,
      severity: _severity,
      type: _type,
      limit: _pageSize,
      offset: _offset,
    ));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incidents'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: () => ref.invalidate(incidentsListProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _errorView(e),
              data: (result) {
                if (result.incidents.isEmpty) {
                  return _emptyView();
                }
                return Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(incidentsListProvider);
                          await ref.read(incidentsListProvider(
                            status: _status,
                            severity: _severity,
                            type: _type,
                            limit: _pageSize,
                            offset: _offset,
                          ).future);
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          itemCount: result.incidents.length,
                          itemBuilder: (_, i) =>
                              _IncidentCard(incident: result.incidents[i]),
                        ),
                      ),
                    ),
                    _buildPagination(result.total, result.totalPages),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _statusChip(null, 'Tous'),
                for (final s in IncidentStatus.values) _statusChip(s, s.label),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Sévérité + Type
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _severityChip(null, 'Toute sévérité'),
                for (final s in IncidentSeverity.values)
                  _severityChip(s, s.label),
                const SizedBox(width: 12),
                _typeMenu(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(IncidentStatus? value, String label) {
    final selected = _status == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _status = value);
          _resetPage();
        },
      ),
    );
  }

  Widget _severityChip(IncidentSeverity? value, String label) {
    final selected = _severity == value;
    final color = value != null ? _severityColor(value) : Colors.blueGrey;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        selectedColor: color.withValues(alpha: 0.18),
        checkmarkColor: color,
        side: selected ? BorderSide(color: color, width: 1.2) : null,
        onSelected: (_) {
          setState(() => _severity = selected ? null : value);
          _resetPage();
        },
      ),
    );
  }

  Widget _typeMenu() {
    return PopupMenuButton<IncidentType?>(
      tooltip: 'Type',
      onSelected: (v) {
        setState(() => _type = v);
        _resetPage();
      },
      itemBuilder: (_) => [
        const PopupMenuItem<IncidentType?>(
          value: null,
          child: Text('Tous types'),
        ),
        const PopupMenuDivider(),
        for (final t in IncidentType.values)
          PopupMenuItem<IncidentType?>(value: t, child: Text(t.label)),
      ],
      child: Chip(
        avatar: const Icon(Icons.filter_list, size: 18),
        label: Text(_type?.label ?? 'Type'),
      ),
    );
  }

  Widget _buildPagination(int total, int totalPages) {
    if (total <= _pageSize) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$total incident${total > 1 ? 's' : ''} · page $_page/$totalPages'),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _page > 1
                      ? () => setState(() => _page--)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _page < totalPages
                      ? () => setState(() => _page++)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('Aucun incident pour ces filtres',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() {
              _status = null;
              _severity = null;
              _type = null;
              _page = 1;
            }),
            child: const Text('Réinitialiser les filtres'),
          ),
        ],
      ),
    );
  }

  Widget _errorView(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              error.toString().replaceFirst('Exception: ', ''),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(incidentsListProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(incident.severity);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: () => context.pushNamed(
          'incident-detail',
          pathParameters: {'id': incident.id},
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          incident.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          incident.type.label,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statusBadge(incident.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _severityPill(incident.severity, color),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('d MMM, HH:mm', 'fr_FR').format(incident.createdAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
              if (incident.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  incident.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(IncidentStatus status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _severityPill(IncidentSeverity severity, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        severity.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

Color _severityColor(IncidentSeverity severity) {
  switch (severity) {
    case IncidentSeverity.critical:
      return Colors.red.shade700;
    case IncidentSeverity.high:
      return Colors.orange.shade800;
    case IncidentSeverity.medium:
      return Colors.amber.shade700;
    case IncidentSeverity.low:
      return Colors.blueGrey;
  }
}

Color _statusColor(IncidentStatus status) {
  switch (status) {
    case IncidentStatus.open:
      return Colors.red.shade700;
    case IncidentStatus.inProgress:
      return Colors.blue.shade700;
    case IncidentStatus.resolved:
      return Colors.green.shade700;
    case IncidentStatus.closed:
      return Colors.grey;
  }
}

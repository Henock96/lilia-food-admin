import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lilia_admin/features/incidents/presentation/providers/incidents_provider.dart';
import 'package:lilia_admin/models/incident.dart';

/// Détail d'un incident — affiche tout le contexte + actions de résolution
/// (changer le statut, ajouter une note de résolution).
class IncidentDetailScreen extends ConsumerWidget {
  const IncidentDetailScreen({super.key, required this.incidentId});

  final String incidentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(incidentDetailProvider(incidentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident'),
        centerTitle: true,
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _errorView(context, ref, e),
        data: (incident) => _IncidentDetailBody(incident: incident),
      ),
    );
  }

  Widget _errorView(BuildContext context, WidgetRef ref, Object error) {
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
              onPressed: () =>
                  ref.invalidate(incidentDetailProvider(incidentId)),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncidentDetailBody extends ConsumerStatefulWidget {
  const _IncidentDetailBody({required this.incident});

  final Incident incident;

  @override
  ConsumerState<_IncidentDetailBody> createState() =>
      _IncidentDetailBodyState();
}

class _IncidentDetailBodyState extends ConsumerState<_IncidentDetailBody> {
  late final TextEditingController _resolutionController;
  bool _updating = false;

  Incident get incident => widget.incident;

  @override
  void initState() {
    super.initState();
    _resolutionController =
        TextEditingController(text: incident.resolution ?? '');
  }

  @override
  void dispose() {
    _resolutionController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(IncidentStatus target) async {
    final resolution = _resolutionController.text.trim();
    final needsResolution = target.isTerminal;
    if (needsResolution && resolution.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Ajoutez une note de résolution avant de clôturer l\'incident.'),
        ),
      );
      return;
    }

    setState(() => _updating = true);
    try {
      await ref.read(incidentsRepositoryProvider).updateIncident(
            incident.id,
            status: target,
            resolution: needsResolution ? resolution : null,
          );
      if (!mounted) return;
      ref.invalidate(incidentDetailProvider(incident.id));
      ref.invalidate(incidentsListProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Statut mis à jour : ${target.label}'),
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
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final severityColor = _severityColor(incident.severity);
    final dateFmt = DateFormat('d MMM yyyy, HH:mm', 'fr_FR');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header : titre + badges
        Row(
          children: [
            Container(
              width: 6,
              height: 56,
              decoration: BoxDecoration(
                color: severityColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    incident.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    incident.type.label,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _pill(incident.severity.label, severityColor),
            const SizedBox(width: 8),
            _pill(incident.status.label, _statusColor(incident.status)),
          ],
        ),

        const SizedBox(height: 20),
        _section('Description'),
        const SizedBox(height: 6),
        Text(incident.description, style: const TextStyle(fontSize: 14)),

        const SizedBox(height: 20),
        _section('Références'),
        const SizedBox(height: 6),
        _kv('ID', incident.id, copyable: true),
        if (incident.orderId != null)
          _kv('Commande', incident.orderId!, copyable: true),
        if (incident.restaurantId != null)
          _kv('Restaurant', incident.restaurantId!, copyable: true),
        if (incident.riderId != null)
          _kv('Livreur', incident.riderId!, copyable: true),
        if (incident.reportedBy != null)
          _kv('Reporté par', incident.reportedBy!, copyable: true),
        if (incident.resolvedBy != null)
          _kv('Résolu par', incident.resolvedBy!, copyable: true),

        const SizedBox(height: 20),
        _section('Chronologie'),
        const SizedBox(height: 6),
        _kv('Créé le', dateFmt.format(incident.createdAt)),
        _kv('Mis à jour', dateFmt.format(incident.updatedAt)),
        if (incident.resolvedAt != null)
          _kv('Résolu le', dateFmt.format(incident.resolvedAt!)),

        if (incident.metadata != null && incident.metadata!.isNotEmpty) ...[
          const SizedBox(height: 20),
          _section('Contexte'),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              incident.metadata!.entries
                  .map((e) => '${e.key}: ${e.value}')
                  .join('\n'),
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),
        _section('Résolution'),
        const SizedBox(height: 6),
        TextField(
          controller: _resolutionController,
          enabled: !incident.status.isTerminal && !_updating,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: incident.status.isTerminal
                ? 'Incident clôturé'
                : 'Décrire ce qui a été fait pour résoudre…',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: incident.status.isTerminal
                ? Colors.grey.shade100
                : Colors.white,
          ),
        ),

        const SizedBox(height: 20),
        _buildActions(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildActions() {
    if (incident.status == IncidentStatus.closed) {
      return _infoBanner(
        Icons.lock_outlined,
        'Incident fermé — plus aucune action possible.',
        Colors.grey,
      );
    }
    if (incident.status == IncidentStatus.resolved) {
      return Column(
        children: [
          _infoBanner(
            Icons.check_circle_outline,
            'Incident résolu. Vous pouvez le clôturer définitivement.',
            Colors.green,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _updating
                  ? null
                  : () => _updateStatus(IncidentStatus.closed),
              icon: const Icon(Icons.lock_outlined),
              label: const Text('Fermer définitivement'),
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        if (incident.status == IncidentStatus.open)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _updating
                  ? null
                  : () => _updateStatus(IncidentStatus.inProgress),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Prendre en charge'),
            ),
          ),
        if (incident.status == IncidentStatus.open) const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _updating
                ? null
                : () => _updateStatus(IncidentStatus.resolved),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.check),
            label: const Text('Marquer résolu'),
          ),
        ),
      ],
    );
  }

  Widget _section(String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade600,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _kv(String key, String value, {bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              key,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontFamily: copyable ? 'monospace' : null,
              ),
            ),
          ),
          if (copyable)
            IconButton(
              icon: const Icon(Icons.copy, size: 14),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$key copié'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _infoBanner(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 13),
            ),
          ),
        ],
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

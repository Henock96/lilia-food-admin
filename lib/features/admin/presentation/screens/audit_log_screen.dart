import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lilia_admin/features/admin/data/audit_log_service.dart';

/// Journal des actions d'administration.
///
/// Lecture seule, et c'est volontaire : un journal d'audit qu'on peut modifier
/// depuis l'interface qu'il surveille ne vaut rien. Le backend n'expose
/// d'ailleurs aucune route d'écriture ou de suppression.
class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  String? _action;

  static const _filters = <String, String>{
    'USER_ROLE_CHANGED': 'Rôles',
    'USER_BANNED': 'Bannissements',
    'VENDOR_SUSPENDED': 'Suspensions',
    'PAYMENT_CONFIRMED': 'Paiements',
  };

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(auditLogListProvider(_action));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Journal d\'audit')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Tout'),
                  selected: _action == null,
                  onSelected: (_) => setState(() => _action = null),
                ),
                const SizedBox(width: 8),
                ..._filters.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(e.value),
                      selected: _action == e.key,
                      onSelected: (_) => setState(() => _action = e.key),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: logsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('$error', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            ref.invalidate(auditLogListProvider(_action)),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return Center(
                    child: Text(
                      'Aucune action enregistrée',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(auditLogListProvider(_action)),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) => _EntryTile(entry: entries[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});

  final AuditLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final actor = entry.actorNom ?? entry.actorEmail ?? 'Administrateur';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      leading: CircleAvatar(
        backgroundColor: entry.isSensitive
            ? cs.errorContainer
            : cs.surfaceContainerHighest,
        child: Icon(
          entry.isSensitive ? Icons.warning_amber : Icons.history,
          size: 20,
          color: entry.isSensitive ? cs.error : cs.onSurfaceVariant,
        ),
      ),
      title: Text(
        entry.label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            'Par $actor · ${entry.targetType} ${_short(entry.targetId)}',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          if (entry.reason != null && entry.reason!.isNotEmpty)
            Text(
              entry.reason!,
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          if (entry.metadata != null && entry.metadata!.isNotEmpty)
            Text(
              entry.metadata!.entries
                  .map((e) => '${e.key}: ${e.value}')
                  .join(' · '),
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
        ],
      ),
      trailing: Text(
        DateFormat('dd/MM HH:mm').format(entry.createdAt.toLocal()),
        style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
      ),
      isThreeLine: true,
    );
  }

  /// Les identifiants cuid sont illisibles en entier ; les 6 derniers
  /// caractères suffisent à recouper avec le reste de l'interface.
  String _short(String id) =>
      id.length >= 6 ? '…${id.substring(id.length - 6)}' : id;
}

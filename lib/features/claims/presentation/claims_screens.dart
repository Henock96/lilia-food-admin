import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:lilia_admin/features/auth/user_sync_provider.dart';
import 'package:lilia_admin/features/claims/data/claims_repository.dart';
import 'package:lilia_admin/features/claims/presentation/claims_providers.dart';
import 'package:lilia_admin/models/role.dart';

final _time = DateFormat('d MMM, HH:mm', 'fr_FR');
final _xaf = NumberFormat.decimalPattern('fr_FR');

/// Réclamations (F3-06) — le vendeur voit celles de sa boutique, le support
/// toutes. La portée vient du serveur.
class ClaimsScreen extends ConsumerStatefulWidget {
  const ClaimsScreen({super.key});

  @override
  ConsumerState<ClaimsScreen> createState() => _ClaimsScreenState();
}

class _ClaimsScreenState extends ConsumerState<ClaimsScreen> {
  bool _openOnly = true;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(claimsListProvider(openOnly: _openOnly));
    return Scaffold(
      appBar: AppBar(title: const Text('Réclamations')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('À traiter')),
                ButtonSegment(value: false, label: Text('Toutes')),
              ],
              selected: {_openOnly},
              onSelectionChanged: (s) => setState(() => _openOnly = s.first),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.refresh(claimsListProvider(openOnly: _openOnly).future),
              child: switch (state) {
                // L'erreur d'abord : la relance automatique de Riverpod
                // laisserait sinon la roue tourner indéfiniment.
                AsyncValue(hasError: true, hasValue: false, :final error?) =>
                  ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('$error', textAlign: TextAlign.center),
                      ),
                    ],
                  ),
                AsyncValue(:final value?) when value.isEmpty => ListView(
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'Aucune réclamation.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                AsyncValue(:final value?) => ListView.separated(
                  itemCount: value.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final c = value[i];
                    return ListTile(
                      title: Text(
                        '#${c.orderRef} — ${claimReasonLabels[c.reason] ?? c.reason}',
                      ),
                      subtitle: Text(
                        '${claimStateLabel(c.status, c.outcome)} · '
                        '${_time.format(c.createdAt)}\n${c.summary}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.pushNamed(
                        'claim-detail',
                        pathParameters: {'id': c.id},
                      ),
                    );
                  },
                ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ClaimDetailScreen extends ConsumerStatefulWidget {
  const ClaimDetailScreen({super.key, required this.claimId});

  final String claimId;

  @override
  ConsumerState<ClaimDetailScreen> createState() => _ClaimDetailScreenState();
}

class _ClaimDetailScreenState extends ConsumerState<ClaimDetailScreen> {
  final _reply = TextEditingController();
  bool _staffOnly = false;
  bool _sending = false;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _reply.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(claimsRepositoryProvider)
          .reply(widget.claimId, text, staffOnly: _staffOnly);
      _reply.clear();
      ref.invalidate(claimThreadProvider(widget.claimId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(currentUserProfileProvider)?.role == Role.admin;
    final state = ref.watch(claimThreadProvider(widget.claimId));
    return Scaffold(
      appBar: AppBar(title: const Text('Réclamation')),
      body: switch (state) {
        AsyncValue(hasError: true, hasValue: false, :final error?) => Center(
          child: Text('$error'),
        ),
        AsyncValue(:final value?) => _body(value, isAdmin),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Widget _body(ClaimThread claim, bool isAdmin) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '#${claim.orderRef} — ${claimReasonLabels[claim.reason] ?? claim.reason}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(claim.summary),
              Text(claimStateLabel(claim.status, claim.outcome)),
              if (claim.resolution != null) Text('Issue : ${claim.resolution}'),
              if (claim.vendorImpactXaf > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${_xaf.format(claim.vendorImpactXaf)} FCFA seront déduits '
                    'du prochain reversement.',
                    style: const TextStyle(color: Colors.orange),
                  ),
                ),
              if (isAdmin)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Rembourser, offrir un avoir ou refuser : depuis l’admin web '
                    '(Réclamations), où le montant est calculé par le serveur.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              const Divider(height: 24),
              for (final m in claim.messages)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: m.staffOnly
                        ? Colors.amber.shade50
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${m.authorLabel} · ${_time.format(m.createdAt)}'
                        '${m.staffOnly ? ' · non visible du client' : ''}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      Text(m.body),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (!claim.isClosed)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isAdmin)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: const Text('Support et vendeur seulement'),
                      value: _staffOnly,
                      onChanged: (v) => setState(() => _staffOnly = v),
                    )
                  else
                    const Text(
                      'Votre réponse n’est visible que du service client.',
                      style: TextStyle(fontSize: 12),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _reply,
                          maxLength: 2000,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Répondre…',
                            counterText: '',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Envoyer',
                        icon: const Icon(Icons.send),
                        onPressed: _sending ? null : _send,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

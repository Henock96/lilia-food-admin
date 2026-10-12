import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lilia_admin/core/network/api_exception.dart';
import 'package:lilia_admin/features/reservations/data/reservation_settings_repository.dart';
import 'package:lilia_admin/features/reservations/presentation/arrival_times.dart';
import 'package:lilia_admin/features/reservations/presentation/reservation_settings_providers.dart';

/// « Réservations sur place » (Premium Lot 3) — le restaurant prépare son
/// service : activation, jours et heures, tables, places, règles.
///
/// Le serveur décide de tout : droit Premium, bornes, erreurs, alertes,
/// créneaux. L'écran affiche ses verdicts ; « Vérifier » lui soumet le
/// brouillon sans rien écrire (possible sans Premium), « Enregistrer » exige
/// le Premium. Aucun client ne peut encore réserver : c'est dit en tête.
///
/// Seule exception, d'affichage : sous chaque plage, les heures d'arrivée
/// qu'elle propose sont calculées localement (`arrival_times.dart`) pour
/// suivre la saisie sans aller-retour. Elles ne valident rien et un test les
/// compare aux créneaux réellement rendus par le serveur.
class ReservationSettingsScreen extends ConsumerWidget {
  const ReservationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myReservationSettingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Réservations sur place')),
      // Riverpod 3 garde l'erreur pendant la relance automatique : on lit
      // `hasError`, jamais le type de l'état (sinon spinner sans fin).
      body: async.hasValue
          ? _Editor(
              // Nouvelle version enregistrée = brouillon repris du serveur.
              key: ValueKey(async.requireValue.config?.version ?? 0),
              state: async.requireValue,
            )
          : async.hasError
          ? ListView(
              children: [
                const SizedBox(height: 120),
                Text(
                  key: const Key('res-load-error'),
                  async.error is ApiException
                      ? reservationErrorMessage(async.error! as ApiException)
                      : 'Impossible de charger la configuration. Réessayez.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Center(
                  child: FilledButton(
                    onPressed: () =>
                        ref.invalidate(myReservationSettingsProvider),
                    child: const Text('Réessayer'),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

class _Editor extends ConsumerStatefulWidget {
  const _Editor({super.key, required this.state});

  final ReservationState state;

  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  /// Dernier état serveur connu : celui du chargement, puis celui que rend un
  /// enregistrement réussi — sans attendre le rechargement, qui peut échouer
  /// (sinon un second « Enregistrer » partirait d'une version et d'ids périmés).
  late ReservationState _current = widget.state;
  late ReservationDraft _draft = ReservationDraft.fromState(widget.state);
  late List<ReservationIssue> _issues = widget.state.issues;
  late ReservationPreview? _preview = widget.state.preview;
  bool _busy = false;
  String? _error;
  bool _conflict = false;

  /// L'aperçu (capacité, créneaux par jour) date du dernier « Vérifier » ou
  /// enregistrement : toute modification ultérieure le rend périmé, et c'est
  /// dit sur la carte (revue Flutter du 12/10).
  bool _previewStale = false;

  ReservationState get _state => _current;

  @override
  void didUpdateWidget(covariant _Editor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Même version relue (ex. Premium expiré entre-temps) : droits et bandeaux
    // suivent le serveur, le brouillon en cours est conservé.
    if (!identical(widget.state, oldWidget.state)) _current = widget.state;
  }

  ReservationLimits get _limits => _state.limits;

  void _edit(VoidCallback change) => setState(() {
    change();
    _previewStale = true;
  });

  /// Les constats du serveur désignent les champs par position
  /// (`spaces[3].label`). Après un retrait, les éléments suivants glissent :
  /// un constat resterait affiché sous le mauvais élément. On les oublie
  /// jusqu'à la prochaine vérification (revue Flutter du 12/10).
  void _forgetPositionalIssues() {
    _issues = _issues
        .where(
          (i) =>
              !(i.field?.startsWith('spaces[') ?? false) &&
              !(i.field?.startsWith('windows[') ?? false),
        )
        .toList(growable: false);
  }

  static const _unexpected = 'Une erreur est survenue. Réessayez.';

  /// Alertes serveur que le bandeau d'état exprime déjà.
  static const _bannerCodes = {'PLATFORM_DISABLED', 'NOT_ENTITLED'};

  List<ReservationIssue> _issuesAt(String field) => _issues
      .where(
        (i) => i.field == field || (i.field?.startsWith('$field.') ?? false),
      )
      .toList(growable: false);

  Future<void> _check() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final check = await ref
          .read(reservationSettingsRepositoryProvider)
          .preview(_draft);
      if (!mounted) return;
      setState(() {
        _issues = check.issues;
        _preview = check.preview;
        _previewStale = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = reservationErrorMessage(e));
    } catch (_) {
      // Réponse illisible : jamais d'échec silencieux.
      if (mounted) setState(() => _error = _unexpected);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
      _conflict = false;
    });
    final repo = ref.read(reservationSettingsRepositoryProvider);
    try {
      final saved = await repo.save(_draft);
      if (!mounted) return;
      // L'éditeur repart de l'état que rend le PUT (version et ids des
      // ressources créées), même si le rechargement ci-dessous échoue.
      setState(() {
        _current = saved;
        _draft = ReservationDraft.fromState(saved);
        _issues = saved.issues;
        _preview = saved.preview;
        _previewStale = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuration des réservations enregistrée.'),
        ),
      );
      ref.invalidate(myReservationSettingsProvider);
    } on ApiException catch (e) {
      if (!mounted) return;
      switch (e.code) {
        case ReservationErrorCodes.invalid:
          // Le refus porte les constats ; l'aperçu les rend champ par champ.
          setState(
            () => _error =
                'La configuration contient des erreurs : voir les champs signalés.',
          );
          try {
            final check = await repo.preview(_draft);
            if (mounted) {
              setState(() {
                _issues = check.issues;
                _preview = check.preview;
                _previewStale = false;
              });
            }
          } catch (_) {
            // Toute erreur (réseau, 429, réponse illisible) : aucun champ n'a
            // pu être signalé, ne pas le prétendre — et ne rien laisser
            // échapper de ce bloc `catch` englobant.
            if (mounted) {
              setState(
                () => _error =
                    'La configuration contient des erreurs, mais leur détail '
                    'n’a pas pu être chargé. Touchez « Vérifier » pour les afficher.',
              );
            }
          }
        case ReservationErrorCodes.conflict:
          setState(() {
            _error = e.message;
            _conflict = true;
          });
        case ReservationErrorCodes.premiumRequired:
          // Premium expiré ou révoqué pendant l'édition : le serveur relu met
          // à jour le bandeau et désactive « Enregistrer » ; brouillon gardé.
          setState(() => _error = e.message);
          ref.invalidate(myReservationSettingsProvider);
        default:
          setState(() => _error = reservationErrorMessage(e));
      }
    } catch (_) {
      if (mounted) setState(() => _error = _unexpected);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_state.eligible) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _Notice(
            key: Key('res-not-eligible'),
            text: 'La réservation sur place est réservée aux restaurants.',
          ),
        ],
      );
    }

    final globalIssues = _issues
        // Les constats d'un champ s'affichent sous ce champ ; ici, le reste.
        .where(
          (i) => i.field == null || i.field == 'spaces' || i.field == 'windows',
        )
        // Déjà dits par le bandeau d'état (`_StatusBanner`) : pas deux fois.
        .where((i) => !_bannerCodes.contains(i.code))
        .toList(growable: false);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _StatusBanner(state: _state),
              const SizedBox(height: 12),
              SwitchListTile(
                key: const Key('res-enabled'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Accepter les réservations sur place'),
                subtitle: const Text(
                  'Désactivée, la configuration reste un brouillon : elle peut '
                  'être incomplète.',
                ),
                value: _draft.enabled,
                onChanged: (v) => _edit(() => _draft.enabled = v),
              ),
              if (globalIssues.isNotEmpty) ...[
                const SizedBox(height: 8),
                _IssueList(key: const Key('res-issues'), issues: globalIssues),
              ],
              _Section(title: 'Règles des créneaux', children: _rules()),
              _Section(
                title: 'Tables',
                children: _spaces(ReservationSpaceKind.table),
              ),
              _Section(
                title: 'Places individuelles',
                subtitle:
                    'Un comptoir ou une terrasse : chaque client réserve une ou '
                    'plusieurs places, sans prendre tout l’espace.',
                children: _spaces(ReservationSpaceKind.seats),
              ),
              if (_state.config?.archivedSpaces.isNotEmpty ?? false)
                _Section(
                  title: 'Archivées',
                  children: [
                    for (final s in _state.config!.archivedSpaces)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.inventory_2_outlined),
                        title: Text(s.label),
                        subtitle: const Text('Conservée, non proposée'),
                      ),
                  ],
                ),
              _Section(
                key: const Key('res-arrivals-section'),
                title: 'Heures d’arrivée des clients',
                subtitle:
                    'Indiquez quand vos clients peuvent arriver, pas vos '
                    'heures d’ouverture. Une arrivée toutes les '
                    '${_draft.slotStepMin} min ; chaque table reste ensuite '
                    'occupée ${_minutes(_draft.slotDurationMin)}. '
                    'Au plus ${_limits.maxWindowsPerDay} séries par jour, '
                    'sans passer minuit.',
                children: [for (final day in reservationWeekDays) _dayRow(day)],
              ),
              if (_preview != null)
                _PreviewCard(preview: _preview!, stale: _previewStale),
            ],
          ),
        ),
        _BottomBar(
          busy: _busy,
          error: _error,
          conflict: _conflict,
          canSave: _state.canEdit,
          onCheck: _check,
          onSave: _save,
          onReload: () => ref.invalidate(myReservationSettingsProvider),
        ),
      ],
    );
  }

  List<Widget> _rules() {
    final l = _limits;
    return [
      _Stepper(
        key: const Key('res-duration'),
        label: 'Durée d’occupation d’une table',
        value: _draft.slotDurationMin,
        limit: l.slotDurationMin,
        step: 15,
        format: _minutes,
        issues: _issuesAt('slotDurationMin'),
        onChanged: (v) => _edit(() => _draft.slotDurationMin = v),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Une arrivée toutes les'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final step in l.slotStepAllowed)
                  ChoiceChip(
                    key: Key('res-step-$step'),
                    label: Text('$step min'),
                    selected: _draft.slotStepMin == step,
                    onSelected: (_) => _edit(() => _draft.slotStepMin = step),
                  ),
              ],
            ),
            _FieldIssues(issues: _issuesAt('slotStepMin')),
          ],
        ),
      ),
      _Stepper(
        key: const Key('res-buffer'),
        label: 'Marge entre deux réservations d’une table',
        value: _draft.bufferMin,
        limit: l.bufferMin,
        step: 5,
        format: _minutes,
        issues: _issuesAt('bufferMin'),
        onChanged: (v) => _edit(() => _draft.bufferMin = v),
      ),
      _Stepper(
        key: const Key('res-lead'),
        label: 'Réserver au moins … avant l’arrivée',
        value: _draft.minLeadMin,
        limit: l.minLeadMin,
        step: 30,
        format: _minutes,
        issues: _issuesAt('minLeadMin'),
        onChanged: (v) => _edit(() => _draft.minLeadMin = v),
      ),
      _Stepper(
        key: const Key('res-horizon'),
        label: 'Réserver au plus … à l’avance',
        value: _draft.maxAdvanceDays,
        limit: l.maxAdvanceDays,
        step: 1,
        format: (v) => v > 1 ? '$v jours' : '$v jour',
        issues: _issuesAt('maxAdvanceDays'),
        onChanged: (v) => _edit(() => _draft.maxAdvanceDays = v),
      ),
      _Stepper(
        key: const Key('res-party'),
        label: 'Groupe le plus grand accepté',
        value: _draft.maxPartySize,
        limit: l.maxPartySize,
        step: 1,
        format: (v) => v > 1 ? '$v personnes' : '$v personne',
        issues: _issuesAt('maxPartySize'),
        onChanged: (v) => _edit(() => _draft.maxPartySize = v),
      ),
    ];
  }

  List<Widget> _spaces(ReservationSpaceKind kind) {
    final rows = <Widget>[];
    for (var i = 0; i < _draft.spaces.length; i++) {
      final s = _draft.spaces[i];
      if (s.kind != kind) continue;
      rows.add(
        _SpaceRow(
          key: ObjectKey(s),
          index: i,
          space: s,
          limits: _limits,
          issues: _issuesAt('spaces[$i]'),
          onChanged: () => setState(() {}),
          // Une ressource enregistrée s'archive (jamais supprimée) ; une
          // ressource pas encore enregistrée se retire simplement.
          onRemove: () => _edit(() {
            if (s.isNew) {
              _draft.spaces.removeAt(i);
              _forgetPositionalIssues();
            } else {
              s.archived = !s.archived;
            }
          }),
        ),
      );
    }
    final isTable = kind == ReservationSpaceKind.table;
    rows.add(
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          key: Key(isTable ? 'res-add-table' : 'res-add-seats'),
          onPressed: () => _edit(
            () => _draft.spaces.add(
              DraftSpace(
                kind: kind,
                label: _freeLabel(isTable ? 'Table' : 'Comptoir', isTable),
              ),
            ),
          ),
          icon: const Icon(Icons.add),
          label: Text(
            isTable ? 'Ajouter une table' : 'Ajouter un espace de places',
          ),
        ),
      ),
    );
    return rows;
  }

  /// Nom proposé pour une nouvelle ressource, libre parmi les ressources
  /// actives du brouillon (sinon le serveur répondrait `DUPLICATE_LABEL` :
  /// deux « Comptoir », ou « Table 3 » quand « Table 1 » et « Table 3 »
  /// existent). Comparaison en minuscules, espaces réduits — comme la clé
  /// serveur, qui reste seule juge.
  String _freeLabel(String base, bool numberFirst) {
    String key(String s) =>
        s.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
    final taken = {
      for (final s in _draft.spaces)
        if (!s.archived) key(s.label),
    };
    // « Table 1, Table 2… » ; « Comptoir, Comptoir 2, Comptoir 3… ».
    if (!numberFirst && !taken.contains(key(base))) return base;
    for (var n = numberFirst ? 1 : 2; ; n++) {
      final candidate = '$base $n';
      if (!taken.contains(key(candidate))) return candidate;
    }
  }

  Widget _dayRow(String day) {
    final entries = <MapEntry<int, ReservationWindow>>[
      for (var i = 0; i < _draft.windows.length; i++)
        if (_draft.windows[i].dayOfWeek == day) MapEntry(i, _draft.windows[i]),
    ];
    final opening = _preview?.days
        .where((d) => d.dayOfWeek == day)
        .firstOrNull
        ?.opening;
    final small = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reservationDayLabel(day),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          // Les horaires d'ouverture ne sont connus qu'après un aperçu ; ils
          // sont nommés comme tels pour ne pas se confondre avec les arrivées.
          if (_preview != null)
            Text(
              key: Key('res-opening-$day'),
              opening == null
                  ? 'Restaurant fermé ce jour-là'
                  : 'Restaurant ouvert $opening',
              style: small,
            ),
          if (entries.isEmpty) Text('Aucune arrivée ce jour-là.', style: small),
          for (final e in entries) _windowTile(e.key, e.value),
          if (entries.length < _limits.maxWindowsPerDay)
            TextButton.icon(
              key: Key('res-add-window-$day'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter des heures d’arrivée'),
              onPressed: () => _edit(
                () => _draft.windows.add(
                  ReservationWindow(
                    dayOfWeek: day,
                    startTime: entries.isEmpty ? '12:00' : '19:00',
                    endTime: entries.isEmpty ? '14:00' : '21:00',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Une série d'arrivées : ses bornes en clair, puis les heures qu'elle
  /// propose réellement avec le pas courant (affichage seul, la validation
  /// reste celle du serveur).
  Widget _windowTile(int index, ReservationWindow w) {
    final theme = Theme.of(context);
    final step = _draft.slotStepMin;
    final times = arrivalTimes(w.startTime, w.endTime, step);
    final unreached = times.isNotEmpty && times.last != w.endTime;
    final issues = _issuesAt('windows[$index]');
    return Card(
      key: Key('res-window-$index'),
      margin: const EdgeInsets.only(top: 6),
      child: InkWell(
        onTap: () => _editWindow(index),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 0, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      key: Key('res-window-range-$index'),
                      'Première arrivée ${w.startTime} · '
                      'Dernière arrivée ${w.endTime}',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    // Plage invalide : le constat du serveur, s'il existe, dit
                    // déjà quoi corriger — ne pas le répéter.
                    if (times.isNotEmpty || issues.isEmpty)
                      Text(
                        key: Key('res-window-arrivals-$index'),
                        times.isEmpty
                            ? 'Heures à corriger : la dernière arrivée doit '
                                  'venir après la première.'
                            : 'Arrivées proposées : ${arrivalSummary(times)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    if (unreached)
                      Text(
                        key: Key('res-window-unreached-$index'),
                        '${w.endTime} n’est pas proposée : une arrivée toutes '
                        'les $step min, la dernière à ${times.last}.',
                        style: theme.textTheme.bodySmall,
                      ),
                    _FieldIssues(issues: issues),
                  ],
                ),
              ),
              IconButton(
                key: Key('res-window-remove-$index'),
                tooltip: 'Retirer ces heures d’arrivée',
                icon: const Icon(Icons.close),
                onPressed: () => _edit(() {
                  _draft.windows.removeAt(index);
                  _forgetPositionalIssues();
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editWindow(int index) async {
    final w = _draft.windows[index];
    final start = await _pickTime(w.startTime, 'Première arrivée possible');
    if (start == null || !mounted) return;
    final end = await _pickTime(
      w.endTime,
      'Dernière arrivée possible (pas la fermeture)',
    );
    if (end == null || !mounted) return;
    _edit(
      () => _draft.windows[index] = ReservationWindow(
        dayOfWeek: w.dayOfWeek,
        startTime: start,
        endTime: end,
      ),
    );
  }

  Future<String?> _pickTime(String initial, String help) async {
    final parts = initial.split(':');
    final picked = await showTimePicker(
      context: context,
      helpText: help,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts.first) ?? 12,
        minute: int.tryParse(parts.last) ?? 0,
      ),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return null;
    return '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}';
  }
}

String _minutes(int v) {
  if (v < 60) return '$v min';
  final h = v ~/ 60;
  final m = v % 60;
  return m == 0 ? '$h h' : '$h h $m';
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.state});

  final ReservationState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!state.entitled)
          _Notice(
            key: const Key('res-premium-required'),
            icon: Icons.workspace_premium_outlined,
            text: state.configured
                ? 'Votre abonnement Premium n’est pas actif : votre configuration '
                      'est conservée, mais elle ne peut plus être modifiée et elle '
                      'n’est pas en service.'
                : 'Réservé aux restaurants Premium. Vous pouvez préparer et '
                      'vérifier votre configuration ; l’enregistrer demande un '
                      'abonnement Premium actif.',
          ),
        if (!state.platformEnabled)
          const _Notice(
            key: Key('res-platform-off'),
            icon: Icons.schedule_outlined,
            text:
                'La réservation sur place n’est pas encore ouverte aux clients '
                'sur Lilia Food. Vous pouvez préparer votre service dès maintenant.',
          ),
        if (state.effective)
          const _Notice(
            key: Key('res-effective'),
            icon: Icons.check_circle_outline,
            text: 'Votre configuration est active.',
          ),
        // « Effective » ne promet aucune réservation : le parcours client
        // n'existe pas encore (03-approval §4).
        const _Notice(
          key: Key('res-no-client-yet'),
          icon: Icons.info_outline,
          text:
              'Les clients ne peuvent pas encore réserver depuis l’application. '
              'Cette page prépare votre service.',
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 4),
          ...children,
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    super.key,
    required this.label,
    required this.value,
    required this.limit,
    required this.step,
    required this.format,
    required this.issues,
    required this.onChanged,
  });

  final String label;
  final int value;
  final NumberLimit limit;
  final int step;
  final String Function(int) format;
  final List<ReservationIssue> issues;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            IconButton(
              tooltip: 'Moins',
              onPressed: value > limit.min
                  ? () => onChanged(limit.clamp(value - step))
                  : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 72),
              child: Text(
                format(value),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              tooltip: 'Plus',
              onPressed: value < limit.max
                  ? () => onChanged(limit.clamp(value + step))
                  : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        _FieldIssues(issues: issues),
      ],
    );
  }
}

class _SpaceRow extends StatelessWidget {
  const _SpaceRow({
    super.key,
    required this.index,
    required this.space,
    required this.limits,
    required this.issues,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final DraftSpace space;
  final ReservationLimits limits;
  final List<ReservationIssue> issues;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isTable = space.kind == ReservationSpaceKind.table;
    final archived = space.archived;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: Key('res-space-label-$index'),
                    initialValue: space.label,
                    enabled: !archived,
                    maxLength: limits.labelMaxLength,
                    decoration: InputDecoration(
                      labelText: isTable
                          ? 'Nom de la table'
                          : 'Nom de l’espace',
                      counterText: '',
                    ),
                    onChanged: (v) {
                      space.label = v;
                      onChanged();
                    },
                  ),
                ),
                IconButton(
                  key: Key('res-space-remove-$index'),
                  tooltip: space.isNew
                      ? 'Retirer'
                      : archived
                      ? 'Ne plus archiver'
                      : 'Archiver',
                  onPressed: onRemove,
                  icon: Icon(
                    space.isNew
                        ? Icons.close
                        : archived
                        ? Icons.unarchive_outlined
                        : Icons.archive_outlined,
                  ),
                ),
              ],
            ),
            if (archived)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Sera archivée à l’enregistrement : conservée, plus proposée.',
                ),
              )
            else if (isTable) ...[
              _MiniStepper(
                label: 'Au moins',
                value: space.minGuests,
                min: 1,
                max: limits.tableGuestsMax,
                suffix: 'pers.',
                onChanged: (v) {
                  space.minGuests = v;
                  onChanged();
                },
              ),
              _MiniStepper(
                label: 'Au plus',
                value: space.maxGuests,
                min: 1,
                max: limits.tableGuestsMax,
                suffix: 'pers.',
                onChanged: (v) {
                  space.maxGuests = v;
                  onChanged();
                },
              ),
            ] else ...[
              _MiniStepper(
                label: 'Places',
                value: space.seatCount,
                min: 1,
                max: limits.seatCountMax,
                suffix: '',
                onChanged: (v) {
                  space.seatCount = v;
                  onChanged();
                },
              ),
              _MiniStepper(
                label: 'Au plus par réservation',
                value: space.maxSeatsPerBooking,
                min: 1,
                max: limits.maxSeatsPerBookingMax,
                suffix: '',
                onChanged: (v) {
                  space.maxSeatsPerBooking = v;
                  onChanged();
                },
              ),
            ],
            _FieldIssues(issues: issues),
          ],
        ),
      ),
    );
  }
}

class _MiniStepper extends StatelessWidget {
  const _MiniStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.suffix,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final String suffix;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          tooltip: 'Moins',
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        Text(suffix.isEmpty ? '$value' : '$value $suffix'),
        IconButton(
          tooltip: 'Plus',
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

class _FieldIssues extends StatelessWidget {
  const _FieldIssues({required this.issues});

  final List<ReservationIssue> issues;

  @override
  Widget build(BuildContext context) {
    if (issues.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final i in issues)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  i.isError
                      ? Icons.error_outline
                      : Icons.warning_amber_outlined,
                  size: 18,
                  color: i.isError ? scheme.error : scheme.tertiary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    i.message,
                    style: TextStyle(color: i.isError ? scheme.error : null),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _IssueList extends StatelessWidget {
  const _IssueList({super.key, required this.issues});

  final List<ReservationIssue> issues;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: _FieldIssues(issues: issues),
    ),
  );
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.preview, required this.stale});

  final ReservationPreview preview;

  /// Le brouillon a changé depuis cet aperçu.
  final bool stale;

  @override
  Widget build(BuildContext context) {
    final days = preview.days.where((d) => d.slots.isNotEmpty).toList();
    return _Section(
      title: 'Aperçu',
      subtitle:
          'Créneaux d’une semaine type, sans les congés ni les jours '
          'fériés. Ce n’est pas encore une disponibilité pour les clients.',
      children: [
        if (stale)
          const _Notice(
            key: Key('res-preview-stale'),
            icon: Icons.update,
            text:
                'Cet aperçu date d’avant vos dernières modifications. '
                'Touchez « Vérifier » pour le recalculer.',
          ),
        Text(
          key: const Key('res-capacity'),
          '${preview.tables} table(s) · ${preview.seats} place(s) · '
          '${preview.totalCovers} couverts au plus en même temps',
        ),
        if (preview.uncoveredPartySizes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Groupes sans table adaptée : '
              '${preview.uncoveredPartySizes.join(', ')} personne(s).',
            ),
          ),
        for (final d in days)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reservationDayLabel(d.dayOfWeek)),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final s in d.slots)
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          s.inOpeningHours
                              ? s.occupationPastClosing
                                    ? '${s.time} ⚠'
                                    : s.time
                              : '${s.time} (fermé)',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.busy,
    required this.error,
    required this.conflict,
    required this.canSave,
    required this.onCheck,
    required this.onSave,
    required this.onReload,
  });

  final bool busy;
  final String? error;
  final bool conflict;
  final bool canSave;
  final VoidCallback onCheck;
  final VoidCallback onSave;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Material(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    error!,
                    key: const Key('res-error'),
                    style: TextStyle(color: scheme.error),
                  ),
                ),
              // Texte agrandi sur écran étroit : côte à côte, « Enregistrer »
              // se coupait au milieu du mot (banc visuel du 12/10, 320 pt ×1,5).
              // Les boutons passent alors l'un sous l'autre.
              LayoutBuilder(
                builder: (context, constraints) {
                  final scale = MediaQuery.textScalerOf(context).scale(1);
                  final check = OutlinedButton(
                    key: const Key('res-check'),
                    onPressed: busy ? null : onCheck,
                    child: const Text('Vérifier'),
                  );
                  final primary = conflict
                      ? FilledButton(
                          key: const Key('res-reload'),
                          onPressed: busy ? null : onReload,
                          child: const Text('Recharger'),
                        )
                      : FilledButton(
                          key: const Key('res-save'),
                          onPressed: busy || !canSave ? null : onSave,
                          child: const Text('Enregistrer'),
                        );
                  if (constraints.maxWidth / scale < 300) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [primary, const SizedBox(height: 8), check],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: check),
                      const SizedBox(width: 12),
                      Expanded(child: primary),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    super.key,
    required this.text,
    this.icon = Icons.info_outline,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}

import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/core/network/api_exception.dart';
import 'package:lilia_admin/utils/api_response.dart';

/// « Réservations sur place » (Premium Lot 3) — configuration côté restaurant.
///
/// `GET`, `POST …/preview`, `PUT /vendors/me/reservation-settings`. Le serveur
/// borne tout au restaurant du compte connecté : l'app n'envoie aucun
/// identifiant de boutique. Il décide aussi de tout le reste — droit Premium,
/// bornes, erreurs, alertes, aperçu des créneaux : l'app affiche ses verdicts,
/// elle ne recopie aucune règle.
class ReservationSettingsRepository {
  ReservationSettingsRepository(this._api);

  final ApiClient _api;

  static const _path = '/vendors/me/reservation-settings';

  Future<ReservationState> mine() async {
    final res = await _api.getJson(_path);
    return ReservationState.fromJson(ApiResponse.mapOf(res.data));
  }

  /// Valide le brouillon sans rien écrire (Premium non requis).
  Future<ReservationCheck> preview(ReservationDraft draft) async {
    final res = await _api.postJson('$_path/preview', body: draft.toJson());
    return ReservationCheck.fromJson(ApiResponse.mapOf(res.data));
  }

  /// Enregistre (Premium requis). [ReservationDraft.version] = version lue :
  /// le serveur répond 409 si la configuration a changé entre-temps.
  Future<ReservationState> save(ReservationDraft draft) async {
    final res = await _api.putJson(
      _path,
      body: {...draft.toJson(), 'version': draft.version},
    );
    return ReservationState.fromJson(ApiResponse.mapOf(res.data));
  }
}

/// Codes d'erreur serveur (`error.code`) que l'écran distingue.
abstract final class ReservationErrorCodes {
  static const invalid = 'RESERVATION_SETTINGS_INVALID';
  static const conflict = 'RESERVATION_SETTINGS_CONFLICT';
  static const premiumRequired = 'PREMIUM_REQUIRED';
  static const vendorType = 'RESERVATIONS_NOT_AVAILABLE_FOR_VENDOR_TYPE';
}

/// Message à montrer au vendeur pour une erreur de cette page.
///
/// Le 429 du serveur porte un texte technique en anglais
/// (« ThrottlerException: Too Many Requests », sans `error.code` — réponse
/// réelle capturée le 12/10) : il est remplacé ici, localement, sans toucher
/// à l'intercepteur partagé. Les autres messages serveur sont déjà en français.
String reservationErrorMessage(ApiException e) => e.statusCode == 429
    ? 'Trop de demandes rapprochées. Patientez une seconde, puis réessayez.'
    : e.message;

/// Jours dans l'ordre d'affichage (valeurs de l'API).
const reservationWeekDays = [
  'LUNDI',
  'MARDI',
  'MERCREDI',
  'JEUDI',
  'VENDREDI',
  'SAMEDI',
  'DIMANCHE',
];

String reservationDayLabel(String day) => switch (day) {
  'LUNDI' => 'Lundi',
  'MARDI' => 'Mardi',
  'MERCREDI' => 'Mercredi',
  'JEUDI' => 'Jeudi',
  'VENDREDI' => 'Vendredi',
  'SAMEDI' => 'Samedi',
  'DIMANCHE' => 'Dimanche',
  _ => day,
};

int _i(Object? v, [int fallback = 0]) => v is num ? v.toInt() : fallback;
int? _iOrNull(Object? v) => v is num ? v.toInt() : null;
String _s(Object? v) => v is String ? v : '';
bool _b(Object? v) => v == true;
DateTime? _d(Object? v) => v is String ? DateTime.tryParse(v) : null;
Map<String, dynamic> _m(Object? v) =>
    v is Map<String, dynamic> ? v : const <String, dynamic>{};
List<Map<String, dynamic>> _l(Object? v) => v is List
    ? v.whereType<Map<String, dynamic>>().toList(growable: false)
    : const [];

/// Borne numérique envoyée par le serveur (`limits`).
class NumberLimit {
  const NumberLimit({
    required this.min,
    required this.max,
    required this.fallback,
  });

  factory NumberLimit.fromJson(Object? json, NumberLimit fallback) {
    final m = _m(json);
    if (m.isEmpty) return fallback;
    return NumberLimit(
      min: _i(m['min'], fallback.min),
      max: _i(m['max'], fallback.max),
      fallback: _i(m['default'], fallback.fallback),
    );
  }

  final int min;
  final int max;

  /// Valeur proposée pour une première configuration.
  final int fallback;

  int clamp(int v) => v.clamp(min, max);
}

/// Bornes de la configuration, **lues du serveur**. Les valeurs de repli ne
/// servent que si un serveur ancien ne les envoyait pas ; elles ne décident
/// de rien (le serveur revalide tout).
class ReservationLimits {
  const ReservationLimits({
    required this.slotDurationMin,
    required this.slotStepAllowed,
    required this.slotStepDefault,
    required this.bufferMin,
    required this.minLeadMin,
    required this.maxAdvanceDays,
    required this.maxPartySize,
    required this.tableGuestsMax,
    required this.seatCountMax,
    required this.maxSeatsPerBookingMax,
    required this.maxWindowsPerDay,
    required this.labelMaxLength,
  });

  factory ReservationLimits.fromJson(Map<String, dynamic> j) {
    final step = _m(j['slotStepMin']);
    final allowed = step['allowed'] is List
        ? (step['allowed'] as List)
              .whereType<num>()
              .map((n) => n.toInt())
              .toList()
        : const [15, 30, 60];
    return ReservationLimits(
      slotDurationMin: NumberLimit.fromJson(
        j['slotDurationMin'],
        const NumberLimit(min: 30, max: 240, fallback: 90),
      ),
      slotStepAllowed: allowed,
      slotStepDefault: _i(step['default'], 30),
      bufferMin: NumberLimit.fromJson(
        j['bufferMin'],
        const NumberLimit(min: 0, max: 60, fallback: 15),
      ),
      minLeadMin: NumberLimit.fromJson(
        j['minLeadMin'],
        const NumberLimit(min: 30, max: 2880, fallback: 120),
      ),
      maxAdvanceDays: NumberLimit.fromJson(
        j['maxAdvanceDays'],
        const NumberLimit(min: 1, max: 90, fallback: 30),
      ),
      maxPartySize: NumberLimit.fromJson(
        j['maxPartySize'],
        const NumberLimit(min: 1, max: 50, fallback: 8),
      ),
      tableGuestsMax: _i(j['tableGuestsMax'], 50),
      seatCountMax: _i(j['seatCountMax'], 200),
      maxSeatsPerBookingMax: _i(j['maxSeatsPerBookingMax'], 50),
      maxWindowsPerDay: _i(j['maxWindowsPerDay'], 3),
      labelMaxLength: _i(j['labelMaxLength'], 40),
    );
  }

  final NumberLimit slotDurationMin;
  final List<int> slotStepAllowed;
  final int slotStepDefault;
  final NumberLimit bufferMin;
  final NumberLimit minLeadMin;
  final NumberLimit maxAdvanceDays;
  final NumberLimit maxPartySize;
  final int tableGuestsMax;
  final int seatCountMax;
  final int maxSeatsPerBookingMax;
  final int maxWindowsPerDay;
  final int labelMaxLength;
}

enum ReservationSpaceKind {
  table('TABLE'),
  seats('SEATS');

  const ReservationSpaceKind(this.wire);
  final String wire;

  static ReservationSpaceKind parse(Object? v) =>
      v == 'SEATS' ? ReservationSpaceKind.seats : ReservationSpaceKind.table;
}

/// Table entière ou espace de places, tel que le serveur l'a enregistré.
class ReservationSpace {
  const ReservationSpace({
    required this.id,
    required this.kind,
    required this.label,
    this.minGuests,
    this.maxGuests,
    this.seatCount,
    this.maxSeatsPerBooking,
    this.archivedAt,
  });

  factory ReservationSpace.fromJson(Map<String, dynamic> j) => ReservationSpace(
    id: _s(j['id']),
    kind: ReservationSpaceKind.parse(j['kind']),
    label: _s(j['label']),
    minGuests: _iOrNull(j['minGuests']),
    maxGuests: _iOrNull(j['maxGuests']),
    seatCount: _iOrNull(j['seatCount']),
    maxSeatsPerBooking: _iOrNull(j['maxSeatsPerBooking']),
    archivedAt: _d(j['archivedAt']),
  );

  final String id;
  final ReservationSpaceKind kind;
  final String label;
  final int? minGuests;
  final int? maxGuests;
  final int? seatCount;
  final int? maxSeatsPerBooking;
  final DateTime? archivedAt;
}

class ReservationWindow {
  const ReservationWindow({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  factory ReservationWindow.fromJson(Map<String, dynamic> j) =>
      ReservationWindow(
        dayOfWeek: _s(j['dayOfWeek']),
        startTime: _s(j['startTime']),
        endTime: _s(j['endTime']),
      );

  final String dayOfWeek;
  final String startTime;

  /// Dernière heure d'arrivée autorisée, incluse.
  final String endTime;

  Map<String, dynamic> toJson() => {
    'dayOfWeek': dayOfWeek,
    'startTime': startTime,
    'endTime': endTime,
  };
}

class ReservationConfig {
  const ReservationConfig({
    required this.version,
    required this.enabled,
    required this.slotDurationMin,
    required this.slotStepMin,
    required this.bufferMin,
    required this.minLeadMin,
    required this.maxAdvanceDays,
    required this.maxPartySize,
    required this.spaces,
    required this.archivedSpaces,
    required this.windows,
  });

  factory ReservationConfig.fromJson(Map<String, dynamic> j) =>
      ReservationConfig(
        version: _i(j['version']),
        enabled: _b(j['enabled']),
        slotDurationMin: _i(j['slotDurationMin']),
        slotStepMin: _i(j['slotStepMin']),
        bufferMin: _i(j['bufferMin']),
        minLeadMin: _i(j['minLeadMin']),
        maxAdvanceDays: _i(j['maxAdvanceDays']),
        maxPartySize: _i(j['maxPartySize']),
        spaces: _l(j['spaces']).map(ReservationSpace.fromJson).toList(),
        archivedSpaces: _l(
          j['archivedSpaces'],
        ).map(ReservationSpace.fromJson).toList(),
        windows: _l(j['windows']).map(ReservationWindow.fromJson).toList(),
      );

  final int version;
  final bool enabled;
  final int slotDurationMin;
  final int slotStepMin;
  final int bufferMin;
  final int minLeadMin;
  final int maxAdvanceDays;
  final int maxPartySize;
  final List<ReservationSpace> spaces;
  final List<ReservationSpace> archivedSpaces;
  final List<ReservationWindow> windows;
}

/// Constat serveur : `ERROR` bloque l'enregistrement, `WARNING` informe.
class ReservationIssue {
  const ReservationIssue({
    required this.severity,
    required this.code,
    required this.field,
    required this.message,
    this.partySizes = const [],
  });

  factory ReservationIssue.fromJson(Map<String, dynamic> j) => ReservationIssue(
    severity: _s(j['severity']),
    code: _s(j['code']),
    field: j['field'] is String ? j['field'] as String : null,
    message: _s(j['message']),
    partySizes: j['partySizes'] is List
        ? (j['partySizes'] as List)
              .whereType<num>()
              .map((n) => n.toInt())
              .toList()
        : const [],
  );

  final String severity;
  final String code;

  /// Chemin du champ visé (`spaces[2].label`), `null` si global.
  final String? field;
  final String message;
  final List<int> partySizes;

  bool get isError => severity == 'ERROR';
}

class PreviewSlot {
  const PreviewSlot({
    required this.time,
    required this.inOpeningHours,
    required this.occupationPastClosing,
  });

  factory PreviewSlot.fromJson(Map<String, dynamic> j) => PreviewSlot(
    time: _s(j['time']),
    inOpeningHours: _b(j['inOpeningHours']),
    occupationPastClosing: _b(j['occupationPastClosing']),
  );

  final String time;
  final bool inOpeningHours;
  final bool occupationPastClosing;
}

class PreviewDay {
  const PreviewDay({
    required this.dayOfWeek,
    required this.opening,
    required this.slots,
  });

  factory PreviewDay.fromJson(Map<String, dynamic> j) {
    final opening = _m(j['opening']);
    return PreviewDay(
      dayOfWeek: _s(j['dayOfWeek']),
      opening: opening.isEmpty
          ? null
          : '${_s(opening['openTime'])} – ${_s(opening['closeTime'])}',
      slots: _l(j['slots']).map(PreviewSlot.fromJson).toList(),
    );
  }

  final String dayOfWeek;

  /// « 08:00 – 23:00 », `null` si le restaurant est fermé ce jour-là.
  final String? opening;
  final List<PreviewSlot> slots;
}

class ReservationPreview {
  const ReservationPreview({
    required this.tables,
    required this.tableCovers,
    required this.seatSpaces,
    required this.seats,
    required this.totalCovers,
    required this.uncoveredPartySizes,
    required this.days,
  });

  factory ReservationPreview.fromJson(Map<String, dynamic> j) {
    final c = _m(j['capacity']);
    return ReservationPreview(
      tables: _i(c['tables']),
      tableCovers: _i(c['tableCovers']),
      seatSpaces: _i(c['seatSpaces']),
      seats: _i(c['seats']),
      totalCovers: _i(c['totalCovers']),
      uncoveredPartySizes: j['uncoveredPartySizes'] is List
          ? (j['uncoveredPartySizes'] as List)
                .whereType<num>()
                .map((n) => n.toInt())
                .toList()
          : const [],
      days: _l(j['days']).map(PreviewDay.fromJson).toList(),
    );
  }

  final int tables;
  final int tableCovers;
  final int seatSpaces;
  final int seats;
  final int totalCovers;
  final List<int> uncoveredPartySizes;
  final List<PreviewDay> days;
}

/// État serveur de `GET` / `PUT` : les cinq notions séparées (configurée,
/// activée, Premium, interrupteur plateforme, effective). « Effective » ne
/// promet aucune disponibilité client : le parcours client n'existe pas encore.
class ReservationState {
  const ReservationState({
    required this.eligible,
    required this.configured,
    required this.enabled,
    required this.entitled,
    required this.platformEnabled,
    required this.effective,
    required this.premiumPaidUntil,
    required this.limits,
    required this.config,
    required this.issues,
    required this.preview,
  });

  factory ReservationState.fromJson(Map<String, dynamic> j) => ReservationState(
    eligible: _b(j['eligible']),
    configured: _b(j['configured']),
    enabled: _b(j['enabled']),
    entitled: _b(j['entitled']),
    platformEnabled: _b(j['platformEnabled']),
    effective: _b(j['effective']),
    premiumPaidUntil: _d(j['premiumPaidUntil']),
    limits: ReservationLimits.fromJson(_m(j['limits'])),
    config: j['config'] is Map<String, dynamic>
        ? ReservationConfig.fromJson(j['config'] as Map<String, dynamic>)
        : null,
    issues: _l(j['issues']).map(ReservationIssue.fromJson).toList(),
    preview: j['preview'] is Map<String, dynamic>
        ? ReservationPreview.fromJson(j['preview'] as Map<String, dynamic>)
        : null,
  );

  final bool eligible;
  final bool configured;
  final bool enabled;
  final bool entitled;
  final bool platformEnabled;
  final bool effective;
  final DateTime? premiumPaidUntil;
  final ReservationLimits limits;
  final ReservationConfig? config;
  final List<ReservationIssue> issues;
  final ReservationPreview? preview;

  /// Écriture possible : restaurant éligible et Premium actif.
  bool get canEdit => eligible && entitled;
}

/// Réponse de la prévisualisation.
class ReservationCheck {
  const ReservationCheck({
    required this.valid,
    required this.effective,
    required this.issues,
    required this.preview,
  });

  factory ReservationCheck.fromJson(Map<String, dynamic> j) => ReservationCheck(
    valid: _b(j['valid']),
    effective: _b(j['effective']),
    issues: _l(j['issues']).map(ReservationIssue.fromJson).toList(),
    preview: j['preview'] is Map<String, dynamic>
        ? ReservationPreview.fromJson(j['preview'] as Map<String, dynamic>)
        : null,
  );

  final bool valid;
  final bool effective;
  final List<ReservationIssue> issues;
  final ReservationPreview? preview;
}

/// Ressource en cours d'édition. [id] nul = nouvelle ; [archived] = archivage
/// demandé (jamais par simple retrait de la liste : le serveur le refuse).
class DraftSpace {
  DraftSpace({
    this.id,
    required this.kind,
    this.label = '',
    this.minGuests = 1,
    this.maxGuests = 4,
    this.seatCount = 6,
    this.maxSeatsPerBooking = 2,
    this.archived = false,
  });

  factory DraftSpace.fromSpace(ReservationSpace s) => DraftSpace(
    id: s.id,
    kind: s.kind,
    label: s.label,
    minGuests: s.minGuests ?? 1,
    maxGuests: s.maxGuests ?? 4,
    seatCount: s.seatCount ?? 6,
    maxSeatsPerBooking: s.maxSeatsPerBooking ?? 2,
  );

  final String? id;
  final ReservationSpaceKind kind;
  String label;
  int minGuests;
  int maxGuests;
  int seatCount;
  int maxSeatsPerBooking;
  bool archived;

  bool get isNew => id == null;

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'kind': kind.wire,
    'label': label,
    if (kind == ReservationSpaceKind.table) ...{
      'minGuests': minGuests,
      'maxGuests': maxGuests,
    } else ...{
      'seatCount': seatCount,
      'maxSeatsPerBooking': maxSeatsPerBooking,
    },
    if (archived) 'archived': true,
  };
}

/// Brouillon complet de la configuration.
class ReservationDraft {
  ReservationDraft({
    required this.version,
    required this.enabled,
    required this.slotDurationMin,
    required this.slotStepMin,
    required this.bufferMin,
    required this.minLeadMin,
    required this.maxAdvanceDays,
    required this.maxPartySize,
    required this.spaces,
    required this.windows,
  });

  /// Depuis la configuration enregistrée, ou les valeurs par défaut du serveur.
  factory ReservationDraft.fromState(ReservationState state) {
    final c = state.config;
    final l = state.limits;
    if (c == null) {
      return ReservationDraft(
        version: 0,
        enabled: false,
        slotDurationMin: l.slotDurationMin.fallback,
        slotStepMin: l.slotStepDefault,
        bufferMin: l.bufferMin.fallback,
        minLeadMin: l.minLeadMin.fallback,
        maxAdvanceDays: l.maxAdvanceDays.fallback,
        maxPartySize: l.maxPartySize.fallback,
        spaces: [],
        windows: [],
      );
    }
    return ReservationDraft(
      version: c.version,
      enabled: c.enabled,
      slotDurationMin: c.slotDurationMin,
      slotStepMin: c.slotStepMin,
      bufferMin: c.bufferMin,
      minLeadMin: c.minLeadMin,
      maxAdvanceDays: c.maxAdvanceDays,
      maxPartySize: c.maxPartySize,
      spaces: c.spaces.map(DraftSpace.fromSpace).toList(),
      windows: [...c.windows],
    );
  }

  final int version;
  bool enabled;
  int slotDurationMin;
  int slotStepMin;
  int bufferMin;
  int minLeadMin;
  int maxAdvanceDays;
  int maxPartySize;
  final List<DraftSpace> spaces;
  final List<ReservationWindow> windows;

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'slotDurationMin': slotDurationMin,
    'slotStepMin': slotStepMin,
    'bufferMin': bufferMin,
    'minLeadMin': minLeadMin,
    'maxAdvanceDays': maxAdvanceDays,
    'maxPartySize': maxPartySize,
    'spaces': spaces.map((s) => s.toJson()).toList(),
    'windows': windows.map((w) => w.toJson()).toList(),
  };
}

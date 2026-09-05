import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/models/incident.dart';
import 'package:lilia_admin/utils/api_response.dart';

/// Accès HTTP aux endpoints `/incidents` du backend (ADMIN-only).
///
/// Le backend renvoie :
/// - `GET /incidents?status=&severity=&type=&limit=&offset=` → `{ data: [...], total: number }`
/// - `GET /incidents/:id` → `{ data: Incident }`
/// - `POST /incidents` → `{ data: Incident }`
/// - `PATCH /incidents/:id` → `{ data: Incident }` (update status, resolution)
class IncidentsRepository {
  final ApiClient _api;

  IncidentsRepository(this._api);

  Future<PaginatedIncidents> fetchIncidents({
    IncidentStatus? status,
    IncidentSeverity? severity,
    IncidentType? type,
    int limit = 20,
    int offset = 0,
  }) async {
    final res = await _api.getJson('/incidents', query: {
      'limit': '$limit',
      'offset': '$offset',
      if (status != null) 'status': status.wireValue,
      if (severity != null) 'severity': severity.wireValue,
      if (type != null) 'type': type.wireValue,
    });

    // Contrat v2 : `{ data: [...], meta: { total } }`. On tolère aussi l'ancien
    // `{ data, total }` à plat (fallback racine).
    final body = ApiResponse.mapOf(res.data);
    final list = ApiResponse.listOf(body)
        .map((e) => Incident.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    final meta = body['meta'] as Map<String, dynamic>?;
    return PaginatedIncidents(
      incidents: list,
      total: (body['total'] as int?) ?? (meta?['total'] as int?) ?? list.length,
      limit: limit,
      offset: offset,
    );
  }

  Future<Incident> fetchIncident(String id) async {
    final res = await _api.getJson('/incidents/$id');
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return Incident.fromJson(data);
  }

  /// Met à jour le status / resolution d'un incident.
  /// Le backend stamp automatiquement `resolvedBy` et `resolvedAt` quand le
  /// status passe à RESOLVED / CLOSED.
  Future<Incident> updateIncident(
    String id, {
    IncidentStatus? status,
    String? resolution,
  }) async {
    final payload = <String, dynamic>{
      if (status != null) 'status': status.wireValue,
      if (resolution != null) 'resolution': resolution,
    };
    if (payload.isEmpty) {
      throw ArgumentError('Aucun champ à mettre à jour.');
    }
    final res = await _api.patchJson('/incidents/$id', body: payload);
    return Incident.fromJson((res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>);
  }
}

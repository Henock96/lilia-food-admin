import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:lilia_admin/features/incidents/data/incidents_repository.dart';
import 'package:lilia_admin/models/incident.dart';
import 'package:lilia_admin/core/network/api_client.dart';

part 'incidents_provider.g.dart';

@riverpod
IncidentsRepository incidentsRepository(Ref ref) {
  return IncidentsRepository(ref.watch(apiClientProvider));
}

/// Liste paginée + filtrable des incidents (ADMIN).
///
/// Le `family` de Riverpod prend les filtres comme paramètres pour bénéficier
/// du cache automatique : revenir sur un filtre déjà vu est instantané.
@riverpod
Future<PaginatedIncidents> incidentsList(
  Ref ref, {
  IncidentStatus? status,
  IncidentSeverity? severity,
  IncidentType? type,
  required int limit,
  required int offset,
}) {
  return ref.watch(incidentsRepositoryProvider).fetchIncidents(
        status: status,
        severity: severity,
        type: type,
        limit: limit,
        offset: offset,
      );
}

/// Détail d'un incident par ID (ADMIN).
@riverpod
Future<Incident> incidentDetail(Ref ref, String id) {
  return ref.watch(incidentsRepositoryProvider).fetchIncident(id);
}

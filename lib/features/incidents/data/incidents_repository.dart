import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'package:lilia_admin/models/incident.dart';

import 'package:lilia_admin/constants/app_constants.dart';
/// Accès HTTP aux endpoints `/incidents` du backend (ADMIN-only).
///
/// Le backend renvoie :
/// - `GET /incidents?status=&severity=&type=&limit=&offset=` → `{ data: [...], total: number }`
/// - `GET /incidents/:id` → `{ data: Incident }`
/// - `POST /incidents` → `{ data: Incident }`
/// - `PATCH /incidents/:id` → `{ data: Incident }` (update status, resolution)
class IncidentsRepository {
  final String _baseUrl = AppConstants.baseUrl;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<String> _getAuthToken() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non authentifié.');
    }
    final token = await user.getIdToken();
    if (token == null) {
      throw Exception('Token Firebase indisponible.');
    }
    return token;
  }

  Future<PaginatedIncidents> fetchIncidents({
    IncidentStatus? status,
    IncidentSeverity? severity,
    IncidentType? type,
    int limit = 20,
    int offset = 0,
  }) async {
    final token = await _getAuthToken();
    final query = <String, String>{
      'limit': '$limit',
      'offset': '$offset',
      if (status != null) 'status': status.wireValue,
      if (severity != null) 'severity': severity.wireValue,
      if (type != null) 'type': type.wireValue,
    };
    final url = Uri.parse('$_baseUrl/incidents').replace(queryParameters: query);

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Échec du chargement des incidents: ${response.statusCode} ${response.body}',
      );
    }

    final body = json.decode(utf8.decode(response.bodyBytes))
        as Map<String, dynamic>;
    final list = (body['data'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => Incident.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return PaginatedIncidents(
      incidents: list,
      total: (body['total'] as int?) ?? list.length,
      limit: limit,
      offset: offset,
    );
  }

  Future<Incident> fetchIncident(String id) async {
    final token = await _getAuthToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/incidents/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Échec du chargement de l\'incident: ${response.statusCode} ${response.body}',
      );
    }
    final body = json.decode(utf8.decode(response.bodyBytes))
        as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
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
    final token = await _getAuthToken();
    final payload = <String, dynamic>{
      if (status != null) 'status': status.wireValue,
      if (resolution != null) 'resolution': resolution,
    };
    if (payload.isEmpty) {
      throw ArgumentError('Aucun champ à mettre à jour.');
    }
    final response = await http.patch(
      Uri.parse('$_baseUrl/incidents/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(payload),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Échec de la mise à jour: ${response.statusCode} ${response.body}',
      );
    }
    final body = json.decode(utf8.decode(response.bodyBytes))
        as Map<String, dynamic>;
    return Incident.fromJson(body['data'] as Map<String, dynamic>);
  }
}

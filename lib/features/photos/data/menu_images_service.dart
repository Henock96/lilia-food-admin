import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'photo_models.dart';

class MenuImagesService {
  final String _baseUrl = "https://lilia-backend.onrender.com";
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<String?> _getAuthToken() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return await user.getIdToken();
  }

  Future<List<Photo>> list(String menuDuJourId) async {
    final token = await _getAuthToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/menu-images?menuDuJourId=$menuDuJourId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      final List<dynamic> rawList = decoded is List
          ? decoded
          : (decoded is Map<String, dynamic> && decoded['data'] is List)
              ? decoded['data'] as List<dynamic>
              : <dynamic>[];
      return rawList
          .map((j) => Photo.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load menu images: ${response.body}');
  }

  Future<Photo> create({
    required String menuDuJourId,
    required String url,
    required String publicId,
    String? alt,
    bool isCover = false,
  }) async {
    final token = await _getAuthToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/menu-images'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'menuDuJourId': menuDuJourId,
        'url': url,
        'publicId': publicId,
        if (alt != null) 'alt': alt,
        'isCover': isCover,
      }),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      final decoded =
          json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final photoJson = (decoded['data'] is Map<String, dynamic>)
          ? decoded['data'] as Map<String, dynamic>
          : decoded;
      return Photo.fromJson(photoJson);
    }
    throw Exception('Failed to create menu image: ${response.body}');
  }

  Future<Photo> update(
    String photoId, {
    String? alt,
    bool? isCover,
    int? displayOrder,
  }) async {
    final token = await _getAuthToken();
    final body = <String, dynamic>{};
    if (alt != null) body['alt'] = alt;
    if (isCover != null) body['isCover'] = isCover;
    if (displayOrder != null) body['displayOrder'] = displayOrder;

    final response = await http.patch(
      Uri.parse('$_baseUrl/menu-images/$photoId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );
    if (response.statusCode == 200) {
      final decoded =
          json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final photoJson = (decoded['data'] is Map<String, dynamic>)
          ? decoded['data'] as Map<String, dynamic>
          : decoded;
      return Photo.fromJson(photoJson);
    }
    throw Exception('Failed to update menu image: ${response.body}');
  }

  Future<void> delete(String photoId) async {
    final token = await _getAuthToken();
    final response = await http.delete(
      Uri.parse('$_baseUrl/menu-images/$photoId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete menu image: ${response.body}');
    }
  }

  Future<void> reorder(String menuDuJourId, List<String> ids) async {
    final token = await _getAuthToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/menu-images/reorder'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'menuDuJourId': menuDuJourId, 'ids': ids}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to reorder menu images: ${response.body}');
    }
  }
}

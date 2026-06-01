import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'photo_models.dart';

class VendorPhotosService {
  final String _baseUrl = "https://lilia-backend.onrender.com";
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<String?> _getAuthToken() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return await user.getIdToken();
  }

  Future<List<Photo>> list(String restaurantId) async {
    final token = await _getAuthToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/vendor-photos?restaurantId=$restaurantId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final responseData =
          json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final data = responseData['data'] as List<dynamic>? ?? [];
      return data
          .map((j) => Photo.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load vendor photos: ${response.body}');
  }

  Future<Photo> create({
    required String restaurantId,
    required String url,
    required String publicId,
    String? alt,
    bool isCover = false,
  }) async {
    final token = await _getAuthToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/vendor-photos'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'restaurantId': restaurantId,
        'url': url,
        'publicId': publicId,
        if (alt != null) 'alt': alt,
        'isCover': isCover,
      }),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      final responseData =
          json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final photoJson = responseData['data'] as Map<String, dynamic>?;
      if (photoJson == null) {
        throw Exception('Vendor photo data null in response');
      }
      return Photo.fromJson(photoJson);
    }
    throw Exception('Failed to create vendor photo: ${response.body}');
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
      Uri.parse('$_baseUrl/vendor-photos/$photoId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );
    if (response.statusCode == 200) {
      final responseData =
          json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final photoJson = responseData['data'] as Map<String, dynamic>?;
      if (photoJson == null) {
        throw Exception('Vendor photo data null in response');
      }
      return Photo.fromJson(photoJson);
    }
    throw Exception('Failed to update vendor photo: ${response.body}');
  }

  Future<void> delete(String photoId) async {
    final token = await _getAuthToken();
    final response = await http.delete(
      Uri.parse('$_baseUrl/vendor-photos/$photoId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete vendor photo: ${response.body}');
    }
  }

  Future<void> reorder(String restaurantId, List<String> ids) async {
    final token = await _getAuthToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/vendor-photos/reorder'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'restaurantId': restaurantId, 'ids': ids}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to reorder vendor photos: ${response.body}');
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../../../constants/app_constants.dart';
import '../../../models/app_user.dart';
import '../../../utils/api_response.dart';

class UserRepository {
  //final String _baseUrl = AppConstants.baseUrl; // Mettez votre URL de base ici
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Extrait l'objet user de `/users/me`, tolérant aux deux formes :
  /// legacy `{ user: {...} }` ET wrappée `{ data: { user: {...} } }`.
  static Map<String, dynamic> _extractUser(dynamic decoded) {
    final unwrapped = ApiResponse.mapOf(decoded);
    return (unwrapped['user'] ?? unwrapped) as Map<String, dynamic>;
  }

  Future<String?> _getIdToken() async {
    final user = _firebaseAuth.currentUser;
    return await user?.getIdToken();
  }

  Future<AppUser> updateUserProfile(Map<String, dynamic> data) async {
    final token = await _getIdToken();
    if (token == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return AppUser.fromJson(_extractUser(responseData));
    } else {
      throw Exception('Échec de la mise à jour du profil: ${response.body}');
    }
  }

  Future<AppUser> getUserProfile() async {
    final token = await _getIdToken();
    if (token == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return AppUser.fromJson(_extractUser(responseData));
    } else {
      throw Exception('Échec du chargement du profil: ${response.body}');
    }
  }
}
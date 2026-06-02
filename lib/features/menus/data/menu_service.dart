import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/menu.dart';

import 'package:lilia_admin/constants/app_constants.dart';
class MenuService {
  final String _baseUrl = AppConstants.baseUrl;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<String?> _getAuthToken() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return await user.getIdToken();
  }

  Future<List<MenuDuJour>> getMenus({bool includeExpired = true}) async {
    final token = await _getAuthToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/menus/restaurant/mine?includeExpired=$includeExpired'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      // Le backend renvoie { "data": [...], "message": "...", "count": ... }
      final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
      final List<dynamic> menusData = responseData['data'] as List<dynamic>? ?? [];
      return menusData.map((json) => MenuDuJour.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load menus: ${response.body}');
    }
  }

  Future<MenuDuJour> getMenu(String menuId) async {
    final token = await _getAuthToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/menus/$menuId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      // Le backend renvoie { "data": {...}, "message": "..." }
      final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
      final menuData = responseData['data'] as Map<String, dynamic>?;
      if (menuData == null) {
        throw Exception('Menu data is null');
      }
      return MenuDuJour.fromJson(menuData);
    } else {
      throw Exception('Failed to load menu: ${response.body}');
    }
  }

  Future<MenuDuJour> createMenu(Map<String, dynamic> menuData) async {
    final token = await _getAuthToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/menus'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(menuData),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      // Le backend renvoie { "message": "...", "data": {...} }
      final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
      final menuJson = responseData['data'] as Map<String, dynamic>?;
      if (menuJson == null) {
        throw Exception('Menu data is null in response');
      }
      return MenuDuJour.fromJson(menuJson);
    } else {
      throw Exception('Failed to create menu: ${response.body}');
    }
  }

  Future<MenuDuJour> updateMenu(
      String menuId, Map<String, dynamic> menuData) async {
    final token = await _getAuthToken();
    final response = await http.patch(
      Uri.parse('$_baseUrl/menus/$menuId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(menuData),
    );

    if (response.statusCode == 200) {
      // Le backend renvoie { "message": "...", "data": {...} }
      final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
      final menuJson = responseData['data'] as Map<String, dynamic>?;
      if (menuJson == null) {
        throw Exception('Menu data is null in response');
      }
      return MenuDuJour.fromJson(menuJson);
    } else {
      throw Exception('Failed to update menu: ${response.body}');
    }
  }

  Future<MenuDuJour> toggleMenuStatus(String menuId) async {
    final token = await _getAuthToken();
    final response = await http.patch(
      Uri.parse('$_baseUrl/menus/$menuId/toggle'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      // Le backend renvoie { "message": "...", "data": {...} }
      final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
      final menuJson = responseData['data'] as Map<String, dynamic>?;
      if (menuJson == null) {
        throw Exception('Menu data is null in response');
      }
      return MenuDuJour.fromJson(menuJson);
    } else {
      throw Exception('Failed to toggle menu status: ${response.body}');
    }
  }

  Future<void> deleteMenu(String menuId) async {
    final token = await _getAuthToken();
    final response = await http.delete(
      Uri.parse('$_baseUrl/menus/$menuId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete menu: ${response.body}');
    }
  }
}

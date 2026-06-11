import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/product.dart';

import 'package:lilia_admin/constants/app_constants.dart';
import 'package:lilia_admin/utils/api_response.dart';
class CategoryService {
  final String _baseUrl = AppConstants.baseUrl;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<String?> _getAuthToken() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return await user.getIdToken();
  }

  Future<List<Category>> getCategories(String restaurantId) async {
    final token = await _getAuthToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/categories?restaurantId=$restaurantId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      // Backend renvoie { data:[...], count } → double-wrappé par l'interceptor.
      // ApiResponse.listOf tolère liste brute / simple wrap / double wrap.
      final categoriesData =
          ApiResponse.listOf(json.decode(utf8.decode(response.bodyBytes)));
      return categoriesData.map((json) => Category.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load categories: ${response.body}');
    }
  }

  Future<Category> getCategory(String categoryId) async {
    final token = await _getAuthToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/categories/$categoryId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      // Le backend renvoie { "data": {...} }
      final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
      final categoryData = responseData['data'] as Map<String, dynamic>?;
      if (categoryData == null) {
        throw Exception('Category data is null');
      }
      return Category.fromJson(categoryData);
    } else {
      throw Exception('Failed to load category: ${response.body}');
    }
  }

  Future<Category> createCategory(
      String restaurantId, Map<String, dynamic> categoryData) async {
    final token = await _getAuthToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/categories?restaurantId=$restaurantId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(categoryData),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      // Le backend renvoie { "data": {...}, "message": "..." }
      final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
      final categoryJson = responseData['data'] as Map<String, dynamic>?;
      if (categoryJson == null) {
        throw Exception('Category data is null in response');
      }
      return Category.fromJson(categoryJson);
    } else {
      throw Exception('Failed to create category: ${response.body}');
    }
  }

  Future<Category> updateCategory(
      String categoryId, Map<String, dynamic> categoryData) async {
    final token = await _getAuthToken();
    final response = await http.patch(
      Uri.parse('$_baseUrl/categories/$categoryId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(categoryData),
    );

    if (response.statusCode == 200) {
      // Le backend renvoie { "data": {...}, "message": "..." }
      final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
      final categoryJson = responseData['data'] as Map<String, dynamic>?;
      if (categoryJson == null) {
        throw Exception('Category data is null in response');
      }
      return Category.fromJson(categoryJson);
    } else {
      throw Exception('Failed to update category: ${response.body}');
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    final token = await _getAuthToken();
    final response = await http.delete(
      Uri.parse('$_baseUrl/categories/$categoryId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete category: ${response.body}');
    }
  }
}

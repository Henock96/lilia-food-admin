import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/product.dart';

class ProductService {
  final String _baseUrl = "https://lilia-backend.onrender.com";
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<String?> _getAuthToken() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return await user.getIdToken();
  }

  Future<List<Product>> getProducts(String restaurantId) async {
    final token = await _getAuthToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/products?restaurantId=$restaurantId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      // Le backend renvoie { "data": [...], "meta": {...} }
      final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
      final List<dynamic> productsData = responseData['data'] as List<dynamic>? ?? [];
      return productsData.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load products: ${response.body}');
    }
  }

  Future<Product> getProduct(String productId) async {
    final token = await _getAuthToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/products/$productId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      // Le backend renvoie { "data": {...} }
      final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
      final productData = responseData['data'] as Map<String, dynamic>?;
      if (productData == null) {
        throw Exception('Product data is null');
      }
      return Product.fromJson(productData);
    } else {
      throw Exception('Failed to load product: ${response.body}');
    }
  }

  Future<Product> createProduct(Map<String, dynamic> productData) async {
    final token = await _getAuthToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/products'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(productData),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      // Le backend renvoie { "message": "...", "data": {...} }
      final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
      final productJson = responseData['data'] as Map<String, dynamic>?;
      if (productJson == null) {
        throw Exception('Product data is null in response');
      }
      return Product.fromJson(productJson);
    } else {
      throw Exception('Failed to create product: ${response.body}');
    }
  }

  Future<Product> updateProduct(
      String productId, Map<String, dynamic> productData) async {
    final token = await _getAuthToken();
    final response = await http.patch(
      Uri.parse('$_baseUrl/products/$productId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(productData),
    );

    if (response.statusCode == 200) {
      // Le backend renvoie { "message": "...", "data": {...} }
      final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
      final productJson = responseData['data'] as Map<String, dynamic>?;
      if (productJson == null) {
        throw Exception('Product data is null in response');
      }
      return Product.fromJson(productJson);
    } else {
      throw Exception('Failed to update product: ${response.body}');
    }
  }

  Future<void> deleteProduct(String productId) async {
    final token = await _getAuthToken();
    final response = await http.delete(
      Uri.parse('$_baseUrl/products/$productId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete product: ${response.body}');
    }
  }
}

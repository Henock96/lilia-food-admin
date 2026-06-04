import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../models/restaurant.dart';
import '../../../models/vendor_type.dart';

import 'package:lilia_admin/constants/app_constants.dart';
import 'package:lilia_admin/utils/api_response.dart';
/// Service marketplace admin (LIL-128) — endpoints `/admin/vendors/*`.
/// Réutilise la classe `Restaurant` côté Flutter ; le backend renvoie un
/// payload élargi (owner + vendorProfile + _count) mais les seuls champs
/// dont l'admin a besoin pour la liste/queue/validation sont déjà couverts.
class AdminVendorsService {
  final String _baseUrl = AppConstants.baseUrl;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<String?> _token() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return await user.getIdToken();
  }

  /// GET /admin/vendors?vendorType=&adminApproved=&isActive=
  Future<List<AdminVendorItem>> listVendors({
    VendorType? vendorType,
    bool? adminApproved,
    bool? isActive,
    int page = 1,
    int limit = 50,
  }) async {
    final token = await _token();
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (vendorType != null) 'vendorType': vendorType.name,
      if (adminApproved != null) 'adminApproved': adminApproved.toString(),
      if (isActive != null) 'isActive': isActive.toString(),
    };
    final uri = Uri.parse('$_baseUrl/admin/vendors').replace(queryParameters: params);
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur ${response.statusCode} : ${response.body}');
    }
    // Backend renvoie { data:[...], total } → double-wrappé par l'interceptor.
    final list = ApiResponse.listOf(json.decode(utf8.decode(response.bodyBytes)))
        .cast<Map<String, dynamic>>();
    return list.map(AdminVendorItem.fromJson).toList();
  }

  /// GET /admin/vendors/pending — raccourci badge "à valider".
  Future<List<AdminVendorItem>> listPending() async {
    final token = await _token();
    final response = await http.get(
      Uri.parse('$_baseUrl/admin/vendors/pending'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur ${response.statusCode} : ${response.body}');
    }
    // /admin/vendors/pending → { data:[...], ... } double-wrappé.
    final list = ApiResponse.listOf(json.decode(utf8.decode(response.bodyBytes)))
        .cast<Map<String, dynamic>>();
    return list.map(AdminVendorItem.fromJson).toList();
  }

  /// PATCH /admin/vendors/:id/approve
  Future<void> approveVendor(String restaurantId) async {
    final token = await _token();
    final response = await http.patch(
      Uri.parse('$_baseUrl/admin/vendors/$restaurantId/approve'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur ${response.statusCode} : ${response.body}');
    }
  }

  /// PATCH /admin/vendors/:id/suspend body { reason }
  Future<void> suspendVendor(String restaurantId, String reason) async {
    final token = await _token();
    final response = await http.patch(
      Uri.parse('$_baseUrl/admin/vendors/$restaurantId/suspend'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'reason': reason}),
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur ${response.statusCode} : ${response.body}');
    }
  }
}

/// Représentation enrichie pour la liste admin — `Restaurant` + owner + counts.
/// On évite d'étendre `Restaurant` pour ne pas polluer le modèle utilisé
/// partout ailleurs.
class AdminVendorItem {
  final Restaurant restaurant;
  final String? ownerName;
  final String? ownerEmail;
  final String? ownerPhone;
  final int productCount;
  final int orderCount;

  const AdminVendorItem({
    required this.restaurant,
    this.ownerName,
    this.ownerEmail,
    this.ownerPhone,
    this.productCount = 0,
    this.orderCount = 0,
  });

  factory AdminVendorItem.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'] as Map<String, dynamic>?;
    final count = json['_count'] as Map<String, dynamic>?;
    return AdminVendorItem(
      restaurant: Restaurant.fromJson(json),
      ownerName: owner?['nom'] as String?,
      ownerEmail: owner?['email'] as String?,
      ownerPhone: owner?['phone'] as String?,
      productCount: (count?['products'] as num?)?.toInt() ?? 0,
      orderCount: (count?['orders'] as num?)?.toInt() ?? 0,
    );
  }
}

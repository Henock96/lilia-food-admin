import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/banner.dart';

import 'package:lilia_admin/constants/app_constants.dart';
import 'package:lilia_admin/utils/api_response.dart';
class BannerService {
  final String _baseUrl = AppConstants.baseUrl;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<String?> _getAuthToken() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return await user.getIdToken();
  }

  Future<List<AppBanner>> getBanners({String? restaurantId}) async {
    final token = await _getAuthToken();
    String url = '$_baseUrl/banners';
    if (restaurantId != null) {
      url += '?restaurantId=$restaurantId';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      // Tolère liste brute / simple wrap / double wrap (interceptor backend).
      final data =
          ApiResponse.listOf(json.decode(utf8.decode(response.bodyBytes)));
      return data
          .map((json) => AppBanner.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load banners: ${response.body}');
    }
  }

  Future<AppBanner> createBanner(Map<String, dynamic> bannerData) async {
    final token = await _getAuthToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/banners'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(bannerData),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final Map<String, dynamic> responseData =
          json.decode(utf8.decode(response.bodyBytes));
      final bannerJson = responseData['data'] as Map<String, dynamic>?;
      if (bannerJson == null) {
        throw Exception('Banner data is null in response');
      }
      return AppBanner.fromJson(bannerJson);
    } else {
      throw Exception('Failed to create banner: ${response.body}');
    }
  }

  Future<AppBanner> updateBanner(
      String bannerId, Map<String, dynamic> bannerData) async {
    final token = await _getAuthToken();
    final response = await http.patch(
      Uri.parse('$_baseUrl/banners/$bannerId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(bannerData),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData =
          json.decode(utf8.decode(response.bodyBytes));
      final bannerJson = responseData['data'] as Map<String, dynamic>?;
      if (bannerJson == null) {
        throw Exception('Banner data is null in response');
      }
      return AppBanner.fromJson(bannerJson);
    } else {
      throw Exception('Failed to update banner: ${response.body}');
    }
  }

  Future<void> deleteBanner(String bannerId) async {
    final token = await _getAuthToken();
    final response = await http.delete(
      Uri.parse('$_baseUrl/banners/$bannerId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete banner: ${response.body}');
    }
  }

  Future<void> reorderBanner(String bannerId, int displayOrder) async {
    final token = await _getAuthToken();
    final response = await http.patch(
      Uri.parse('$_baseUrl/banners/$bannerId/reorder'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'displayOrder': displayOrder}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to reorder banner: ${response.body}');
    }
  }
}

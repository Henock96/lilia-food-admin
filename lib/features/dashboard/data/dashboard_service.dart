import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class DashboardService {
  final String _baseUrl = "https://lilia-backend.onrender.com";
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<String?> _getAuthToken() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return await user.getIdToken();
  }

  /// Récupère les statistiques générales du dashboard
  Future<DashboardOverview> getOverview() async {
    final token = await _getAuthToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/dashboard/overview'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return DashboardOverview.fromJson(data['data']);
    } else {
      throw Exception('Failed to load dashboard overview: ${response.body}');
    }
  }

  /// Récupère les statistiques des commandes par statut
  Future<OrderStats> getOrderStats({String? period}) async {
    final token = await _getAuthToken();
    final uri = Uri.parse('$_baseUrl/dashboard/orders${period != null ? '?period=$period' : ''}');
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return OrderStats.fromJson(data['data']);
    } else {
      throw Exception('Failed to load order stats: ${response.body}');
    }
  }

  /// Récupère les produits les plus vendus
  Future<List<TopProduct>> getTopProducts({int limit = 10, String? period}) async {
    final token = await _getAuthToken();
    var url = '$_baseUrl/dashboard/top-products?limit=$limit';
    if (period != null) url += '&period=$period';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      final products = data['data'] as List;
      return products.map((p) => TopProduct.fromJson(p)).toList();
    } else {
      throw Exception('Failed to load top products: ${response.body}');
    }
  }

  /// Récupère l'évolution des revenus par jour
  Future<List<RevenueData>> getRevenueChart({int days = 30}) async {
    final token = await _getAuthToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/dashboard/revenue-chart?days=$days'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      final chartData = data['data'] as List;
      return chartData.map((d) => RevenueData.fromJson(d)).toList();
    } else {
      throw Exception('Failed to load revenue chart: ${response.body}');
    }
  }

  /// Récupère les statistiques des clients
  Future<ClientStats> getClientStats() async {
    final token = await _getAuthToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/dashboard/clients'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return ClientStats.fromJson(data['data']);
    } else {
      throw Exception('Failed to load client stats: ${response.body}');
    }
  }

  /// Récupère les heures de pointe
  Future<PeakHoursData> getPeakHours({String? period}) async {
    final token = await _getAuthToken();
    final uri = Uri.parse('$_baseUrl/dashboard/peak-hours${period != null ? '?period=$period' : ''}');
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return PeakHoursData.fromJson(data);
    } else {
      throw Exception('Failed to load peak hours: ${response.body}');
    }
  }

  /// Récupère le classement des restaurants (ADMIN uniquement)
  Future<List<RestaurantRanking>> getRestaurantRanking({String? period}) async {
    final token = await _getAuthToken();
    var url = '$_baseUrl/dashboard/restaurant-ranking';
    if (period != null) url += '?period=$period';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      final rankings = data['data'] as List;
      return rankings.map((r) => RestaurantRanking.fromJson(r)).toList();
    } else {
      throw Exception('Failed to load restaurant ranking: ${response.body}');
    }
  }
}

// Models

class RestaurantRanking {
  final String id;
  final String nom;
  final String? imageUrl;
  final bool isActive;
  final int orderCount;
  final double totalRevenue;

  RestaurantRanking({
    required this.id,
    required this.nom,
    this.imageUrl,
    required this.isActive,
    required this.orderCount,
    required this.totalRevenue,
  });

  factory RestaurantRanking.fromJson(Map<String, dynamic> json) {
    return RestaurantRanking(
      id: json['id'],
      nom: json['nom'],
      imageUrl: json['imageUrl'],
      isActive: json['isActive'] ?? true,
      orderCount: json['orderCount'] ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
    );
  }
}

class DashboardOverview {
  final OrdersOverview orders;
  final RevenueOverview revenue;
  final int totalProducts;
  final int totalClients;
  final RatingOverview rating;
  final int? totalRestaurants;

  DashboardOverview({
    required this.orders,
    required this.revenue,
    required this.totalProducts,
    required this.totalClients,
    required this.rating,
    this.totalRestaurants,
  });

  factory DashboardOverview.fromJson(Map<String, dynamic> json) {
    return DashboardOverview(
      orders: OrdersOverview.fromJson(json['orders']),
      revenue: RevenueOverview.fromJson(json['revenue']),
      totalProducts: json['products']['total'] ?? 0,
      totalClients: json['clients']['total'] ?? 0,
      rating: RatingOverview.fromJson(json['rating']),
      totalRestaurants: json['totalRestaurants'] as int?,
    );
  }
}

class OrdersOverview {
  final int total;
  final int today;
  final int week;
  final int month;
  final int pending;

  OrdersOverview({
    required this.total,
    required this.today,
    required this.week,
    required this.month,
    required this.pending,
  });

  factory OrdersOverview.fromJson(Map<String, dynamic> json) {
    return OrdersOverview(
      total: json['total'] ?? 0,
      today: json['today'] ?? 0,
      week: json['week'] ?? 0,
      month: json['month'] ?? 0,
      pending: json['pending'] ?? 0,
    );
  }
}

class RevenueOverview {
  final double total;
  final double today;
  final double week;
  final double month;
  final String currency;

  RevenueOverview({
    required this.total,
    required this.today,
    required this.week,
    required this.month,
    required this.currency,
  });

  factory RevenueOverview.fromJson(Map<String, dynamic> json) {
    return RevenueOverview(
      total: (json['total'] as num?)?.toDouble() ?? 0,
      today: (json['today'] as num?)?.toDouble() ?? 0,
      week: (json['week'] as num?)?.toDouble() ?? 0,
      month: (json['month'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] ?? 'XAF',
    );
  }
}

class RatingOverview {
  final double average;
  final int count;

  RatingOverview({required this.average, required this.count});

  factory RatingOverview.fromJson(Map<String, dynamic> json) {
    return RatingOverview(
      average: (json['average'] as num?)?.toDouble() ?? 0,
      count: json['count'] ?? 0,
    );
  }
}

class OrderStats {
  final List<StatusStat> byStatus;
  final OrderTotals totals;

  OrderStats({required this.byStatus, required this.totals});

  factory OrderStats.fromJson(Map<String, dynamic> json) {
    return OrderStats(
      byStatus: (json['byStatus'] as List).map((s) => StatusStat.fromJson(s)).toList(),
      totals: OrderTotals.fromJson(json['totals']),
    );
  }
}

class StatusStat {
  final String status;
  final int count;
  final double revenue;
  final String percentage;

  StatusStat({
    required this.status,
    required this.count,
    required this.revenue,
    required this.percentage,
  });

  factory StatusStat.fromJson(Map<String, dynamic> json) {
    return StatusStat(
      status: json['status'],
      count: json['count'] ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      percentage: json['percentage']?.toString() ?? '0',
    );
  }
}

class OrderTotals {
  final int orders;
  final double revenue;
  final String averageOrderValue;

  OrderTotals({
    required this.orders,
    required this.revenue,
    required this.averageOrderValue,
  });

  factory OrderTotals.fromJson(Map<String, dynamic> json) {
    return OrderTotals(
      orders: json['orders'] ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      averageOrderValue: json['averageOrderValue']?.toString() ?? '0',
    );
  }
}

class TopProduct {
  final int rank;
  final ProductInfo? product;
  final int totalSold;
  final double totalRevenue;
  final int orderCount;

  TopProduct({
    required this.rank,
    this.product,
    required this.totalSold,
    required this.totalRevenue,
    required this.orderCount,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      rank: json['rank'] ?? 0,
      product: json['product'] != null ? ProductInfo.fromJson(json['product']) : null,
      totalSold: json['totalSold'] ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
      orderCount: json['orderCount'] ?? 0,
    );
  }
}

class ProductInfo {
  final String id;
  final String name;
  final String? imageUrl;
  final double price;

  ProductInfo({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.price,
  });

  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
      id: json['id'],
      name: json['nom'],
      imageUrl: json['imageUrl'],
      price: (json['prixOriginal'] as num?)?.toDouble() ?? 0,
    );
  }
}

class RevenueData {
  final String date;
  final double revenue;
  final int orders;

  RevenueData({required this.date, required this.revenue, required this.orders});

  factory RevenueData.fromJson(Map<String, dynamic> json) {
    return RevenueData(
      date: json['date'],
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      orders: json['orders'] ?? 0,
    );
  }
}

class ClientStats {
  final ThisMonthStats thisMonth;
  final int lastMonthTotal;
  final String growth;
  final List<TopClient> topClients;

  ClientStats({
    required this.thisMonth,
    required this.lastMonthTotal,
    required this.growth,
    required this.topClients,
  });

  factory ClientStats.fromJson(Map<String, dynamic> json) {
    return ClientStats(
      thisMonth: ThisMonthStats.fromJson(json['thisMonth']),
      lastMonthTotal: json['lastMonth']['total'] ?? 0,
      growth: json['growth']?.toString() ?? '0',
      topClients: (json['topClients'] as List).map((c) => TopClient.fromJson(c)).toList(),
    );
  }
}

class ThisMonthStats {
  final int total;
  final int newClients;
  final int returning;

  ThisMonthStats({required this.total, required this.newClients, required this.returning});

  factory ThisMonthStats.fromJson(Map<String, dynamic> json) {
    return ThisMonthStats(
      total: json['total'] ?? 0,
      newClients: json['new'] ?? 0,
      returning: json['returning'] ?? 0,
    );
  }
}

class TopClient {
  final int rank;
  final ClientInfo? client;
  final int orderCount;
  final double totalSpent;

  TopClient({
    required this.rank,
    this.client,
    required this.orderCount,
    required this.totalSpent,
  });

  factory TopClient.fromJson(Map<String, dynamic> json) {
    return TopClient(
      rank: json['rank'] ?? 0,
      client: json['client'] != null ? ClientInfo.fromJson(json['client']) : null,
      orderCount: json['orderCount'] ?? 0,
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ClientInfo {
  final String id;
  final String? name;
  final String? email;
  final String? imageUrl;

  ClientInfo({required this.id, this.name, this.email, this.imageUrl});

  factory ClientInfo.fromJson(Map<String, dynamic> json) {
    return ClientInfo(
      id: json['id'],
      name: json['nom'],
      email: json['email'],
      imageUrl: json['imageUrl'],
    );
  }
}

class PeakHoursData {
  final List<HourStat> hours;
  final HourStat peakHour;

  PeakHoursData({required this.hours, required this.peakHour});

  factory PeakHoursData.fromJson(Map<String, dynamic> json) {
    return PeakHoursData(
      hours: (json['data'] as List).map((h) => HourStat.fromJson(h)).toList(),
      peakHour: HourStat.fromJson(json['peakHour']),
    );
  }
}

class HourStat {
  final int hour;
  final int count;

  HourStat({required this.hour, required this.count});

  factory HourStat.fromJson(Map<String, dynamic> json) {
    return HourStat(
      hour: json['hour'] ?? 0,
      count: json['count'] ?? 0,
    );
  }
}

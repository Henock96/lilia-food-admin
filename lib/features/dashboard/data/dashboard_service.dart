import 'package:lilia_admin/core/network/api_client.dart';

class DashboardService {
  final ApiClient _api;

  DashboardService(this._api);

  /// Récupère les statistiques générales du dashboard
  Future<DashboardOverview> getOverview() async {
    final res = await _api.getJson('/dashboard/overview');
    return DashboardOverview.fromJson(_payloadMap(res.data));
  }

  /// Récupère les statistiques des commandes par statut
  Future<OrderStats> getOrderStats({String? period}) async {
    final res = await _api.getJson(
      '/dashboard/orders',
      query: {if (period != null) 'period': period},
    );
    return OrderStats.fromJson(_payloadMap(res.data));
  }

  /// Récupère les produits les plus vendus
  Future<List<TopProduct>> getTopProducts({
    int limit = 10,
    String? period,
  }) async {
    final res = await _api.getJson(
      '/dashboard/top-products',
      query: {'limit': '$limit', if (period != null) 'period': period},
    );
    final products = _payloadList(res.data);
    return products.map((p) => TopProduct.fromJson(_asMap(p))).toList();
  }

  /// Récupère l'évolution des revenus par jour
  Future<List<RevenueData>> getRevenueChart({int days = 30}) async {
    final res = await _api
        .getJson('/dashboard/revenue-chart', query: {'days': '$days'});
    final chartData = _payloadList(res.data);
    return chartData.map((d) => RevenueData.fromJson(_asMap(d))).toList();
  }

  /// Récupère les statistiques des clients
  Future<ClientStats> getClientStats() async {
    final res = await _api.getJson('/dashboard/clients');
    return ClientStats.fromJson(_payloadMap(res.data));
  }

  /// Récupère les heures de pointe
  Future<PeakHoursData> getPeakHours({String? period}) async {
    final res = await _api.getJson(
      '/dashboard/peak-hours',
      query: {if (period != null) 'period': period},
    );
    return PeakHoursData.fromJson(_payloadMap(res.data));
  }

  /// Récupère le classement des restaurants (ADMIN uniquement)
  Future<List<RestaurantRanking>> getRestaurantRanking({String? period}) async {
    final res = await _api.getJson(
      '/dashboard/restaurant-ranking',
      query: {if (period != null) 'period': period},
    );
    final rankings = _payloadList(res.data);
    return rankings
        .map((r) => RestaurantRanking.fromJson(_asMap(r)))
        .toList();
  }

  Map<String, dynamic> _payloadMap(dynamic decoded) {
    final map = decoded is Map<String, dynamic>
        ? decoded
        : (decoded is Map
            ? Map<String, dynamic>.from(decoded)
            : const <String, dynamic>{});
    final data = map['data'];
    if (data is Map<String, dynamic>) return data;
    return map;
  }

  List<dynamic> _payloadList(dynamic body) {
    if (body is List) return body;
    final decoded = body is Map<String, dynamic>
        ? body
        : body is Map
        ? Map<String, dynamic>.from(body)
        : const <String, dynamic>{};
    final data = decoded['data'];
    if (data is List) return data;
    final restaurants = decoded['restaurants'];
    if (restaurants is List) return restaurants;
    final items = decoded['items'];
    if (items is List) return items;
    if (decoded['date'] != null || decoded['hour'] != null) return [decoded];
    return const [];
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  return const [];
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _asString(dynamic value, [String fallback = '']) {
  final text = value?.toString();
  return text == null || text.isEmpty ? fallback : text;
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
      id: _asString(json['id']),
      nom: _asString(json['nom'], 'Restaurant'),
      imageUrl: json['imageUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      orderCount: _asInt(json['orderCount']),
      totalRevenue: _asDouble(json['totalRevenue']),
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
    final products = _asMap(json['products']);
    final clients = _asMap(json['clients']);
    return DashboardOverview(
      orders: OrdersOverview.fromJson(_asMap(json['orders'])),
      revenue: RevenueOverview.fromJson(_asMap(json['revenue'])),
      totalProducts: _asInt(products['total']),
      totalClients: _asInt(clients['total']),
      rating: RatingOverview.fromJson(_asMap(json['rating'])),
      totalRestaurants: json['totalRestaurants'] == null
          ? null
          : _asInt(json['totalRestaurants']),
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
      total: _asInt(json['total']),
      today: _asInt(json['today']),
      week: _asInt(json['week']),
      month: _asInt(json['month']),
      pending: _asInt(json['pending']),
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
      total: _asDouble(json['total']),
      today: _asDouble(json['today']),
      week: _asDouble(json['week']),
      month: _asDouble(json['month']),
      currency: _asString(json['currency'], 'XAF'),
    );
  }
}

class RatingOverview {
  final double average;
  final int count;

  RatingOverview({required this.average, required this.count});

  factory RatingOverview.fromJson(Map<String, dynamic> json) {
    return RatingOverview(
      average: _asDouble(json['average']),
      count: _asInt(json['count']),
    );
  }
}

class OrderStats {
  final List<StatusStat> byStatus;
  final OrderTotals totals;

  OrderStats({required this.byStatus, required this.totals});

  factory OrderStats.fromJson(Map<String, dynamic> json) {
    return OrderStats(
      byStatus: _asList(
        json['byStatus'],
      ).map((s) => StatusStat.fromJson(_asMap(s))).toList(),
      totals: OrderTotals.fromJson(_asMap(json['totals'])),
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
      status: _asString(json['status'], 'INCONNU'),
      count: _asInt(json['count']),
      revenue: _asDouble(json['revenue']),
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
      orders: _asInt(json['orders']),
      revenue: _asDouble(json['revenue']),
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
      rank: _asInt(json['rank']),
      product: json['product'] != null
          ? ProductInfo.fromJson(_asMap(json['product']))
          : null,
      totalSold: _asInt(json['totalSold']),
      totalRevenue: _asDouble(json['totalRevenue']),
      orderCount: _asInt(json['orderCount']),
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
      id: _asString(json['id']),
      name: _asString(json['nom'], 'Produit'),
      imageUrl: json['imageUrl'] as String?,
      price: _asDouble(json['prixOriginal']),
    );
  }
}

class RevenueData {
  final String date;
  final double revenue;
  final int orders;

  RevenueData({
    required this.date,
    required this.revenue,
    required this.orders,
  });

  factory RevenueData.fromJson(Map<String, dynamic> json) {
    return RevenueData(
      date: _asString(json['date']),
      revenue: _asDouble(json['revenue']),
      orders: _asInt(json['orders']),
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
    final lastMonth = _asMap(json['lastMonth']);
    return ClientStats(
      thisMonth: ThisMonthStats.fromJson(_asMap(json['thisMonth'])),
      lastMonthTotal: _asInt(lastMonth['total']),
      growth: json['growth']?.toString() ?? '0',
      topClients: _asList(
        json['topClients'],
      ).map((c) => TopClient.fromJson(_asMap(c))).toList(),
    );
  }
}

class ThisMonthStats {
  final int total;
  final int newClients;
  final int returning;

  ThisMonthStats({
    required this.total,
    required this.newClients,
    required this.returning,
  });

  factory ThisMonthStats.fromJson(Map<String, dynamic> json) {
    return ThisMonthStats(
      total: _asInt(json['total']),
      newClients: _asInt(json['new']),
      returning: _asInt(json['returning']),
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
      rank: _asInt(json['rank']),
      client: json['client'] != null
          ? ClientInfo.fromJson(_asMap(json['client']))
          : null,
      orderCount: _asInt(json['orderCount']),
      totalSpent: _asDouble(json['totalSpent']),
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
      id: _asString(json['id']),
      name: json['nom'] as String?,
      email: json['email'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}

class PeakHoursData {
  final List<HourStat> hours;
  final HourStat peakHour;

  PeakHoursData({required this.hours, required this.peakHour});

  factory PeakHoursData.fromJson(Map<String, dynamic> json) {
    final hours = _asList(json['data'] ?? json['hours']);
    final peakHour = _asMap(json['peakHour']);
    return PeakHoursData(
      hours: hours.map((h) => HourStat.fromJson(_asMap(h))).toList(),
      peakHour: HourStat.fromJson(peakHour),
    );
  }
}

class HourStat {
  final int hour;
  final int count;

  HourStat({required this.hour, required this.count});

  factory HourStat.fromJson(Map<String, dynamic> json) {
    return HourStat(hour: _asInt(json['hour']), count: _asInt(json['count']));
  }
}

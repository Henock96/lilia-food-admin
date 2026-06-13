import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/dashboard_service.dart';
import 'package:lilia_admin/core/network/api_client.dart';

part 'dashboard_provider.g.dart';

final dashboardServiceProvider =
    Provider((ref) => DashboardService(ref.watch(apiClientProvider)));

@riverpod
Future<DashboardOverview> dashboardOverview(Ref ref) async {
  final service = ref.read(dashboardServiceProvider);
  return await service.getOverview();
}

@riverpod
Future<OrderStats> orderStats(Ref ref, {String? period}) async {
  final service = ref.read(dashboardServiceProvider);
  return await service.getOrderStats(period: period);
}

@riverpod
Future<List<TopProduct>> topProducts(Ref ref, {int limit = 10, String? period}) async {
  final service = ref.read(dashboardServiceProvider);
  return await service.getTopProducts(limit: limit, period: period);
}

@riverpod
Future<List<RevenueData>> revenueChart(Ref ref, {int days = 30}) async {
  final service = ref.read(dashboardServiceProvider);
  return await service.getRevenueChart(days: days);
}

@riverpod
Future<ClientStats> clientStats(Ref ref) async {
  final service = ref.read(dashboardServiceProvider);
  return await service.getClientStats();
}

@riverpod
Future<PeakHoursData> peakHours(Ref ref, {String? period}) async {
  final service = ref.read(dashboardServiceProvider);
  return await service.getPeakHours(period: period);
}

@riverpod
Future<List<RestaurantRanking>> restaurantRanking(Ref ref, {String? period}) async {
  final service = ref.read(dashboardServiceProvider);
  return await service.getRestaurantRanking(period: period);
}

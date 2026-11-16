import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/features/dashboard/data/dashboard_service.dart';

/// Rend toujours le même corps JSON : la réponse réelle du serveur.
class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter(this.body);
  final Object body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      ResponseBody.fromString(
        jsonEncode(body),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}

DashboardService _serviceAnswering(Object body) {
  final api = ApiClient.test(
    baseUrl: 'http://test.local',
    tokenProvider: () async => 'jeton',
    forceRefreshToken: () async => 'jeton',
  );
  api.dio.httpClientAdapter = _JsonAdapter(body);
  return DashboardService(api);
}

void main() {
  // Lot D (16/11/2026) — produits phares et heures de pointe réservés au
  // Premium : l'app lit le verdict `premiumRequired` du serveur.
  group('Statistiques Premium (lot D)', () {
    test('vendeur Standard : produits phares vides + premiumRequired', () async {
      final result = await _serviceAnswering({
        'data': <Object>[],
        'premiumRequired': true,
      }).getTopProducts(limit: 5);

      expect(result.premiumRequired, isTrue);
      expect(result.products, isEmpty);
    });

    test('vendeur Premium : les produits, premiumRequired faux', () async {
      final result = await _serviceAnswering({
        'data': [
          {
            'rank': 1,
            'product': {'id': 'p1', 'nom': 'Poulet DG'},
            'totalSold': 3,
            'totalRevenue': 6000,
            'orderCount': 2,
          },
        ],
        'premiumRequired': false,
      }).getTopProducts(limit: 5);

      expect(result.premiumRequired, isFalse);
      expect(result.products.single.totalSold, 3);
    });

    test('serveur ancien (sans le champ) : aucune restriction', () async {
      final result = await _serviceAnswering({'data': <Object>[]})
          .getTopProducts(limit: 5);
      expect(result.premiumRequired, isFalse);
    });

    test('heures de pointe Standard : vides, peakHour nul toléré', () async {
      final peak = await _serviceAnswering({
        'data': <Object>[],
        'peakHour': null,
        'premiumRequired': true,
      }).getPeakHours();

      expect(peak.premiumRequired, isTrue);
      expect(peak.hours, isEmpty);
    });
  });

  group('Dashboard models', () {
    test('DashboardOverview tolerates missing nested fields', () {
      final overview = DashboardOverview.fromJson({
        'orders': {'today': 3},
        'revenue': {'today': '1500'},
      });

      expect(overview.orders.today, 3);
      expect(overview.orders.total, 0);
      expect(overview.revenue.today, 1500);
      expect(overview.totalProducts, 0);
      expect(overview.totalClients, 0);
      expect(overview.rating.average, 0);
    });

    test('ClientStats tolerates empty payloads', () {
      final stats = ClientStats.fromJson({});

      expect(stats.thisMonth.total, 0);
      expect(stats.lastMonthTotal, 0);
      expect(stats.topClients, isEmpty);
    });

    test('PeakHoursData accepts hours fallback without peakHour', () {
      final peakHours = PeakHoursData.fromJson({
        'hours': [
          {'hour': '12', 'count': 4},
        ],
      });

      expect(peakHours.hours.single.hour, 12);
      expect(peakHours.hours.single.count, 4);
      expect(peakHours.peakHour.hour, 0);
    });
  });
}

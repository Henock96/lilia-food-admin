import 'package:flutter_test/flutter_test.dart';
import 'package:lilia_admin/features/dashboard/data/dashboard_service.dart';

void main() {
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

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:lilia_admin/features/admin/data/admin_operations_repository.dart';
import 'package:lilia_admin/models/admin_payment.dart';
import 'package:lilia_admin/models/admin_deliverer.dart';
import 'package:lilia_admin/models/payments_stats.dart';
import 'package:lilia_admin/models/platform_settings.dart';
import 'package:lilia_admin/core/network/api_client.dart';

part 'admin_operations_provider.g.dart';

@riverpod
AdminOperationsRepository adminOperationsRepository(Ref ref) {
  return AdminOperationsRepository(ref.watch(apiClientProvider));
}

/// Paiements paginés (ADMIN). `status` vide → vue "Tous statuts confondus".
@riverpod
Future<PaginatedPayments> adminPayments(
  Ref ref, {
  required int page,
  required String status,
}) {
  return ref
      .watch(adminOperationsRepositoryProvider)
      .fetchPayments(page: page, status: status);
}

/// KPI paiements (ADMIN) — pending à confirmer, encaissé ce mois, 7j roulants.
@riverpod
Future<PaymentsStats> adminPaymentsStats(Ref ref) {
  return ref.watch(adminOperationsRepositoryProvider).fetchPaymentsStats();
}

/// Livreurs paginés (ADMIN).
@riverpod
Future<PaginatedDeliverers> adminDeliverers(Ref ref, {required int page}) {
  return ref
      .watch(adminOperationsRepositoryProvider)
      .fetchDeliverers(page: page);
}

/// Configuration plateforme (ADMIN).
@riverpod
Future<PlatformSettings> platformSettings(Ref ref) {
  return ref.watch(adminOperationsRepositoryProvider).fetchPlatformSettings();
}
